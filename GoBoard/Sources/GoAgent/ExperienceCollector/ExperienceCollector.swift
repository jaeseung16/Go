//
//  ExperienceCollector.swift
//  GoBoard
//
//  Created by Jae Seung Lee on 7/19/26.
//

/// Accumulates self-play decisions into flat, contiguous Swift arrays.
///
/// Nothing here holds an `MLXArray`. Storing a tensor per decision pinned about three Metal
/// buffers each for the whole run, against a fixed device limit of live buffers.
///
/// Decisions are appended straight into the run-level storage and only *committed* by
/// ``completeEpisode(reward:)``; ``beginEpisode()`` discards anything an abandoned episode
/// left behind.
public class ExperienceCollector {

    /// `[rows, cols, planes]` -- the shape of a single state.
    public let stateShape: [Int]
    private let featureCount: Int

    private var states: [UInt8] = []
    private var actions: [Int32] = []
    private var rewards: [Float] = []
    private var advantages: [Float] = []

    /// Value estimates for the episode in progress. Its count is also how many
    /// trailing decisions in `states` and `actions` are still uncommitted.
    private var estimatedValuesFromCurrentEpisode: [Float] = []

    /// Decisions committed by completed episodes.
    public private(set) var count = 0

    public init(stateShape: [Int]) {
        self.stateShape = stateShape
        self.featureCount = stateShape.reduce(1, *)
    }

    public func beginEpisode() {
        self.discardUncommitted()
    }

    /// `state` is a board tensor nested as [row][col][feature].
    public func recordDecision(state: [[[UInt8]]], action: Int, estimatedValue: Float) {
        let start = self.states.count
        for row in state {
            for features in row {
                self.states += features
            }
        }
        precondition(state.count == self.stateShape[0] && self.states.count - start == self.featureCount,
                     "state does not match collector shape \(self.stateShape)")

        self.actions.append(Int32(action))
        self.estimatedValuesFromCurrentEpisode.append(estimatedValue)
    }

    public func completeEpisode(reward: Float) {
        let numberOfStates = self.estimatedValuesFromCurrentEpisode.count

        self.rewards += repeatElement(reward, count: numberOfStates)
        self.advantages += self.estimatedValuesFromCurrentEpisode.map { reward - $0 }

        self.count += numberOfStates
        self.estimatedValuesFromCurrentEpisode.removeAll(keepingCapacity: true)
    }

    /// The committed decisions, as a buffer. Anything an unfinished episode left
    /// behind is dropped rather than shipped.
    public func makeBuffer() -> ExperienceBuffer {
        self.discardUncommitted()
        return ExperienceBuffer(stateShape: self.stateShape,
                                states: self.states,
                                actions: self.actions,
                                rewards: self.rewards,
                                advantages: self.advantages)
    }

    private func discardUncommitted() {
        let pending = self.estimatedValuesFromCurrentEpisode.count
        guard pending > 0 else { return }

        self.states.removeLast(pending * self.featureCount)
        self.actions.removeLast(pending)
        self.estimatedValuesFromCurrentEpisode.removeAll(keepingCapacity: true)
    }

}
