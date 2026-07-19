//
//  ExperienceCollector.swift
//  GoBoard
//
//  Created by Jae Seung Lee on 7/19/26.
//

import MLX

public class ExperienceCollector {
    
    public var shape: (Int, Int, Int)
    
    public var states: [MLXArray]
    public var actions: [MLXArray]
    public var rewards: [MLXArray]
    public var advantages: [MLXArray]
    
    private var statesFromCurrentEpisode: [MLXArray]
    private var actionsFromCurrentEpisode: [MLXArray]
    private var estimatedValuesFromCurrentEpisode: [MLXArray]
    
    init(shape: (Int, Int, Int)) {
        self.shape = shape
        
        self.states = []
        self.actions = []
        self.rewards = []
        self.advantages = []
        
        self.statesFromCurrentEpisode = []
        self.actionsFromCurrentEpisode = []
        self.estimatedValuesFromCurrentEpisode = []
    }
    
    public func beginEpisode() {
        self.statesFromCurrentEpisode = []
        self.actionsFromCurrentEpisode = []
        self.estimatedValuesFromCurrentEpisode = []
    }
    
    public func recordDecision(state: MLXArray, action: MLXArray, estimatedValue: MLXArray) {
        self.statesFromCurrentEpisode.append(state)
        self.actionsFromCurrentEpisode.append(action)
        self.estimatedValuesFromCurrentEpisode.append(estimatedValue)
    }
    
    public func completeEpisode(reward: MLXArray) {
        let numberOfStates = self.statesFromCurrentEpisode.count
        self.states += self.statesFromCurrentEpisode
        self.actions += self.actionsFromCurrentEpisode
        self.rewards += Array(repeating: reward, count: numberOfStates)
        
        for i in 0..<numberOfStates {
            let advantage = reward - self.estimatedValuesFromCurrentEpisode[i]
            self.advantages.append(advantage)
        }
    }

}

