//
//  MoveAge.swift
//  GoBoard
//
//  Created by Jae Seung Lee on 12/21/25.
//

public class MoveAges {
    private var ages: [[Int]] = []
    
    public init(dimension: Int) {
        self.ages = Array(repeating: Array(repeating: -1, count: dimension), count: dimension)
    }
    
    public func of(_ point: Point) -> Int {
        return ages[point.row - 1][point.col - 1]
    }
    
    public func reset(_ point: Point) {
        ages[point.row - 1][point.col - 1] = -1
    }
    
    public func add(_ point: Point) {
        ages[point.row - 1][point.col - 1] = 0
    }
    
    public func incrementAll() {
        for row in 0..<ages.count {
            for col in 0..<ages[row].count {
                if ages[row][col] > -1 {
                    ages[row][col] += 1
                }
            }
        }
    }
}
