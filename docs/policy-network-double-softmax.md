# The policy network is softmaxed twice

*GoBoard · Small / PolicyAgentModel · 30 August 2026 (branch `dlgo`)*

`Small` ends in a `softmax`, and the training loss normalizes its input again. The
network therefore trains against a distribution that has been flattened roughly
**85×** relative to the one it actually produced. This is open — nothing here is
fixed yet.

The same double normalization used to affect move *selection* as well; that half is
already resolved, and understanding why is what makes the training half easy to
miss.

---

## 1. The two halves of the same bug

`Small.callAsFunction` returns probabilities, not logits:

```swift
// Sources/GoAgent/Network/Small.swift:44
x = softmax(dense2(x))
```

Two consumers then treat that output as though it were unnormalized.

### Selection — **fixed**

`PolicyAgent.select` used to hand those probabilities to
`MLXRandom.categorical`, whose parameter is named `logits` and whose documentation
says the values are "unnormalized" — it applies its own softmax internally.
Measured on the first two moves of a real game:

| | max/min ratio across the 81 moves |
|---|---|
| What `Small` outputs | **1.104** |
| What `categorical` sampled from | **1.0012** |

The network's preferences were compressed about 85×, leaving essentially a uniform
distribution. Replacing `categorical` with a Gumbel top-k ranking removed this:
that construction consumes `log(p)` directly, so no second softmax occurs, and the
measured spread reaching the sampler is now the network's own 1.0996.

### Training — **open**

```swift
// Sources/GoAgent/Model/PolicyAgentModel.swift:28-29
private static func loss(model: Model, x: MLXArray, y: MLXArray) -> MLXArray {
    crossEntropy(logits: model(x), targets: y, reduction: .mean)
}
```

MLXNN's `crossEntropy` normalizes internally — it computes a `score`, then

```swift
// mlx-swift/Source/MLXNN/Losses.swift:58
let logSumExpLogits = logSumExp(logits, axis: axis)
```

and returns `logSumExpLogits - score`. That is the log-softmax written out by hand,
so the function expects **raw logits**. It is being fed softmax output, which
normalizes a second time — the identical mistake, in the identical direction, in
the path that actually updates the weights.

## 2. Why the port has this bug

dlgo's Keras model also ends in a softmax, and dlgo's loss is
`categorical_crossentropy`. That combination is correct in Keras, because
`categorical_crossentropy` defaults to `from_logits=False` — it expects
probabilities.

MLX has no such flag. `MLXNN.crossEntropy` always assumes logits. So a
line-by-line port of a correct Keras program produces an incorrect MLX one, with
no type error and no runtime warning to catch it.

## 3. What it costs

The loss is minimized against `softmax(softmax(z))` rather than `softmax(z)`. For
81 near-uniform outputs, the inner softmax squeezes the spread by the factor
measured above (~85×), and the gradient reaching `dense2` is attenuated by the
inner softmax's Jacobian — entries on the order of `1/n` for a near-uniform
distribution. The network can still learn, but it is pushing against a
deliberately flattened target, so training moves far more slowly than the
learning rate suggests.

Practical consequence for the project right now: **tuning anything downstream of
the policy is premature.** In particular, the ε values in
[policy-agent-temperature.md](policy-agent-temperature.md) cannot be evaluated
against a policy that cannot express a preference.

## 4. Two ways to fix it

Both are correct; they differ in which contract `Small` publishes.

### Option A — the network returns logits *(recommended)*

Remove the `softmax` from `Small.callAsFunction`, and apply it explicitly in the
one place that needs probabilities:

```diff
  // Small.swift
- x = softmax(dense2(x))
+ x = dense2(x)
```

```diff
  // PolicyAgent.select, policy branch
- moveProbs = self.model.predict(from: boardTensor.expandedDimensions(axis: 0))[0]
+ let logits = self.model.predict(from: boardTensor.expandedDimensions(axis: 0))[0]
+ moveProbs = softmax(logits, axis: -1)
```

`crossEntropy` then becomes correct exactly as written. This is the conventional
arrangement, and it is numerically better: `logSumExp` is computed once, in a
numerically stable form, instead of exponentiating and re-normalizing twice.

The cost is that it changes `Small`'s public output contract, so every current and
future consumer has to know it receives logits. Today there is exactly one
consumer (`PolicyAgent`, via `PolicyAgentModel.predict`), so the change is cheap
now and gets more expensive later.

### Option B — keep probabilities, change the loss

Leave `Small` alone and replace `crossEntropy` with a loss that expects
probabilities — either by taking the log first and using a negative-log-likelihood
formulation, or by writing the cross-entropy directly.

This keeps `predict` returning something directly usable and keeps the port
visually close to dlgo. It is more code to maintain, and it forgoes the numerical
stability of the fused form.

**Recommendation: Option A.** One consumer, one line each side, and it puts the
codebase on the arrangement every MLX example assumes.

## 5. Adjacent, and worth its own look

While reading the loss I noticed the targets are not what `crossEntropy` treats
them as, independently of the softmax question.

`prepareTargets` builds dense `[N, 81]` vectors holding the **reward** at the
chosen action's slot and zero elsewhere:

```swift
// PolicyAgentModel.swift:92
targetVectors[index, action.asType(.int32)] = experience.rewards[index]
```

Because `targets.ndim == logits.ndim`, `crossEntropy` takes its
`targets_as_probs` branch: `score = sum(logits * targets)`, and the loss is
`logSumExp(z) - score`. Writing `L = logSumExp(z)` and `a` for the chosen action:

- **Reward +1** → loss `= L - z_a = -log softmax(z)_a`. This is exactly the
  REINFORCE loss for a positively-rewarded action. Correct.
- **Reward −1** → loss `= L + z_a`. The intended REINFORCE loss is
  `-R · log π(a) = z_a - L`. These are not the same expression, and they do not
  have the same gradient.

So roughly half the training signal — every move from every lost game — may be
applying the wrong update. The algebra above is straightforward, but I have not
traced the gradients numerically or tested it, so treat this as an observation to
verify rather than a diagnosis. It should be settled before or alongside the
softmax fix, since both live in the same expression.

## 6. Related

- [policy-agent-temperature.md](policy-agent-temperature.md) — the exploration rate
  that cannot be tuned until this is fixed.
- [mlx-buffer-ceiling.md](mlx-buffer-ceiling.md) — the self-play crash at scale.
