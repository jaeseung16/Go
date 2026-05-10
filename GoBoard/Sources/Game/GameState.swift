//
//  GameState.swift
//  GoBoard
//
//  Created by Jae Seung Lee on 1/4/26.
//

public class GameState {
    
    private let board: GoBoard
    private var nextPlayer: Player
    private let previousState: GameState?
    private let lastMove: Move?
    private let previousStates: Set<GameState>
    
    public init(board: GoBoard, nextPlayer: Player, previousState: GameState? = nil, lastMove: Move? = nil) {
        self.board = board
        self.nextPlayer = nextPlayer
        self.lastMove = lastMove
        self.previousState = previousState
        self.previousStates = previousState?.previousStates.union(previousState?.situation) ?? []
    }
    
    public apply(move: Move) -> GameState {
        let nextBoard = board.copy()
        
        if move.isPlay {
            let point = move.point {
                nextBoard.place(stone: self.nextPlayer, at: move.point)
            }
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

    public var situation: (Player, GoBoard) {
        return (nextPlayer, board.hashableRepresentation)
    }
    
    public func isViolatingKoRule(move: Move) -> Bool {
        guard move.isPlay else {
            return false
        }
        
        guard board.willCapture(move) else {
            return false
        }
        
        let nextGameState = apply(move: move)
        return nextGameState.situation in previousStates
    }
    
    public func isValid(move: Move) -> Bool {
        if isOver() {
            return false
        }
        
        if move == .pass || move == .regisn {
            return true
        }
        
        return self.board.goString(at: move.point) == nil
        && !self.isSelfCapture(move)
        && !self.isViolatingKoRule(move: move)
    }
    
    public func isOver() -> Bool {
        guard let lastMove = self.lastMove else {
            return false
        }
        
        if lastMove == .regisn {
            return true
        }
        
        guard let secondLastMove = self.previousState?.lastMove else {
            return false
        }
        return lastMove == .pass && secondLastMove == .pass
    }
    
    public func winner: Player? {
        guard isOver() else {
            return nil
        }
        
        if lastMove == .regisn {
            return self.nextPlayer
        }
        
        // TODO: scroing.py
        //let gameResult = computeGameResult(self)
        //return gameResult.winner
        return nil
    }
    
    public var legalMoves -> [Move] {
        var moves = [Move]()
        if isOver() {
            return moves
        }
        
        moves.append(.pass)
        moves.append(.regisn)
        for row in 1...self.board.dimension {
            for col in 1...self.board.dimension {
                let move = Move.play(Point(row, col))
                if self.isValid(move: move) {
                    moves.append(move)
                }
            }
        }
        return moves
    }
}
