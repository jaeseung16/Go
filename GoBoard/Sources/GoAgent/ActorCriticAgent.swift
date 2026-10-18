//
//  ActorCriticAgent.swift
//  GoBoard
//
//  Created by Jae Seung Lee on 10/4/26.
//

import Foundation
import GoBoard
import Logging

public class ActorCriticAgent: GoAgent {
    public static let logger = Logger(label: "com.resonance.GoAgent.ActorCriticAgent")
    
    private static let eps = 1e-6
    
    public let stone: Stone
    private let player: Player
    private var lastStateValue: Float
    
    private let encoder: GoBoardEncoder
    private let model: GoAgentModel
    public var experienceCollector: ExperienceCollector?
    
    public init(stone: Stone, encoder: GoBoardEncoder, model: GoAgentModel, experienceCollector: ExperienceCollector? = nil) {
        self.stone = stone
        self.player = Player.from(stone: stone)!
        self.encoder = encoder
        self.model = model
        self.experienceCollector = experienceCollector
        self.lastStateValue = 0.0
    }
    
    public func select(from state: GameState) -> Move {
        
        let numMoves = state.board.dimension * state.board.dimension
        
        let boardTensor = encoder.encode(gameState: state)
        
        // TODO: actions, values = self.model.predict(X, verbose=0)
        let actionsAndValues = self.model.predict(from: [boardTensor])
        print("actionsAndValues: \(actionsAndValues.count), actionsAndValues[0]: \(actionsAndValues[0].count)")
        let moveProbs = actionsAndValues[0][0..<numMoves]
        let estimatedValue = actionsAndValues[0][numMoves]
        
        lastStateValue = estimatedValue
        
        let clippedMoveProbs = moveProbs.map { min(max($0, Float(Self.eps)), 1 - Float(Self.eps)) }
        let total = clippedMoveProbs.reduce(0, +)
        let moveProbsToUse = clippedMoveProbs.map { $0 / total }

        // Turn the probabilities into a ranked list of moves.
        let rankedMoves = self.rankMoves(by: moveProbsToUse, count: numMoves)
        
        for pointIdx in rankedMoves {
            let point = self.encoder.decode(index: pointIdx)
            if state.isValid(move: .play(self.player, point)) && !isEye(point: point, on: state.board) {
                // if self._collector is not None:
                //     self._collector.record_decision(state=board_tensor, action=point_idx)
                if let collector = experienceCollector {
                    collector.recordDecision(state: boardTensor.data, action: pointIdx, estimatedValue: estimatedValue)
                }
                return .play(self.player, point)
            }
        }
        
        // No legal, non-self-destructive move less.
        return .pass
    }
    
    public func diagnostics() -> String {
        "QAgent(stone: \(stone), value: \(lastStateValue))"
    }
    
    private func rankMoves(by moveProbs: [Float], count: Int) -> [Int] {
        // `low` stays above zero so that log(u) is finite.
        let u = (0..<count).map { _ in
            Float.random(in: Float(Self.eps)..<1.0)
        }

        let gumbel = u.map { -log(-log($0)) }

        // argSort is ascending, so sort on the negated keys to rank most-likely first.
        let keys: [Float] = zip(moveProbs, gumbel).map { -(log($0) + $1) }
        return keys.argsort()
    }
    
}
