//
//  GoAgentTests.swift
//  GoBoard
//
//  Created by Jae Seung Lee on 6/21/26.
//

import Foundation
import Testing
import MLX
import GoBoard
@testable import GoAgent

@Suite struct GoAgentTests {
    @Test func testIsEyeCorner() async throws {
        let board = ZobristGoBoard()
        board.place(stone: .black, at: Point(row: 1, col: 2))
        board.place(stone: .black, at: Point(row: 2, col: 2))
        board.place(stone: .black, at: Point(row: 2, col: 1))
        
        let blackAgent = NaiveAgent(stone: .black)
        let whiteAgent = NaiveAgent(stone: .white)
        #expect(blackAgent.isEye(point: Point(row: 1, col: 1), on: board) == true)
        #expect(whiteAgent.isEye(point: Point(row: 1, col: 1), on: board) == false)
    }
    
    @Test func testIsNotEyeCorner() async throws {
        let board = ZobristGoBoard()
        board.place(stone: .black, at: Point(row: 1, col: 2))
        board.place(stone: .black, at: Point(row: 2, col: 1))
        
        let blackAgent = NaiveAgent(stone: .black)
        #expect(blackAgent.isEye(point: Point(row: 1, col: 1), on: board) == false)
        
        board.place(stone: .white, at: Point(row: 2, col: 2))
        #expect(blackAgent.isEye(point: Point(row: 1, col: 1), on: board) == false)
    }
 
    @Test func testMiddle() async throws {
        let board = ZobristGoBoard()
        board.place(stone: .black, at: Point(row: 2, col: 2))
        board.place(stone: .black, at: Point(row: 3, col: 2))
        board.place(stone: .black, at: Point(row: 4, col: 2))
        board.place(stone: .black, at: Point(row: 4, col: 3))
        board.place(stone: .black, at: Point(row: 4, col: 4))
        board.place(stone: .black, at: Point(row: 3, col: 4))
        board.place(stone: .black, at: Point(row: 2, col: 4))
        board.place(stone: .black, at: Point(row: 2, col: 3))
        
        let blackAgent = NaiveAgent(stone: .black)
        #expect(blackAgent.isEye(point: Point(row: 3, col: 3), on: board) == true)
    }
    
    @Test func testChoose() async throws {
        let moveProbs: [Float] = [0.1, 0.4, 0.4, 0.1]
        
        let rankedMoves = MLXRandom.categorical(moveProbs.asMLXArray(dtype: .float16), count: moveProbs.count)
        
        print(rankedMoves)
    }
    
    @Test func testSaveAndLoadWeights() async throws {
        let model = Small(encoder: SimpleEncoder(boardDimension: 19))
        let policyAgentModel = PolicyAgentModel(model: model, optimizer: nil)
        
        let tempURL = URL(fileURLWithPath: "temp_weights.safetensors")
        print("Saving experiences to \(tempURL.path)")
        
        try policyAgentModel.save(to: tempURL)
        print("Saved")
        try policyAgentModel.load(from: tempURL)
        print("Loaded")
        
        try FileManager.default.removeItem(at: tempURL)
        print("File successfully deleted.")
        
    }

}
