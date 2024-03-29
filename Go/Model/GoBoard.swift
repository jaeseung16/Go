//
//  GoBoard.swift
//  Go
//
//  Created by Jae Seung Lee on 8/4/20.
//  Copyright © 2020 Jae Seung Lee. All rights reserved.
//

import Foundation

struct GoBoard {
    var size = 19
    var intersections = [Intersection]()
    
    init(size: Int = 19) {
        self.size = size
        
        for row in 0..<size {
            for column in 0..<size {
                let intersection = Intersection(row: row, column: column)
                intersections.append(intersection)
            }
        }
    }
    
    func status(row: Int, column: Int) -> Stone? {
        let intersection = intersections[row * size + column]
        return intersection.stone
    }
    
    func status(intersection: Intersection) -> Stone? {
        let intersection = intersections[intersection.row * size + intersection.column]
        return intersection.stone
    }
    
    mutating func update(row: Int, column: Int, stone: Stone?) -> Void {
        intersections[row * size + column].stone = stone
    }
    
    func isEye(row: Int, column: Int) -> Bool {
        let intersection = intersections[row * size + column]
        return intersection.isEye
    }
    
    mutating func update(row: Int, column: Int, isEye: Bool) -> Void {
        intersections[row * size + column].isEye = isEye
    }
    
    func containsEye() -> Bool {
        var result = false
        for intersection in intersections {
            if intersection.stone == nil {
                result = true
                break
            }
        }
        return result
    }
    
    func getAnEye() -> Intersection? {
        for intersection in intersections {
            if intersection.stone == nil {
                return intersection
            }
        }
        return nil
    }
    
    
}
