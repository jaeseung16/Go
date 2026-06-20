//
//  ScoringHelper.swift
//  GoBoard
//
//  Created by Jae Seung Lee on 5/17/26.
//

public class ScoringHelper {

    private static let deltas = [(-1, 0), (1, 0), (0, -1), (0, 1)]

    private let gameState: GameState
    private let rule: ScoringRule
    private let komi: Double
    private let deadStones: Set<Point>

    /// - Parameters:
    ///   - gameState: The finished game state to score.
    ///   - rule: `.area` (Chinese) counts territory + live stones; `.territory` (Japanese) counts territory + prisoners.
    ///   - komi: Points added to white's score for playing second. Defaults to 7.5 (Chinese standard).
    ///   - deadStones: Points whose stones are agreed dead; treated as empty for territory detection
    ///     and counted as prisoners for the opponent under both rule sets.
    public init(gameState: GameState, rule: ScoringRule = .area, komi: Double = 7.5, deadStones: Set<Point> = []) {
        self.gameState = gameState
        self.rule = rule
        self.komi = komi
        self.deadStones = deadStones
    }

    public func compute() -> GameResult {
        switch rule {
        case .area:
            return computeAreaScore()
        case .territory:
            return computeTerritoryScore()
        }
    }

    public func computeTerritory() -> Territory {
        return evaluate(board: gameState.board)
    }

    // MARK: - Scoring strategies

    private func computeAreaScore() -> GameResult {
        let territory = evaluate(board: gameState.board)
        // Area: territory + live stones on the board (dead stones excluded)
        return GameResult(
            black: Double(territory.numBlackTerritory + territory.numBlackStones),
            white: Double(territory.numWhiteTerritory + territory.numWhiteStones),
            komi: komi
        )
    }

    private func computeTerritoryScore() -> GameResult {
        let territory = evaluate(board: gameState.board)

        // Agreed-dead stones count as prisoners for the opponent.
        let deadWhite = deadStones.filter { gameState.board.stone(at: $0) == .white }.count
        let deadBlack = deadStones.filter { gameState.board.stone(at: $0) == .black }.count

        // Japanese: territory only, no stones on the board.
        // Black score = black empty territory + white prisoners (captured during game + agreed dead)
        // White score = white empty territory + black prisoners (captured during game + agreed dead)
        return GameResult(
            black: Double(territory.numBlackTerritory + gameState.whiteCaptured + deadWhite),
            white: Double(territory.numWhiteTerritory + gameState.blackCaptured + deadBlack),
            komi: komi
        )
    }

    // MARK: - Territory detection (shared by both rules)

    func evaluate(board: GoBoard) -> Territory {
        var status: [Point: String] = [:]
        var visited: Set<Point> = []

        for row in 1...board.dimension {
            for col in 1...board.dimension {
                let point = Point(row: row, col: col)
                if status[point] != nil { continue }

                let color = effectiveStone(at: point, board: board)
                if color != .none {
                    status[point] = color == .black ? "b" : "w"
                } else {
                    let (group, borderColors) = collectRegion(start: point, board: board, visited: &visited)
                    // Filter out .none from borders — board edges contribute no border color
                    let liveColors = borderColors.filter { $0 != .none }
                    let fillWith: String
                    if liveColors.count == 1, let sole = liveColors.first {
                        fillWith = "territory_\(sole == .black ? "b" : "w")"
                    } else {
                        fillWith = "dame"
                    }
                    group.forEach { status[$0] = fillWith }
                }
            }
        }

        return Territory(territoryMap: status)
    }

    /// Returns the stone color at a point, treating dead stones as `.none`.
    private func effectiveStone(at point: Point, board: GoBoard) -> Stone {
        if deadStones.contains(point) { return .none }
        return board.stone(at: point) ?? .none
    }

    /// DFS flood-fill starting at `start`. Expands through points whose effective
    /// color matches the starting point. Returns (region points, border stone colors).
    private func collectRegion(start: Point, board: GoBoard, visited: inout Set<Point>) -> ([Point], Set<Stone>) {
        guard !visited.contains(start) else { return ([], Set()) }
        visited.insert(start)

        var allPoints: [Point] = [start]
        var allBorders: Set<Stone> = []

        let color = effectiveStone(at: start, board: board)

        for neighbor in board.neighbors(of: start) {
            let neighborColor = effectiveStone(at: neighbor, board: board)
            if neighborColor == color {
                let (points, borders) = collectRegion(start: neighbor, board: board, visited: &visited)
                allPoints.append(contentsOf: points)
                allBorders.formUnion(borders)
            } else {
                allBorders.insert(neighborColor)
            }
        }
        return (allPoints, allBorders)
    }
}
