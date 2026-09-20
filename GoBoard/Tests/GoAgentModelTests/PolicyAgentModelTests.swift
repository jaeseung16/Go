//
//  PolicyAgentModelTests.swift
//  GoBoard
//
//  Created by Jae Seung Lee on 9/20/26.
//

import Foundation
import Testing
import MLX
import GoBoard
@testable import GoAgent

@Suite struct PolicyAgentModelTests {
    
    @Test func testPredictBatch() async throws {
        let boardTensor1 = [[[UInt8]]](repeating: [[UInt8]](repeating: [UInt8](repeating: 0, count: 11), count: 19), count: 19)
        let boardTensor2 = [[[UInt8]]](repeating: [[UInt8]](repeating: [UInt8](repeating: 1, count: 11), count: 19), count: 19)
        let boardTensors = [GoBoardTensor(data: boardTensor1), GoBoardTensor(data: boardTensor2)]
        
        let encoder = SimpleEncoder(boardDimension: 19)
        let network = Small(encoder: encoder)
        let agentModel = PolicyAgentModel(network: network)
        
        let predictions = agentModel.predict(from: boardTensors)
        #expect(predictions.count == 2)
        #expect(predictions[0].count == 361)
        #expect(predictions[1].count == 361)
    }
}
