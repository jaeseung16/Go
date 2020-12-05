//
//  GameAnalysis.swift
//  Go
//
//  Created by Jae Seung Lee on 9/7/20.
//  Copyright © 2020 Jae Seung Lee. All rights reserved.
//

import Foundation

struct GameAnalysis {
    var playMade: Play
    var bestNextPlay: Play
    var winrate: Double
    var scoreLead: Double
    var otherPlays: [Play]
    var otherWinrates: [Double]
    var otherScoreLeads: [Double]
}
