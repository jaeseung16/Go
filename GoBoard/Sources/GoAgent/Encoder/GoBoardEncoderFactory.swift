//
//  EncoderFactory.swift
//  GoBoard
//
//  Created by Jae Seung Lee on 9/11/26.
//

public protocol GoBoardEncoderFactory {
    
    func create(_ name: GoBoardEncoderName, boardDimension: Int) -> GoBoardEncoder
    
}

public struct GoBoardEncoderFactoryImpl: GoBoardEncoderFactory {
    public init() {}
    
    public func create(_ name: GoBoardEncoderName, boardDimension: Int) -> GoBoardEncoder {
        switch name {
        case .simple:
            return SimpleEncoder(boardDimension: boardDimension)
        }
    }
    
}
