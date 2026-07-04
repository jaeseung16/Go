//
//  GoAgentTests.swift
//  GoBoard
//
//  Created by Jae Seung Lee on 6/21/26.
//

import Testing
import GoBoard
@testable import GoAgent

@Suite struct GoAgnetTests {
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

}
