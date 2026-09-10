# 2026-09-10 — Training segfault: a lazy scatter chain too deep for `vjp`

Branch `dlgo`. Started from a report of two segmentation faults, one after 100 games of
19×19 and one after 1,000 games of 9×9, with the suspicion that storing experiences as
`MLXArray` in `ExperienceCollector` was the cause and that experiences should be kept as
bytes and converted per batch.

The crash is in training, not in the collector. `PolicyAgentModel.prepareTargets` built its
target matrix with one lazy scatter per experience, so the graph was as deep as the corpus,
and MLX's gradient transform walks graphs recursively. Converting per batch is the right fix,
but only because it also moves *target construction* to the host.

Claims are tagged **[measured]** (ran it, read the number off the output), **[projected]**
(arithmetic on measured inputs), or **[inferred]** (read from source, not profiled).

## What was investigated

**1. Which process crashed.** `GoBoard/experience.safetensors` was written at 10:42 and is
complete: `states` U8 `[39386, 19, 19, 11]`, `actions` F16, `rewards` F32 split 19,721 × +1 /
19,665 × −1, actions all integral in 0…360. So the 100-game 19×19 self-play finished and
saved. No crash reports exist in `~/Library/Logs/DiagnosticReports` for these runs.
**[measured]**

**2. Reproduced under lldb.** Existing `TrainGoBots` binary, `small.safetensors`, that corpus:

```
lldb -b -o run -k "thread backtrace -c 30" -- .xcodebuild/Build/Products/Debug/TrainGoBots \
    --model-to-train small.safetensors --trained-model out.safetensors experience.safetensors
```

`EXC_BAD_ACCESS (code=2)` on the main thread 11 s in, before the first loss was printed.
Every frame is the `recurse` lambda inside `mlx::core::vjp`, about seven frames per graph
node; the lambda's visited set held 14,167 nodes when the stack guard page was hit.
**[measured]**

**3. The mechanism.** `targetVectors[index, action] = reward` in mlx-swift calls
`_updateInternal(scattered(...))` (`MLXArray+Indexing.swift:348`): the array is replaced by a
new scatter whose input is the previous array. N experiences make a chain N nodes deep.
`eval` walks graphs with an explicit `std::stack` (`transforms.cpp:86`) and never noticed.
`vjp` — reached through `valueAndGrad` on the first batch, because `y` gathers from the chain —
uses a recursive `std::function` (`transforms.cpp:395`) and overflows the 8 MB main-thread
stack. **[inferred]** from source, **[measured]** in the backtrace.

**4. Confirmed by changing only the stack.** Same binary, same corpus, `ulimit -s 65520`: all
77 batches, exit 0, 42.9 s of training. **[measured]**

The 1,000-game 9×9 crash was not rerun. At ~89 decisions per game that corpus is ~89,000
experiences, a deeper chain than the one that crashed, so the same failure is expected.
**[projected]** If that crash was in `SelfPlay` rather than `TrainGoBots`, it is something else.

**5. The collector, which is not the crash.** Each decision pins about three Metal buffers:
the state, the `Int32` action held alive by the lazy `.asType(.float16)`, and the estimated
value held alive by the lazy `reward - estimatedValue`. 100 games of 19×19 is ~118,000, under
the 499,000 resource limit; the limit arrives around 420 games of 19×19.
`ExperienceBuffer.from` also calls `MLX.stacked` eight times, four of them only for `print`.
**[inferred] [projected]**

**6. On `Data`.** Keep a run's experiences in contiguous Swift arrays — `[UInt8]` states,
`[Int32]` actions, `[Float]` rewards and advantages — rather than one `Data` per experience,
which is still one allocation per decision. mlx-swift builds arrays from `[T]` plus a shape,
so bytes need to become an `MLXArray` only per field at save time and per batch in training.

**7. The earlier refactor still exists.** `stash@{0}: On dlgo: experience-buffer-protocol`
holds the design from [2026-08-30-experience-path-refactor.md](2026-08-30-experience-path-refactor.md):
flat-array collector, inert `ExperienceBuffer`, `SafetensorsExperienceStore`, per-batch
`BatchSequence`, eight tests. A dry-run merge onto HEAD
(`git merge-tree --write-tree --merge-base=2598a3d HEAD stash@{0}`) conflicts in seven files —
`Encoder`, `SimpleEncoder`, `ExperienceCollector`, `GoAgentModel`, `PolicyAgentModel`,
`PolicyAgent`, `TrainGoBots` — because `f09c484` took the encoder and model API a different
way. **[measured]**

## What changed

Committed as `2d645e9`, with this worklog as `54a7f23`.

| Change | Files |
|---|---|
| `BatchSequence` reads the corpus back to host once and builds each batch's `x` and `y` in Swift, two fresh `MLXArray`s per batch; `prepareTargets` deleted; preconditions on corpus consistency and action range | `Model/PolicyAgentModel.swift` |
| Two tests: every experience lands in exactly one batch with its ±1 target; training over 50,000 experiences completes | `Tests/GoAgentTests/TrainingBatchTests.swift` **(new)** |

`GoTrainingExperience`, `train(with:optimizer:batchSize:clipNorm:)` and `iterateBatches` keep
their signatures, so `TrainGoBots` is untouched. Batch order is still `SplitMix64(seed: 0)`
over `0 ..< count`, and `x` is still cast to `float16`, as in `321258f`.

## Measurements taken

19×19 corpus above, `small.safetensors`, batch size 512. **[measured]**

| Run | Stack | Result | Training time |
|---|---|---|---|
| HEAD | 8 MB (default) | `EXC_BAD_ACCESS` before the first batch | — |
| HEAD | 64 MB | 77 batches, exit 0 | 42.9 s |
| This change | 8 MB (default) | 77 batches, exit 0 | **4.5 s** |

