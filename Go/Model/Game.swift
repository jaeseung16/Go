//
//  Game.swift
//  Go
//
//  Created by Jae Seung Lee on 8/15/20.
//  Copyright © 2020 Jae Seung Lee. All rights reserved.
//

import Foundation

class Game {
    
    // Players
    var blackPlayer = Player(stone: .Black, score: 0)
    var whitePlayer = Player(stone: .White, score: 0)
    
    var goBoard: GoBoard
    
    // Plays
    // play number, stone, coordinate, time
    
    var plays = [Play]()
    var removed = [Play]()
    
    var removedStones = Set<Intersection>()
    
    init() {
        self.goBoard = GoBoard()
    }
    
    init(goBoard: GoBoard) {
        self.goBoard = goBoard
    }
    
    var currentPlay: Player? {
        guard let lastPlay = plays.last else {
            return nil
        }
        
        return lastPlay.stone == .Black ? whitePlayer : blackPlayer
    }
    
    var blackStonesCurrentlyOnBoard: [Play] {
        return plays.filter { $0.stone == .Black && !removed.contains($0) }
    }
    
    var whiteStonesCurrentlyOnBoard: [Play] {
        return plays.filter { $0.stone == .White && !removed.contains($0) }
    }
    
    var removedBlackStone: [Play] {
        return removed.filter { $0.stone == .Black }
    }
    
    var removedWhiteStone: [Play] {
        return removed.filter { $0.stone == .White }
    }
    
    // Rule
    // Korean, Chinese, Japan, and so on
    // Komi 5.5, 6.5, 7.5
    // Handicap: 1-9
    // How to end
    // Score
    
    // Clock
    
    func append(play: Play) {
        plays.append(play)
    }
    
}
