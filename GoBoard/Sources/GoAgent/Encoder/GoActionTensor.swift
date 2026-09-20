//
//  GoActionTensor.swift
//  GoBoard
//
//  Created by Jae Seung Lee on 9/19/26.
//

public struct GoActionTensor {
    
    // N is the batch dimension
    // H is the input image height
    // W is the input image width
    // C is the number of input channels
    
    public let data: [[UInt8]]
    
    public init(data: [[UInt8]]) {
        self.data = data
    }
    
    public var nRows: Int {
        data.count
    }
    
    public var nCols: Int {
        data.first?.count ?? 0
    }
    
    public var shape: [Int] {
        [nRows, nCols]
    }
    
}
