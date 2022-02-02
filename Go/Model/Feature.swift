//
//  Feature.swift
//  Go
//
//  Created by Jae Seung Lee on 12/29/21.
//  Copyright © 2021 Jae Seung Lee. All rights reserved.
//

enum Feature: String, CaseIterable {
    case none
    case black
    case white
    case sequence
    case allowed
    case removed
    case chainBlack = "chain (B)"
    case chainWhite = "chain (W)"
    case libertyBlack = "liberty (B)"
    case libertyWhite = "liberty (W)"
    
    static var titles: [String] {
        Feature.allCases.map { $0.rawValue }
    }
}
