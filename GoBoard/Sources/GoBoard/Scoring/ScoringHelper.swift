//
//  ScoringHelper.swift
//  GoBoard
//
//  Created by Jae Seung Lee on 5/17/26.
//

public class ScoringHelper {

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

        // Post-process 1: reclassify false eyes as dame.
        var falseEyePoints: Set<Point> = []
        for (point, label) in status {
            let owningColor: Stone
            if label == "territory_b" { owningColor = .black }
            else if label == "territory_w" { owningColor = .white }
            else { continue }
            if isFalseEye(point, owningColor: owningColor, board: board) {
                falseEyePoints.insert(point)
            }
        }
        for point in falseEyePoints { status[point] = "dame" }

        // Post-process 2: seki detection — stone groups with fewer than 2 eyes
        // have their territory relabeled as dame.
        detectSeki(in: &status, board: board)

        return Territory(territoryMap: status)
    }

    /// Returns the stone color at a point, treating dead stones as `.none`.
    private func effectiveStone(at point: Point, board: GoBoard) -> Stone {
        if deadStones.contains(point) { return .none }
        return board.stone(at: point) ?? .none
    }

    /// Returns true if `point` is a false eye for `owningColor`.
    ///
    /// A false eye looks enclosed but the surrounding group doesn't fully control
    /// its diagonal corners, meaning the opponent can eventually capture into it.
    /// Heuristic (tenuki-style):
    ///   - The point must have enough occupied neighbors to look like an eye.
    ///   - The opponent occupies at least 1 diagonal (edge/corner positions) or
    ///     at least 2 diagonals (interior positions).
    private func isFalseEye(_ point: Point, owningColor: Stone, board: GoBoard) -> Bool {
        let onEdge = point.row == 1 || point.row == board.dimension
                  || point.col == 1 || point.col == board.dimension
        let threshold = onEdge ? 1 : 2

        let occupiedNeighbors = board.neighbors(of: point).filter {
            effectiveStone(at: $0, board: board) != .none
        }.count
        guard occupiedNeighbors >= threshold else { return false }

        let opponent: Stone = owningColor == .black ? .white : .black
        let hostileDiagonals = board.corners(of: point).filter {
            effectiveStone(at: $0, board: board) == opponent
        }.count
        return hostileDiagonals >= threshold
    }

    /// Identifies stone groups with fewer than 2 eyes and relabels their territory as dame.
    ///
    /// A stone group's "eyes" are its distinct connected territory regions (after false eye
    /// detection). Groups with ≥ 2 eyes are alive; groups with < 2 eyes are either dead
    /// or in seki, and their enclosed space is not scored as territory.
    private func detectSeki(in status: inout [Point: String], board: GoBoard) {
        var processedGroups: Set<Point> = []
        var sekiPoints: Set<Point> = []

        for (point, label) in status {
            let territoryColor: Stone
            let territoryLabel: String
            if label == "territory_b" {
                territoryColor = .black; territoryLabel = "territory_b"
            } else if label == "territory_w" {
                territoryColor = .white; territoryLabel = "territory_w"
            } else { continue }

            // BFS to find the stone group enclosing this territory point.
            var stoneGroup: Set<Point> = []
            var queue: [Point] = board.neighbors(of: point).filter {
                effectiveStone(at: $0, board: board) == territoryColor
            }
            while !queue.isEmpty {
                let s = queue.removeLast()
                guard !stoneGroup.contains(s),
                      effectiveStone(at: s, board: board) == territoryColor else { continue }
                stoneGroup.insert(s)
                queue.append(contentsOf: board.neighbors(of: s))
            }
            guard !stoneGroup.isEmpty else { continue }

            // Use the lexicographically smallest stone as a canonical group ID so
            // we process each stone group exactly once.
            let rep = stoneGroup.min { $0.row != $1.row ? $0.row < $1.row : $0.col < $1.col }!
            guard !processedGroups.contains(rep) else { continue }
            processedGroups.insert(rep)

            // Collect all territory points of this color adjacent to the stone group.
            var eyePoints: Set<Point> = []
            for s in stoneGroup {
                for n in board.neighbors(of: s) where status[n] == territoryLabel {
                    eyePoints.insert(n)
                }
            }

            // Count distinct connected territory regions (eyes).
            var eyeCount = 0
            var eyeSeen: Set<Point> = []
            var groupEyePoints: Set<Point> = []
            for ep in eyePoints where !eyeSeen.contains(ep) {
                eyeCount += 1
                var bfs: [Point] = [ep]
                while !bfs.isEmpty {
                    let p = bfs.removeLast()
                    guard !eyeSeen.contains(p), status[p] == territoryLabel else { continue }
                    eyeSeen.insert(p)
                    groupEyePoints.insert(p)
                    bfs.append(contentsOf: board.neighbors(of: p))
                }
            }

            if eyeCount < 2 { sekiPoints.formUnion(groupEyePoints) }
        }

        for p in sekiPoints { status[p] = "dame" }
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
