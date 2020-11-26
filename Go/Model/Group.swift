//
//  Chain.swift
//  Go
//
//  Created by Jae Seung Lee on 11/23/20.
//  Copyright © 2020 Jae Seung Lee. All rights reserved.
//

import Foundation

struct Group: Hashable, CustomStringConvertible {
    static func == (lhs: Group, rhs: Group) -> Bool {
        return (lhs.id == rhs.id) && (lhs.stone == rhs.stone) && (lhs.locations == rhs.locations) && (lhs.liberties == rhs.liberties) && (lhs.opponentLocations == rhs.opponentLocations)
    }
    
    var id: Int
    var stone: Stone
    var locations: Set<Intersection>
    var liberties: Set<Intersection>
    var opponentLocations: Set<Intersection>
    
    init(id: Int, stone: Stone, locations: Set<Intersection>, liberties: Set<Intersection>, oppenentLocations: Set<Intersection>) {
        self.id = id
        self.stone = stone
        self.locations = locations
        self.liberties = liberties
        self.opponentLocations = oppenentLocations
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(stone)
        hasher.combine(locations)
        hasher.combine(liberties)
        hasher.combine(opponentLocations)
    }
    
    var description: String {
        //return "\(self.hashValue) \(self.id.hashValue) \(self.head.hashValue) \(self.locations.hashValue) \(self.liberties.hashValue)"
        return "Group(id: \(id), stone: \(stone), locations: \(locations), liberties: \(liberties)), opponentLocations: \(opponentLocations)"
    }
    
}
