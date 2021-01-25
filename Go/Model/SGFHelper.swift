//
//  SGFHelper.swift
//  Go
//
//  Created by Jae Seung Lee on 1/21/21.
//  Copyright © 2021 Jae Seung Lee. All rights reserved.
//

import Foundation
import Cocoa
import SmartGameFormat_Swift

class SGFHelper {
    var url: URL?
    var gameTrees = [SGFGameTree]()
    var succeeded = false
    
    func load(from url: URL) -> Void {
        self.succeeded = false
        self.url = url
        
        guard let inputString = try? String(contentsOf: url) else {
            print("Failed to load from url = \(url)")
            return
        }
        
        let parser = SGFParser(inputString)
    
        do {
            try parser.parse()
        } catch {
            print("Failed parsing inputString: \(error)")
            return
        }
        
        self.gameTrees.append(contentsOf: parser.gameTrees)
        self.succeeded = true
    }
    
    func getPlays(gameNumber: Int = 0) -> [Play]? {
        guard gameNumber < self.gameTrees.count else {
            return nil
        }
        
        guard let gameInfo = self.gameTrees[gameNumber].gameInfo, let boardSize = Int(gameInfo.boardSize) else {
            return nil
        }
        
        let rootNode = self.gameTrees[gameNumber].rootNode
        
        var count = 0
        var currentNode = rootNode.eldest
        var plays = [Play]()
        while currentNode.children.count > 0 {
            let blackMove = currentNode.properties["B"]
            let whiteMove = currentNode.properties["W"]
            
            let sgfCoordinate = blackMove != nil ? blackMove!.values![0] : (whiteMove != nil ? whiteMove!.values![0] : String())
            let stone = blackMove != nil ? Stone.Black : (whiteMove != nil ? Stone.White : nil)
            // TODO:- How to better handle pass?
            if !isPass(coordinate: sgfCoordinate, boardSize: boardSize) && stone != nil {
                plays.append(generatePlay(for: stone!, count: count, coordinate: sgfCoordinate))
                count += 1
            }
            
            currentNode = currentNode.eldest
        }
        
        return plays
    }
    
    private func isPass(coordinate: String, boardSize: Int) -> Bool {
        return coordinate.isEmpty || (coordinate == "tt" && boardSize <= 19)
    }
    
    private func generatePlay(for player: Stone, count: Int, coordinate: String) -> Play {
        let sgfRow = SGFCoordinate(rawValue: String(coordinate.last!))!
        let sgfcolumn = SGFCoordinate(rawValue: String(coordinate.first!))!
        return Play(id: count, row: sgfRow.toNumber(), column: sgfcolumn.toNumber(), stone: player)
    }
    
    func load(from plays: [Play]) -> Void {
        let rootNode = SGFNode()
        
        let application = SGFProperty(id: "AP", values: ["Go"])
        let gameType = SGFProperty(id: "GM", values: ["1"])
        let boardSize = SGFProperty(id: "SZ", values: ["19"])
        let characterSet = SGFProperty(id: "CA", values: ["ISO-8859-1"])
        let fileFormat = SGFProperty(id: "FF", values: ["SGF"])
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let gameDate = SGFProperty(id: "DT", values: [dateFormatter.string(from: Date())])
        
        rootNode.add(property: application)
        rootNode.add(property: gameType)
        rootNode.add(property: boardSize)
        rootNode.add(property: characterSet)
        rootNode.add(property: fileFormat)
        rootNode.add(property: gameDate)
        
        var currentNode = rootNode
        for play in plays {
            let row = SGFCoordinate.toString(play.location.row)
            let column = SGFCoordinate.toString(play.location.column)
            let location = "\(column)\(row)"
            
            let player = play.stone == .Black ? "B" : "W"
            
            let property = SGFProperty(id: player, values: [location])
                
            let node = SGFNode(properties: [property])
            
            currentNode.add(child: node)
            currentNode = node
        }
        
        let gameTree = SGFGameTree()
        gameTree.rootNode = rootNode
        
        self.gameTrees.append(gameTree)
    }
    
    func save(to url: URL) -> Void {
        self.succeeded = false
        var stringToSave = ""
        
        if gameTrees.count > 0 {
            for gameTree in gameTrees {
                stringToSave += gameTree.sgfString
            }
            
            do {
                try stringToSave.write(to: url, atomically: true, encoding: .utf8)
            } catch {
                print("Failed saving to \(url): \(error)")
                return
            }
        }
        self.succeeded = true
    }
            
}
