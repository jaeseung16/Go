//
//  QNetwork.swift
//  GoBoard
//
//  Created by Jae Seung Lee on 9/20/26.
//

import MLX
import MLXNN

public class QNetwork: Module, GoNetwork {
    
    @ModuleInfo var conv1: Conv2d
    @ModuleInfo var conv2: Conv2d
    @ModuleInfo var dense1: Linear
    @ModuleInfo var dense2: Linear
    @ModuleInfo var dense3: Linear
    
    public let name = GoNetworkName.q.rawValue
    public let shape: [Int]
    public let encoder: GoBoardEncoder
    
    public init(encoder: GoBoardEncoder) {
        self.shape = encoder.shape
        self.encoder = encoder

        conv1 = Conv2d(inputChannels: shape[2], outputChannels: 64, kernelSize: 5, padding: 2)
        conv2 = Conv2d(inputChannels: 64, outputChannels: 64, kernelSize: 3, padding: 1)
        
        dense1 = Linear(64 * shape[0] * shape[1], 512)
        dense2 = Linear(512 + shape[0] * shape[1], 256)
        dense3 = Linear(256, 1)
    }
    
    public func callAsFunction(_ x: MLX.MLXArray) -> MLX.MLXArray {
        let xSplit = split(x, indices: [shape[2]], axis: 3)
        
        var processedBoard : MLX.MLXArray = relu(conv1(xSplit[0]))
        processedBoard = relu(conv2(processedBoard))
        processedBoard = flatten(processedBoard, startAxis: 1)
        processedBoard = dense1(processedBoard)
        
        let action = flatten(xSplit[1], startAxis: 1)
        
        var combined = concatenated([action, processedBoard], axis: 1)
        combined = relu(dense2(combined))
        return MLX.tanh(dense3(combined))
    }
}
