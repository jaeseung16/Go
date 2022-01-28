//
//  GroupLocations.swift
//  Go
//
//  Created by Jae Seung Lee on 1/24/22.
//  Copyright © 2022 Jae Seung Lee. All rights reserved.
//

import Foundation

struct GroupLocations: Intersections {
    var playNumber: Int
    var locations: [Intersection]
    var groups: [Group]
    
    init(playNumber: Int, groups: [Group]) {
        self.playNumber = playNumber
        self.groups = groups
        
        self.locations = [Intersection]()
        groups.forEach { group in
            self.locations.append(contentsOf: group.locations)
        }
    }
}
