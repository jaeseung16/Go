//
//  GoTrainingExperience.swift
//  GoBoard
//
//  Created by Jae Seung Lee on 7/12/26.
//

import MLX

public struct GoTrainingExperience {
    
    public let states: MLXArray
    public let actions: MLXArray
    public let rewards: MLXArray
    
    public init(states: MLXArray, actions: MLXArray, rewards: MLXArray) {
        self.states = states
        self.actions = actions
        self.rewards = rewards
    }
    
}
