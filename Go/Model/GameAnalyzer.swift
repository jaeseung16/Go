//
//  GameAnalyzer.swift
//  Go
//
//  Created by Jae Seung Lee on 9/2/20.
//  Copyright © 2020 Jae Seung Lee. All rights reserved.
//

import Foundation
import Combine

class GameAnalyzer {
    static let shared = GameAnalyzer()
    
    var plays: [Play]?
    var request: KataGoRequest?
    var kataGo: KataGo?
    var responses = [KataGoResponse]()
    var count = 0
    
    @Published var isReady = false
    
    private let responseQueue = DispatchQueue(label: "com.resonance.Go.GameAnalyzer.responseQueue", attributes: .concurrent)
    
    init() {
    }
    
    init(with url: URL) {
        kataGo = KataGo(with: url)
        kataGo!.delegate = self
    }
    
    var isEngingStarted: Bool {
        return kataGo != nil
    }
    
    func setEngine(with url: URL) -> Void {
        kataGo = KataGo(with: url)
        kataGo!.delegate = self
    }
    
    func startEngine() -> Void {
        kataGo?.startEngine()
    }
    
    func stopEngine() -> Void {
        kataGo?.stopEngine()
    }
    
    func analyze(plays: [Play]) -> Void {
        guard let ready = kataGo?.ready, ready else {
            return
        }
        
        self.plays = plays
        
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
                                    includeOwnership: true,
                                    includePolicy: nil,
                                    includePVVisits: nil,
                                    avoidMoves: nil,
                                    allowMoves: nil,
                                    overrideSettings: setting,
                                    priority: nil)
        
        //print("\(request)")
        
        let encoder = JSONEncoder()
        let data = try? encoder.encode(request)
        
        //print("json: " + String(data: data!, encoding: .utf8)!)
        
        let query = String(data: data!, encoding: .utf8)! + "\n"
        
        responseQueue.async(flags: .barrier) {
            self.kataGo?.process(query: query)
            self.count += 1
        }

    }
    
    func isAnalysisAvailable() -> Bool {
        return false
    }
    
    func getResult() -> GameAnalysis? {
        var gameAnalysis: GameAnalysis?
        var response: KataGoResponse?
        
        responseQueue.sync {
            if (self.responses.count > 0 && self.responses.count == count) {
                response = self.responses.last!
            }
        }
        
        if (response != nil) {
            let id = response!.turnNumber
            let playMade = plays![id-1]
            
            //print("plays.count = \(plays!.count)")
            //print("id = \(id)")
            
            let nextPlayer = playMade.stone == .White ? Stone.Black : Stone.White
            
            let (bestPlayColumn, bestPlayRow) = toLocation(move: response!.moveInfos[0].move)
            let nextBestPlay = Play(id: id, row: bestPlayRow, column: bestPlayColumn, stone: nextPlayer)
            
            var otherPlays = [Play]()
            var otherWinrates = [Double]()
            var otherScoreLeads = [Double]()
            var otherVisits = [Int]()
            for moveInfo in response!.moveInfos {
                let (column, row) = toLocation(move: moveInfo.move)
                if (moveInfo.order == 0) {
                    continue
                } else {
                    otherPlays.append(Play(id: id, row: row, column: column, stone: nextPlayer))
                    otherWinrates.append(moveInfo.winrate)
                    otherScoreLeads.append(moveInfo.scoreLead)
                    otherVisits.append(moveInfo.visits)
                }
            }
            
            gameAnalysis = GameAnalysis(playMade: playMade,
                                        bestNextPlay: nextBestPlay,
                                        winrate: response!.moveInfos[0].winrate,
                                        scoreLead: response!.moveInfos[0].scoreLead,
                                        visits: response!.moveInfos[0].visits,
                                        otherPlays: otherPlays,
                                        otherWinrates: otherWinrates,
                                        otherScoreLeads: otherScoreLeads,
                                        otherVisits: otherVisits)
        }
       
        return gameAnalysis
    }
    
    let letterToNumber: [Character: Int] = ["A": 1, "B": 2, "C": 3, "D": 4,
                          "E": 5, "F": 6, "G": 7, "H": 8,
                          "J": 9, "K": 10, "L": 11, "M": 12,
                          "N": 13, "O": 14, "P": 15, "Q": 16,
                          "R": 17, "S": 18, "T": 19]
    
    func toLocation(move: String) -> (Int, Int) {
        var moveString = move
        let column = letterToNumber[moveString.removeFirst()]!
        let row = Int(moveString)!
        return (column - 1, row - 1)
    }
}

extension GameAnalyzer: EngineDelegate {
    func read(result: String) -> Void {
        print("received: \(result)")
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
    
    func setReady() -> Void {
        isReady = true
    }
}
