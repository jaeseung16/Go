//
//  GoAgent.swift
//  GoBoard
//
//  Created by Jae Seung Lee on 6/20/26.
//

import GoBoard
import Logging

public protocol GoAgent {
    
    static var logger: Logger { get }
    
    var stone: Stone { get }
    var experienceCollector: ExperienceCollector? { get set }
    
    func select(from state: GameState) -> Move
    func diagnostics() -> String
}

extension GoAgent {
    
    static var logger: Logger {
        return Logger(label: "com.resonance.GoAgent.GoAgent")
    }
    
    func isEye(point: Point, on board: GoBoard) -> Bool {
        guard board.goString(at: point) == nil else {
            Self.logger.info("There already exists a stone at \(point)")
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
