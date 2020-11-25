//
//  Intersection.swift
//  Go
//
//  Created by Jae Seung Lee on 8/4/20.
//  Copyright © 2020 Jae Seung Lee. All rights reserved.
//

import Foundation

struct Intersection: Hashable {
    // Poistion in board
    let row: Int
    let column: Int
    
    // Black, White, nil
    var stone: Stone?
    
    // Forbidden for the next play?
    // forbidden can be true only when stone is nil
    var forbidden = false
    
    var isEye = true
    
}
