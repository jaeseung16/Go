//
//  AgentModel.swift
//  GoBoard
//
//  Created by Jae Seung Lee on 7/12/26.
//

import MLX

public protocol GoAgentModel {
    func predict(from boardTensor: MLXArray) -> [Int: Float]
    func train(with experiences: GoTrainingExperience) -> Void // May deserve a separate protocol, for example, Trainable?
}
