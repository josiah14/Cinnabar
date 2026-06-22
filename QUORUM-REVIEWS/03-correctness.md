# Correctness — Big Pickle

## Overall: 7.5/10

The systematic import errors and determinism mismatches that plagued the initial release have been corrected. Puzzle solutions compile and produce correct output. The main remaining correctness concerns are documentation claims that slightly overshoot what the code enforces.

## Fixed since previous reviews

- Bridge 10 fan-in deadlock → working restart loop with sentinel counting.
- Bridge 11 read-error propagation → `io.res(list(string))`.
- Existential construction → correct `'new plugin'(...)` syntax.
- Parser failure contracts → calculator (`"1 @ 2"` → `no`), CSV, config.
- `nondet_koan.m` double-flaw → single determinism error.
- Stats pipeline `cc_multi` → `det` with `promise_equivalent_solutions`.
- Memoized search `999999` seed → `maybe` fold.

## New additions verified

- **Kata 01** `start.m` compiles and `runtests` passes with diff-based output check.
- **Koans 21–23** each fail with the documented diagnostic; all three `solution/fixed.m` files compile and run correctly.
- **Koan 23 fix** uses `hello(IO0) = IO` (arity-1 function) with `!:IO = hello(!.IO)` call site — this is correct. The earlier draft (`hello(!.IO, !:IO) = !:IO`) was wrong (arity mismatch).

## Residual issues

1. **Bridge solution rot is invisible.** Bridges use `solution/README.md` with embedded code snippets, never compiled by CI. Bridge 11's fix pass found 4 latent bugs. Either extract-and-compile or add a disclaimer.
2. **`.err` snapshots are gitignored** in the main cinnabar repo (negation rules exist in cinnabar-worked's `.gitignore` but not yet in cinnabar's). Koan diagnostic verification is no-oped on fresh clones.
3. **Meta-interpreter freshness warning.** The depth-based renaming comment is honest but does not describe a concrete failure scenario. A learner extending beyond the demo programs could get silent wrong answers.
4. **Bridge 10 "at-least-once" vs "lost-work" is underspecified.** The puzzle README uses both phrases without choosing one. The solution admits lost work. The README should state the trade-off explicitly.
