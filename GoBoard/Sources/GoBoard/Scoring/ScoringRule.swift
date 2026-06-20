//
//  ScoringRule.swift
//  GoBoard
//
//  Created by Jae Seung Lee on 6/14/26.
//

/// Selects which ruleset governs final scoring.
///
/// - `area`: Chinese rules — count empty territory plus all live stones on the board.
/// - `territory`: Japanese rules — count empty territory plus prisoners (captured and dead stones).
public enum ScoringRule {
    case area
    case territory
}
