# The 499,000 buffer ceiling

*GoBoard · SelfPlay · MLX Metal backend · 30 August 2026 (branch `dlgo`)*

Self-play died at game 59 of 1,000 with:

```
[metal::malloc] Resource limit (499000) exceeded.
```

It is **not** an out-of-memory error — it is a cap on the number of *live* Metal
buffers, and the board encoder was spending about **96 of them per position**. Two
one-file changes bring that to one, and 1,000 games now finishes.

Claims below are tagged **[measured]** (ran it, read the number off the output),
**[projected]** (arithmetic on measured inputs), or **[inferred]** (read from
source, not profiled).

---

## 1. The arithmetic that ends the run

MLX's Metal allocator refuses to allocate once the number of live `MTLBuffer`
objects reaches the device's resource limit —
`mlx/backend/metal/allocator.cpp:140`. The check is
`num_resources_ >= resource_limit_`: a *count*, not a byte total. On this machine
the limit is 499,000. Total memory in use is irrelevant to it.

| | Value | |
|---|---|---|
| Ceiling | 499,000 | live buffers, device resource limit |
| Cost per position | ≈ 96 | buffers pinned by one encoded board state |
| Predicted failure | 5,198 | positions, if the cost is exactly 96 |
| Observed failure | **5,176** | positions — game 59 of the 1,000-game run |

Dividing the ceiling by the observed crash point recovers the per-position cost:
499,000 ÷ 5,176 ≈ 96. Games 60 through 1,000 never got a chance to run. **[measured]**

## 2. Where 96 buffers per position came from

`SimpleEncoder.encode` built its `[9, 9, 11]` tensor by assigning into it one point
at a time. Each `boardTensor[…] = MLXArray(1.0)` queues a *lazy* scatter operation,
and the operands of that operation — the index array and the `1.0` constant — are
allocated eagerly, right then.

Nothing ever evaluated the tensor before it was stored. MLX is lazy, so an
unevaluated array keeps its entire computation graph alive, and that graph is
roughly ninety small buffers wide for a 9×9 board. `ExperienceCollector` then held
every one of those graphs for the whole run — 1,000 games × ~89 moves ≈ 89,000
positions — because nothing is stacked until `ExperienceBuffer.from` runs at the
very end.

> The encoder wasn't leaking. It was deferring: ninety pending operations per
> board, multiplied by every board ever seen, all waiting for an `eval` that only
> came after the last game.

## 3. A second bug, silent, in the same three lines

The encoder's index expression does not do what it reads like. A single `MLXArray`
subscript is a *gather along axis 0*, not element indexing — so this assigned three
entire 9×11 slices instead of one element:

```swift
// what the code did — a[MLXArray([...])] gathers rows of axis 0
boardTensor[MLXArray([row, col, libertyPlane])] = MLXArray(1.0)
```

Probe on a `[3,3,4]` array, run against the built binary:

```
a[MLXArray([1, 2, 3])] = 1.0   → gatherShape=[3, 3, 4]  sum=24.0   // 2 whole slices set
b[1, 2, 3]             = 1.0   → sum=1.0                           // one element, as intended
```

The consequence is that every experience file written before this fix holds
meaningless state planes — including `experience.safetensors` and anything trained
from it. **[measured]**

## 4. What changed

### `Sources/GoAgent/Encoder/SimpleEncoder.swift`

Fill a plain Swift `[Float]` and hand MLX a single allocation. One buffer per
position instead of ninety-six, faster, and the flat index
`(row · cols + col) · planes + plane` is the element the code always meant to set.

```diff
- let boardTensor = MLXArray.zeros(self.shape)
- boardTensor[MLXArray([row, col, libertyPlane])] = MLXArray(1.0)
+ var boardTensor = [Float](repeating: 0, count: rows * cols * planes)
+ boardTensor[base + libertyPlane] = 1
+ return MLXArray(boardTensor, self.shape)
```

### `Sources/GoAgent/ExperienceCollector/ExperienceCollector.swift`

Materialize on the way in, so nothing lazy is retained across the run — belt and
braces against any future caller that hands the collector an unevaluated array.

```diff
+ eval(state, action, estimatedValue)   // in recordDecision
+ eval(advantage)                       // in completeEpisode
```

## 5. Verified on the same binary

Board size 9, default agent and network. **[measured]**

| Run | Before | After | Wall clock | Peak RSS |
|---|---|---|---|---|
| 200 games | crash at game 59 | 17,888 positions | 113 s | 339 MB |
| 1,000 games | crash at game 59 | 89,401 positions | 581 s | 2.32 GB |

Note the direction of the peak-RSS column: before the fix, 200 games peaked at
**1.32 GB** on its way to dying at 5,176 positions. After the fix the same run
holds three times as many positions in a quarter of the memory.

## 6. 19×19 hits the same wall again

The fix buys a factor of 32 on buffer count, not an unlimited budget. Three buffers
still survive per decision — state, action, advantage — and a 19×19 game contains
far more decisions. Measured across sixteen 19×19 games: **~390 decisions per
game**, against 89 at 9×9.

