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
    var kataGo: KataGo?
    var responses = [KataGoResponse]()
    
    private let responseQueue = DispatchQueue(label: "com.resonance.Go.GameAnalyzer.responseQueue", attributes: .concurrent)
    
    init(with url: URL) {
        kataGo = KataGo(with: url)
        kataGo!.delegate = self
    }
    
    func startEngine() {
        kataGo?.startEngine()
    }
    
    func analyze(plays: [Play]) -> Void {
        guard let ready = kataGo?.ready, ready else {
            return
        }
        
        let moves = plays.map {$0.toKataGoMove()!}
        
        let komi = Float(6.5)
        let rules = "korean"
        
        let setting: [String: String] = ["reportAnalysisWinratesAs": "BLACK"]
        
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
                                    maxVisits: 100,
                                    rootPolicyTemperature: nil,
                                    rootFpuReductionMax: nil,
                                    includeOwnership: nil,
                                    includePolicy: nil,
                                    includePVVisits: nil,
                                    avoidMoves: nil,
                                    allowMoves: nil,
                                    overrideSettings: setting,
                                    priority: nil)
        
        print("\(request)")
        
        let encoder = JSONEncoder()
        let data = try? encoder.encode(request)
        
        print("json: " + String(data: data!, encoding: .utf8)!)
        
        let query = String(data: data!, encoding: .utf8)! + "\n"
        kataGo?.process(query: query)
    }
    
    func isAnalysisAvailable() -> Bool {
        return false
    }
    
    func getResult() -> Void {
        
    }
}

extension GameAnalyzer: EngineDelegate {
    func read(result: String) {
        //print("received: \(result)")
        responseQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else {
                return
            }
            
            let decoder = JSONDecoder()
            if let response = try? decoder.decode(KataGoResponse.self, from: result.data(using: .utf8)!) {
                self.responses.append(response)
                print("responses.count = \(self.responses.count)")
            } else {
                print("Result cannot be parsed: \(result)")
            }
        }
    }
}
