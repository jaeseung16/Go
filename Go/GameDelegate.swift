//
//  GameSceneDelegate.swift
//  Go
//
//  Created by Jae Seung Lee on 8/17/20.
//  Copyright © 2020 Jae Seung Lee. All rights reserved.
//

import Foundation

protocol GameDelegate {
    func play(stone: Stone, column: Int, row: Int) -> Void
    
    func isPlayable(stone: Stone, column: Int, row: Int) -> Bool
    
    func updateClock(_ currentTime: TimeInterval) -> Void
    
    func needToShowAnalysis() -> Bool
}
