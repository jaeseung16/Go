//
//  SimpleEncoder.swift
//  GoBoard
//
//  Created by Jae Seung Lee on 6/21/26.
//

import GoBoard
import MLX

public class SimpleEncoder: Encoder {
    public let name = "Simple"
    
    public var shape = [Int]()
    
    public init(boardDimension: Int) {
        self.shape = [boardDimension, boardDimension, 7]
    }
    
    public func encode(gameState: GameState) -> MLXArray {
        var boardTensor = MLXArray.zeros(self.shape)
        
        switch gameState.nextPlayer {
        case .black:
            boardTensor[.ellipsis, 8] = MLXArray.ones([self.shape[0], self.shape[1]])
        case .white:
            boardTensor[.ellipsis, 9] = MLXArray.ones([self.shape[0], self.shape[1]])
        }
        
        for row in 0..<self.shape[0] {
            for col in 0..<self.shape[1] {
                let point = Point(row: row + 1, col: col + 1)
                if let goString = gameState.board.goString(at: point) {
                    var libertyPlane = min(4, goString.numberOfLiberties) - 1
                    if goString.color == .white {
                        libertyPlane += 4
                    }
                    boardTensor[MLXArray([row, col, libertyPlane])] = MLXArray(1.0)
                } else {
                    if gameState.isViolatingKoRule(move: .play(gameState.nextPlayer, point)) {
                        boardTensor[MLXArray([row, col, 10])] = MLXArray(1.0)
                    }
                }
            }
        }
        
        return boardTensor
    }
    
    public func encode(point: Point) -> Int {
        return self.shape[0] * (point.row - 1) + (point.col - 1)
    }
    
    public func decode(index: Int) -> Point {
        let (row, col) = index.quotientAndRemainder(dividingBy: self.shape[0])
        return Point(row: row + 1, col: col + 1)
    }
    
    
}
