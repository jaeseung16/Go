//
//  ScoringHelper.swift
//  GoBoard
//
//  Created by Jae Seung Lee on 5/17/26.
//

public class ScoringHelper {
    
    private static let deltas = [(-1, 0), (1, 0), (0, -1), (0, 1)]
    
    private let gameState: GameState
    
    public init(gameState: GameState) {
        self.gameState = gameState
    }
    
    // This follows Chinese rule
    public func compute() -> GameResult {
        let territory = evaluate(board: gameState.board)
        return GameResult(
            black: Double(territory.numBlackTerritory + territory.numBlackStones),
            white: Double(territory.numWhiteTerritory + territory.numWhiteStones),
            komi: 7.5
        )
    }
    
    public func computeTerritory() -> Territory {
        return evaluate(board: gameState.board)
    }
    
    func evaluate(board: GoBoard) -> Territory {
        var status: [Point: String] = [:]
        
        for row in 1...board.dimension {
            for col in 1...board.dimension {
                let point = Point(row: row, col: col)
                if status.keys.contains(point) {
                    continue
                }
                
                if let stone = board.stone(at: point), stone != .none {
                    switch stone {
                    case .black: status[point] = "b"
                    case .white: status[point] = "w"
                    case .none: continue
                    }
                } else {
                    var visited: Set<Point> = []
                    let (group, neighbors) = collectRegion(start: point, board: board, visited: &visited)
                    let fillWith: String
                    if neighbors.count == 1,
                        let neighbor = neighbors.first,
                        let neighborColor = board.stone(at: neighbor) {
                            fillWith = "territory_\(neighborColor == Stone.black ? "b" : "w")"
                    } else {
                        fillWith = "dame"
                    }
                    group.forEach { status[$0] = fillWith }
                }
            }
        }
        
        return Territory(territoryMap: status)
        
    }
    
    private func collectRegion(start: Point, board: GoBoard, visited: inout Set<Point>) -> ([Point], Set<Point>) {
        guard !visited.contains(start) else {
            return ([], Set())
        }
        
        visited.insert(start)
        
        var allPoints: [Point] = [start]
        var allBorders: Set<Point> = []
        
        let color = board.stone(at: start) ?? .none
        
        for (row, col) in ScoringHelper.deltas {
            let neighbor = Point(row: start.row + row, col: start.col + col)
            if !board.isOnGrid(neighbor) {
                continue
            }
            let neighborColor = board.stone(at: neighbor)
            if neighborColor == color {
                let (points, borders) = collectRegion(start: neighbor, board: board, visited: &visited)
                allPoints.append(contentsOf: points)
                allBorders.formUnion(borders)
            } else {
                allBorders.formUnion([neighbor])
            }
        }
        
        return (allPoints, allBorders)
    }
    
}
