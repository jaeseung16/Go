//
//  ExperienceStore.swift
//  GoBoard
//
//  Created by Jae Seung Lee on 8/30/26.
//

import Foundation
import MLX

public enum ExperienceStoreError: Error, CustomStringConvertible {
    case missingArrays(url: URL, expected: [String])
    case malformedStates(url: URL, shape: [Int])

    public var description: String {
        switch self {
        case .missingArrays(let url, let expected):
            return "\(url.lastPathComponent) is missing one of \(expected.joined(separator: ", "))"
        case .malformedStates(let url, let shape):
            return "\(url.lastPathComponent) has states of shape \(shape); expected [count, rows, cols, planes]"
        }
    }
}

public protocol ExperienceStore {

    func write(_ buffer: ExperienceBuffer, to url: URL) throws

    func read(from url: URL) throws -> ExperienceBuffer

}

/// The one place a whole corpus crosses into MLX, and it crosses once per file.
///
/// Self-play used to reach MLX through three `MLXArray`s per decision and a `MLX.stacked`
/// over all of them; this builds four arrays, writes them, and lets them go.
public struct SafetensorsExperienceStore: ExperienceStore {

    private static let keys = ["states", "actions", "rewards", "advantages"]

    public init() {}

    public func write(_ buffer: ExperienceBuffer, to url: URL) throws {
        let arrays: [String: MLXArray] = [
            "states": MLXArray(buffer.states, buffer.batchedStateShape),
            "actions": MLXArray(buffer.actions),
            "rewards": MLXArray(buffer.rewards),
            "advantages": MLXArray(buffer.advantages),
        ]
        try MLX.save(arrays: arrays, url: url)
    }

    /// Converts on the way in, so files written with float16 actions still load.
    public func read(from url: URL) throws -> ExperienceBuffer {
        let data = try MLX.loadArrays(url: url)

        guard let states = data["states"],
              let actions = data["actions"],
              let rewards = data["rewards"],
              let advantages = data["advantages"] else {
            throw ExperienceStoreError.missingArrays(url: url, expected: Self.keys)
        }

        guard states.ndim == 4 else {
            throw ExperienceStoreError.malformedStates(url: url, shape: states.shape)
        }

        return ExperienceBuffer(stateShape: Array(states.shape.dropFirst()),
                                states: states.asType(.uint8).asArray(UInt8.self),
                                actions: actions.asType(.int32).asArray(Int32.self),
                                rewards: rewards.asType(.float32).asArray(Float.self),
                                advantages: advantages.asType(.float32).asArray(Float.self))
    }

}
