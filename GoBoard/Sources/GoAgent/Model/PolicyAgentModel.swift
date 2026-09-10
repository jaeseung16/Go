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

public class PolicyAgentModel<Network: GoNetwork>: GoAgentModel {

    private let network: Network
    private let optimizer: Optimizer?
    private var messages = [String]()

    public init(network: Network, optimizer: Optimizer? = nil) {
        self.network = network
        self.optimizer = optimizer
    }
    
    public func predict(from boardTensor: [[[UInt8]]]) -> [Float] {
        // The first dimension is batch size (= 1)
        let x = MLXArray(boardTensor.flatMap {$0}.flatMap {$0}, [1] + network.shape).asType(.float16)
        let probabilities = softmax(network(x), axis: -1)
        return probabilities.asArray(Float.self)
    }

    /// Keras's `categorical_crossentropy` over a softmax head, as dlgo trains its policy agent:
    /// `-sum(y * log p)` per row, averaged over the batch. With `y` holding the reward at the
    /// chosen move, each row is `-reward * log p(move)`.
    ///
    /// Not `MLXNN.crossEntropy(logits:targets:)`: with probability targets it computes
    /// `logSumExp(z) - sum(y * z)`, which leaves the reward out of the `logSumExp` term and is
    /// wrong whenever the reward is not +1.
    static func loss(network: GoNetwork, x: MLXArray, y: MLXArray) -> MLXArray {
        -(y * logSoftmax(network(x), axis: -1)).sum(axis: -1).mean()
    }
    
    public func train(with experiences: GoTrainingExperience, optimizer: Optimizer, batchSize: Int, clipNorm: Float) {
        network.train()
        defer {
            network.train(false)
        }
        
        eval(network)
        let lossAndGradient = valueAndGrad(model: network, Self.loss)
        var generator: RandomNumberGenerator = SplitMix64(seed: 0)
        
        let start = Date()
        print("Start training at \(start.formatted(date: .abbreviated, time: .standard))")
        for (x, y) in iterateBatches(batchSize: batchSize, experiences: experiences, using: &generator) {
            let (loss, grads) = lossAndGradient(network, x, y)
            print("loss = \(loss)")
            let (clippedGrads, _) = clipGradNorm(gradients: grads, maxNorm: clipNorm)
            optimizer.update(model: network, gradients: clippedGrads)
            
            eval(network, optimizer)
        }
        let end = Date()
        print("Training ended at \(end.formatted(date: .abbreviated, time: .standard)) \(end.timeIntervalSince(start))")

        messages.append("training time: \(end.timeIntervalSince(start))")
    }
    
    public func iterateBatches(batchSize: Int = 32, experiences: GoTrainingExperience, using generator: inout any RandomNumberGenerator) -> some Sequence<(MLXArray, MLXArray)> {
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

            precondition(states.count == actions.count * featureCount && rewards.count == actions.count,
                         "states, actions and rewards disagree on the number of experiences")

            self.order = Array(0 ..< actions.count).shuffled(using: &generator)
        }

        mutating func next() -> (MLXArray, MLXArray)? {
            guard index < order.count else { return nil }

            let rows = order[index ..< Swift.min(index + batchSize, order.count)]
            index += batchSize

            var planes = [UInt8]()
            planes.reserveCapacity(rows.count * featureCount)
            var targets = [Float](repeating: 0, count: rows.count * numberOfActions)

            for (position, row) in rows.enumerated() {
                planes += states[row * featureCount ..< (row + 1) * featureCount]

                let action = Int(actions[row])
                precondition((0 ..< numberOfActions).contains(action), "action \(action) is out of range for \(numberOfActions) moves")
                targets[position * numberOfActions + action] = rewards[row]
            }

            let x = MLXArray(planes, [rows.count] + stateShape).asType(.float16)
            let y = MLXArray(targets, [rows.count, numberOfActions])
            return (x, y)
        }
    }
    
    public func save(to url: URL) throws -> Void {
        let arrays: [String: MLXArray] = Dictionary(uniqueKeysWithValues: network.parameters().flattened())
        let metadata: [String: String] = [:]
        try MLX.save(arrays: arrays, metadata: metadata, url: url)
    }
    
    public func load(from url: URL) throws -> Void {
        let (arrays, _) = try MLX.loadArraysAndMetadata(url: url)
        
        let parameters = ModuleParameters.unflattened(arrays)
        try network.update(parameters: parameters, verify: [.all])

        eval(network)
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
