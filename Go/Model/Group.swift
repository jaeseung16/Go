//
//  Chain.swift
//  Go
//
//  Created by Jae Seung Lee on 11/23/20.
//  Copyright © 2020 Jae Seung Lee. All rights reserved.
//

import Foundation

class Group: Equatable, CustomStringConvertible {
    static func == (lhs: Group, rhs: Group) -> Bool {
        return (lhs.id == rhs.id) && (lhs.head == rhs.head) && (lhs.locations == rhs.locations) && (lhs.liberties == rhs.liberties)
    }
    
    var id: Int
    var head: Play
    var locations: [Intersection]
    var liberties: [Intersection]
    
    init(id: Int, head: Play, locations: [Intersection], liberties: [Intersection]) {
        self.id = id
        self.head = head
        self.locations = locations
        self.liberties = liberties
    }
    
    var description: String {
        return "Group(id: \(id), head: \(head), locations: \(locations), liberties: \(liberties))"
    }
}
