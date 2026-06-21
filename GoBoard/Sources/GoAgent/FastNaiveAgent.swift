//
//  FastNaiveAgent.swift
//  GoBoard
//
//  Created by Jae Seung Lee on 6/20/26.
//

import GoBoard
import Logging

public class FastNaiveAgent: GoAgent {
    
    public static let logger = Logger(label: "com.resonance.GoAgent.FastNaiveAgent")
    
    public let stone: Stone
    private let player: Player
    private var pointCache = [Point]()
    private var dimension: Int?
    
    public init(stone: Stone) {
        precondition(stone == .black || stone == .white)
        self.stone = stone
        self.player = Player.from(stone: stone)!
    }
    
    private func updateCache(_ dimension: Int) {
        self.dimension = dimension
        for row in 1...dimension {
            for col in 1...dimension {
                self.pointCache.append(Point(row: row, col: col))
            }
        }
    }
    
    public func select(from state: GameState) -> Move {
        let dimension = state.board.dimension
        if dimension != self.dimension {
            updateCache(dimension)
        }
        
        let shuffled = self.pointCache.shuffled()
        for candidate in shuffled {
            if state.isValid(move: .play(self.player, candidate)) && isEye(point: candidate, on: state.board) {
                return .play(self.player, candidate)
            }
        }
        return .pass
    }
    
    public func diagnostics() -> String {
        "FastNaiveAgent"
    }
                    
}


