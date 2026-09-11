//
//  GoNetworkFactory.swift
//  GoBoard
//
//  Created by Jae Seung Lee on 9/11/26.
//

public protocol GoNetworkFactory {
    func create(_ name: GoNetworkName, with encoder: GoBoardEncoder) -> GoNetwork
}

public struct GoNetworkFactoryImpl: GoNetworkFactory {
    
    public init() {}
    
    public func create(_ name: GoNetworkName, with encoder: GoBoardEncoder) -> GoNetwork {
        switch name {
        case .small:
            return Small(encoder: encoder)
        }
    }
}
