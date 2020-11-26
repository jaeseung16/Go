//
//  Chain.swift
//  Go
//
//  Created by Jae Seung Lee on 11/23/20.
//  Copyright © 2020 Jae Seung Lee. All rights reserved.
//

import Foundation

class Group: Hashable, CustomStringConvertible {
    static func == (lhs: Group, rhs: Group) -> Bool {
        return (lhs.id == rhs.id) && (lhs.head == rhs.head) && (lhs.plays == rhs.plays) && (lhs.liberties == rhs.liberties)
    }
    
    var id: Int
    var head: Play
    var plays: Set<Play>
    var liberties: Set<Intersection>
    
    init(id: Int, head: Play, plays: Set<Play>, liberties: Set<Intersection>) {
        self.id = id
        self.head = head
        self.plays = plays
        self.liberties = liberties
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(head)
        hasher.combine(plays)
        hasher.combine(liberties)
    }
    
    var description: String {
        //return "\(self.hashValue) \(self.id.hashValue) \(self.head.hashValue) \(self.locations.hashValue) \(self.liberties.hashValue)"
        return "Group(id: \(id), head: \(head), locations: \(plays), liberties: \(liberties))"
    }
    
}
