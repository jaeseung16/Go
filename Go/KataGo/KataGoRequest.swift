//
//  KataGoRequest.swift
//  Go
//
//  Created by Jae Seung Lee on 9/3/20.
//  Copyright © 2020 Jae Seung Lee. All rights reserved.
//

import Foundation

struct KataGoRequest: Codable {
    var id: String
    var moves: [Move]
    var initialStones: [Move]?
    var initialPlayer: String?
    var rules: String
    var komi: Float?
    var whiteHandicapBonus: Int?
    var boardXSize: Int
    var boardYSize: Int
    var analyzeTurns: [Int]?
    var maxVisits: Int
    var rootPolicyTemperature: Float?
    var rootFpuReductionMax: Float?
    var includeOwnership: Bool?
    var includePolicy: Bool?
    var includePVVisits: Bool?
    var avoidMoves: [AvoidMove]?
    var allowMoves: [AllowMove]?
    var overrideSettings: [String: String]?
    var priority: Int?
}


struct Move: Codable {
    var player: String
    var location: String
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(player)
        try container.encode(location)
    }
}

/*
struct Rule: Codable {
    var rule: String
}
*/

struct AvoidMove: Codable {
    var player: String
    var moves: [Move]
    var untilDepth: Int
}

struct AllowMove: Codable {
    var player: String
    var moves: [Move]
    var untilDepth: Int
}

struct Setting: Codable {
    var key: String
    var value: String
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(key)
        try container.encode(value)
    }
}
