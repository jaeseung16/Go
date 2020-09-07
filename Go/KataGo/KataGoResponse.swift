//
//  KataGoResponse.swift
//  Go
//
//  Created by Jae Seung Lee on 9/6/20.
//  Copyright © 2020 Jae Seung Lee. All rights reserved.
//

import Foundation

struct KataGoResponse: Codable {
    var id: String
    var turnNumber: Int
    var moveInfos: [MoveInfo]
    var rootInfo: RootInfo
    var ownership: [Double]?
    var policy: [Double]?
}

struct MoveInfo: Codable {
    var order: Int
    var move: String
    var winrate: Double
    var lcb: Double
    var scoreLead: Double
    var scoreMean: Double
    var scoreStdev: Double
    var scoreSelfplay: Double
    var prior: Double
    var utility: Double
    var utilityLcb: Double
    var pv: [String]
    var pvVisits: Int?
    
}

struct RootInfo: Codable {
    var winrate: Double
    var scoreLead: Double
    var scoreStdev: Double
    var scoreSelfplay: Double
    var utility: Double
    var visits: Int
}
