# The dead temperature branch

*GoBoard · PolicyAgent · 30 August 2026 (branch `dlgo`)*

`PolicyAgent.temperature` appeared exactly twice in the codebase: it was declared,
and it was compared against. It was never assigned, its default was `0.0`, and the
comparison is a strict `<` — so **the exploration branch it guards had never
executed**. This note covers what it is actually for, why its name is wrong, and
what turning it on required.

**Status: fixed.** `--temperature` is now a `SelfPlay` option and reaches
`PolicyAgent` through its initializer.

---

## 1. Original state: two references, zero reachability

A grep across `Sources/` and `Tests/` returned two lines, both in
`PolicyAgent.swift`:

```
PolicyAgent.swift:24  public var temperature: Float = 0.0
PolicyAgent.swift:41  if (Float.random(in: 0..<1) < self.temperature) {
```

Nothing else in the package read or wrote it. `SelfPlay` never set it, and neither
did any test. With the default of `0.0`, `Float.random(in: 0..<1) < 0.0` is false
for every draw — the random-play branch was unreachable, and every move went
through the policy branch.

The comparison itself is correct: `0.0` never explores and `1.0` always explores,
which is the behavior you want from an exploration rate. The bug was entirely in
the plumbing — there was no way to give it a value.

## 2. It is not a temperature

The name will mislead whoever tunes this next. What the code implements is
**ε-greedy exploration**: flip a coin each move, and with probability ε throw the
policy away entirely and use a uniform distribution instead. A softmax temperature
is a different mechanism — it divides the logits by *T* before normalizing,
reshaping the whole distribution rather than replacing it.

Eight moves from an illustrative logit vector, so the two mechanisms can be
compared on the same policy (ε-greedy shown as its expected mixture,
`(1−ε)·p + ε/n`):

| | best | | | | | | | worst | top/bottom |
|---|---|---|---|---|---|---|---|---|---|
| The policy as-is | .446 | .245 | .148 | .074 | .045 | .025 | .012 | .006 | 74× |
| ε-greedy, ε = 0.25 | .366 | .215 | .143 | .087 | .065 | .050 | .040 | .036 | 10× |
| Softmax, T = 2.0 | .281 | .208 | .162 | .114 | .089 | .066 | .046 | .033 | 8.6× |

The two middle rows land in a similar place overall but by different means:
ε-greedy adds a flat floor under every move, so the worst move on the board gets
the same absolute boost as the second-best one. A temperature rescales every
probability proportionally, keeping the policy's shape and merely softening its
confidence.

For REINFORCE self-play, ε-greedy is the conventional and simpler choice — **keep
the mechanism, fix the name**. `explorationRate` or `epsilon` says what it does.
*(Not done: the property is still called `temperature`, matching dlgo.)*

## 3. What turning it on required

### The property isn't reachable through the protocol

`createPlayer` returns `GoAgent`, and `temperature` is declared on `PolicyAgent`,
not on the protocol. In `SelfPlay.run`, `whitePlayer` and `blackPlayer` are typed
as `GoAgent`, so `whitePlayer.temperature = …` does not compile.

Resolved by passing it through the initializer, where the concrete type is still in
hand. That keeps the protocol free of a property only one agent has.

```swift
// PolicyAgent
public init(stone: Stone, encoder: Encoder, model: GoAgentModel, temperature: Float = 0.0)

// SelfPlay.createPlayer
let agent = PolicyAgent(stone: color, encoder: encoder, model: agentModel,
                        temperature: self.temperature)
```

### The command-line option

Self-play and evaluation want different values, so it has to be a flag rather than
a constant. A range check was added because both out-of-range directions fail
silently: `> 1` always explores, `< 0` never does.

```swift
@Option(help: "The probability of playing a uniformly random move instead of following the policy")
var temperature: Float = 0.0

func validate() throws {
    guard (0...1).contains(self.temperature) else {
        throw ValidationError("temperature must be between 0 and 1, got \(self.temperature)")
    }
}
```

### Verified

| Check | Result |
|---|---|
| `--help` | option listed, `(default: 0.0)` |
| `--temperature 1.5` | `Error: temperature must be between 0 and 1, got 1.5` |
| `--temperature 0.0` / `0.25` / `1.0` | all complete games |

## 4. What it does to the experience buffer

Exploratory moves are recorded by `ExperienceCollector` exactly like policy moves,
and receive the same episode reward and advantage. That is the intended behavior
for REINFORCE with ε-greedy exploration — the whole point is to credit actions the
policy would not have picked — but two consequences are worth being deliberate
about:

- A fraction ε of every training batch is off-policy. At ε = 0.25 that is a quarter
  of the gradient signal coming from moves the network did not choose, which slows
  convergence even as it broadens coverage.
- Exploration interacts with the early-pass problem. A uniform draw is more likely
  to land on moves that fail the `isValid` and `isEye` filters, so raising ε pushes
  more decisions further down the candidate list. *(The candidate list itself was
  fixed separately — it used to repeat about 40% of its entries.)*

## 5. Suggested values

Starting points, not tuned results — nothing here has been run to convergence.

| Use | ε | Why |
|---|---|---|
| Evaluation / head-to-head | 0.0 | Measure the policy you actually have. The default. |
| Early self-play | 0.2 – 0.3 | An untrained network's output is nearly uniform anyway, so a high ε costs little and guarantees coverage. |
| Later self-play | 0.02 – 0.05 | Once the policy has an opinion, most of the batch should be on-policy. |

A decay across the run — ε from 0.25 down to 0.02 over the generations, rather than
a fixed value per invocation — is the usual next step, but it only makes sense once
training actually moves the policy. That is **not yet true**: see
[policy-network-double-softmax.md](policy-network-double-softmax.md).

## 6. Related

- [policy-network-double-softmax.md](policy-network-double-softmax.md) — the
  remaining bug in the training path.
- [mlx-buffer-ceiling.md](mlx-buffer-ceiling.md) — the self-play crash at scale.
