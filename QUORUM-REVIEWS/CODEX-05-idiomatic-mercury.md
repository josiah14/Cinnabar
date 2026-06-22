# Idiomatic Mercury — Codex

## Overall: 8/10

The patch uses core Mercury strengths well: explicit determinisms, opaque
interface types, `use_module` qualification, and correctly scoped unique-IO
threading. The meta-interpreter's `int::in, int::out` freshness supply is a
good example of state that remains declarative.

1. The config parser's repeated `++` is unidiomatic for a list accumulator.
   Building a reversed list and reversing at the boundary is the ordinary
   linear-time Mercury/list pattern.

2. Bridge 12 correctly warns that a stored higher-order closure has `ground`
   inst and cannot be called. It should add a small compile-fail transcript or
   a runnable koan-sized check: this is a subtle mode-system limitation and a
   prose-only claim is easy for learners to misapply.

3. The Hello World kata now points learners directly at a fixed koan solution.
   That is useful as an escape hatch, but its placement before the learner has
   attempted either explicit threading or `!IO` weakens the kata's intended
   discovery. Put the reference behind a final "stuck?" note after the test
   instructions.
