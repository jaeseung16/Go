//
//  ExperienceBuffer.swift
//  GoBoard
//
//  Created by Jae Seung Lee on 7/19/26.
//

import MLX
import Foundation
import Logging

public struct ExperienceBuffer {
    private static let logger = Logger(label: "ExperienceBuffer")
    
    public var states: MLXArray
    public var actions: MLXArray
    public var rewards: MLXArray
    public var advantages: MLXArray

    public init(states: MLXArray, actions: MLXArray, rewards: MLXArray, advantages: MLXArray) {
        self.states = states
        self.actions = actions
        self.rewards = rewards
        self.advantages = advantages
    }
    
    public static func from(experiences: [ExperienceCollector]) -> ExperienceBuffer {
        print("states: \(MLX.stacked(experiences.flatMap(\.states)).shape)")
        print("actions: \(MLX.stacked(experiences.flatMap(\.actions)).shape)")
        print("rewards: \(MLX.stacked(experiences.flatMap(\.rewards)).shape)")
        print("advantages: \(MLX.stacked(experiences.flatMap(\.advantages)).shape)")
        return ExperienceBuffer(states: MLX.stacked(experiences.flatMap(\.states)),
                                actions: MLX.stacked(experiences.flatMap(\.actions)),
                                rewards: MLX.stacked(experiences.flatMap(\.rewards)),
                                advantages: MLX.stacked(experiences.flatMap(\.advantages)))
    }
    
    private var data: [String: MLXArray] {
        [
            "states": states,
            "actions": actions,
            "rewards": rewards,
            "advantages": advantages
        ]
    }
    
    public func save(to url: URL) {
        do {
            try MLX.save(arrays: self.data, url: url)
        } catch {
            Self.logger.error("Failed to save experience: \(error)")
        }
    }
    
    public static func load(from url: URL) -> ExperienceBuffer? {
        guard let data = try? MLX.loadArrays(url: url) else {
            Self.logger.error("Failed to load experience from \(url)")
            return nil
        }
        
        guard let states = data["states"], let actions = data["actions"], let rewards = data["rewards"], let advantages = data["advantages"] else {
            return nil
        }
        
        return ExperienceBuffer(states: states, actions: actions, rewards: rewards, advantages: advantages)
   
    }
    
}
