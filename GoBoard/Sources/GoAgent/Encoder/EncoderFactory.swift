//
//  EncoderFactory.swift
//  GoBoard
//
//  Created by Jae Seung Lee on 9/11/26.
//

public protocol EncoderFactory {
    
    func create(_ name: EncoderName, boardDimension: Int) -> Encoder
    
}

public struct EncoderFactoryImpl: EncoderFactory {
    public init() {}
    
    public func create(_ name: EncoderName, boardDimension: Int) -> Encoder {
        switch name {
        case .simple:
            return SimpleEncoder(boardDimension: boardDimension)
        }
    }
    
}
