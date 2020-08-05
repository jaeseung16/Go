//
//  GoBoard.swift
//  Go
//
//  Created by Jae Seung Lee on 8/4/20.
//  Copyright © 2020 Jae Seung Lee. All rights reserved.
//

import Foundation

class GoBoard {
    let size = 19
    var intersections = [Intersection]()
    
    init() {
        for row in 0..<size {
            for column in 0..<size {
                let intersection = Intersection(row: row, column: column)
                intersections.append(intersection)
            }
        }
    }
}
