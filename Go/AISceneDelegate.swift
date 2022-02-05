//
//  AISceneDelegate.swift
//  Go
//
//  Created by Jae Seung Lee on 2/4/22.
//  Copyright © 2022 Jae Seung Lee. All rights reserved.
//

import Foundation

protocol AISceneDelegate {
    func getAnalysis() -> GameAnalysis?
    func getFeature() -> AnalyzerFeature?
    func update() -> Void
}
