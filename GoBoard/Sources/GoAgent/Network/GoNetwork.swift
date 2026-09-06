//
//  GoNetwork.swift
//  GoBoard
//
//  Created by Jae Seung Lee on 9/6/26.
//

import MLX
import MLXNN

public protocol GoNetwork: Module, UnaryLayer {
    
    var shape: [Int] { get }
    
}
