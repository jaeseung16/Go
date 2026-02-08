//
//  Stone.swift
//  GoBoard
//
//  Created by Jae Seung Lee on 11/23/25.
//

public enum Stone: CaseIterable, Sendable {
    case black
    case white
    case none
    
    public static func from(player: Player?) -> Stone {
        switch player {
        case .black:
            return .black
        case .white:
            return .white
        default:
            return .none
        }
    }
}
