//
//  GoNetwork.swift
//  GoBoard
//
//  Created by Jae Seung Lee on 9/6/26.
//

import MLX
import MLXNN

public protocol GoNetwork: Module, UnaryLayer {
    
    var name: String { get }
    
    var shape: [Int] { get }
    
    var encoder: Encoder { get }
    
}
