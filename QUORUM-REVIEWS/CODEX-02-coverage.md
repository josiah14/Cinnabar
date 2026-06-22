# Coverage breadth + depth — Codex

## Breadth: 8/10; depth: 7.5/10

The new multi-module config puzzle closes a real structural gap: it requires
module boundaries, opaque types, a dependency DAG, and error accumulation.
Bridge 12 also gives higher-order functions and impurity a concrete home.

Remaining gaps:

1. **The config puzzle's contract does not specify duplicate-key semantics.**
   The parser preserves every pair and the validator uses `assoc_list.search`.
   A learner cannot tell whether `port = 1` followed by `port = 2` should be
   rejected, use the first value, or use the final value. Add an acceptance
   case and make duplicate handling an explicit validation rule.

2. **Bridge 12 has no executable completion contract.** It asks learners to
   print a filtered count and implement two counter designs, but gives neither
   expected output nor assertions. A short expected-output block (including
   the count) would make the extension verifiable like the reactivation kata.

3. The source inventory contains many advanced concurrency mechanisms, but
   there is still no end-to-end exercise that requires designing a transactional
   invariant across multiple shared values. The STM kata/koan teach mechanics;
   a puzzle would provide the needed design practice.
