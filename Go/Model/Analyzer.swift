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
}
