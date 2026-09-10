# Color bias in self-play rewards

*GoBoard · SelfPlay · TrainGoBots · 10 September 2026 (branch `dlgo`)*

In 9×9 self-play with the untrained `Small` network, white wins about **78%** of games.
Nothing about white's moves is better. The 7.5 komi that white receives was set to balance
black's first-move advantage between strong players, and between near-random players that
advantage is only about two points, so komi over-compensates by about five.

The result is that the ±1 reward on every recorded decision mostly says *which color moved*,
not whether the move was good. That makes policy-gradient training noisier and makes
evaluation misleading unless colors are balanced.

Claims are tagged **[measured]** (ran it, read the number off the output), **[projected]**
(arithmetic on measured inputs), or **[inferred]** (read from source or general Go knowledge,
not measured here).

---

## 1. Where it comes from

`GameState.winner` calls `ScoringHelper(gameState:).compute()` with its defaults: area
scoring (`.area`, territory plus stones on the board) and `komi: 7.5`. `GameResult.winner`
gives the game to black only if `black > white + komi`. No dead stones are removed, which
matters little here because random games fill most of the board. **[inferred]** from source.

Seven and a half points is the standard compensation for moving first, calibrated on strong
play. Black's actual advantage depends on how well both sides play. **[inferred]**

From a 50-game 9×9 run of `SelfPlay` with freshly initialized weights, black's lead on the
board before komi, recovered from the printed scores: **[measured]**

| | Black − white, before komi |
|---|---|
| Mean | +2.3 (standard error ±1.3) |
| Median | +1.5 |
| Standard deviation | 9.1 |
| Range | −12 to +29 |

What black's win rate would have been over the same 50 games under different komi:
**[measured]**

| Komi | Black wins |
|---|---|
| 0 | 54% |
| 2.5 | 48% |
| 4.5 | 44% |
| 5.5 | 34% |
| 6.5 | 24% |
| **7.5 (current)** | **22%** |

The 100-game 9×9 corpus in `GoBoard/experience.safetensors` (9,102 decisions) agrees: white
won 155 of the 199 player-game segments that can be recovered from it, 78%. **[measured]**

## 2. What the reward tells the network

Every decision a player made is stored with that game's final reward, +1 or −1. Grouping the
100-game corpus's decisions by whose turn it was: **[measured]**

| Color to play | Decisions | Reward +1 | Reward −1 | Mean reward |
|---|---|---|---|---|
| White | 4,531 | 3,536 | 995 | **+0.56** |
| Black | 4,571 | 1,037 | 3,534 | **−0.55** |

The network can see the color: `SimpleEncoder` sets plane 8 on every point when black is to
play and plane 9 when white is.

Policy-gradient training (REINFORCE) nudges each played move's log-probability by its reward:
`−reward · log p(move)` is the per-decision loss `PolicyAgentModel` now uses. Because white's
moves are rewarded about three times out of four and black's punished about three times out
of four, most updates amount to "raise whatever white played, lower whatever black played",
regardless of the move. **[inferred]**

That does not *bias* learning. The moves were sampled from the policy itself, so on average
those color-driven nudges cancel. But each one still adds noise to the gradient, and with few
games the network can fit them. In a diagnostic that trained on games 0–79 and tested on
80–99, the gain on the training games was about ten times the gain on the held-out games,
and the held-out gain was never more than about one standard error from zero. **[measured]**

## 3. How much a baseline buys

The standard remedy is to subtract a baseline that does not depend on the move: weight each
decision by `reward − b` instead of `reward`, where `b` is the average reward for that color.
This leaves the expected gradient unchanged and removes the part of the reward that color
explains. **[inferred]**

The typical squared weight falls from `E[reward²] = 1` to `1 − b²`: **[projected]**

| Color | `b` | `1 − b²` |
|---|---|---|
| White | +0.561 | 0.686 |
| Black | −0.546 | 0.702 |
| Overall | | **0.694** |

About 30% less noise per decision. If the weight is roughly independent of the gradient's
size, that is worth about as much as 1.44× as many games. **[projected]**

It is a real gain but not the main problem. The larger source of noise is that one ±1 outcome
is shared by about 45 near-random moves per player, and 100 games is far too few to separate
good moves from lucky ones. In the same diagnostic, training with and without the per-color
baseline gave held-out results that could not be told apart at this sample size — for
example 1.06e-4 ± 1.3e-4 with the baseline and 1.00e-4 without, at learning rate 0.1 and
batch size 512. **[measured]**

The baseline also needs enough data to estimate. On games 0–79 alone the color means were
−0.45 and +0.48 rather than ±0.55, and games 80–99 were more lopsided still. With 100 games,
a win rate carries a standard error of about ±4 percentage points. **[measured] [projected]**

## 4. Two other places it bites

**Evaluation.** Two copies of the *same* bot produce a white win about 78% of the time. A
trained bot that happens to play white more often, or a single win rate pooled across colors
when the split is uneven, will show improvement that is only color. Play equal numbers of
games with each color and report both win rates. At 400 games the standard error of a win rate
is 2.5 percentage points, so a 55% result is only two standard errors; per color, with 200
games each, it is 3.5 points. **[projected]**

**Drift.** Black's first-move advantage grows as play gets stronger, so the win split will move
as training rounds improve the bot. Any fixed correction — a hand-picked baseline, or a
self-play komi tuned to today's random play — will go stale. **[inferred]**

## 5. Options

1. **Per-color baseline at training time — recommended now.** Compute `b` for each color from
   the corpus being trained on, and weight each target by `reward − b` in `BatchSequence`.
   A small change, unbiased, and it follows the drift automatically because it is re-estimated
   for every corpus.
2. **A value network as the baseline — later.** This is dlgo's actor-critic approach. The data
   path is already in place: `ExperienceCollector.recordDecision` takes an `estimatedValue`,
   and the collector stores `advantages = reward − estimatedValue`. Today `PolicyAgent` passes
   `0.0`, so `advantages` equals `rewards`, and training ignores `advantages` entirely. A
   value head would account for the position as well as the color, at the cost of a second
   output, a second loss and a model change.
3. **Lower komi for self-play** (about 2 points for random 9×9 play). This balances the rewards
   directly, but changes the game the bot learns, would need re-tuning as play improves, and
   would make results incomparable with standard scoring. Not recommended.

Whichever is chosen, evaluation should alternate colors regardless.

## 6. Limits

- Board margins come from only 50 games, and all the measurements here use freshly initialized
  weights, whose policy is essentially uniform (entropy equal to ln 81 to four digits). Stronger
  policies will split differently.
- Nothing here was measured on 19×19.
- The held-out comparisons came from a temporary diagnostic test that trained five epochs with
  SGD on one 100-game corpus. It was not committed.
- The estimate that a baseline is worth about 1.44× the games assumes the weight is independent
  of the gradient's magnitude, which was not checked.
