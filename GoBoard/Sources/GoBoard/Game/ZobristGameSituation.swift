//
//  ZobristGameSituation.swift
//  GoBoard
//
//  Created by Jae Seung Lee on 2/8/26.
//

public class ZobristGameSituation {
    private let nextPlayer: Player
    private let goBoard: GoBoard
    
    public init(nextPlayer: Player, goBoard: GoBoard) {
        self.nextPlayer = nextPlayer
        self.goBoard = goBoard
    }
    
    public func situation() -> (Player, any Hashable) {
        return (nextPlayer, goBoard.hashableRepresentation())
    }
}
