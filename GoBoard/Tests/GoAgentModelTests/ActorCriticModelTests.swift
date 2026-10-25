//
//  ActorCriticModelTests.swift
//  GoBoard
//
//  Created by Jae Seung Lee on 10/25/26.
//

import Foundation
import Testing
import MLX
import GoBoard
@testable import GoAgent

@Suite struct ActorCriticModelTests {
    @Test func testPredict() async throws {
        let boardTensor = [[[UInt8]]](repeating: [[UInt8]](repeating: [UInt8](repeating: 0, count: 11), count: 19), count: 19)
        
        let encoder = SimpleEncoder(boardDimension: 19)
        let network = ActorCriticNetwork(encoder: encoder)
        let agentModel = ActorCriticModel(network: network)
        
        let prediction = agentModel.predict(from: GoBoardTensor(data: boardTensor))
        #expect(prediction.count == 19*19 + 1)
    }
    
    @Test func testPredictBatch() async throws {
        let boardTensor1 = [[[UInt8]]](repeating: [[UInt8]](repeating: [UInt8](repeating: 0, count: 11), count: 19), count: 19)
        let boardTensor2 = [[[UInt8]]](repeating: [[UInt8]](repeating: [UInt8](repeating: 1, count: 11), count: 19), count: 19)
        let boardTensors = [GoBoardTensor(data: boardTensor1), GoBoardTensor(data: boardTensor2)]
        
        let encoder = SimpleEncoder(boardDimension: 19)
        let network = ActorCriticNetwork(encoder: encoder)
        let agentModel = ActorCriticModel(network: network)
        
        let predictions = agentModel.predict(from: boardTensors)
        #expect(predictions.count == 2)
        #expect(predictions[0].count == 19*19 + 1)
        #expect(predictions[1].count == 19*19 + 1)
    }
    
    @Test func testLossAndGrad() async throws {
        let boardTensor = MLXArray([UInt8](repeating: 0, count: 1 * 19 * 19 * 11), [1] + [19, 19, 11]).asType(.float16)
        let actionTensor = MLXArray([Float](repeating: 0, count: 1 * 19 * 19), [1] + [19, 19]).asType(.float16).expandedDimensions(axis: 3)
        let policyTargets = [Float](repeating: 0, count: 1 * 19 * 19)
        let valueTargets = [Float](repeating: 0, count: 1)
        
        let x = concatenated([boardTensor, actionTensor], axis: 3)
        let y1 = MLXArray(policyTargets, [1, 19 * 19])
        let y2 = MLXArray(valueTargets, [1, 1])
        
        let encoder = SimpleEncoder(boardDimension: 19)
        let network = ActorCriticNetwork(encoder: encoder)
        let agentModel = ActorCriticModel(network: network)
        
        let loss = agentModel.loss(network: network, x: x, y1: y1, y2: y2)
        #expect(loss.shape == [])
    }
    
    @Test func testLossAndGradBatch() async throws {
        let boardTensors = MLXArray([UInt8](repeating: 0, count: 2 * 19 * 19 * 11), [2] + [19, 19, 11]).asType(.float16)
        let actionTensors = MLXArray([Float](repeating: 0, count: 2 * 19 * 19), [2] + [19, 19]).asType(.float16).expandedDimensions(axis: 3)
        
        let policyTargets = [Float](repeating: 0, count: 2 * 19 * 19)
        let valueTargets = [Float](repeating: 0, count: 2)
        
        let x = concatenated([boardTensors, actionTensors], axis: 3)
        let y1 = MLXArray(policyTargets, [2, 19 * 19])
        let y2 = MLXArray(valueTargets, [2, 1])
        
        let encoder = SimpleEncoder(boardDimension: 19)
        let network = ActorCriticNetwork(encoder: encoder)
        let agentModel = ActorCriticModel(network: network)
        
        let loss = agentModel.loss(network: network, x: x, y1: y1, y2: y2)
        #expect(loss.shape == [])
    }

}
