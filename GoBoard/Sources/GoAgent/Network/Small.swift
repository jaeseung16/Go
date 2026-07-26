//
//  Small.swift
//  GoBoard
//
//  Created by Jae Seung Lee on 7/26/26.
//

import MLX
import MLXNN

public class Small: Module, UnaryLayer {
    
    @ModuleInfo var conv1: Conv2d
    @ModuleInfo var conv2: Conv2d
    @ModuleInfo var conv3: Conv2d
    @ModuleInfo var dense1: Linear
    @ModuleInfo var dense2: Linear
    
    // https://swiftpackageindex.com/ml-explore/mlx-swift/0.31.6/documentation/mlxnn/conv2d/init(inputchannels:outputchannels:kernelsize:stride:padding:dilation:groups:bias:)
    // The channels are expected to be last i.e. the input shape should be NHWC where:
    // N is the batch dimension
    // H is the input image height
    // W is the input image width
    // C is the number of input channels
    
    public init(encoder: Encoder) {
        // TODO: NHWC
        let shape = encoder.shape
        
        conv1 = Conv2d(inputChannels: shape[2], outputChannels: 48, kernelSize: 7, padding: 3)
        conv2 = Conv2d(inputChannels: 48, outputChannels: 32, kernelSize: 5, padding: 2)
        conv3 = Conv2d(inputChannels: 32, outputChannels: 32, kernelSize: 5, padding: 2)
        dense1 = Linear(32 * shape[0] * shape[1], 512)
        dense2 = Linear(512, shape[0] * shape[1])
    }
    
    public func callAsFunction(_ x: MLX.MLXArray) -> MLX.MLXArray {
        var x = x
        x = relu(conv1(x))
        x = relu(conv2(x))
        x = relu(conv3(x))
        x = flatten(x, startAxis: 1)
        x = relu(dense1(x))
        x = softmax(dense2(x))
        return x
    }
    
}

