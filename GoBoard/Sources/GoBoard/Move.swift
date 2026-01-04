//
//  Move.swift
//  GoBoard
//
//  Created by Jae Seung Lee on 11/23/25.
//

public struct Move: Hashable, Sendable {
    public var player: Player?
    public var point: Point
}
