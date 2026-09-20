//
//  QAgent.swift
//  GoBoard
//
//  Created by Jae Seung Lee on 9/13/26.
//

import Foundation
import GoBoard
import Logging

public class QAgent: GoAgent {
    public static let logger = Logger(label: "com.resonance.GoAgent.QAgent")
    
    private static let eps = 1e-5
    
    public let stone: Stone
    private let player: Player
    private var lastStateValue: Float
    private let encoder: GoBoardEncoder
    private let model: GoAgentModel
    
    public var temperature: Float
    public var experienceCollector: ExperienceCollector?

    init(stone: Stone, player: Player, encoder: GoBoardEncoder, model: GoAgentModel, experienceCollector: ExperienceCollector? = nil, temperature: Float = 0.0) {
        self.stone = stone
        self.player = player
        self.encoder = encoder
        self.model = model
        self.experienceCollector = experienceCollector
        self.temperature = temperature
        self.lastStateValue = 0.0
    }
    
    public func select(from state: GameState) -> Move {
        let boardTensor = self.encoder.encode(gameState: state)
        
        // Loop over all legal moves.

        var moves = [Move]()
        var boardTensors = [GoBoardTensor]()
        var actionTensors = [GoActionTensor]()
        
        for move in state.legalMoves {
            guard move.isPlay, let point = move.point else { continue }
            moves.append(move)
            boardTensors.append(boardTensor)
            
            var action = Array(repeating: [UInt8](repeating: 0, count: state.board.dimension), count: state.board.dimension)
            action[point.row - 1][point.col - 1] = 1
            actionTensors.append(GoActionTensor(data: action))
        }
        
        if moves.isEmpty {
            return .pass
        }
        
        let values = self.model.predict(from: boardTensors, actions: actionTensors).flatMap { $0 }
        let rankedMoves = rankMovesEpsilonGreedy(values)
        for pointIdx in rankedMoves {
            let point = self.encoder.decode(index: pointIdx)
            if !isEye(point: point, on: state.board) {
                if let collector = experienceCollector {
                    collector.recordDecision(state: boardTensor.data, action: pointIdx, estimatedValue: 0.0)
                }
                self.lastStateValue = values[pointIdx]
                return .play(self.player, point)
            }
        }
        return .pass
    }
    
    private func rankMovesEpsilonGreedy(_ values: [Float]) -> [Int] {
        var values = values
        if Float.random(in: 0..<1) < self.temperature {
            values = (0..<values.count).map { _ in
                Float.random(in: 0..<1)
            }
        }
        return values.argsort().reversed()
    }
    
    
    public func diagnostics() -> String {
        "QAgent(stone: \(stone), value: \(lastStateValue))"
    }
    
}
