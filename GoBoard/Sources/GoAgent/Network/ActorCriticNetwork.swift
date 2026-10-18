//
//  ActorCriticNetwork.swift
//  GoBoard
//
//  Created by Jae Seung Lee on 10/4/26.
//

import MLX
import MLXNN

public class ActorCriticNetwork: Module, GoNetwork {
    
    @ModuleInfo var conv1: Conv2d
    @ModuleInfo var conv2: Conv2d
    @ModuleInfo var dense1: Linear
    @ModuleInfo var dense2: Linear
    @ModuleInfo var dense3: Linear
    @ModuleInfo var dense4: Linear
    @ModuleInfo var dense5: Linear
    
    public let name = GoNetworkName.actorCritic.rawValue
    public let shape: [Int]
    public let encoder: GoBoardEncoder
    
    public init(encoder: GoBoardEncoder) {
        self.shape = encoder.shape
        self.encoder = encoder

        conv1 = Conv2d(inputChannels: shape[2], outputChannels: 64, kernelSize: 5, padding: 2)
        conv2 = Conv2d(inputChannels: 64, outputChannels: 64, kernelSize: 3, padding: 1)
        
        dense1 = Linear(64 * shape[0] * shape[1], 512)
        dense2 = Linear(512, 512)
        dense3 = Linear(512, shape[0] * shape[1])
        dense4 = Linear(512, 512)
        dense5 = Linear(512, 1)
    }
    
    public func callAsFunction(_ x: MLX.MLXArray) -> MLX.MLXArray {
        let xSplit = split(x, indices: [shape[2]], axis: 3)
        
        var processedBoard : MLX.MLXArray = relu(conv1(xSplit[0]))
        processedBoard = relu(conv2(processedBoard))
        processedBoard = flatten(processedBoard, startAxis: 1)
        processedBoard = dense1(processedBoard)
        
        let policyHidden = relu(dense2(processedBoard))
        let policyOut = softmax(dense3(policyHidden))
        
        let valueHidden = relu(dense4(processedBoard))
        let valueOut = MLX.tanh(dense5(valueHidden))
        return concatenated([policyOut, valueOut], axis: 1)
    }
    
}
