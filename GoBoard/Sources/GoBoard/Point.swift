//
//  Point.swift
//  GoBoard
//
//  Created by Jae Seung Lee on 11/23/25.
//

public struct Point: Equatable, Hashable, Sendable {
    public var row: Int
    public var col: Int
    
    public var neighbors: [Point] {
        [
            Point(row: row - 1, col: col),
            Point(row: row + 1, col: col),
            Point(row: row, col: col - 1),
            Point(row: row, col: col + 1)
        ]
    }
    
    public var corners: [Point] {
        [
            Point(row: row - 1, col: col - 1),
            Point(row: row - 1, col: col + 1),
            Point(row: row + 1, col: col - 1),
            Point(row: row + 1, col: col + 1)
        ]
    }
}
