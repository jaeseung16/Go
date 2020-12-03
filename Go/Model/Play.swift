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
    var location: Intersection
    var stone: Stone
    var groupId: Int?
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(location)
        hasher.combine(stone)
    }
    
    static func == (lhs: Play, rhs: Play) -> Bool {
        return lhs.id == rhs.id && lhs.location == rhs.location && lhs.stone == rhs.stone
    }
    
    init(id: Int, row: Int, column: Int, stone: Stone) {
        self.id = id
        self.location = Intersection(row: row, column: column)
        self.stone = stone
    }
    
    func toKataGoMove() -> Move? {
        let player = stone == .Black ? "B" : "W"
        
        guard let column = Column(rawValue: location.column + 1) else {
            print("column = \(self.location.column)")
            return nil
        }
        
        let location = "\(column)\(self.location.row+1)"
        return Move(player: player, location: location)
    }
}

enum Column: Int {
    case A = 1, B, C, D, E, F, G, H, J, K, L, M, N, O, P, Q, R, S, T
}

