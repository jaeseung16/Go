# Scoring Algorithm Comparison: This Repo vs. lightvector/goscorer

**Reference:** https://github.com/lightvector/goscorer  
**Date:** 2026-06-20

---

## 1. Summary of goscorer's Algorithm

goscorer targets **Japanese-rule territory scoring with fully automated seki detection**, requiring no player intervention beyond marking dead stones. It runs ten sequential phases:

| Phase | Name | Purpose |
|---|---|---|
| 1 | Connection blocks | Mark empty points that block territory from "leaking" through diagonal cuts |
| 2 | Reachability | Two flood-fills per color: strict (no blocks) and block-aware |
| 3 | Regions | Maximal areas reachable by exactly one color (block-aware); mixed → dame |
| 4 | Chains | Connected-component stone groups within regions |
| 5 | Macrochains | Union same-color chains connected through dame, for life analysis |
| 6 | Potential eyes | Connected empty clusters inside a region, with macrochain adjacency |
| 7 | False eye detection | Graph search: can surrounding macrochains reach all sides of the point? |
| 8 | Eye values | Heuristic: assign each eye a value of 0, 1, or 2 live eyes |
| 9 | Seki detection | Regions with total eye value ≤ 1 are seki; excluded from territory |
| 10 | Final scoring | Territory = points not in seki, not false eyes, not strictly reachable by opponent |

The key innovation is **connection blocks**: without them, territory floods through diagonal cuts
(e.g., a white group in the corner with a one-point gap) and assigns incorrect ownership.
Seki is derived rather than pattern-matched: insufficient eye count (≤ 1) means the group
cannot independently live, so its surrounding space is not scored as territory.

---

## 2. What This Repo Currently Does

```
ScoringHelper.evaluate(board:)
  └── For each point:
        • occupied → mark "b" / "w"
        • empty → DFS flood-fill empty region, collect border stone colors
            - border is one color → "territory_b" / "territory_w"
            - border is mixed    → "dame"

ScoringHelper.compute()
  ├── .area      → territory + live stones on board + komi
  └── .territory → territory + captures (whiteCaptured/blackCaptured) + dead stones + komi

GameState.apply(move:) accumulates capture counts.
ScoringHelper accepts deadStones: Set<Point>; dead stones treated as .none in flood-fill.
```

---

## 3. Gap Analysis

### 3.1 Critical Correctness Gaps

| Gap | Our Behaviour | goscorer Behaviour | Impact |
|---|---|---|---|
| **Seki detection** | None — seki regions scored as territory | Derived from eye count ≤ 1 → excluded from territory | Incorrect score in any game with seki |
| **False eye detection** | False eyes count as territory | Graph-search confirms reachability from all sides | Incorrect score when false eyes exist |
| **Connection blocks** | Territory floods freely through diagonals | Block points prevent leakage at diagonal cuts | Territory incorrectly assigned in positions with diagonal cuts |

**Seki** is the most impactful omission. Seki is not a rare edge case — it arises regularly in
corner and side fights. Under Japanese rules, the empty points inside seki are dame, not territory
for either player. Our code currently awards them as territory to whichever color surrounds them.

**False eyes** are almost as common. A false eye inside a live group is not territory but our
flood-fill treats it as such.

**Connection blocks** matter less for simple positions but cause systematic errors in any position
where territory is only enclosed diagonally (common at the edge and in corners).

### 3.2 Minor / Scope Gaps

| Gap | Our Behaviour | goscorer Behaviour | Priority |
|---|---|---|---|
| Reachability model | Single flood-fill per empty region | Two flood-fills (strict + block-aware) | Low until connection blocks added |
| Macrochains | Not modeled | Same-color groups connected through dame treated as one unit | Required for accurate seki detection |
| Per-point metadata | Not exposed | `LocScore` per point with territory/seki/false-eye flags | Useful for UI; not blocking |
| Equivalence (Ing) scoring | Not implemented | Not in goscorer either | Out of scope |
| Area scoring | Implemented | Not the focus of goscorer | ✅ Our advantage |
| Capture tracking | Implemented | Not in goscorer (territory only) | ✅ Our advantage |
| Configurable komi | Implemented | Not configurable in goscorer's public API | ✅ Our advantage |

### 3.3 What We Have That goscorer Doesn't

- **Area (Chinese) scoring**: goscorer targets Japanese territory scoring only. Our `.area` rule is not in scope for goscorer.
- **Capture / prisoner tracking**: `GameState.blackCaptured`/`whiteCaptured` feed into Japanese prisoner counts. goscorer assumes these are supplied externally.
- **Full game tree integration**: `GameState` immutable linked list, Ko rule, `winner` wiring. goscorer is a standalone scoring function.

---

## 4. Recommended Changes

