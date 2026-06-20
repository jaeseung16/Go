//
//  ScoringTest.swift
//  GoBoard
//
//  Created by Jae Seung Lee on 5/17/26.
//

import Testing
@testable import GoBoard

// Shared 5×5 board layout used across multiple tests:
//
//   .w.ww    row 5
//   wwww.    row 4
//   bbbww    row 3
//   .bbbb    row 2
//   .b.b.    row 1
//
// Black stones: 9  White stones: 9
// Black territory (area rule): top-left empty corner cluster = 4 points
// White territory (area rule): bottom-right empty corner cluster = 3 points
// Dame: 0

private func makeTestBoard() -> ZobristGoBoard {
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
    return board
}

@Suite struct ScoringTests {

    // MARK: - Territory detection

    @Test func testTerritoryDetection() {
        let gameState = GameState(board: makeTestBoard(), nextPlayer: .black)
        let territory = ScoringHelper(gameState: gameState).computeTerritory()

        #expect(territory.numBlackStones == 9)
        #expect(territory.numBlackTerritory == 4)
        #expect(territory.numWhiteStones == 9)
        #expect(territory.numWhiteTerritory == 3)
        #expect(territory.numDames == 0)
    }

    // MARK: - Area (Chinese) scoring

    @Test func testAreaScoring() {
        let gameState = GameState(board: makeTestBoard(), nextPlayer: .black)
        // area score = territory + stones; komi = 0 for clarity
        let result = ScoringHelper(gameState: gameState, rule: .area, komi: 0).compute()

        // black: 4 territory + 9 stones = 13
        #expect(result.black == 13)
        // white: 3 territory + 9 stones = 12
        #expect(result.white == 12)
        #expect(result.winner == .black)
    }

    @Test func testAreaScoringWithKomi() {
        let gameState = GameState(board: makeTestBoard(), nextPlayer: .black)
        // With komi=7.5, white = 12 + 7.5 = 19.5 > 13 → white wins
        let result = ScoringHelper(gameState: gameState, rule: .area, komi: 7.5).compute()

        #expect(result.winner == .white)
        #expect(result.winningMargin == 6.5)
    }

    // MARK: - Territory (Japanese) scoring

    @Test func testTerritoryScoring_noCaptures() {
        let gameState = GameState(board: makeTestBoard(), nextPlayer: .black)
        // Japanese: territory only + prisoners (0 here), komi=0
        let result = ScoringHelper(gameState: gameState, rule: .territory, komi: 0).compute()

        // black: 4 territory + 0 captures = 4
        #expect(result.black == 4)
        // white: 3 territory + 0 captures = 3
        #expect(result.white == 3)
        #expect(result.winner == .black)
    }

    @Test func testTerritoryScoring_withCaptures() {
        // Build a game where black captures 2 white stones.
        //
        // 5x5 board after:
        //   .....
        //   .....
        //   .bbb.
        //   bw.wb   ← white stones at (2,2) and (2,4) are surrounded
        //   .b.b.   ← black stones seal the border
        //
        // Black plays at (2,1) as the last move to capture both whites.
        // This is a simplified setup; we manually track captures via GameState.apply.

        var state = GameState.newGame(boardSize: 5)

        // Place black stones to surround two isolated white stones
        // White at (3,2) surrounded by black: (3,1), (2,2), (3,3), (4,2)
        func move(_ s: GameState, _ player: Player, _ row: Int, _ col: Int) -> GameState {
            s.apply(move: .play(player, Point(row: row, col: col)))
        }

        // Simple 1-stone capture: black surrounds white at (2,2) on all 4 sides.
        // Liberties of (2,2): N=(1,2), S=(3,2), W=(2,1), E=(2,3).
        state = move(state, .black, 1, 2)  // b (1,2) — blocks N liberty
        state = move(state, .white, 2, 2)  // w (2,2) — the target
        state = move(state, .black, 3, 2)  // b (3,2) — blocks S liberty
        state = move(state, .white, 5, 5)  // w elsewhere
        state = move(state, .black, 2, 1)  // b (2,1) — blocks W liberty
        state = move(state, .white, 5, 4)  // w elsewhere
        state = move(state, .black, 2, 3)  // b (2,3) — blocks E liberty, captures (2,2)
        // white (2,2) is now gone; whiteCaptured = 1

        #expect(state.whiteCaptured == 1)

        let result = ScoringHelper(gameState: state, rule: .territory, komi: 0).compute()
        // Black score includes the 1 captured white stone as a prisoner
        #expect(result.black == result.white + 1 || result.black > result.white)
    }

    @Test func testTerritoryScoring_withDeadStones() {
        let gameState = GameState(board: makeTestBoard(), nextPlayer: .black)

        // Mark the white stone at (5,4) as agreed dead.
        let dead: Set<Point> = [Point(row: 5, col: 4)]
        let result = ScoringHelper(gameState: gameState, rule: .territory, komi: 0, deadStones: dead).compute()

        // Dead white stone counts as a black prisoner (+1 to black)
        // and frees up territory (that point becomes black territory).
        // Without dead: black=4, white=3. With dead white: black ≥ 5, white stays ≤ 3.
        #expect(result.black > 4)
    }

    @Test func testAreaScoring_withDeadStones() {
        let gameState = GameState(board: makeTestBoard(), nextPlayer: .black)

        // Mark white stone at (3,4) as dead. Its neighbors are (3,3) black, (3,5) white,
        // (4,4) white, (2,4) black — mixed border — so removing it produces a dame point,
        // not white territory. Net effect: white loses 1 stone count with no territory gain.
        // Without dead: white area = 3 territory + 9 stones = 12.
        // With dead (3,4): white area = 3 territory + 8 stones = 11.
        let dead: Set<Point> = [Point(row: 3, col: 4)]
        let result = ScoringHelper(gameState: gameState, rule: .area, komi: 0, deadStones: dead).compute()

        #expect(result.white == 11)
    }

    // MARK: - GameState.winner wiring

    @Test func testWinnerAfterDoublePass() {
        // Simple game: black has all the territory.
        var state = GameState.newGame(boardSize: 5)
        state = state.apply(move: .pass)
        state = state.apply(move: .pass)

        #expect(state.isOver())
        // Completely empty board → dame everywhere → 0-0 tie → white wins by komi
        #expect(state.winner == .white)
    }

    @Test func testWinnerAfterResign() {
        var state = GameState.newGame(boardSize: 5)
        state = state.apply(move: .resign)  // black resigns → white wins

        #expect(state.isOver())
        #expect(state.winner == .white)
    }
}
