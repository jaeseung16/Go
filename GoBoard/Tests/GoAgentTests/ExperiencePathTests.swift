//
//  ExperiencePathTests.swift
//  GoBoard
//
//  Created by Jae Seung Lee on 8/30/26.
//

import Foundation
import Testing
import MLX
import GoBoard
@testable import GoAgent

/// Covers the experience path without tensors: the collector accumulates plain bytes,
/// and the store is the only thing that turns them into `MLXArray`s.
@Suite struct ExperiencePathTests {

    private static func game(nextPlayer: Player = .black) -> GameState {
        GameState(board: ZobristGoBoard(dimension: 9), nextPlayer: nextPlayer)
    }

    private static func flattened(_ state: [[[UInt8]]]) -> [UInt8] {
        state.flatMap { $0.flatMap { $0 } }
    }

    private static func temporaryURL() -> URL {
        URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("experience-\(UUID().uuidString).safetensors")
    }

    @Test func collectorCommitsOnlyCompletedEpisodes() async throws {
        let encoder = SimpleEncoder(boardDimension: 9)
        let collector = ExperienceCollector(stateShape: encoder.shape)
        let blackToPlay = encoder.encode(gameState: Self.game(nextPlayer: .black))
        let whiteToPlay = encoder.encode(gameState: Self.game(nextPlayer: .white))

        collector.beginEpisode()
        collector.recordDecision(state: blackToPlay, action: 12, estimatedValue: 0)
        collector.recordDecision(state: whiteToPlay, action: 34, estimatedValue: 0.25)
        collector.completeEpisode(reward: 1)

        // A second episode is abandoned: beginEpisode drops what it left behind.
        collector.beginEpisode()
        collector.recordDecision(state: blackToPlay, action: 56, estimatedValue: 0)
        collector.beginEpisode()

        #expect(collector.count == 2)

        let buffer = collector.makeBuffer()
        #expect(buffer.count == 2)
        #expect(buffer.actions == [12, 34])
        #expect(buffer.rewards == [1, 1])
        #expect(buffer.advantages == [1, 0.75])
        #expect(buffer.states.count == 2 * buffer.featureCount)
        #expect(Array(buffer.state(at: 0)) == Self.flattened(blackToPlay))
        #expect(Array(buffer.state(at: 1)) == Self.flattened(whiteToPlay))
    }

    @Test func mergingConcatenatesBuffersThatShareAShape() async throws {
        let encoder = SimpleEncoder(boardDimension: 9)
        let state = encoder.encode(gameState: Self.game())

        func buffer(action: Int, reward: Float) -> ExperienceBuffer {
            let collector = ExperienceCollector(stateShape: encoder.shape)
            collector.beginEpisode()
            collector.recordDecision(state: state, action: action, estimatedValue: 0)
            collector.completeEpisode(reward: reward)
            return collector.makeBuffer()
        }

        let merged = try #require(ExperienceBuffer.merging([buffer(action: 1, reward: 1),
                                                           buffer(action: 2, reward: -1)]))
        #expect(merged.count == 2)
        #expect(merged.actions == [1, 2])
        #expect(merged.rewards == [1, -1])
        #expect(merged.states.count == 2 * merged.featureCount)

        let mismatched = ExperienceBuffer.merging([buffer(action: 1, reward: 1),
                                                   ExperienceBuffer(stateShape: [19, 19, 11],
                                                                    states: [], actions: [],
                                                                    rewards: [], advantages: [])])
        #expect(mismatched == nil)
    }

    @Test func storeRoundTripsABuffer() async throws {
        let encoder = SimpleEncoder(boardDimension: 9)
        let collector = ExperienceCollector(stateShape: encoder.shape)
        let state = encoder.encode(gameState: Self.game())

        collector.beginEpisode()
        collector.recordDecision(state: state, action: 7, estimatedValue: 0.5)
        collector.recordDecision(state: state, action: 8, estimatedValue: -0.5)
        collector.completeEpisode(reward: -1)

        let written = collector.makeBuffer()
        let store = SafetensorsExperienceStore()
        let url = Self.temporaryURL()
        defer { try? FileManager.default.removeItem(at: url) }

        try store.write(written, to: url)
        let read = try store.read(from: url)

        #expect(read == written)
    }

    @Test func storeReadsFilesWithFloat16Actions() async throws {
        // SelfPlay wrote actions as float16 while the collector held MLXArrays.
        let url = Self.temporaryURL()
        defer { try? FileManager.default.removeItem(at: url) }

        try MLX.save(arrays: [
            "states": MLXArray([UInt8](repeating: 1, count: 2 * 3 * 3 * 2), [2, 3, 3, 2]),
            "actions": MLXArray([Int32(4), Int32(8)]).asType(.float16),
            "rewards": MLXArray([Float(1), Float(-1)]),
            "advantages": MLXArray([Float(1), Float(-1)]),
        ], url: url)

        let buffer = try SafetensorsExperienceStore().read(from: url)
        #expect(buffer.stateShape == [3, 3, 2])
        #expect(buffer.actions == [4, 8])
        #expect(buffer.rewards == [1, -1])
    }

    @Test func trainerReadsWhatTheStoreWrites() async throws {
        let encoder = SimpleEncoder(boardDimension: 9)
        let collector = ExperienceCollector(stateShape: encoder.shape)
        let state = encoder.encode(gameState: Self.game())

        collector.beginEpisode()
        collector.recordDecision(state: state, action: 10, estimatedValue: 0)
        collector.completeEpisode(reward: -1)

        let url = Self.temporaryURL()
        defer { try? FileManager.default.removeItem(at: url) }
        try SafetensorsExperienceStore().write(collector.makeBuffer(), to: url)

        // The same load TrainGoBots does.
        let arrays = try MLX.loadArrays(url: url)
        let experience = GoTrainingExperience(states: try #require(arrays["states"]),
                                              actions: try #require(arrays["actions"]),
                                              rewards: try #require(arrays["rewards"]))

        let model = PolicyAgentModel(network: Small(encoder: encoder))
        var generator: RandomNumberGenerator = SplitMix64(seed: 0)
        let batches = Array(model.iterateBatches(batchSize: 32, experiences: experience, using: &generator))

        #expect(batches.count == 1)
        let (x, y) = try #require(batches.first)
        #expect(x.shape == [1, 9, 9, 11])
        #expect(x.asType(.uint8).asArray(UInt8.self) == Self.flattened(state))

        var expected = [Float](repeating: 0, count: 81)
        expected[10] = -1
        #expect(y.asArray(Float.self) == expected)
    }

    @Test func policyAgentRecordsTheMoveItPlays() async throws {
        let encoder = SimpleEncoder(boardDimension: 9)
        let model = PolicyAgentModel(network: Small(encoder: encoder))
        let collector = ExperienceCollector(stateShape: encoder.shape)

        let agent = PolicyAgent(stone: .black, encoder: encoder, model: model)
        agent.experienceCollector = collector

        collector.beginEpisode()
        let move = agent.select(from: Self.game())
        collector.completeEpisode(reward: 1)

        guard case .play(_, let point) = move else {
            Issue.record("expected a play on an empty board, got \(move)")
            return
        }
        let buffer = collector.makeBuffer()
        #expect(buffer.count == 1)
        #expect(encoder.decode(index: Int(buffer.actions[0])) == point)
    }

}
