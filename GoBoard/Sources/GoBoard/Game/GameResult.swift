//
//  Scoring.swift
//  GoBoard
//
//  Created by Jae Seung Lee on 5/17/26.
//

public struct GameResult: CustomStringConvertible {
    
    public let black: Double
    public let white: Double
    public let komi: Double
    
    public var winner: Player {
        return black > white + komi ? .black : .white
    }
    
    public var winningMargin: Double {
        return abs(black - (white + komi))
    }
    
    public var description: String {
        return winner == .black ? "B+\(winningMargin)" : "W+\(winningMargin)"
    }
}
