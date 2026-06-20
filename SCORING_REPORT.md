# Go Scoring Logic: Analysis & Enhancement Plan

## 1. Current State (this repo)

### What exists

| File | Purpose |
|---|---|
| `GoBoard/Sources/GoBoard/Scoring/ScoringHelper.swift` | Core engine — flood-fill territory detection |
| `GoBoard/Sources/GoBoard/Scoring/Territory.swift` | Data container for raw board status |
| `GoBoard/Sources/GoBoard/Game/GameResult.swift` | Winner + margin calculation |

**Algorithm (ScoringHelper):**
- Iterate every point on the board.
- If occupied: mark `"b"` or `"w"`.
- If empty: recursive DFS flood-fill collects the connected empty region and the set of stone colors touching its border.
  - Border is one color → `"territory_b"` or `"territory_w"`.
  - Border is mixed → `"dame"`.

**Score formula (hard-coded Chinese rules):**
```
black_score = numBlackTerritory + numBlackStones
white_score = numWhiteTerritory + numWhiteStones + komi (7.5, hard-coded)
```

### What is missing

1. **Japanese (territory-only) scoring** — not implemented at all.
2. **Dead stone marking** — no mechanism to designate stones as dead before scoring.
3. **Seki detection** — for territory scoring, regions inside seki must not be counted as territory.
4. **False-eye detection** — territory scoring requires false eyes to be filled before region detection.
5. **Configurable komi** — hard-coded at 7.5 in `ScoringHelper.compute()`.
6. **`GameState.winner` wiring** — the property returns `nil` after double-pass (marked `// TODO: scoring.py`).
7. **Capture tracking** — `Territory.swift` has no field for captured stones; Japanese scoring needs prisoner counts.

---

## 2. Reference Implementation (tenuki, JavaScript)

### Architecture

```
Scorer(scoreBy, komi)
  ├── TerritoryScoring  (Japanese rules)
  └── AreaScoring       (Chinese / Ing rules)
```

`Scorer` is a strategy object. `scoreBy` is `"territory"`, `"area"`, or `"equivalence"` (Ing).

### Region detection (`region.js`)

Tenuki's `Region.allFor(boardState)` is a flood-fill identical in spirit to `ScoringHelper.collectRegion`, but operates on colored intersections (stones included, not just empty points).

A region `isTerritory()` if:
- All its points are empty, AND
- All boundary stones are the same color.

`territoryColor()` returns that one color.

### Area scoring (`AreaScoring` in scorer.js)

```javascript
// Territory detection:
// 1. Remove dead stones from the board state.
// 2. Find all regions that are territory (empty, single-color border).

score = {
  black: blackTerritory.length + liveBlackStones.length,
  white: whiteTerritory.length + liveWhiteStones.length + komi
}
```

Identical conceptually to the current Swift implementation, except dead stone removal is a separate pre-processing step.

### Territory scoring (`TerritoryScoring` in scorer.js)

Much more elaborate — four pre-processing phases before region detection:

```
1. boardStateWithoutDeadPoints   — remove dead stones (treat them as empty)
2. boardStateWithoutNeutralPoints — fill neutral (dame) regions with
                                    alternating black/white (checkerboard)
                                    so they don't contaminate territory regions
3. boardStateWithClearFalseEyesFilled — detect and fill false eyes that are
                                        adjacent to groups in atari
4. Region.allFor(...)            — flood-fill to find territory regions
5. Seki filter                   — merge connected territory regions; exclude
                                   any merged set that has < 2 eyes (seki)
```

**Score formula:**
```
black_score = blackTerritory.length + whiteStonesCaptured + whiteDeadStones.length
white_score = whiteTerritory.length + blackStonesCaptured + blackDeadStones.length + komi
```
Stones on the board are NOT counted; only empty territory + prisoners.

### Seki detection

After collecting all territory regions:
- For each territory region `r`, compute `Region.merge(allTerritoryRegions, r)` — finds all connected same-color territory regions reachable through shared boundary stones.
- Count total eyes in the merged set using `numberOfEyes()`.
- If merged eye count < 2, the region is in seki → exclude it from territory.

`numberOfEyes()` uses a heuristic based on `lengthOfTerritoryBoundary()` (boundary stones + edge points + corner points), with special-case detection for square-four and curved-four shapes.

### False-eye detection (`eye-point.js`)

A point is a false eye if:
- It is empty.
- It has ≥1 occupied neighbor (≥2 if not on the first line).
- Among its diagonal neighbors, ≥1 (first line) or ≥2 (interior) are occupied by the opposing color.

