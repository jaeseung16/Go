//
//  Territory.swift
//  GoBoard
//
//  Created by Jae Seung Lee on 5/17/26.
//

public struct Territory {
    
    public var numBlackTerritory: Int
    public var numWhiteTerritory: Int
    public var numBlackStones: Int
    public var numWhiteStones: Int
    
    public var dames: [Point]
    
    public var numDames: Int {
        return dames.count
    }
    
    public init(territoryMap: [Point: String] = [:]) {
        self.numBlackTerritory = 0
        self.numWhiteTerritory = 0
        self.numBlackStones = 0
        self.numWhiteStones = 0
        self.dames = []
        
        for status in territoryMap {
            if status.value == "b" {
                self.numBlackStones += 1
            }
            
            if status.value == "w" {
                self.numWhiteStones += 1
            }
               
            if status.value == "territory_b" {
                self.numBlackTerritory += 1
            }
                
            if status.value == "territory_w" {
                self.numWhiteTerritory += 1
            }
                
            if status.value == "dame" {
                self.dames.append(status.key)
            }
        }
    }
    
}
