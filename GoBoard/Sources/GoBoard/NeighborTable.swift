//
//  NeighborTable.swift
//  GoBoard
//
//  Created by Jae Seung Lee on 12/7/25.
//

struct NeighborTable {
    
    var dimension: Int
    var table: [Point: [Point]]
    
    init(dimension: Int) {
        self.dimension = dimension
        table = [Point: [Point]]()
        for row in 1...dimension {
            for col in 1...dimension {
                let point = Point(row: row, col: col)
                let trueNeighbors = point.neighbors.filter {
                    1...dimension ~= $0.row && 1...dimension ~= $0.col
                }
                table[point] = trueNeighbors
            }
        }
    }
}
