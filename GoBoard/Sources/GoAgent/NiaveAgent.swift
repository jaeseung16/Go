//
//  NiaveAgent.swift
//  GoBoard
//
//  Created by Jae Seung Lee on 6/20/26.
//

import GoBoard
import Logging

public class NiaveAgent: GoAgent {
    // In fact, when agent is initialized, black or white is given.
    
    public static let logger = Logger(label: "com.resonance.GoAgent.NiaveAgent")
    
    public let stone: Stone
    private let player: Player
    
    public init(stone: Stone) {
        precondition(stone == .black || stone == .white)
        self.stone = stone
        self.player = Player.from(stone: stone)!
    }
    
    public func select(from state: GameState) -> Move {
        let board = state.board
        
        var candidates: [Move] = []
        for row in 1...board.dimension {
            for col in 1...board.dimension {
                let candidate = Move.play(self.player, Point(row: row, col: col))
                if state.isValid(move: candidate) && !isEye(point: candidate.point!, on: board) {
                    candidates.append(candidate)
                }
            }
        }
        return candidates.isEmpty ? Move.pass : candidates.randomElement()!
    }
    
    public func diagnostics() -> String {
        "NiaveAgent"
    }
                
}
