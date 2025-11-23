//
//  Move.swift
//  GoBoard
//
//  Created by Jae Seung Lee on 11/23/25.
//

struct Move: Hashable, Sendable {
    var player: Player?
    var point: Point
}
