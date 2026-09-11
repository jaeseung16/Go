//
//  GoAgentModelFactory.swift
//  GoBoard
//
//  Created by Jae Seung Lee on 9/11/26.
//

public enum GoAgentModelFactoryError: Error {
    case unknownNetowork
}

public protocol GoAgentModelFactory {
    func create(_ name: GoAgentModelName, with network: GoNetwork) throws -> GoAgentModel
}

public struct GoAgentModelFactoryImpl: GoAgentModelFactory {
    public init() {}
    
    public func create(_ name: GoAgentModelName, with network: GoNetwork) throws -> GoAgentModel {
        let networkName = GoNetworkName(rawValue: network.name)
        
        switch name {
        case .policy:
            switch networkName {
            case .small:
                return PolicyAgentModel<Small>(network: network as! Small)
            case .none:
                throw GoAgentModelFactoryError.unknownNetowork
            }
        }
    }
}
