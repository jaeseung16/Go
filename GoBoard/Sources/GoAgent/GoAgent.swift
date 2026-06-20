//
//  GoAgent.swift
//  GoBoard
//
//  Created by Jae Seung Lee on 6/20/26.
//

import GoBoard

public protocol GoAgent {
    
    var stone: Stone { get }
    
    func select(from state: GameState) -> Move
    func diagnostics() -> String
}

extension GoAgent {
    func isEye(point: Point, on board: GoBoard) -> Bool {
        guard let stone = board.stone(at: point), stone == .black || stone == .white else {
            return false
        }
        
        for neighbor in point.neighbors {
            if board.isOnGrid(neighbor) {
                let neighborStone = board.stone(at: neighbor)
                if self.stone != neighborStone {
                    return false
                }
            }
        }
        
        var friendlyCorners = 0
        var offBoardCorners = 0
        let corners: [Point] = [
            Point(row: point.row - 1, col: point.col - 1),
            Point(row: point.row - 1, col: point.col + 1),
            Point(row: point.row + 1, col: point.col - 1),
            Point(row: point.row + 1, col: point.col + 1),
        ]
        
        for corner in corners {
            if board.isOnGrid(corner) {
                let cornerStone = board.stone(at: corner)
                if stone == cornerStone {
                    friendlyCorners += 1
                }
            } else {
                offBoardCorners += 1
            }
        }
        
        return offBoardCorners > 0 ? offBoardCorners + friendlyCorners == 4 : friendlyCorners >= 3
    }
}
