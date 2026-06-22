# Correctness — Laguna M.1

## Overall: 8/10

The curriculum has undergone a systematic correctness pass that addressed the
issues flagged by Opus, Codex, Ring, and Big Pickle. The current tree is in
better shape than any of the earlier reviews reflect: bridge snippets are now
compiled by CI, `.err` snapshots are tracked by git, parser contracts are
tightened, and the multi-module capstone builds cleanly. Most residual issues
are documentation imprecision rather than code bugs.

## Fixed and verified

- **Bridge solution snippets** are now extracted and compiled by `ci.sh §6`.
  All 12 bridge solution READMEs pass. This was the single highest-ROI fix and
  it is correctly implemented.
- **Koan `.err` snapshots** are tracked via `.gitignore` negation rules
  (`!**/*_koan.err`, `!**/solution/*.err`). CI can now verify koans fail for
  the intended diagnostic on fresh clones.
- **Bridge 10** (parallel pipeline) — fan-in deadlock fixed with sentinel
  counting; supervisor rewritten as a real restart loop with `try_io`.
- **Bridge 11** (error handling) — `read_lines` now propagates errors as
  `io.res(list(string))`. Three additional latent bugs were found and fixed
  during the correction pass (`filter_map` func/pred form, spurious `reverse`,
  missing `int` import).
- **Parser contracts** — calculator rejects `"1 @ 2"`; CSV rejects malformed
  rows; config parser documents its lenient-skip policy explicitly.
- **Existential construction** — plugin puzzle uses correct `'new plugin'(...)`
  syntax. The `apply` collision with Mercury's builtin is resolved via module
  qualification.
- **Koan 23** — function-form `hello(IO0) = IO` is correct and the call site
  `!:IO = hello(!.IO)` is right. The arity-1 function is called correctly.
- **`nondet_koan.m`** — double-flaw resolved; only the determinism error fires.
- **Hygiene fixes** — module names reconciled with filenames across 5+ koan
  solutions; duplicate declarations removed from config parser; unused imports
  cleaned; `FIX:` comments rewritten as durable invariants.

## Residual correctness concerns

1. **Bridge "Why Mercury" sections still oversimplify or are absent.** Correct
   content, but the framing mismatch means a learner working a bridge without
   stated acceptance criteria has no way to verify completion. The README must
   state what the exercise checks, not just what it builds.

2. **Meta-interpreter freshness warning is honest but incomplete.** The code
   comment and solution README warn that depth-based renaming is not globally
   unique, and the TODO notes that a concrete failure scenario was demonstrated
   with a counter-based fix. But the puzzle README still presents the depth
   version as the starting point, and the extension task ("describe the flaw")
   was upgraded from description to graded fix-it during the Opus pass. The
   current state is accurate but the gap between "here is a warning" and "here
   is a test that fails because of it" means a learner extending the
   interpreter can still hit silent wrong answers before encountering the
   explanation.

3. **Generic printer and `deconstruct`/`canonicalize`.** The solution README
   does not explain that `canonicalize` strips type names from functors. A
   learner who types `yes(yes(42))` and sees `yes/1` rather than
   `yes(yes(42))/1` will not understand why. The code is correct but the
   educational gap between what the code does and what the learner understands
   it to do is a correctness concern for a teaching resource.

4. **Bridge 10 acceptance criteria still underspecified.** The puzzle README
   uses both "at-least-once" and "lost-work" semantics without choosing one.
   The solution admits lost work. The README should state the trade-off
   explicitly rather than implying the stronger guarantee.
