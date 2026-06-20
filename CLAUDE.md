# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A Swift implementation of the Go board game, focusing on correct rule enforcement, immutable game state management, and eventual AI engine integration. Active development is in the `GoBoard/` SPM package; the `Go/` directory is a legacy macOS app with SpriteKit UI.

## Commands

```bash
# Build GoBoard library
cd GoBoard && swift build

# Run all tests
cd GoBoard && swift test

# Run specific test suite
cd GoBoard && swift test --filter GoBoardTests

# Build legacy macOS app
xcodebuild -project Go.xcodeproj -scheme Go build
```

## Architecture

### Package Layout

- **`GoBoard/`** — Active SPM package (Swift 6.2), two source modules:
  - `GoBoard/` — Board representation primitives
  - `Game/` — Game state and move validation
  - Depends on `swift-log`
- **`Go/`** — Legacy Xcode/SpriteKit app; mostly UI stubs, not kept in sync with `GoBoard/`
- **`dlgo/`** — Empty placeholder SPM package

### Board Layer (`GoBoard/Sources/GoBoard/`)

- `Point` — 1-indexed `(row, col)` coordinates (1–19)
- `Stone` — `.black | .white | .none`; `Player` — `.black | .white`
- `Move` — `.play(Player?, Point) | .pass | .resign`
- `GoString` — **Immutable** connected group of same-colored stones + their liberty set. Merging/removing liberties returns new instances.
- `GoBoard` (protocol) — Abstract board interface: `place(stone:at:)`, `stone(at:)`, `goString(at:)`, `isSelfCapture(_:)`, `willCapture(_:)`, `copy()`, `hashableRepresentation()`
- `ZobristGoBoard` — Concrete implementation. Uses a pre-computed 19×19×3 Zobrist table (`Zobrist.swift`) for O(1) board hashing. Maintains `goStringByPoint: [Point: GoString]` for O(1) group lookup. `NeighborTable`/`CornerTable` cache adjacency.

### Game Layer (`GoBoard/Sources/Game/`)

- `GameState` — **Immutable** linked-list game tree. Each node holds the board, current player, last move, and a reference to its parent state. `apply(move:)` returns a new `GameState`.
- Ko rule is enforced by walking the parent chain and comparing `ZobristGameSituation` (hash + player) against the new board state.
- `isOver()` is true when both players pass consecutively. `winner` is not yet implemented (scoring/endgame is missing).

### Key Design Decisions

- **Immutability**: `GoString` and `GameState` are value-typed / functionally updated, enabling safe game tree traversal without copying the whole board each step.
- **Zobrist hashing**: Enables fast equality checks for Ko rule and repeated-position detection without full board comparison.
- **`GoBoard` protocol**: Separates the board interface from the Zobrist implementation, allowing alternative backends.
