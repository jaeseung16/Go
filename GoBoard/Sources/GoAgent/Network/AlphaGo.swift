//
//  AlphaGo.swift
//  GoBoard
//
//  Created by Jae Seung Lee on 9/13/26.
//

import MLX
import MLXNN

public class AlphaGo: Module, GoNetwork {
    
    @ModuleInfo var conv1: Conv2d
    @ModuleInfo var conv2: Conv2d
    @ModuleInfo var conv3: Conv2d
    @ModuleInfo var conv4: Conv2d
    @ModuleInfo var conv5: Conv2d
    @ModuleInfo var conv6: Conv2d
    @ModuleInfo var conv7: Conv2d
    @ModuleInfo var conv8: Conv2d
    @ModuleInfo var conv9: Conv2d
    @ModuleInfo var conv10: Conv2d
    @ModuleInfo var conv11: Conv2d
    @ModuleInfo var conv12: Conv2d
    @ModuleInfo var conv13: Conv2d
    @ModuleInfo var conv14: Conv2d
    @ModuleInfo var convPolicy: Conv2d
    @ModuleInfo var dense1: Linear
    @ModuleInfo var dense2: Linear
    
    // https://swiftpackageindex.com/ml-explore/mlx-swift/0.31.6/documentation/mlxnn/conv2d/init(inputchannels:outputchannels:kernelsize:stride:padding:dilation:groups:bias:)
    // The channels are expected to be last i.e. the input shape should be NHWC where:
    // N is the batch dimension
    // H is the input image height
    // W is the input image width
    // C is the number of input channels
    
    public let name = GoNetworkName.large.rawValue
    public let shape: [Int]
    public let encoder: GoBoardEncoder
    public let isPolicy: Bool
    
    // dlgo's small network: `padding: p` here is Keras's `ZeroPadding2D(padding=p)` followed by
    // an unpadded `Conv2D`, and `dense2` is the `Dense(num_points)` head dlgo's agents add on top.
    public init(encoder: GoBoardEncoder, isPolicy: Bool = false, numFilters: Int = 192, firstKernelSize: Int = 5, otherKernelSize: Int = 3) {
        // TODO: NHWC
        self.shape = encoder.shape
        self.encoder = encoder
        
        // TODO: - Need to check input shape depending on policy vs. value
        self.isPolicy = isPolicy

        let firstPadding = (firstKernelSize - 1) / 2
        let otherPadding = (otherKernelSize - 1) / 2
        
        conv1 = Conv2d(inputChannels: shape[2], outputChannels: numFilters, kernelSize: IntOrPair(firstKernelSize), padding: IntOrPair(firstPadding))
        conv2 = Conv2d(inputChannels: numFilters, outputChannels: numFilters, kernelSize: IntOrPair(otherKernelSize), padding: IntOrPair(otherPadding))
        conv3 = Conv2d(inputChannels: numFilters, outputChannels: numFilters, kernelSize: IntOrPair(otherKernelSize), padding: IntOrPair(otherPadding))
        conv4 = Conv2d(inputChannels: numFilters, outputChannels: numFilters, kernelSize: IntOrPair(otherKernelSize), padding: IntOrPair(otherPadding))
        conv5 = Conv2d(inputChannels: numFilters, outputChannels: numFilters, kernelSize: IntOrPair(otherKernelSize), padding: IntOrPair(otherPadding))
        conv6 = Conv2d(inputChannels: numFilters, outputChannels: numFilters, kernelSize: IntOrPair(otherKernelSize), padding: IntOrPair(otherPadding))
        conv7 = Conv2d(inputChannels: numFilters, outputChannels: numFilters, kernelSize: IntOrPair(otherKernelSize), padding: IntOrPair(otherPadding))
        conv8 = Conv2d(inputChannels: numFilters, outputChannels: numFilters, kernelSize: IntOrPair(otherKernelSize), padding: IntOrPair(otherPadding))
        conv9 = Conv2d(inputChannels: numFilters, outputChannels: numFilters, kernelSize: IntOrPair(otherKernelSize), padding: IntOrPair(otherPadding))
        conv10 = Conv2d(inputChannels: numFilters, outputChannels: numFilters, kernelSize: IntOrPair(otherKernelSize), padding: IntOrPair(otherPadding))
        conv11 = Conv2d(inputChannels: numFilters, outputChannels: numFilters, kernelSize: IntOrPair(otherKernelSize), padding: IntOrPair(otherPadding))
        conv12 = Conv2d(inputChannels: numFilters, outputChannels: numFilters, kernelSize: IntOrPair(otherKernelSize), padding: IntOrPair(otherPadding))
        conv13 = Conv2d(inputChannels: numFilters, outputChannels: numFilters, kernelSize: IntOrPair(otherKernelSize), padding: IntOrPair(otherPadding))
        conv14 = Conv2d(inputChannels: numFilters, outputChannels: 1, kernelSize: 1)
        convPolicy = Conv2d(inputChannels: numFilters, outputChannels: 1, kernelSize: 1)
        dense1 = Linear(1 * shape[0] * shape[1], 256)
        dense2 = Linear(256, shape[0] * shape[1])
    }

    /// Unnormalized move scores (logits), one row per board and one column per point.
    ///
    /// dlgo ends the network with `Activation('softmax')`; here that is left to the caller.
    /// `PolicyAgentModel` applies it per row when predicting and inside the loss when training.
    public func callAsFunction(_ x: MLX.MLXArray) -> MLX.MLXArray {
        var x = x
        x = relu(conv1(x))
        x = relu(conv2(x))
        x = relu(conv3(x))
        x = relu(conv4(x))
        x = relu(conv5(x))
        x = relu(conv6(x))
        x = relu(conv7(x))
        x = relu(conv8(x))
        x = relu(conv9(x))
        x = relu(conv10(x))
        x = relu(conv11(x))
        x = relu(conv12(x))
        
        if self.isPolicy {
            x = softmax(convPolicy(x))
            return flatten(x, startAxis: 1)
        } else {
            x = relu(conv13(x))
            x = relu(conv14(x))
            x = flatten(x, startAxis: 1)
            x = relu(dense1(x))
            x = dense2(x)
            return Tanh()(x)
        }
    }
    
}
