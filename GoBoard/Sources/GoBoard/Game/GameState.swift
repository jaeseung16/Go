//
//  GameState.swift
//  GoBoard
//
//  Created by Jae Seung Lee on 1/4/26.
//

public class GameState {

    public let board: GoBoard
    private var nextPlayer: Player
    private let previousState: GameState?
    private let lastMove: Move?
    private let previousStates: Set<GameSituation>
    
    public init(board: GoBoard, nextPlayer: Player, previousState: GameState? = nil, lastMove: Move? = nil) {
        self.board = board
        self.nextPlayer = nextPlayer
        self.lastMove = lastMove
        self.previousState = previousState
        
        if let previousState = previousState {
            self.previousStates = previousState.previousStates.union([previousState.situation])
        } else {
            self.previousStates = []
        }
    }
    
    public func apply(move: Move) -> GameState {
        let nextBoard = board.copy()
        
        if move.isPlay, let point = move.point {
            nextBoard.place(stone: Stone.from(player: nextPlayer), at: point)
        }
        
        return GameState(board: nextBoard, nextPlayer: nextPlayer.other, previousState: self, lastMove: move)
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
        
        // TODO: scroing.py
        //let gameResult = computeGameResult(self)
        //return gameResult.winner
        return nil
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
