# Cinnabar README and conceptual-quality review

*Reviewed 2026-06-20 by big-pickle (via Claude Code). Independent read of the current tree after the Opus/Codex/Ring synthesis fixes were applied. Where my findings differ from the consensus, I flag it.*

## Overall README quality: 7/10

The prose has real voice — direct, technical, respectful of the learner's agency — and the best individual exercise READMEs are models of their format. The root README communicates the project's ambition clearly and the ore/heat metaphor lands well. What keeps this from being an 8 or 9 is a residual unevenness in the bridge format, a few stale assumptions in the root, and the fact that the navigation layer was only recently repaired (it reads well now, but the repair was clearly recent — some of the connecting tissue still feels bolted on).

## 1. Clarity and self-containment

The best READMEs follow a repeatable pattern: representation or starting signature → ordered implementation steps → concrete checkpoint → reflective question. This pattern is most consistently applied in the puzzles, which have standard sections for "Primary skills," "Why Mercury," "Prerequisites," "Representation," and "Design questions."

Standouts:
- `puzzles/advanced/07-mercury-in-mercury/README.md` — decomposes a genuinely hard problem into rename → deref → unify → solve with isolated checkpoints for each. The suggested build order (Checkpoint A/B/C) is exemplary pedagogical scaffolding. Each checkpoint gives a runnable `main` snippet before the full interpreter exists.
- `puzzles/logic/01-sudoku/README.md:90-102` — the design questions are the right kind of prompt: "What would happen if you checked all constraints only when the grid was full?" This tests understanding, not recall.
- `bridge/01-maybe-extend/README.md` — clear starting state, three tasks that escalate naturally, explicit hints but no full solution.

The bridge format is weaker than puzzles and katas at self-containment. `bridge/10-parallel-pipeline/README.md` had known specification issues (fan-in termination was underspecified, supervisor task was over-large) that the synthesis identified and the TODO notes claim were fixed. The remaining concern is that bridge READMEs still vary in whether they include a "Why Mercury" section — bridges 01–03 and 07–10 go straight to "Build and run it first" without stating what checked property the exercise exposes. Compare bridge 05's explicit framing ("mode reversal: one logical relation, two checked directions") with bridge 03's unqualified "extend the tokenizer."

## 2. "Why Mercury" framing

The best framings name a specific, checked language property:

- `puzzles/advanced/04-combinator-library/README.md:6-8`: "Each combinator's determinism is a function of its argument combinators' determinisms — and Mercury verifies this."
- `bridge/04-determinism-ratchet/README.md:5-9`: explicitly connects committed choice to `solutions/2` containment and parallel conjunction constraints.
- `bridge/05-mode-reversal/README.md:5-9`: "One logical relation with two checked directions" — this is exactly the right note.

The inconsistency is in the bridges. Only 04, 05, 06, and 11 have mechanism-specific "Why Mercury" paragraphs. For bridges 01–03 and 07–10, the framing is implicit in the task description. Bridge 09 says it "generalizes an evaluator with typeclasses" but doesn't say why Mercury's typeclass constraints, instance resolution, or interface/module model teach something different from a generic evaluator in Haskell or OCaml. Every bridge should state its Mercury-specific lesson up front.

## 3. Task scope

Katas are appropriately narrow — one concept, clear start state, the README gives enough to begin without giving away the solution. The koan format is well executed when it has one diagnostic; the `nondet_koan.m` double-flaw (type error before determinism error) has been fixed since the earlier reviews.

Puzzle scope is generally good. The meta-interpreter puzzle is decomposed into checkpointed sub-problems that make a very hard task startable without making it trivial. The calculator puzzle's README now correctly specifies that `"1 @ 2"` should return `no` — but this contract change was made in the solution without a corresponding update to the puzzle README's implied test expectations. The README says "handle operator precedence via grammar structure" but does not enumerate the specific failure cases (`"1 @ 2"`, `"1 + "`) that the solution now tests. A puzzle README should state the acceptance criteria, not just the approach.

## 4. Prerequisite chains and navigation

The navigation layer has been substantially repaired since the earlier reviews. The ci.sh `check_index` function now validates that README table row counts match on-disk directory counts for all 8 kata tracks and bridges. The `bridge/README.md` previously listed only 4 of 11 bridges; it now lists all 11 with correct "After" references.

One residual issue: `katas/README.md:9-16` now correctly lists all 8 tracks with short descriptions, which reads well. But the root `README.md:25-27` says "Foundations → Type system → Mode system → Determinism → Parsing. After those five, Tooling, Concurrency, and Advanced can be taken in any order." This over-simplifies — the advanced solver kata requires trailing grade and FFI knowledge from `katas/advanced/01-ffi-depth`, concurrency depends on modes and determinism, and "any order" does not account for these. A sub-path recommendation would be more useful: "Tooling → Concurrency recommended order; Advanced 01 (FFI) → 02 (solver) → 03–07 (any order)."

## 5. Voice and consistency

The writing voice is one of the project's strengths: direct, technical, balanced. The "You bring raw material; the heat does the work" metaphor in the root README is well-chosen and the project mostly lives up to it.

Format consistency has improved. Adopting a standard section order (purpose → prerequisites → task → checkpoint → reflection) would lock this in. The `docs/TEMPLATES.md` created during the fix pass is a good step. I'd recommend running a quick audit to ensure every puzzle README now has expected-output blocks — some do (sudoku, meta-interpreter, pipeline) but others don't (crypto-arithmetic, graph-reachability, calculator).

## 6. Notable outliers

**Better than average:**
- `puzzles/advanced/07-mercury-in-mercury/README.md` — best-structured hard problem in the repo. Checkpoint isolation is pitch-perfect.
- `bridge/11-error-handling/README.md` — the decision table framing ("maybe vs io.res vs exceptions") is genuinely useful as a reference, not just an exercise.
- `bridge/05-mode-reversal/README.md` — strong Mercury framing and good escalating questions about determinism and `promise_equivalent_clauses`.

**Worse than average:**
- `bridge/03-dcg-extend/README.md` — lacks any "Why Mercury" or "Primary skills" section. A DCG bridge that doesn't explain what makes DCGs Mercury-specific (hidden state threading, determinism propagation through `-->`) is a missed teaching opportunity.
- `bridge/09-typeclass-refactor/README.md` — says what it builds but not what the learner learns about Mercury's typeclass system that they wouldn't learn from generics in another language.
- `koans/type-system/01-adt/README.md` — the shortest koan README, and it barely explains what the compiler error teaches. A learner who doesn't already understand non-exhaustive switches will miss the lesson.

## 7. Before public release

1. **Audit bridge "Why Mercury" sections.** Every bridge needs one. The best models are bridges 04, 05, 06, and 11. Apply the same template to 01–03 and 07–10.

2. **Make puzzle README acceptance criteria explicit.** At minimum: which inputs must succeed/fail, and what the expected output shape is. Currently puzzles vary between "here's an approach" and "here's a sample run." Standardise on sample input/output pairs.

3. **Fix the root "any order" claim.** Replace the vague recommendation with explicit sub-paths and note dependencies for advanced puzzles.

4. **Complete expected-output blocks.** Every puzzle should have one, not just the three that currently do.

5. **Bridge solutions are notes-only and unverified by CI.** This was flagged in the synthesis and identified as a latent-rot vector. Bridge 11's solution had 4 bugs because it was never compiled. Either add `solution/*.m` files and compile them, or extract and compile the fenced code blocks from the READMEs. Until then, a note in `bridge/README.md` warning that solution notes are design sketches, not compiled code, would set correct expectations.
