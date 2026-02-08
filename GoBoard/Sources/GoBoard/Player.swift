//
//  Player.swift
//  GoBoard
//
//  Created by Jae Seung Lee on 11/23/25.
//

public enum Player: Sendable {
    case black
    case white
    
    public static func from(stone: Stone) -> Player? {
        switch stone {
        case .black: return .black
        case .white: return .white
        case .none: return nil
        }
    }
    
    public var other: Player {
        switch self {
        case .black: return .white
        case .white: return .black
        }
    }
}
