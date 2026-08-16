//
//  AgentModel.swift
//  GoBoard
//
//  Created by Jae Seung Lee on 7/12/26.
//

import MLX
import MLXOptimizers

public protocol GoAgentModel {
    func predict(from boardTensor: MLXArray) -> [Int: Float]
    func train(with experiences: GoTrainingExperience, optimizer: Optimizer, clipNorm: Float) -> Void // May deserve a separate protocol, for example, Trainable?
}
