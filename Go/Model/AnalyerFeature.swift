//
//  AnalyerFeature.swift
//  Go
//
//  Created by Jae Seung Lee on 2/4/22.
//  Copyright © 2022 Jae Seung Lee. All rights reserved.
//

import Foundation

enum AnalyzerFeature: String, CaseIterable {
    case none
    case winrate = "winrate"
    case scoreLead = "score lead"
    case visits = "# of visits"
    
    static var titles: [String] {
        Feature.allCases.map { $0.rawValue }
    }
}
