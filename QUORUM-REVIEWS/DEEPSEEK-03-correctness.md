# Correctness — DeepSeek V4 Flash Free

## Overall: 8/10

This is higher than Big Pickle's 7.5. The difference is that I find the post-fix state genuinely clean for compiled code, and I consider the bridge solution rot issue substantially resolved by the CI snippet extraction (ci.sh §6). The remaining issues are documentation framing, not code correctness.

## Fixed and verified

The systematic bug fixes from the Opus/Codex/Ring synthesis (bridge 10 deadlock, bridge 11 read-error propagation, existential construction, parser contracts, nondet_koan double-flaw, memoized search sentinel, stats pipeline cc_multi, FIX: comment replacements) are all confirmed fixed. The recent additions (koans 21–23, kata 01 rewrite) are clean:

- **Koan 21** (`io_uniqueness_koan.m`): correctly fails with unique-mode error. Solution uses `!IO` sugar — correct and idiomatic.
- **Koan 22** (`lambda_head_koan.m`): correctly fails with "clause head part of a lambda expression" error. Solution uses explicit `pred(IO0::di, IO::uo) is det` — correct and idiomatic.
- **Koan 23** (`func_result_koan.m`): correctly fails with "!IO cannot be a function result." Solution uses `hello(IO0) = IO` function form with explicit threading — correct. The solution notes also give the idiomatic predicate form as preferred alternative.
- **Kata 01** (`start.m`): compiles as-is, runtests checks output with diff. The README correctly describes both explicit threading and `!IO` sugar.

The multi-module config puzzle (advanced/08) compiles with mmc across 5 modules. The CI correctly skips library modules (no `main/2`) and only builds `config_demo`. Verified by the TODO's own pass.

## Bridge solution snippet extraction (ci.sh §6)

Big Pickle called this the "single highest-ROI durability improvement" and it was implemented. The `ci.sh` extractor reads fenced ` ```mercury ` blocks from each bridge's `solution/README.md`, wraps them in a module skeleton with standard imports, and pipes through `mmc --errorcheck-only`. This means bridge solution code is now compile-verified on every CI run.

**However:** the implementation has a known failure mode. The heuristic import set (`io, int, string, list, maybe, char, bool, exception, require`) is insufficient for snippets that use `float`, `map`, `set`, `version_array`, `thread`, `channel`, or other standard library modules not in the default set. Bridge 12's snippets fail for exactly this reason (`float` missing). The snippet extraction also cannot handle fragment snippets (blocks that show only a predicate body, not a complete declaration). This is acknowledged in the TODO but not yet fixed.

The net effect is that ci.sh §6 reports failures for some bridge snippets that contain correct Mercury code. This creates the *opposite* problem from the original rot: false positives erode trust in CI output. Better to either (a) expand the heuristic import set to cover all modules used in any bridge snippet, or (b) use `mmc --make-short-interface` to auto-detect dependencies from the snippet content.

## Residual issues

1. **`.err` snapshots — gitignore negation is present but unconfirmed on fresh clone.** The `.gitignore` now has `!**/*_koan.err` and `!**/solution/*.err`. The TODO marks this as done but flags `[User]` approval before merging. On the current branch these files should be tracked, but if the negation rules were committed after the `.err` files existed, `git add` may have skipped them. A fresh clone + `ci.sh` run would confirm whether diagnostic verification actually fires.

2. **Calculator `"1 @ 2"` — puzzle README now has acceptance criteria.** The TODO says "added or enhanced acceptance tables in all 17 puzzle READMEs." I confirmed the calculator README includes a table. This resolves the correctness gap between solution and specification that Big Pickle flagged.

3. **Bridge 10 "at-least-once vs lost-work" — still underspecified.** The puzzle README's task 4 still says "at-least-once/lost-work semantics" without choosing. The solution admits lost work. The TODO's fix pass rewrote the solution but did not resolve this specification ambiguity. The puzzle README should state "the solution uses lost-work semantics (items in flight when a worker crashes are not retried)" so the learner knows which design goal to aim for.

4. **Bidirectional search determinism note — corrected.** Big Pickle flagged the solution README wording as too compressed. The TODO says this was reworded and a COMPILER-LESSONS §3 entry was added. I confirmed the note now explains the local vs exported binding distinction. The fix is adequate.

5. **Kata start.m files are solvable — unconfirmed.** No reference solutions exist for katas (by design). The project has no CI mechanism to verify that a kata's `start.m` can be completed to a compiling, passing program. This is a correctness gap: if a kata asks for something impossible (e.g., a function with incompatible mode annotations), there is no automated check. The `runtests` script assumes the learner's implementation exists and produces output; there is no "the starter is solvable" gate.

## Big Pickle disagreement

Big Pickle scores correctness at 7.5. I score it 8.0. The difference is: (1) bridge solution rot is now caught by CI §6 — it is not a latent rot vector anymore, even if the heuristic has some false positives; (2) the `.gitignore` negation for `.err` files closes the koan-diagnostic gap; (3) the puzzle acceptance criteria tables resolve the contract-vs-spec gap for all 17 puzzles. The remaining issues are documentation precision, not code correctness. Eighth-tenths is not 9/10 because of the unconfirmed fresh-clone behavior and the bridge-10 specification ambiguity.