The last row ran concurrently with an `xcodebuild test`, so if anything it is pessimistic.
Most of the old 42.9 s was CPU time spent building and evaluating the 39,386-node chain
(41.4 s user, against 0.4 s after).

Tests, `xcodebuild test -scheme GoBoard-Package -derivedDataPath .xcodebuild
-enableCodeCoverage NO`: all 30 pass — 9 GoBoard, 14 Scoring, 7 GoAgent including the 2 new.

The large-corpus test was checked against the old code by temporarily restoring HEAD's
`PolicyAgentModel.swift`: the runner exited unexpectedly during
`trainingOnALargeCorpusCompletes()` and the run failed with exit 65. The batch-contents test
passes on both — the old targets had the right *values*; the chain was just too deep.

## Step 3 — MLX out of the collector

Done after Step 2 was committed; not yet committed itself. The stash's collector, buffer and
store were ported by hand onto HEAD's `[[[UInt8]]]` encoder and `GoNetwork` API rather than
popping the stash.

| Change | Files |
|---|---|
| Collector appends into flat `[UInt8]` / `[Int32]` / `[Float]` storage and commits per episode; `init(stateShape:)`, `completeEpisode(reward: Float)`, `count`, `makeBuffer()`; no `import MLX` | `ExperienceCollector/ExperienceCollector.swift` |
| `ExperienceBuffer` becomes an inert struct with `merging`; loses `import MLX`, `from(experiences:)` and its eight `stacked` calls, `save`, `load` | `ExperienceCollector/ExperienceBuffer.swift` |
| `ExperienceStore` protocol + `SafetensorsExperienceStore`: four `MLXArray`s per write; read converts types | `ExperienceCollector/ExperienceStore.swift` **(new)** |
| Collectors sized from the encoder; `Float` rewards; buffers merged; the write throws instead of logging | `SelfPlay/SelfPlay.swift` |
| Six tests: commit/discard, merging, store round trip, float16-action files, the trainer's load path, agent recording | `Tests/GoAgentTests/ExperiencePathTests.swift` **(new)** |

Deliberately not ported: the `ExperienceCollecting` protocol, which exists for a move-replay
collector that is still blocked on pass recording, and the `BoardTensor` encoder, which
conflicts with `f09c484`. The agents, `PolicyAgentModel`, `GoTrainingExperience` and
`TrainGoBots` are unchanged.

Files written by `SelfPlay` change in one way: actions are `int32` instead of `float16`.
`BatchSequence` and the store both convert with `asType`, so older files — including the
19×19 corpus above — still load. A failed save now throws out of `run()` instead of going to
`self-play.log`.

**Measurements.** **[measured]**

- All 36 tests pass: 9 GoBoard, 14 Scoring, 13 GoAgent (5 existing, 2 from Step 2, 6 new).
- 9×9, 50 games of self-play: 25.0 s, peak RSS 61.8 MB, 4,500 experiences. The file holds
  `states` U8 `[4500, 9, 9, 11]`, `actions` I32, `rewards` and `advantages` F32, 4.1 MB.
- `TrainGoBots` on that file at the default 8 MB stack: 9 batches, exit 0.
- The same 50 games wrote 284 MB of `self-play.log`.

Self-play no longer holds any `MLXArray` per decision, so the 499,000-buffer ceiling is out of
reach of the collector. **[inferred]** — not demonstrated with a run long enough to have hit it
under the old collector, which would have been ~420 games of 19×19.

## Open

- **Training does not learn.** Every one of the 77 batches prints `loss = 5.88888` (ln 361),
  before and after this change. The new test shows targets, including −1 rewards, arrive
  correctly, so target construction is ruled out — which retracts the suspicion raised during
  the investigation that the −1 targets were not landing. `Small` still ends in `softmax`
  while `crossEntropy` expects logits; that remains the lead.
  → [policy-network-double-softmax.md](../policy-network-double-softmax.md). Not traced.
- **Peak memory at the end of a run.** The two collectors' arrays, the merged buffer and the
  `MLXArray` the store builds are all resident at once — roughly 4× the corpus, measured on
  the same design in [2026-08-30-experience-path-refactor.md](2026-08-30-experience-path-refactor.md).
  Sharded writes every N games would make peak memory constant in the number of games.
- **Training still loads through `MLXArray`.** `TrainGoBots` builds a `GoTrainingExperience`
  and `BatchSequence` reads it back to host. Having `train` take an `ExperienceBuffer` from
  `SafetensorsExperienceStore.read` would drop that round trip; it changes `GoAgentModel`.
- **`self-play.log` is 50 GB.** `ZobristGoBoard.swift:95` logs the whole `goStringByPoint`
  dictionary at `.info` on every `place`, including speculative applies in `isValid` and the
  ko checks the encoder runs for every empty point. Demote or remove; it also costs self-play
  time. The file was left in place.
- **`TrainGoBots.swift:80` hardcodes `SimpleEncoder(boardDimension: 9)`.** 19×19 training
  works only because `update(parameters:)` without `verify` accepts the loaded 19×19 shapes.

## Notes

- `docs/experience-buffer-protocol.md` §6 already flagged `prepareTargets`, but as a
  buffer-count problem — "under the ceiling at 9×9, over it at 19×19". The limit it actually
  hit is graph *depth*, a different one, reached well before any buffer count matters.
- The pattern to grep for is any loop that repeatedly assigns into the same `MLXArray`
  (`a[i] = …`, `a += …`). mlx-swift turns each one into a node whose input is the previous
  array. `eval` tolerates arbitrarily deep chains; `vjp` and `vmap` recurse and do not.
- lldb was the only route to a backtrace: a stack-overflow segfault left no crash report.
