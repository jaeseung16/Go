//
//  Score.swift
//  Go
//
//  Created by Jae Seung Lee on 1/4/21.
//  Copyright © 2021 Jae Seung Lee. All rights reserved.
//

import Foundation

class Score {
    var board: GoBoard?
    var value = 0
    
    func findReached(from anEye: Intersection, on goBboard: GoBoard) -> (Set<Intersection>, Set<Intersection>) {
        let status = goBboard.status(row: anEye.row, column: anEye.column)
        var chain = Set(arrayLiteral: anEye)
        var reached = Set<Intersection>()
        var frontier = Set(arrayLiteral: anEye)
        
        while !frontier.isEmpty {
            let current = frontier.popFirst()!
            print("current = \(current)")
            
            chain.insert(current)
            for neighbor in Neighbor.allCases {
                var row: Int?
                var column: Int?
                
                switch neighbor {
                case .up:
                    if current.row > 0 {
                        row = current.row - 1
                        column = current.column
                    }
                case .down:
                    if current.row < goBboard.size - 1 {
                        row = current.row + 1
                        column = current.column
                    }
                case .left:
                    if current.column > 0 {
                        row = current.row
                        column = current.column - 1
                    }
                case .right:
                    if current.column < goBboard.size - 1 {
                        row = current.row
                        column = current.column + 1
                    }
                }
                
                if let row = row, let column = column {
                    let statusNeighbor = goBboard.status(row: row, column: column)
                    let neighbor = Intersection(row: row, column: column, stone: statusNeighbor)
                    if status == statusNeighbor && !chain.contains(neighbor) {
                        frontier.insert(neighbor)
                    } else if status != statusNeighbor {
                        reached.insert(neighbor)
                    }
                }
            }
        }
        
        return (chain, reached)
    }
    
    func place(_ places: Set<Intersection>, stone: Stone?, goBoard: GoBoard) -> GoBoard {
        var workingBoard = goBoard
        for place in places {
            workingBoard.update(row: place.row, column: place.column, stone: stone)
            print("Updating \(place)")
        }
        return workingBoard
    }
    
    func evaluate() -> Int {
        var workingBoard = self.board!
        
        print("EVALUATE")
        
        while workingBoard.containsEye() {
            let eye = workingBoard.getAnEye()!
            let (territory, borders) = findReached(from: eye, on: workingBoard)
            let borderColors = Set(borders.map { border -> Stone in
                return border.stone!
            })
            
            let blackBorder = borderColors.contains(.Black)
            let whiteBorder = borderColors.contains(.White)
            
            var territoryColor: Stone?
            if blackBorder && !whiteBorder {
                territoryColor = .Black
            } else if !blackBorder && whiteBorder {
                territoryColor = .White
            } else {
                territoryColor = nil
            }
            
            workingBoard = place(territory, stone: territoryColor, goBoard: workingBoard)
        }
        
        board = workingBoard
        
        var blackScore = 0
        var whiteScore = 0
        for intersecion in workingBoard.intersections {
            if intersecion.stone == .Black {
                blackScore += 1
            } else if intersecion.stone == .White {
                whiteScore += 1
            }
        }
        
        print("SCORE - \(blackScore) : \(whiteScore)")
        
        value = blackScore - whiteScore
        
        return value
    }
}
