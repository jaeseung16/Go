//
//  Play.swift
//  Go
//
//  Created by Jae Seung Lee on 8/18/20.
//  Copyright © 2020 Jae Seung Lee. All rights reserved.
//

import Foundation

struct Play: Hashable {
    var id: Int
    var row: Int
    var column: Int
    var stone: Stone
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(row)
        hasher.combine(column)
    }
    
    static func == (lhs: Play, rhs: Play) -> Bool {
        return lhs.row == rhs.row && lhs.column == rhs.column
    }
    
    func toKataGoMove() -> Move? {
        let player = stone == .Black ? "B" : "W"
        
        guard let column = Column(rawValue: column + 1) else {
            return nil
        }
        
        let location = "\(column)\(row + 1)"
        return Move(player: player, location: location)
    }
}

enum Column: Int {
    case A = 1, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S
}

