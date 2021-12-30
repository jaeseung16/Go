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
    case chain
    case liberty
    
    static var titles: [String] {
        Feature.allCases.map { $0.rawValue }
    }
}