The scoring pre-process fills false eyes adjacent to groups in atari with the neighbor's color, then repeats until convergence.

### Equivalence (Ing) scoring

Same as area scoring, plus pass stones:
- Each pass adds one "pass stone" for the passer.
- White gets an extra pass stone if the game didn't end on white's pass.

---

## 3. Gap Analysis

| Feature | Current (Swift) | Tenuki reference |
|---|---|---|
| Flood-fill territory detection | ✅ Recursive DFS | ✅ Iterative DFS |
| Area / Chinese scoring | ✅ Hard-coded | ✅ Selectable |
| Territory / Japanese scoring | ❌ Missing | ✅ Implemented |
| Dead stone marking | ❌ Missing | ✅ `toggleDeadAt` / `_deadPoints` |
| Dame/neutral point handling | ❌ Counted as dame, not pre-processed | ✅ Checkerboard fill before region detection |
| False-eye detection | ❌ Missing | ✅ `EyePoint.isFalse()` |
| Seki detection | ❌ Missing | ✅ Eye-count merge filter |
| Configurable komi | ❌ Hard-coded 7.5 | ✅ Constructor param |
| Capture count | ❌ Not tracked in Territory | ✅ Tracked in BoardState |
| `GameState.winner` wiring | ❌ Returns nil | ✅ Wired through Scorer |
| Equivalence (Ing) scoring | ❌ Missing | ✅ Pass-stone variant |

---

## 4. Enhancement Plan

### Phase 1 — Foundation

**A. `ScoringRule` enum**
```swift
public enum ScoringRule {
    case area    // Chinese: territory + stones on board
    case territory  // Japanese: territory + captures (no stones)
}
```

**B. Configurable komi in `GameResult`**
- `GameResult` already takes `komi` as a parameter — it just needs to flow from the caller.
- `ScoringHelper.init` should accept `komi: Double` and `rule: ScoringRule`.

**C. Capture tracking**
- `GameState` must accumulate `blackCaptured` and `whiteCaptured` counts as moves are applied.
- These flow into Japanese scoring as prisoner counts.

### Phase 2 — Territory (Japanese) scoring

**D. Dead stone input**
- `ScoringHelper` accepts `deadStones: Set<Point>`.
- Scoring pre-processes: treat dead stone points as empty.

**E. `TerritoryScorer` (new type)**
```swift
struct TerritoryScorer {
    // 1. Strip dead stones from board view
    // 2. Flood-fill empty regions, label territory
    // 3. Score = territory + captures + dead opponents
    func score(board: GoBoard, blackCaptured: Int, whiteCaptured: Int,
               deadStones: Set<Point>, komi: Double) -> GameResult
}
```

Seki detection (Phase 3) is omitted in the first iteration — it requires significant graph logic and covers an edge case. A simpler first cut uses the same flood-fill but without the seki and false-eye filters.

### Phase 3 — Seki & false-eye detection (advanced)

**F. `Region` type**
- Model regions as value types with `boundaryStones`, `isEmpty`, `isTerritory`, `territoryColor`.
- Enable `Region.merge` for connected-region analysis.

**G. `EyePoint`**
- Implement the diagonal-check heuristic for false-eye detection.

**H. `numberOfEyes()` heuristic**
- Port the boundary-length + shape-detection heuristic from tenuki.

### Phase 4 — Integration

**I. Wire `GameState.winner`**
```swift
public var winner: Player? {
    guard isOver() else { return nil }
    if lastMove == .resign { return nextPlayer }
    let helper = ScoringHelper(gameState: self, rule: .area, komi: 6.5)
    return helper.compute().winner
}
```

**J. Tests**
- Territory scoring: verify territory-only counts on the existing 5×5 board.
- Configurable komi: verify correct winner with fractional komi.
- Capture counting: verify prisoners add to Japanese score.
- Dead stone input: verify dead stones add to opponent's prisoner count.

---

## 5. Files to Create / Modify

| Action | File |
|---|---|
| Add | `GoBoard/Sources/GoBoard/Scoring/ScoringRule.swift` |
| Modify | `GoBoard/Sources/GoBoard/Scoring/ScoringHelper.swift` |
| Modify | `GoBoard/Sources/GoBoard/Game/GameResult.swift` |
| Modify | `GoBoard/Sources/GoBoard/Game/GameState.swift` |
| Modify | `GoBoard/Tests/ScoringTests/ScoringTests.swift` |
