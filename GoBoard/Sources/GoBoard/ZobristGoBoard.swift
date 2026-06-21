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
    private var neighborsByPoint: [Point: [Point]]
    private var cornersByPoint: [Point: [Point]]
    private var goStringByPoint: [Point: GoString] = [:]
    private var moveAges: MoveAges
    
    public init(dimension: Int = 19) {
        self.dimension = dimension
        self.zobristHash = Zobrist.EMPTY_BOARD
        self.neighborsByPoint = NeighborTable(dimension: dimension).table
        self.cornersByPoint = CornerTable(dimension: dimension).table
        self.moveAges = MoveAges(dimension: dimension)
    }
    
    public func copy() -> GoBoard {
        let copy = ZobristGoBoard(dimension: dimension)
        copy.zobristHash = self.zobristHash
        copy.neighborsByPoint = self.neighborsByPoint
        copy.cornersByPoint = self.cornersByPoint
        copy.goStringByPoint = self.goStringByPoint
        copy.moveAges = self.moveAges
        return copy
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

        let moveToRemove = Move.play(.none, point)
        let moveToAdd = Move.play(Player.from(stone: stone), point)
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
                let moveToRemove = Move.play(player, point)
                let moveToAdd = Move.play(.none, point)
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
    
    public func stone(at point: Point) -> Stone? {
        return goStringByPoint[point]?.color
    }
    
    public func goString(at point: Point) -> GoString? {
        return goStringByPoint[point]
    }
    
    public func isSelfCapture(_ move: Move) -> Bool {
        guard move.isPlay else {
            return false
        }
        
        var friendlyStrings : [GoString] = []
        
        for neighbor in self.neighbors(of: move.point!) {
            guard let neighborGoString = goStringByPoint[neighbor] else {
                // This point is a liberty of a neighbor's string. Can't be self capture
                return false
            }
            
            if move.player == Player.from(stone: neighborGoString.color) {
                // Gather for layer analysis
                friendlyStrings.append(neighborGoString)
            } else {
                if neighborGoString.numberOfLiberties == 1 {
                    // This move is real capture, not a self capture
                    return false
                }
            }
        }
        
        return friendlyStrings.allSatisfy { $0.numberOfLiberties == 1 }
    }

    public func willCapture(_ move: Move) -> Bool {
        for neighbor in self.neighbors(of: move.point!) {
            guard let neighborGoString = goStringByPoint[neighbor] else {
                continue
            }
            
            guard move.player != Player.from(stone: neighborGoString.color) else {
                continue
            }
            
            if neighborGoString.numberOfLiberties == 1 {
                return true
            }
        }
        return false
    }
    
    public func hashableRepresentation() -> any Hashable {
        return zobristHash
    }
}
