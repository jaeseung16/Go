//
//  GameAnalyzer.swift
//  Go
//
//  Created by Jae Seung Lee on 9/2/20.
//  Copyright © 2020 Jae Seung Lee. All rights reserved.
//

import Foundation

class GameAnalyzer {
    var plays: [Play]?
    var request: KataGoRequest?
    
    func analyze(plays: [Play]) -> Void {
        let moves = plays.map {$0.toKataGoMove()!}
        
        let komi = Float(6.5)
        let rules = "korean"
        
        let request = KataGoRequest(id: "Query\(moves.count)",
                                    moves: moves,
                                    initialStones: nil,
                                    initialPlayer: nil,
                                    rules: rules,
                                    komi: komi,
                                    whiteHandicapBonus: nil,
                                    boardXSize: 19,
                                    boardYSize: 19,
                                    analyzeTurns: nil,
                                    maxVisits: 1,
                                    rootPolicyTemperature: nil,
                                    rootFpuReductionMax: nil,
                                    includeOwnership: nil,
                                    includePolicy: nil,
                                    includePVVisits: nil,
                                    avoidMoves: nil,
                                    allowMoves: nil,
                                    overrideSetting: nil,
                                    priority: nil)
        
        print("\(request)")
        
        let encoder = JSONEncoder()
        let data = try? encoder.encode(request)
        
        print(String(data: data!, encoding: .utf8)!)
    }
    
    func isAnalysisAvailable() -> Bool {
        return false
    }
    
    func getResult() -> Void {
        
    }
}
