//
//  Intersections.swift
//  Go
//
//  Created by Jae Seung Lee on 1/24/22.
//  Copyright © 2022 Jae Seung Lee. All rights reserved.
//

import Foundation

protocol Intersections {
    var playNumber: Int { get set }
    var locations: [Intersection] { get set }
    
    func locationMatrix(in boardSize: Int) -> [[Int]]
}

extension Intersections {
    func locationMatrix(in boardSize: Int) -> [[Int]] {
        var result = Array(repeating: Array(repeating: 0, count: boardSize), count: boardSize)
        
        locations.forEach { intersection in
            result[intersection.row][intersection.column] = 1
        }
        
        return result
    }
}
