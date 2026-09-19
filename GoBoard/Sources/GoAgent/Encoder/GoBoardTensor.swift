//
//  GoBoardTensor.swift
//  GoBoard
//
//  Created by Jae Seung Lee on 9/13/26.
//

public struct GoBoardTensor {
    
    // N is the batch dimension
    // H is the input image height
    // W is the input image width
    // C is the number of input channels
    
    public let data: [[[UInt8]]]
    
    public init(data: [[[UInt8]]]) {
        self.data = data
    }
    
}
