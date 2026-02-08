//
//  GameSituation.swift
//  GoBoard
//
//  Created by Jae Seung Lee on 2/8/26.
//

protocol GameSituation {
    func situation() -> (Player, Hashable)
}
