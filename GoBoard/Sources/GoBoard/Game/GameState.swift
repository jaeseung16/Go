//
//  GameState.swift
//  GoBoard
//
//  Created by Jae Seung Lee on 1/4/26.
//

public class GameState {

    public let board: GoBoard
    public var nextPlayer: Player
    private let previousState: GameState?
    private let lastMove: Move?
    private let previousStates: Set<GameSituation>

    /// Total black stones captured by white over the course of the game.
    public let blackCaptured: Int
    /// Total white stones captured by black over the course of the game.
    public let whiteCaptured: Int

    public init(board: GoBoard, nextPlayer: Player, previousState: GameState? = nil, lastMove: Move? = nil, blackCaptured: Int = 0, whiteCaptured: Int = 0) {
        self.board = board
        self.nextPlayer = nextPlayer
        self.lastMove = lastMove
        self.previousState = previousState
        self.blackCaptured = blackCaptured
        self.whiteCaptured = whiteCaptured

        if let previousState = previousState {
            self.previousStates = previousState.previousStates.union([previousState.situation])
        } else {
            self.previousStates = []
        }
    }

    public func apply(move: Move) -> GameState {
        let nextBoard = board.copy()
        var newBlackCaptured = blackCaptured
        var newWhiteCaptured = whiteCaptured

        if move.isPlay, let point = move.point {
            let opponentStone: Stone = nextPlayer == .black ? .white : .black
            let before = countStones(opponentStone, on: nextBoard)
            nextBoard.place(stone: Stone.from(player: nextPlayer), at: point)
            let captured = before - countStones(opponentStone, on: nextBoard)
            if nextPlayer == .black {
                newWhiteCaptured += captured
            } else {
                newBlackCaptured += captured
            }
        }

        return GameState(board: nextBoard, nextPlayer: nextPlayer.other, previousState: self, lastMove: move, blackCaptured: newBlackCaptured, whiteCaptured: newWhiteCaptured)
    }

    private func countStones(_ stone: Stone, on board: GoBoard) -> Int {
        var count = 0
        for row in 1...board.dimension {
            for col in 1...board.dimension {
                if board.stone(at: Point(row: row, col: col)) == stone { count += 1 }
            }
        }
        return count
    }
    
    public static func newGame(boardSize: Int) -> GameState {
        // Use ZobristGoBoard because it is the only GoBoard
        return GameState(board: ZobristGoBoard(dimension: boardSize), nextPlayer: .black)
    }
    
    public func isSelfCapture(_ move: Move) -> Bool {
        guard move.isPlay else { return false }
        return board.isSelfCapture(move)
        
    }

    public var situation: GameSituation {
        return GameSituation(nextPlayer: nextPlayer, boardHash: board.hashableRepresentation())
    }
    
    public func isViolatingKoRule(move: Move) -> Bool {
        guard move.isPlay else {
            return false
        }
        
        guard board.willCapture(move) else {
            return false
        }
        
        let nextGameState = apply(move: move)
        return previousStates.contains(nextGameState.situation)
    }
    
    public func isValid(move: Move) -> Bool {
        if isOver() {
            return false
        }
        
        switch move {
        case .pass, .resign:
            return true
        case .play(_, let point):
            return self.board.goString(at: point) == nil
            && !self.isSelfCapture(move)
            && !self.isViolatingKoRule(move: move)
        }
    }
    
    public func isOver() -> Bool {
        guard let lastMove = self.lastMove else {
            return false
        }
        
        if lastMove == .resign {
            return true
        }
        
        guard let secondLastMove = self.previousState?.lastMove else {
            return false
        }
        return lastMove == .pass && secondLastMove == .pass
    }
    
    public var winner: Player? {
        guard isOver() else {
            return nil
        }

        if lastMove == .resign {
            return self.nextPlayer
        }

        return ScoringHelper(gameState: self).compute().winner
    }
    
    public var legalMoves: [Move] {
        var moves = [Move]()
        if isOver() {
            return moves
        }
        
        moves.append(.pass)
        moves.append(.resign)
        for row in 1...self.board.dimension {
            for col in 1...self.board.dimension {
                let move = Move.play(nil, Point(row: row, col: col))
                if isValid(move: move) {
                    moves.append(move)
                }
            }
        }
        return moves
    }
}
