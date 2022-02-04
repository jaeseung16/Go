//
//  Engine.swift
//  Go
//
//  Created by Jae Seung Lee on 9/6/20.
//  Copyright © 2020 Jae Seung Lee. All rights reserved.
//

import Foundation

protocol EngineDelegate {
    func read(result: String) -> Void
    func setReady() -> Void
}
