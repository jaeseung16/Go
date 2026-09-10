//
//  ExperienceBuffer.swift
//  GoBoard
//
//  Created by Jae Seung Lee on 7/19/26.
//

/// A finished corpus of self-play decisions, held as plain bytes.
///
/// Inert by design. Turning this into tensors is the job of an ``ExperienceStore``
/// (once per file) or of the training batch loop (once per batch), and never of the
/// code that produces it.
public struct ExperienceBuffer: Sendable, Equatable {

    /// `[rows, cols, planes]` -- the shape of a *single* state.
    public let stateShape: [Int]

    /// `count * featureCount` elements, one encoded position after another.
    public var states: [UInt8]
    public var actions: [Int32]
    public var rewards: [Float]
    public var advantages: [Float]

    public init(stateShape: [Int], states: [UInt8], actions: [Int32], rewards: [Float], advantages: [Float]) {
        precondition(actions.count == rewards.count && actions.count == advantages.count,
                     "actions, rewards and advantages must line up: \(actions.count)/\(rewards.count)/\(advantages.count)")
        precondition(states.count == actions.count * stateShape.reduce(1, *),
                     "states holds \(states.count) elements, \(actions.count) decisions of shape \(stateShape) need \(actions.count * stateShape.reduce(1, *))")
        self.stateShape = stateShape
        self.states = states
        self.actions = actions
        self.rewards = rewards
        self.advantages = advantages
    }

    /// Elements in one encoded position.
    public var featureCount: Int {
        self.stateShape.reduce(1, *)
    }

    /// The number of decisions.
    public var count: Int {
        self.actions.count
    }

    /// The shape `states` takes once batched: `[count, rows, cols, planes]`.
    public var batchedStateShape: [Int] {
        [self.count] + self.stateShape
    }

    /// The elements of the state recorded for decision `index`.
    public func state(at index: Int) -> ArraySlice<UInt8> {
        let start = index * self.featureCount
        return self.states[start ..< start + self.featureCount]
    }

    /// Concatenates buffers that share a state shape -- self-play keeps one
    /// collector per seat, and training wants them as a single corpus.
    public static func merging(_ buffers: [ExperienceBuffer]) -> ExperienceBuffer? {
        guard let first = buffers.first else { return nil }
        guard buffers.allSatisfy({ $0.stateShape == first.stateShape }) else { return nil }

        var merged = first
        merged.states.reserveCapacity(buffers.reduce(0) { $0 + $1.states.count })
        merged.actions.reserveCapacity(buffers.reduce(0) { $0 + $1.count })

        for buffer in buffers.dropFirst() {
            merged.states += buffer.states
            merged.actions += buffer.actions
            merged.rewards += buffer.rewards
            merged.advantages += buffer.advantages
        }
        return merged
    }

}
