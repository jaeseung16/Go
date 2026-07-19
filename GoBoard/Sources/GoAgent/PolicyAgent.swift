//
//  PolicyAgent.swift
//  GoBoard
//
//  Created by Jae Seung Lee on 7/5/26.
//

import GoBoard
import Logging
import MLX

public class PolicyAgent: GoAgent {
    public static let logger = Logger(label: "com.resonance.GoAgent.PolicyAgent")
    
    private static let eps = 1e-5
    
    public let stone: Stone
    private let player: Player
    
    private let encoder: Encoder
    private let model: GoAgentModel
    
    public var temperature: Float = 0.0
    
    public init(stone: Stone, encoder: Encoder, model: GoAgentModel) {
        precondition(stone == .black || stone == .white)
        self.stone = stone
        self.player = Player.from(stone: stone)!
        self.encoder = encoder
        self.model = model
    }
    
    public func select(from state: GameState) -> Move {
        let numMoves = self.encoder.shape[0] * self.encoder.shape[1]
        let boardTensor = self.encoder.encode(gameState: state)
        
        // x = np.array([board_tensor])
        
        var moveProbs: MLXArray
        if (Float.random(in: 0..<1) < self.temperature){
            moveProbs = MLXArray.ones([numMoves]) / Double(numMoves)
        } else {
            // Follow our current policy.
            // move_probs = self._model.predict(x, verbose=0)[0]
            moveProbs = MLXArray.ones([numMoves]) / Double(numMoves)
        }
        
        // Prevent move probs from getting stuck at 0 or 1
        moveProbs = clip(moveProbs, min: Self.eps, max: 1 - Self.eps)
        
        // Re-normalize to get another probability distribution.
        
        moveProbs = moveProbs / moveProbs.sum()
        
        // TODO :- Turn the probabilities into a ranked list of moves
        // let candidates = MLXArray(0..<numMoves)
        let rankedMoves = MLXRandom.categorical(moveProbs, count: numMoves)
        
        for pointIdx in rankedMoves {
            let point = self.encoder.decode(index: pointIdx.all().item())
            if state.isValid(move: .play(self.player, point)) && !isEye(point: point, on: state.board) {
                // if self._collector is not None:
                //     self._collector.record_decision(state=board_tensor, action=point_idx)
                return .play(self.player, point)
            }
        }
        
        // No legal, non-self-destructive move less.
        return .pass
    }
    
    public func diagnostics() -> String {
        "PolicyAgent(stone: \(stone))"
    }
    
}
