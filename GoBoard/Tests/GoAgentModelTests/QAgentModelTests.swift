//
//  QAgentModelTests.swift
//  GoBoard
//
//  Created by Jae Seung Lee on 9/19/26.
//

import Foundation
import Testing
import MLX
import GoBoard
@testable import GoAgent

@Suite struct QAgentModelTests {

    @Test func testConcatSplitMLXArry() async throws {
        let boardTensor = [[[UInt8]]](repeating: [[UInt8]](repeating: [UInt8](repeating: 0, count: 11), count: 19), count: 19)
        let action = Array(repeating: [UInt8](repeating: 0, count: 19), count: 19)
        
        let x1 = MLXArray(boardTensor.flatMap {$0}.flatMap {$0}, [1] + [19, 19, 11]).asType(.float16)
        let x2 = MLXArray(action.flatMap {$0}, [1] + [19, 19]).asType(.float16).expandedDimensions(axis: 3)
        #expect(x1.shape == [1, 19, 19, 11])
        #expect(x2.shape == [1, 19, 19, 1])
        
        let concat = concatenated([x1, x2], axis: 3)
        #expect(concat.shape == [1, 19, 19, 12])
        
        let x3 = split(concat, indices: [11], axis: 3)
        #expect(x3.count == 2)
        #expect(x3[0].shape == [1, 19, 19, 11])
        #expect(x3[1].shape == [1, 19, 19, 1])
    }
    
    @Test func testPredictOne() async throws {
        let boardTensor = [[[UInt8]]](repeating: [[UInt8]](repeating: [UInt8](repeating: 0, count: 11), count: 19), count: 19)
        let action = Array(repeating: [UInt8](repeating: 0, count: 19), count: 19)
        
        let encoder = SimpleEncoder(boardDimension: 19)
        let network = QNetwork(encoder: encoder)
        let agentModel = QAgentModel(network: network)
        
        let prediction = agentModel.predict(from: GoBoardTensor(data: boardTensor), action: GoActionTensor(data: action))
        #expect(prediction.count == 1)
    }
    
    @Test func testPredictBatch() async throws {
        let boardTensor = [[[UInt8]]](repeating: [[UInt8]](repeating: [UInt8](repeating: 0, count: 11), count: 19), count: 19)
        let action1 = Array(repeating: [UInt8](repeating: 1, count: 19), count: 19)
        let action2 = Array(repeating: [UInt8](repeating: 2, count: 19), count: 19)
        
        let boardTensors = [GoBoardTensor](repeating: .init(data: boardTensor), count: 2)
        let actionTensors = [GoActionTensor(data: action1), GoActionTensor(data: action2)]
        
        let encoder = SimpleEncoder(boardDimension: 19)
        let network = QNetwork(encoder: encoder)
        let agentModel = QAgentModel(network: network)
        
        let predictions = agentModel.predict(from: boardTensors, actions: actionTensors)
        #expect(predictions.count == 2)
    }
}

