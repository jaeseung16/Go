//
//  Move.swift
//  GoBoard
//
//  Created by Jae Seung Lee on 11/23/25.
//

public enum Move: Equatable, Hashable, Sendable {
    case play(Player?, Point)
    case pass
    case regisn
    
    public var isPlay: Bool {
        guard case .play = self else { return false }
        return true
    }
    
    public var player: Player? {
        guard case .play(let player, _) = self else { return nil }
        return player
    }
    
    public var point: Point? {
        guard case .play(_, let point) = self else { return nil }
        return point
    }
}
