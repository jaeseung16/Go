//
//  GameSceneDelegate.swift
//  Go
//
//  Created by Jae Seung Lee on 8/17/20.
//  Copyright © 2020 Jae Seung Lee. All rights reserved.
//

import Foundation

protocol GameDelegate {
    func play(at intersection: Intersection) -> Void
    
    func isPlayable(at intersection: Intersection) -> Bool
    
    func playablePositions(stone: Stone) -> [Intersection]
    
    func updateClock(_ currentTime: TimeInterval) -> Void
    
    func needToShowAnalysis() -> Bool
    
    func getAnalysis() -> GameAnalysis?
}
