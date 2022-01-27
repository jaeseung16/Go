//
//  Analyzer.swift
//  Go
//
//  Created by Jae Seung Lee on 1/26/22.
//  Copyright © 2022 Jae Seung Lee. All rights reserved.
//

import Foundation

class Analyzer {
    var plays: [Play]
    
    init(plays: [Play]) {
        self.plays = plays
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
        return AllowedLocations(playNumber: plays.count, locations: [])
    }
    
    var chainLocations: GroupLocations {
        return GroupLocations(playNumber: plays.count, locations: [])
    }
    
    var libertyLocations: LibertyLocations {
        return LibertyLocations(playNumber: plays.count, locations: [])
    }
}
