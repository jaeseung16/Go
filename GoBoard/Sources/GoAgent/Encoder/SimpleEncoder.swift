//
//  SimpleEncoder.swift
//  GoBoard
//
//  Created by Jae Seung Lee on 6/21/26.
//

import GoBoard

public class SimpleEncoder: Encoder {
    private static let featureCount = 11
    
    public let name = "Simple"
    
    public let shape: [Int]
    
    private let rowCount: Int
    private let columnCount: Int
    
    public init(boardDimension: Int) {
        self.shape = [boardDimension, boardDimension, Self.featureCount]
        self.rowCount = boardDimension
        self.columnCount = boardDimension
    }
    
    public func encode(gameState: GameState) -> [[[UInt8]]] {
        var boardTensor = [[[UInt8]]](repeating: [[UInt8]](repeating: [UInt8](repeating: 0, count: Self.featureCount), count: columnCount), count: rowCount)
        
        for row in 0..<rowCount {
            for col in 0..<columnCount {
                switch gameState.nextPlayer {
                case .black:
                    boardTensor[row][col][8] = 1
                case .white:
                    boardTensor[row][col][9] = 1
                }
                
                let point = Point(row: row + 1, col: col + 1)
                if let goString = gameState.board.goString(at: point) {
                    var libertyPlane = min(4, goString.numberOfLiberties) - 1
                    if goString.color == .white {
                        libertyPlane += 4
                    }
                    boardTensor[row][col][libertyPlane] = 1
                } else {
                    if gameState.isViolatingKoRule(move: .play(gameState.nextPlayer, point)) {
                        boardTensor[row][col][10] = 1
                    }
                }
            }
        }
        
        return boardTensor
    }
    
    public func encode(point: Point) -> Int {
        return columnCount * (point.row - 1) + (point.col - 1)
    }
    
    public func decode(index: Int) -> Point {
        let (row, col) = index.quotientAndRemainder(dividingBy: columnCount)
        return Point(row: row + 1, col: col + 1)
    }
    
    
}
