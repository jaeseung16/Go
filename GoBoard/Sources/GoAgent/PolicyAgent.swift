//
//  PolicyAgent.swift
//  GoBoard
//
//  Created by Jae Seung Lee on 7/5/26.
//

import Foundation
import GoBoard
import Logging

public class PolicyAgent: GoAgent {
    public static let logger = Logger(label: "com.resonance.GoAgent.PolicyAgent")
    
    private static let eps = 1e-5
    
    public let stone: Stone
    private let player: Player
    
    private let encoder: Encoder
    private let model: GoAgentModel
    public var experienceCollector: ExperienceCollector?
    
    public var temperature: Float
    
    public init(stone: Stone, encoder: Encoder, model: GoAgentModel, temperature: Float = 0.0) {
        precondition(stone == .black || stone == .white)
        self.stone = stone
        self.player = Player.from(stone: stone)!
        self.encoder = encoder
        self.model = model
        self.temperature = temperature
    }
    
    public func select(from state: GameState) -> Move {
        let numMoves = self.encoder.shape[0] * self.encoder.shape[1]
        let boardTensor = self.encoder.encode(gameState: state)
        
        var moveProbs: [Float]
        if (Float.random(in: 0..<1) < self.temperature){
            moveProbs = [Float](repeating: 1.0 / Float(numMoves), count: numMoves)
        } else {
            // Follow our current policy. The network is batched (NHWC), so add the batch
            // axis on the way in and take the single row back out.
            moveProbs = self.model.predict(from: boardTensor)
        }
        
        // Prevent move probs from getting stuck at 0 or 1
        moveProbs = moveProbs.map { min(max($0, Float(Self.eps)), 1 - Float(Self.eps)) }

        // Re-normalize to get another probability distribution.
        let total = moveProbs.reduce(0, +)
        moveProbs = moveProbs.map { $0 / total }
        
        // Turn the probabilities into a ranked list of moves.
        let rankedMoves = self.rankMoves(by: moveProbs, count: numMoves)
        
        for pointIdx in rankedMoves {
            let point = self.encoder.decode(index: pointIdx)
            if state.isValid(move: .play(self.player, point)) && !isEye(point: point, on: state.board) {
                // if self._collector is not None:
                //     self._collector.record_decision(state=board_tensor, action=point_idx)
                if let collector = experienceCollector {
                    collector.recordDecision(state: boardTensor, action: pointIdx, estimatedValue: 0.0)
                }
                return .play(self.player, point)
            }
        }
        
        // No legal, non-self-destructive move less.
        return .pass
    }
    
    /// Ranks all `count` moves in the order that repeated weighted draws *without replacement*
    /// would produce, which is what walking the list as a candidate order requires.
    ///
    /// This is the Gumbel top-k trick: perturb each log-probability with Gumbel noise, then sort.
    /// `MLXRandom.categorical` cannot do this — it draws *with* replacement, so a third of its
    /// candidates were duplicates and legal moves could be missed, and it treats its input as
    /// unnormalized logits, applying a second softmax to an already-normalized distribution.
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
    
    public func diagnostics() -> String {
        "PolicyAgent(stone: \(stone))"
    }
}

extension Sequence where Element: Comparable {
    func argsort() -> [Int] {
        return self.enumerated()
            .sorted { $0.element < $1.element }
            .map { $0.offset }
    }
}