Live buffers held at the end of a 1,000-game run, against the 499,000 ceiling:

| Configuration | Live buffers | % of ceiling | |
|---|---|---|---|
| 9×9, after the fix | 268,203 | 54% | **pass** — this is the run that completed |
| 19×19, after the fix | 1,170,000 | 234% | **fail** — exhausted at roughly game 427 |
| 19×19, stacking once per episode | ≈ 3,000 | 0.6% | **pass** — three buffers per game, not per move |

The 9×9 row is measured. The two 19×19 rows are arithmetic on measured inputs:
390 decisions/game × 1,000 games × 3 buffers. **[projected]**

### And a second, independent wall: memory

A 19×19 state tensor is 19 · 19 · 11 float32 = **15,884 bytes**, and 1,000 games
produce ~390,000 of them — **6.2 GB** of state data, held until the run ends.
Actual resident cost is worse than that, because each small buffer occupies at
least a 16 KB page. Two 19×19 runs give the real slope: 4 games / 1,601 decisions
peaked at 155 MB, 12 games / 4,667 decisions at 286 MB — **≈ 43 KB of resident
memory per decision**, or about **17 GB** at 1,000 games.

Then `ExperienceBuffer.from` calls `MLX.stacked` over the whole collection, which
needs a *further* contiguous 6.2 GB allocation. That one is checked against
`maxBufferLength` — a different limit, with a different error message.
**[measured] [projected]**

## 7. Getting to 19×19

Ranked by leverage. The first is required; the first two together are probably
enough; the fourth is what you'd do if self-play becomes the centre of the project.
Together they take a 1,000-game 19×19 run from "crashes at game 427, 17 GB
resident" to comfortably bounded.

1. **Stack once per episode, not once per run.**
   In `completeEpisode`, `MLX.stacked` the episode's states, actions and advantages
   into one array each and store those. Buffer cost goes from three per *decision*
   to three per *game*, and stops scaling with board size at all. It also removes
   the per-buffer page overhead, since one game becomes one contiguous allocation.
   `ExperienceBuffer.from` switches from `stacked` to `concatenated`, and
   `SelfPlay`'s `states.count` progress line becomes a count of episodes, so it
   needs adjusting.
   *→ 1,170,000 → ~3,000 buffers*

2. **Store the planes as `UInt8`.**
   Every plane is strictly 0 or 1, so float32 is paying 4 bytes for 1 bit. Build the
   buffer as `[UInt8]` in the encoder and cast to float in the training batch loop;
   safetensors stores `uint8` natively.
   *→ 6.2 GB → 1.6 GB*

3. **Flush to sharded files during the run.**
   Write `experience-0000.safetensors` every ~50 games and clear the collector. Peak
   memory becomes one shard rather than the whole run, and it sidesteps the single
   giant `stacked` allocation at the end entirely. The trainer iterates shards
   instead of loading one buffer.
   *→ peak memory becomes constant in the number of games*

4. **Store moves, not tensors.**
   A game is a sequence of ~400 move indices. Persist `[UInt16]` plus the reward, and
   re-encode boards during training. This is what production Go engines do, and it
   makes the encoder a train-time detail you can change without regenerating your
   corpus. The cost is CPU work in the training loop, which overlaps with GPU batches.
   *→ 6.2 GB → ~800 KB*

One free saving alongside these: planes 8 and 9 encode whose turn it is as a
*constant full plane* — 2 of the 11 planes carry a single bit, derivable from move
parity.

## 8. The wall clock is the other 19×19 problem

Memory aside, 19×19 self-play is currently too slow to run at this scale. **[measured]**

| Board | Decisions / game | Per move | Per game | 1,000 games |
|---|---|---|---|---|
| 9×9 | 89 | 6.5 ms | 0.58 s | 9.7 min |
| 19×19 | 390 | 66.7 ms | 25.9 s | **7.2 h** |

The board is 4.5× larger but each move costs **10×** more, so something is scaling
worse than area. Reading the code, the likely cause is
`Sources/GoBoard/Game/GameState.swift:30`:

```swift
self.previousStates = previousState.previousStates.union([previousState.situation])
```

Every `GameState` construction copies the entire ko-history set — O(moves) per move,
so O(moves²) per game. And every *speculative* `apply(move:)` inside `isValid` and
`isViolatingKoRule` pays that copy too, on top of a full board copy and an O(N²)
`countStones`. At 400-move games those quadratics dominate. Sharing the set instead
of copying it, or keeping a hash chain, is the thing to try. **[inferred]** — read
from source and the timing ratio, not profiled, so treat the specific attribution as
a strong hypothesis rather than a measurement.

## 9. Also noticed

- `MLXRandom.categorical(moveProbs, count: numMoves)` samples *with replacement*, so
  `rankedMoves` was not a ranked list of distinct moves. Fixed separately — see
  [policy-agent-temperature.md](policy-agent-temperature.md) and
  [policy-network-double-softmax.md](policy-network-double-softmax.md).
- Regenerate `experience.safetensors` and retrain — both predate the encoder fix.
