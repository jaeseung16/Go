//
//  GameSituation.swift
//  GoBoard
//
//  Created by Jae Seung Lee on 5/24/26.
//

public struct GameSituation: Hashable {
    public static func == (lhs: GameSituation, rhs: GameSituation) -> Bool {
        guard let lhsHash = lhs.boardHash as? UInt,
              let rhsHash = rhs.boardHash as? UInt else {
            return false
        }
        return lhsHash == rhsHash && lhs.nextPlayer == rhs.nextPlayer
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(nextPlayer)
        if let hash = boardHash as? UInt {
            hasher.combine(hash)
        }
    }
    
    public let nextPlayer: Player
    public let boardHash: any Hashable
}
