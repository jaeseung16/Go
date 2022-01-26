//
//  BlackPlayer.swift
//  Go
//
//  Created by Jae Seung Lee on 1/24/22.
//  Copyright © 2022 Jae Seung Lee. All rights reserved.
//

import Foundation

struct BlackLocations: Intersections {
    var playNumber: Int
    var locations: [Intersection]
    
    var turn: Bool
}
