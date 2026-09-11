//
//  AgentModel.swift
//  GoBoard
//
//  Created by Jae Seung Lee on 7/12/26.
//

import Foundation
import MLX
import MLXOptimizers

public protocol GoAgentModel {
    
    var name: String { get }
    var encoder: Encoder { get }
    
    func predict(from boardTensor: [[[UInt8]]]) -> [Float]
    func train(with experiences: GoTrainingExperience, optimizer: Optimizer, batchSize:Int, clipNorm: Float) -> Void // May deserve a separate protocol, for example, Trainable?
    
    func save(to: URL) throws -> Void
    func load(from: URL) throws -> Void
}
