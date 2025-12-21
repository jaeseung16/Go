//
//  ZobristGoBoard.swift
//  GoBoard
//
//  Created by Jae Seung Lee on 12/7/25.
//

import Logging

public class ZobristGoBoard: GoBoard {
    
    private static let logger = Logger(label: "com.resonance.GoBoard.ZobristGoBoard")
    
    public let dimension: Int
    private var zobristHash: UInt
    private let neighborsByPoint: [Point: [Point]]
    private let cornersByPoint: [Point: [Point]]
    private var goStringByPoint: [Point: GoString] = [:]
    private let moveAges: MoveAges
    
    init(dimension: Int = 19) {
        self.dimension = dimension
        self.zobristHash = Zobrist.EMPTY_BOARD
        self.neighborsByPoint = NeighborTable(dimension: dimension).table
        self.cornersByPoint = CornerTable(dimension: dimension).table
        self.moveAges = MoveAges(dimension: dimension)
    }
    
    public func isOnGrid(_ point: Point) -> Bool {
        return 1...dimension ~= point.row && 1...dimension ~= point.col
    }
    
    public func place(stone: Stone, at point: Point) {
        guard isOnGrid(point) && goStringByPoint[point] == nil else {
            ZobristGoBoard.logger.warning("Illegal play at \(point) for \(stone)")
            return
        }
        
        ZobristGoBoard.logger.info("Placing stone=\(stone) at point=\(point)")
        
        var adjacentSameColor = Set<GoString>()
        var adjaerentOppositeColor = Set<GoString>()
        var liberties = Set<Point>()

        moveAges.incrementAll()
        moveAges.add(point)
        
        for neighbor in neighborsByPoint[point] ?? [] {
            if let neighborGoString = goStringByPoint[neighbor] {
                if neighborGoString.color == stone {
                    if !adjacentSameColor.contains(neighborGoString) {
                        adjacentSameColor.insert(neighborGoString)
                    }
                } else {
                    if !adjaerentOppositeColor.contains(neighborGoString) {
                        adjaerentOppositeColor.insert(neighborGoString)
                    }
                }
            } else {
                liberties.insert(neighbor)
            }
        }
        
        let newGoString = adjacentSameColor.reduce(GoString(color: stone, stones: [point], liberties: liberties)) {
            $0.merged(with: $1)
        }
        for point in newGoString.stones {
            goStringByPoint[point] = newGoString
        }

        let moveToRemove = Move(player: .none, point: point)
        let moveToAdd = Move(player: .from(stone: stone), point: point)
        updateZobrist(with: moveToRemove, moveToAdd: moveToAdd)
           
        // Remove empty-point hash code.
        for goString in adjaerentOppositeColor {
            let replacement = goString.without(liberty: point)
            if !replacement.liberties.isEmpty {
                replace(replacement)
            } else {
                remove(goString)
            }
        }
        
        ZobristGoBoard.logger.info("goStringByPoint=\(goStringByPoint)")
        
        
    }
    
    public func neighbors(of point: Point) -> [Point] {
        neighborsByPoint[point] ?? []
    }
    
    public func corners(of point: Point) -> [Point] {
        cornersByPoint[point] ?? []
    }
    
    private func replace(_ goString: GoString) {
        for point in goString.stones {
            goStringByPoint[point] = goString
        }
    }
    
    private func remove(_ goString: GoString) {
        for point in goString.stones {
            moveAges.reset(point)
            
            for neighbor in neighborsByPoint[point] ?? [] {
                if let neighborGoString = goStringByPoint[neighbor] {
                    replace(neighborGoString.with(liberty: point))
                }
            }
            
            goStringByPoint[point] = nil
            
            if let player = Player.from(stone: goString.color) {
                let moveToRemove = Move(player: player, point: point)
                let moveToAdd = Move(player: .none, point: point)
                updateZobrist(with: moveToRemove, moveToAdd: moveToAdd)
            }
        }
    }
    
    private func updateZobrist(with moveToRemove: Move, moveToAdd: Move) {
        updateZobrist(with: moveToRemove)
        updateZobrist(with: moveToAdd)
    }
    
    private func updateZobrist(with move: Move) {
        if let hash = Zobrist.HASH_CODE[move] {
            zobristHash ^= hash
        }
    }
    
    public func getStone(at: Point) -> Stone? {
        return goStringByPoint[at]?.color
    }
}
