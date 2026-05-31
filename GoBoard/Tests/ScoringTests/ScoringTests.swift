//
//  ScoringTest.swift
//  GoBoard
//
//  Created by Jae Seung Lee on 5/17/26.
//

import Testing
@testable import GoBoard

@Suite struct ScoringTests {
    
    @Test func testScoring() {
        // .w.ww
        // wwww.
        // bbbww
        // .bbbb
        // .b.b.
        
        let board = ZobristGoBoard(dimension: 5)
        board.place(stone: .black, at: Point(row: 1, col: 2))
        board.place(stone: .black, at: Point(row: 1, col: 4))
        board.place(stone: .black, at: Point(row: 2, col: 2))
        board.place(stone: .black, at: Point(row: 2, col: 3))
        board.place(stone: .black, at: Point(row: 2, col: 4))
        board.place(stone: .black, at: Point(row: 2, col: 5))
        board.place(stone: .black, at: Point(row: 3, col: 1))
        board.place(stone: .black, at: Point(row: 3, col: 2))
        board.place(stone: .black, at: Point(row: 3, col: 3))
        board.place(stone: .white, at: Point(row: 3, col: 4))
        board.place(stone: .white, at: Point(row: 3, col: 5))
        board.place(stone: .white, at: Point(row: 4, col: 1))
        board.place(stone: .white, at: Point(row: 4, col: 2))
        board.place(stone: .white, at: Point(row: 4, col: 3))
        board.place(stone: .white, at: Point(row: 4, col: 4))
        board.place(stone: .white, at: Point(row: 5, col: 2))
        board.place(stone: .white, at: Point(row: 5, col: 4))
        board.place(stone: .white, at: Point(row: 5, col: 5))
        
        let gameState = GameState(board: board, nextPlayer: .black)
        let territory = ScoringHelper(gameState: gameState).computeTerritory()
        
        #expect(9 == territory.numBlackStones)
        #expect(4 == territory.numBlackTerritory)
        #expect(9 == territory.numWhiteStones)
        #expect(3 == territory.numWhiteTerritory)
        #expect(0 == territory.numDames)
    }
    
}
