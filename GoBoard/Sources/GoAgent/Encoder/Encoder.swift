//
//  Encoder.swift
//  GoBoard
//
//  Created by Jae Seung Lee on 6/21/26.
//

import GoBoard

public protocol Encoder {
    
    var name: String { get }
    
    var shape: [Int] { get }
    
    func encode(gameState: GameState) -> [[[UInt8]]] 
    
    // Turn a board point into an integer index
    func encode(point: Point) -> Int
    
    // Turn an integer index into a board point
    func decode(index: Int) -> Point
    
}
