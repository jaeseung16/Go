//
//  ActorCriticModel.swift
//  GoBoard
//
//  Created by Jae Seung Lee on 10/4/26.
//

import Foundation
import MLX
import MLXNN
import MLXOptimizers

public class ActorCriticModel<Network: GoNetwork>: GoAgentModel {
    
    private let network: Network
    private let optimizer: Optimizer?
    private var messages = [String]()
    private let lossWeights: [Float]
    
    public let name: String = GoAgentModelName.actorCritic.rawValue
    
    public var encoder: GoBoardEncoder {
        network.encoder
    }

    public init(network: Network, optimizer: Optimizer? = nil, lossWeights: [Float] = [1.0, 0.5]) {
        self.network = network
        self.optimizer = optimizer
        self.lossWeights = lossWeights
    }
    
    public func predict(from boardTensor: GoBoardTensor) -> [Float] {
        // The first dimension is batch size (= 1)
        let x = MLXArray(boardTensor.data.flatMap {$0}.flatMap {$0}, [1] + network.shape).asType(.float16)
        return network(x).asArray(Float.self)
    }
    
    public func predict(from boardTensors: [GoBoardTensor]) -> [[Float]] {
        // The first dimension is batch size (= 1)
        let x = MLXArray(boardTensors.flatMap { $0.data.flatMap {$0}.flatMap {$0} }, [boardTensors.count] + network.shape).asType(.float16)
        return network(x).map { $0.asArray(Float.self) }
    }
    
    public func predict(from boardTensor: GoBoardTensor, action: GoActionTensor) -> [Float] {
        fatalError("You must use predict(from:)")
    }
    
    public func predict(from boardTensors: [GoBoardTensor], actions: [GoActionTensor]) -> [[Float]] {
        fatalError("You must use predict(from:)")
    }
    
    func loss(network: GoNetwork, x: MLXArray, y1: MLXArray, y2: MLXArray) -> MLXArray {
        let output = split(network(x), indices: [network.shape[0] * network.shape[1]], axis: 1)
        let loss1 =   (-1.0 * y1 * logSoftmax(output[0], axis: -1)).sum(axis: -1).mean()
        let loss2 = mseLoss(predictions: output[1], targets: y2, reduction: .sum)
        return self.lossWeights[0] * loss1 + self.lossWeights[1] * loss2
    }
    
    public func train(with experiences: GoTrainingExperience, optimizer: any MLXOptimizers.Optimizer, batchSize: Int, clipNorm: Float) {
        
        network.train()
        defer {
            network.train(false)
        }
        
        eval(network)
        let lossAndGradient = valueAndGrad(model: network) { model, args -> [MLXArray] in
            [self.loss(network: model, x: args[0], y1: args[1], y2: args[2])]
        }
        var generator: RandomNumberGenerator = SplitMix64(seed: 0)
        
        let start = Date()
        print("Start training at \(start.formatted(date: .abbreviated, time: .standard))")
        for (x, y1, y2) in iterateBatches(batchSize: batchSize, experiences: experiences, using: &generator) {
            let (loss, grads) = lossAndGradient(network, [x, y1, y2])
            print("loss = \(loss)")
            let (clippedGrads, _) = clipGradNorm(gradients: grads, maxNorm: clipNorm)
            optimizer.update(model: network, gradients: clippedGrads)
            
            eval(network, optimizer)
        }
        let end = Date()
        print("Training ended at \(end.formatted(date: .abbreviated, time: .standard)) \(end.timeIntervalSince(start))")

        messages.append("training time: \(end.timeIntervalSince(start))")
        
    }
    
    public func save(to url: URL) throws {
        let arrays: [String: MLXArray] = Dictionary(uniqueKeysWithValues: network.parameters().flattened())
        let metadata: [String: String] = ["encoder": network.encoder.name, "network": network.name, "agentModel": name]
        try MLX.save(arrays: arrays, metadata: metadata, url: url)
    }
    
    public func load(from url: URL) throws {
        let (arrays, _) = try MLX.loadArraysAndMetadata(url: url)
        
        let parameters = ModuleParameters.unflattened(arrays)
        try network.update(parameters: parameters, verify: [.all])

        eval(network)
    }
    
    public func iterateBatches(batchSize: Int = 32, experiences: GoTrainingExperience, using generator: inout any RandomNumberGenerator) -> some Sequence<(MLXArray, MLXArray, MLXArray)> {
        BatchSequence(batchSize: batchSize, experiences: experiences, using: &generator)
    }

    /// Builds each batch's inputs and targets in host memory and hands MLX two fresh arrays.
    ///
    /// The corpus is read back from the device once, up front. Targets used to be built by
    /// scattering one experience at a time into a single `MLXArray`, which chains one lazy
    /// operation per experience onto the graph. `valueAndGrad` walks that graph recursively,
    /// so tens of thousands of experiences overflowed the stack on the first batch.
    private struct BatchSequence: Sequence, IteratorProtocol {
        let batchSize: Int
        let stateShape: [Int]
        let featureCount: Int
        let numberOfActions: Int

        let states: [UInt8]
        let actions: [Int32]
        let rewards: [Float]
        let advantages: [Float]

        let order: [Int]
        var index = 0

        init(batchSize: Int, experiences: GoTrainingExperience, using generator: inout any RandomNumberGenerator) {
            self.batchSize = batchSize
            self.stateShape = Array(experiences.states.shape.dropFirst()) // [rows, cols, planes]
            self.featureCount = stateShape.reduce(1, *)
            self.numberOfActions = stateShape[0] * stateShape[1] // TODO: - related to how to encode a game

            self.states = experiences.states.asType(.uint8).asArray(UInt8.self)
            self.actions = experiences.actions.asType(.int32).asArray(Int32.self)
            self.rewards = experiences.rewards.asType(.float32).asArray(Float.self)
            self.advantages = experiences.advanteges?.asType(.float32).asArray(Float.self) ?? []

            precondition(states.count == actions.count * featureCount && rewards.count == actions.count && advantages.count == actions.count,
                         "states, actions, rewards, and advantages disagree on the number of experiences")

            self.order = Array(0 ..< actions.count).shuffled(using: &generator)
        }

        mutating func next() -> (MLXArray, MLXArray, MLXArray)? {
            guard index < order.count else { return nil }

            let rows = order[index ..< Swift.min(index + batchSize, order.count)]
            index += batchSize

            var planes = [UInt8]()
            planes.reserveCapacity(rows.count * featureCount)
            var policyTargets = [Float](repeating: 0, count: rows.count * numberOfActions)
            var valueTargets = [Float](repeating: 0, count: rows.count)
            var actionVectors = [Float](repeating: 0, count: rows.count * numberOfActions)

            for (position, row) in rows.enumerated() {
                planes += states[row * featureCount ..< (row + 1) * featureCount]

                let action = Int(actions[row])
                precondition((0 ..< numberOfActions).contains(action), "action \(action) is out of range for \(numberOfActions) moves")
                policyTargets[position * numberOfActions + action] = rewards[row]
                valueTargets[position] = advantages[row]
                actionVectors[position * numberOfActions + action] = 1
            }

            let boardTensor = MLXArray(planes, [rows.count] + stateShape).asType(.float16)
            let actionTensor = MLXArray(actionVectors, [rows.count] + [stateShape[0], stateShape[1]]).asType(.float16).expandedDimensions(axis: 3)
            let x = concatenated([boardTensor, actionTensor], axis: 3)
            let y1 = MLXArray(policyTargets, [rows.count, numberOfActions])
            let y2 = MLXArray(valueTargets, [rows.count])
            return (x, y1, y2)
        }
    }
    
    
}
