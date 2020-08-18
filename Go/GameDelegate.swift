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
}