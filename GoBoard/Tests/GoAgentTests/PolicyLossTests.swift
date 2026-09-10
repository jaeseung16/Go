//
//  PolicyLossTests.swift
//  GoBoard
//
//  Created by Jae Seung Lee on 9/10/26.
//

import Foundation
import Testing
import MLX
import MLXOptimizers
import GoBoard
@testable import GoAgent

@Suite struct PolicyLossTests {

    private static func emptyBoard(_ encoder: SimpleEncoder) -> [[[UInt8]]] {
        encoder.encode(gameState: GameState(board: ZobristGoBoard(dimension: 9), nextPlayer: .black))
    }

    @Test func lossIsRewardTimesNegativeLogProbability() async throws {
        let network = LinearPolicy(shape: [2, 2, 1])
        let x = MLXArray((0 ..< 12).map { Float($0) / 12 }, [3, 2, 2, 1])

        // One won move, one lost move, and a row with no reward.
        var targets = [Float](repeating: 0, count: 3 * 4)
        targets[0 * 4 + 1] = 1
        targets[1 * 4 + 2] = -1
        let y = MLXArray(targets, [3, 4])

        let logits = network(x).asArray(Float.self)
        var expected: Float = 0
        for row in 0 ..< 3 {
            let z = Array(logits[row * 4 ..< (row + 1) * 4])
            let logSumExp = log(z.map { exp($0) }.reduce(0, +))
            for action in 0 ..< 4 {
                expected -= targets[row * 4 + action] * (z[action] - logSumExp)
            }
        }
        expected /= 3

        let loss = PolicyAgentModel<LinearPolicy>.loss(network: network, x: x, y: y).item(Float.self)
        #expect(abs(loss - expected) < 1e-5)
    }

    @Test func predictReturnsOneDistributionOverTheBoard() async throws {
        let encoder = SimpleEncoder(boardDimension: 9)
        let model = PolicyAgentModel(network: Small(encoder: encoder))

        let probabilities = model.predict(from: Self.emptyBoard(encoder))

        #expect(probabilities.count == 81)
        #expect(probabilities.allSatisfy { $0 >= 0 })
        #expect(abs(probabilities.reduce(0, +) - 1) < 1e-4)
    }

    /// A softmax over the whole batch followed by a second softmax in the loss left gradients
    /// four to five orders of magnitude too small, so training never moved the policy.
    @Test(arguments: [Float(1), Float(-1)])
    func trainingMovesTheChosenMoveWithItsReward(reward: Float) async throws {
        let encoder = SimpleEncoder(boardDimension: 9)
        let model = PolicyAgentModel(network: Small(encoder: encoder))
        let board = Self.emptyBoard(encoder)
        let action = 40
        let count = 64

        let planes = board.flatMap { $0.flatMap { $0 } }
        let experience = GoTrainingExperience(
            states: MLXArray(Array([[UInt8]](repeating: planes, count: count).joined()), [count] + encoder.shape),
            actions: MLXArray([Int32](repeating: Int32(action), count: count)),
            rewards: MLXArray([Float](repeating: reward, count: count)))

        let before = model.predict(from: board)[action]
        model.train(with: experience, optimizer: SGD(learningRate: 0.1), batchSize: 16, clipNorm: 1.0)
        let after = model.predict(from: board)[action]

        print("reward=\(reward) p(before)=\(before) p(after)=\(after)")
        if reward > 0 {
            #expect(after > before * 1.1)
        } else {
            #expect(after < before / 1.1)
        }
    }

}
