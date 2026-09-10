//
//  TrainingBatchTests.swift
//  GoBoard
//
//  Created by Jae Seung Lee on 9/10/26.
//

import Foundation
import Testing
import MLX
import MLXNN
import MLXOptimizers
@testable import GoAgent

/// A one-layer policy, so that training over a large corpus stays fast.
final class LinearPolicy: Module, GoNetwork {

    @ModuleInfo var dense: Linear

    let shape: [Int]

    init(shape: [Int]) {
        self.shape = shape
        dense = Linear(shape.reduce(1, *), shape[0] * shape[1])
    }

    func callAsFunction(_ x: MLXArray) -> MLXArray {
        dense(flatten(x, startAxis: 1))
    }

}

@Suite struct TrainingBatchTests {

    /// Experience `i` has every plane set to `i`, action `i % 4`, and reward +1 or -1 by parity.
    private func makeExperience(count: Int, stateShape: [Int]) -> GoTrainingExperience {
        let featureCount = stateShape.reduce(1, *)
        let numberOfActions = stateShape[0] * stateShape[1]

        let states = (0 ..< count).flatMap { [UInt8](repeating: UInt8($0 % 256), count: featureCount) }
        let actions = (0 ..< count).map { Int32($0 % numberOfActions) }
        let rewards = (0 ..< count).map { Float($0 % 2 == 0 ? 1 : -1) }

        // Actions are float16 in files written by SelfPlay.
        return GoTrainingExperience(states: MLXArray(states, [count] + stateShape),
                                    actions: MLXArray(actions).asType(.float16),
                                    rewards: MLXArray(rewards))
    }

    @Test func batchesCarryEachExperienceOnceWithItsTarget() async throws {
        let stateShape = [2, 2, 3]
        let numberOfActions = 4
        let experience = makeExperience(count: 10, stateShape: stateShape)

        let model = PolicyAgentModel(network: LinearPolicy(shape: stateShape))
        var generator: RandomNumberGenerator = SplitMix64(seed: 0)

        var seen = [Int]()
        var batchSizes = [Int]()
        for (x, y) in model.iterateBatches(batchSize: 4, experiences: experience, using: &generator) {
            #expect(x.shape == [x.shape[0]] + stateShape)
            #expect(y.shape == [x.shape[0], numberOfActions])
            batchSizes.append(x.shape[0])

            let planes = x.asType(.float32).asArray(Float.self)
            let targets = y.asArray(Float.self)
            let featureCount = stateShape.reduce(1, *)

            for position in 0 ..< x.shape[0] {
                let row = planes[position * featureCount ..< (position + 1) * featureCount]
                let experienceIndex = Int(row.first!)
                #expect(row.allSatisfy { $0 == Float(experienceIndex) })
                seen.append(experienceIndex)

                var expected = [Float](repeating: 0, count: numberOfActions)
                expected[experienceIndex % numberOfActions] = experienceIndex % 2 == 0 ? 1 : -1
                #expect(Array(targets[position * numberOfActions ..< (position + 1) * numberOfActions]) == expected)
            }
        }

        #expect(batchSizes == [4, 4, 2])
        #expect(seen.sorted() == Array(0 ..< 10))
    }

    /// Building targets with one lazy scatter per experience made the graph as deep as the
    /// corpus, and `valueAndGrad` overflowed the stack on it at 39,386 experiences.
    @Test func trainingOnALargeCorpusCompletes() async throws {
        let stateShape = [3, 3, 1]
        let experience = makeExperience(count: 50_000, stateShape: stateShape)

        let model = PolicyAgentModel(network: LinearPolicy(shape: stateShape))
        model.train(with: experience, optimizer: SGD(learningRate: 0.01), batchSize: 4096, clipNorm: 1.0)
    }

}