### Priority 1 — Seki Detection (Necessary for Correct Territory Scoring)

Seki detection is the highest-value improvement. The goscorer approach (derive seki from eye count)
is complex to port directly because it requires macrochains and eye value computation. A pragmatic
first step follows the **tenuki approach** instead: after flood-filling territory regions, merge
connected same-color territory regions sharing boundary stones; if the merged region has fewer
than 2 eyes, mark it seki.

**Eye counting heuristic (from tenuki):**
- An "eye" within a territory region = a connected sub-region of empty points fully enclosed
  by the owning color.
- Eye count ≥ 2 → group is alive → territory is valid.
- Eye count < 2 → group is in seki → territory is invalidated.

This is a simpler approximation than goscorer's eye-value system and does not handle all exotic
positions, but it is correct for the vast majority of real game endings.

**New types needed:**
```swift
// Represents a connected region of same-colored territory with its enclosing stones
struct TerritoryRegion {
    let color: Stone
    var points: Set<Point>
    var boundaryStones: Set<Point>
    var eyes: [Set<Point>]  // sub-clusters of empty points fully inside the region
}
```

**Algorithm change in `ScoringHelper.evaluate`:**
1. After flood-fill, collect `TerritoryRegion` objects.
2. Merge connected regions of the same color (those sharing boundary stones).
3. For each merged region, count enclosed empty sub-regions (eyes).
4. If eye count < 2, relabel all points in the region as `"dame"` instead of territory.

### Priority 2 — False Eye Detection (Necessary for Correct Territory Scoring)

A false eye point `p` satisfies (tenuki heuristic, simpler than goscorer's graph search):
- `p` is empty.
- `p` has at least 1 occupied neighbor (at least 2 if interior — not on row/col 1 or N).
- Among `p`'s diagonal neighbors, at least 1 (on the first line) or at least 2 (interior)
  are occupied by the **opposing** color.

**Algorithm change:**
After computing the territory map, for each `"territory_b"` or `"territory_w"` point `p`,
check the false-eye condition. If it is a false eye, reclassify as `"dame"`.

```swift
private func isFalseEye(_ point: Point, owningColor: Stone, board: GoBoard) -> Bool {
    let isEdge = point.row == 1 || point.row == board.dimension
                  || point.col == 1 || point.col == board.dimension
    let occupiedNeighbors = board.neighbors(of: point).filter {
        effectiveStone(at: $0, board: board) != .none
    }.count
    guard occupiedNeighbors >= (isEdge ? 1 : 2) else { return false }
    let opponent: Stone = owningColor == .black ? .white : .black
    let hostileDiagonals = board.corners(of: point).filter {
        effectiveStone(at: $0, board: board) == opponent
    }.count
    return hostileDiagonals >= (isEdge ? 1 : 2)
}
```

### Priority 3 — Connection Blocks (Improves Accuracy for Non-Trivial Positions)

This requires matching a set of geometric patterns against the board, then restricting the
flood-fill to not cross block points. This is the most complex change and is not strictly
necessary for simple or fully-played-out positions (where all cuts are already filled).
Defer until the AI engine produces positions that expose this bug.

---

## 5. Recommended Implementation Order

```
Step A: False eye detection
  → Small, self-contained change in ScoringHelper.evaluate
  → Fixes systematic over-counting of territory

Step B: Seki detection
  → Requires TerritoryRegion type and eye-merge pass
  → Fixes incorrect territory in seki positions
  → More test cases needed (2-eye groups, seki, bent-four corner)

Step C: Connection blocks (defer)
  → Complex pattern-matching; defer until real game positions expose the bug
  → Re-evaluate after AI engine generates games
```

---

## 6. Test Cases to Add

| Test | Covers |
|---|---|
| Seki: two groups sharing two dame points | Seki → dame, not territory |
| False eye inside a live group | False eye → dame, not territory |
| Bent-four-in-corner (Japanese rules: dead) | Requires dead stone input from players |
| Single-eye group surrounded | Group in atari is dead → mark dead + score |
| Territory with diagonal cut | Connection blocks (Phase 3, defer) |

---

## 7. Conclusion

Our current implementation is **correct for fully played-out positions with no seki and no false
eyes**. For the early AI training goal (area scoring, simple positions), it is sufficient.
For production-quality scoring under Japanese rules, **false eye detection (Step A) and seki
detection (Step B) are necessary**. Connection blocks (Step C) can be deferred until positions
generated by the AI engine reveal the need.

goscorer's approach is the most rigorous available for automated scoring, but its full 10-phase
algorithm is significantly more complex than needed for this project's current stage. The
pragmatic path is to port the simpler tenuki-style false-eye and seki checks first, then
re-evaluate whether the full goscorer approach is warranted once the AI engine is operational
and generating real game positions.
