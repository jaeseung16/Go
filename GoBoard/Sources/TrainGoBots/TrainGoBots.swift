//
//  TrainGoBots.swift
//  GoBoard
//
//  Created by Jae Seung Lee on 8/9/26.
//

import ArgumentParser
import Foundation
import GoAgent
import GoBoard
import GoBotsSupport
import Logging
import MLX
import MLXNN
import MLXOptimizers

@main
struct TraingGoBots: ParsableCommand {
    static var configuration: CommandConfiguration {
        .init(commandName: "train-go-bots",
              abstract: "Train Go bots with a reinforcement learning agent")
    }
    
    @Option(help: "The name of the model to be trained")
    var modelToTrain: String
    
    @Option(help: "The file name to save the trained agent")
    var trainedModel: String
    
    @Option(help: "The learning rate")
    var learningRate: Float = 0.0001
    
    @Option(help: "The clip norm")
    var clipNorm: Float = 1.0
    
    @Option(help: "The batch size")
    var batchSize: Int = 512
    
    @Argument(help: "The experience replay")
    var experiences: [String] = []
    
    func run() throws {

        guard !experiences.isEmpty else {
            print("Nothing to train")
            return
        }
        
        for experience in experiences {
            // Load experiences
            
            let experienceURL = URL(filePath: experience)
            
            let data: [String: MLX.MLXArray]
            do {
                data = try MLX.loadArrays(url: experienceURL)
            } catch {
                print("Cannot load experience: \(experience)")
                continue
            }
            
            // TODO: advantages
            guard let states = data["states"], let actions = data["actions"], let rewards = data["rewards"] else {
                print("Cannot load experience: \(experience)")
                continue
            }
            
            print("states: \(states.count), actions: \(actions.count), rewards: \(rewards.count)")
            
            let trainingExperience = GoTrainingExperience(states: states, actions: actions, rewards: rewards)
            
            // TODO: save and load model
            // Load model
            let modelURL = URL(filePath: modelToTrain)
            let (arrays, metadata) = try MLX.loadArraysAndMetadata(url: modelURL)
            
            let parameters = ModuleParameters.unflattened(arrays)
            
            let model = Small(encoder: SimpleEncoder(boardDimension: 9))
            
            model.update(parameters: parameters)
            
            // Train
            
            let policyAgentModel = PolicyAgentModel(model: model)
            let optimizer = SGD(learningRate: learningRate)
            
            // policyAgentModel.train(with: trainingExperience, optimizer: optimizer, clipNorm: clipNorm)
            
            // Save model
            
            
        }

    }

}
