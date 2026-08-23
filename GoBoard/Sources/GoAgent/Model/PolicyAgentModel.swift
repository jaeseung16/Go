//
//  PolicyAgentModel.swift
//  GoBoard
//
//  Created by Jae Seung Lee on 7/12/26.
//

import Foundation
import MLX
import MLXNN
import MLXOptimizers

public class PolicyAgentModel<Model: Module & UnaryLayer>: GoAgentModel {

    private let model: Model
    private let optimizer: Optimizer?
    private var messages = [String]()

    public init(model: Model, optimizer: Optimizer? = nil) {
        self.model = model
        self.optimizer = optimizer
    }
    
    public func predict(from boardTensor: MLXArray) -> [Int: Float] {
        let predictions = model(boardTensor).asArray(Float.self)
        return Dictionary(
            uniqueKeysWithValues: predictions.enumerated().map { ($0.offset, $0.element) }
        )
    }
    
    private static func loss(model: Model, x: MLXArray, y: MLXArray) -> MLXArray {
        crossEntropy(logits: model(x), targets: y, reduction: .mean)
    }
    
    public func train(with experiences: GoTrainingExperience, optimizer: Optimizer, clipNorm: Float) {
        model.train()
        defer {
            model.train(false)
        }
        
        eval(model)
        let lossAndGradient = valueAndGrad(model: model, Self.loss)
        var generator: RandomNumberGenerator = SplitMix64(seed: 0)
        
        let start = Date()
        print("Start training at \(start.formatted(date: .abbreviated, time: .standard))")
        for (x, y) in iterateBatches(batchSize: 32, experiences: experiences, using: &generator) {
            let (_, grads) = lossAndGradient(model, x, y)
            let (clippedGrads, _) = clipGradNorm(gradients: grads, maxNorm: clipNorm)
            optimizer.update(model: model, gradients: clippedGrads)
            
            eval(model, optimizer)
        }
        let end = Date()
        print("Training ended at \(end.formatted(date: .abbreviated, time: .standard)) \(end.timeIntervalSince(start))")

        messages.append("training time: \(end.timeIntervalSince(start))")
    }
    
    public func iterateBatches(batchSize: Int = 32, experiences: GoTrainingExperience, using generator: inout any RandomNumberGenerator) -> some Sequence<(MLXArray, MLXArray)> {
        let boardSize = experiences.states.shape[1] // TODO: - related to how to encode a game
        let targets = prepareTargets(experience: experiences, boardSize: boardSize)
        return BatchSequence(batchSize: batchSize, x: experiences.states, y: targets, using: &generator)
    }
    
    private struct BatchSequence: Sequence, IteratorProtocol {
        let batchSize: Int
        let x: MLXArray
        let y: MLXArray
        
        let indices: MLXArray
        var index = 0
        
        init(batchSize: Int, x: MLXArray, y: MLXArray, using generator: inout any RandomNumberGenerator) {
            self.batchSize = batchSize
            self.x = x
            self.y = y
            self.indices = MLXArray(Array(0 ..< y.size).shuffled(using: &generator))
        }
        
        mutating func next() -> (MLXArray, MLXArray)? {
            guard index < indices.size else { return nil }

            let rangeForBatch = index ..< Swift.min(index + batchSize, indices.size)
            let indiciesForBatch = indices[rangeForBatch]
            index += batchSize
            return (x[indiciesForBatch], y[indiciesForBatch])
        }
    }
    
    private func prepareTargets(experience: GoTrainingExperience, boardSize: Int) -> MLXArray {
        let experienceSize = experience.actions.shape[0]
        let targetVectors = MLXArray.zeros([experienceSize, boardSize * boardSize], type: Float.self)
        for (index, action) in experience.actions.enumerated() {
            targetVectors[index, action.asType(.int32)] = experience.rewards[index]
        }
        return targetVectors
    }
    
    public func save(to url: URL) throws -> Void {
        let arrays: [String: MLXArray] = Dictionary(uniqueKeysWithValues: model.parameters().flattened())
        let metadata: [String: String] = [:]
        try MLX.save(arrays: arrays, metadata: metadata, url: url)
    }
    
    public func load(from url: URL) throws -> Void {
        let (arrays, _) = try MLX.loadArraysAndMetadata(url: url)
        
        let parameters = ModuleParameters.unflattened(arrays)
        try model.update(parameters: parameters, verify: [.all])
        
        eval(model)
    }
    
}


public struct SplitMix64: RandomNumberGenerator, Sendable {
    private var state: UInt64
    
    public init(seed: UInt64) {
        self.state = seed
    }
    
    public mutating func next() -> UInt64 {
        self.state &+= 0x9e37_79b9_7f4a_7c15
        var z: UInt64 = self.state
        z = (z ^ (z &>> 30)) &* 0xbf58_476d_1ce4_e5b9
        z = (z ^ (z &>> 27)) &* 0x94d0_49bb_1331_11eb
        return z ^ (z &>> 31)
    }
}
