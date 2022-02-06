//
//  Analyzer.swift
//  Go
//
//  Created by Jae Seung Lee on 1/26/22.
//  Copyright © 2022 Jae Seung Lee. All rights reserved.
//

import Foundation

class Analyzer {
    var game: Game
    var goBoard: GoBoard
    var groups = Set<Group>()
    var removedStones = Set<Intersection>()
    
    var plays: [Play] {
        return game.plays
    }
    
    init(game: Game, goBoard: GoBoard, groups: Set<Group>, removedStones: Set<Intersection>) {
        self.game = game
        self.goBoard = goBoard
        self.groups = groups
        self.removedStones = removedStones
    }
    
    var blackLocations: BlackLocations {
        let locations = plays.filter { $0.stone == .Black }.map { $0.location}
        return BlackLocations(playNumber: plays.count, locations: locations, turn: plays.count % 2 == 0)
    }
    
    var whiteLocations: WhiteLocations {
        let locations = plays.filter { $0.stone == .White }.map { $0.location}
        return WhiteLocations(playNumber: plays.count, locations: locations, turn: plays.count % 2 != 0)
    }
    
    var sequenceLocations: SequenceLocations {
        let locations = plays.map { $0.location}
        return SequenceLocations(playNumber: plays.count, locations: locations)
    }
    
    var allowedLocations: AllowedLocations {
        guard let lastPlay = plays.last else {
            return AllowedLocations(playNumber: plays.count, locations: [])
        }
        
        var positions = [Intersection]()
        for row in 0..<goBoard.size {
            for column in 0..<goBoard.size {
                let nextPlay = Play(id: plays.count + 1, row: row, column: column, stone: lastPlay.stone == .Black ? .White : .Black)
                
                var canPlay = goBoard.status(row: row, column: column) == nil
                
                if canPlay {
                    let groupAnalyzer = GroupAnalyzer(play: nextPlay, goBoard: goBoard, groups: groups, lastPlay: lastPlay, removedStones: removedStones)
                    if !groupAnalyzer.allNeighborsAreLiberties {
                        canPlay = groupAnalyzer.isPlayable
                    }
                }
                
                if canPlay {
                    positions.append(Intersection(row: row, column: column))
                }
            }
        }
        return AllowedLocations(playNumber: plays.count, locations: positions)
    }
    
    var chainLocationsForBlack: GroupLocations {
        return GroupLocations(playNumber: plays.count, groups: Array(groups.filter { $0.stone == .Black}))
    }
    
    var chainLocationsForWhite: GroupLocations {
        return GroupLocations(playNumber: plays.count, groups: Array(groups.filter { $0.stone == .White}))
    }
    
    func chainLocations(for stone: Stone) -> GroupLocations {
        return stone == .Black ? chainLocationsForBlack : chainLocationsForWhite
    }
    
    var libertyLocationsForBlack: LibertyLocations {
        var positions = [Intersection]()
        groups.filter { $0.stone == .Black } .forEach { group in
            positions.append(contentsOf: group.liberties)
        }
        
        return LibertyLocations(playNumber: plays.count, locations: positions)
    }
    
    var libertyLocationsForWhite: LibertyLocations {
        var positions = [Intersection]()
        groups.filter { $0.stone == .White } .forEach { group in
            positions.append(contentsOf: group.liberties)
        }
        
        return LibertyLocations(playNumber: plays.count, locations: positions)
    }
    
    func libertyLocations(for stone: Stone) -> LibertyLocations {
        return stone == .Black ? libertyLocationsForBlack : libertyLocationsForWhite
    }
    
    var removedLocations: RemovedLocations {
        return RemovedLocations(playNumber: plays.count, locations: [Intersection](removedStones))
    }
}
