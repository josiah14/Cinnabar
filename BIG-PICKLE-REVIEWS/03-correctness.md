# Cinnabar correctness review: pedagogical and technical alignment

## Scope and rating

Reviewed puzzle solutions, bridge starters and solution notes, and a cross-section of koan source files and READMEs in their current post-fix state. The earlier reviews (Opus/Codex/Ring) identified 15+ technical errors; the TODO indicates all P0 and P1 items have been addressed. This review evaluates the *current* correctness and identifies residual issues.

**Correctness: 7.5/10** (improved from ~6 in the pre-fix state). The systematic import errors (`maybe.map`, `int.between`, `phrase/2`, `=:=`) that plagued the initial release have been corrected. The parser failure contracts have been tightened. Bridge 10 and 11 have working solutions. The remaining correctness concerns are at the level of documentation claims that slightly overshoot what the code enforces, and a few solution-invariant statements that are accurate but incomplete.

## 1. What has been fixed since the earlier reviews

The following were identified by Opus, Codex, or Ring and have been resolved:

- **`solutions/2` sort/dedup claim** — Codex flagged this as incorrect; the consensus adjudication confirmed it is correct (Mercury's universal term order). Not fixed because it wasn't broken. The solution README in `koans/determinism/02-nondet-in-det` has an accurate explanation.
- **Bridge 10 fan-in loses work** — Fixed. The solution now uses a sentinel-counting `fanin_writer` and the supervisor is a real restart loop, not a stub.
- **Bridge 11 read-error propagation** — Fixed. `read_lines` returns `io.res(list(string))` and propagates errors. Three additional latent bugs were found and fixed during the correction pass (`filter_map` func/pred mismatch, spurious `list.reverse`, missing `int` import).
- **Existential construction** — Fixed. The plugin puzzle now correctly uses `'new plugin'(...)` syntax for the constrained existential case. The solution READMES for both the puzzle and the koan are reconciled.
- **Parser failure contracts** — Calculator (`"1 @ 2"` → `no`), CSV (malformed input → `no`), config (lenient policy named explicitly) — all three fixed and compile-verified.
- **`nondet_koan.m` double-flaw** — Fixed. The type error is now absent; only the determinism error fires.
- **`many`/`many_p` progress invariant** — Documented in both solution READMEs with length-guard snippet.
- **Memoized search sentinel** — `999999` seed replaced with `maybe` fold.
- **Stats pipeline `cc_multi`** — Changed to `det` with `promise_equivalent_solutions`.
- **`FIX:` comments** — Calculator and pipeline `FIX:` comments rewritten as durable invariants.
- **Bidirectional search determinism note** — Corrected to explain if-then-else commitment semantics.
- **Bridge 05 `(out,out) is nondet` explanation** — Corrected.

## 2. Residual documentation inaccuracies

### 2a. The bidirectional-search solution still slightly overstates

`puzzles/advanced/03-bidirectional-search/solution/README.md` now correctly explains the if-then-else commitment mechanism, but the explanation buries the key insight: the issue is that `N0` is an *exported* variable from the condition to the then-branch, so `gen`'s multiplicity propagates. This is documented correctly in `COMPILER-LESSONS.md` §3 (new entry), but the solution README's wording ("the condition's nondeterminism is committed for local variables; exported variables still propagate") is too compressed. A reader who doesn't already understand commitment semantics may miss the distinction between local and exported bindings. Add an explicit contrast case (discarded binding → `semidet`, exported binding → `nondet`) with the compiler output.

### 2b. Bridge 10 solution claims verified behaviour but the acceptance criteria shifted

Bridge 10's solution README now describes a working restart loop with `try_io` supervision. But the puzzle README's original task 4 asked for "lost-work semantics" — what happens to items already sent to the crashed worker that were not yet processed. The solution correctly admits items are lost (the channels are cancelled when the transformer dies), but the README still uses the phrase "at-least-once/lost-work semantics" (`bridge/10-parallel-pipeline/README.md:77-91`) without specifying which guarantee applies. If "at-least-once" is intended, the solution must buffer in-flight items or use an acknowledgment protocol. If "lost-work" is accepted, the README should state that explicitly and make it a documented design trade-off rather than a vague requirement.

### 2c. The meta-interpreter's freshness warning

`puzzles/advanced/07-mercury-in-mercury/solution/meta_interp.m:94-96` now has a clearer comment about depth-based renaming not being globally unique: "Not globally unique (same depth can be reached via different paths) but correct for the demo programs that don't share variable names across rules." This is accurate for the two demo programs, but the solution does not identify *when* this assumption breaks. A user extending the demo to a program with shared variable names across rules (e.g., `ancestor` where the same `Z` appears in two sibling subgoals at the same depth) would get silent wrong answers. The comment should describe a concrete failure scenario, or the code should thread a fresh-name counter through `solve`/`resolve`.

### 2d. Calculator test list includes `"1 @ 2"` but puzzle README doesn't specify test cases

The calculator solution now correctly rejects `"1 @ 2"` as `no`. The puzzle README (`puzzles/parsing/01-calculator/README.md`) describes the approach and representation but does not enumerate acceptance criteria or test cases. A learner implementing from the README alone would not know whether `"1 @ 2"` should be an error or a parse of `1`. This is a correctness gap between the puzzle specification and the solution contract. Every puzzle should list its acceptance tests, not just its approach.

## 3. Koan quality

The koan format — one broken file, one focused compiler diagnostic, one repair — is one of the curriculum's strengths when well-executed. The `nondet_koan.m` double-flaw has been fixed. The `semaphore` module path has been fixed. The existential koan's missing `list` import has been fixed.

The `.err` diagnostic snapshots remain a weak link. These files capture the expected compiler output for each koan and are used by `ci.sh`'s `compile_fail` function to verify that the koan fails for the *intended* reason. However, they were added to `.gitignore` (the pattern `*.err` was treated as "build artifacts"), so they are not tracked in git. On a fresh clone, CI runs without diagnostic verification and silently downgrades to "PASS (broke as expected)" without checking that the error is the right one. This is a correctness gap in the CI pipeline: koan diagnostic verification is an opt-in manual step rather than an automated gate.

**Fix:** Either force-add the `.err` snapshots (`git add -f *.err` for koan directories) or add a `.gitignore` negation (`!**/*_koan.err`, `!**/solution/*.err`, etc.) so they are tracked. The `TODO.md` flags this as a `[User]` decision, but the decision matters for correctness: without tracked `.err` files, CI cannot verify that a koan teaches the intended lesson.

## 4. Solution quality (reference solutions)

The puzzle solutions I examined (`sudoku.m`, `meta_interp.m`, `calculator.m`, `pipeline.m`, `csv_reader.m`, `config_parser.m`) all compile as verified and produce correct output for their declared test cases.

The bridge solution notes are the weak link. Bridges do not ship `solution/*.m` files — solutions are prose notes in `solution/README.md` with embedded code snippets. This means:
- Bridge solution code is never compiled by CI (no `*.m` to find).
- The bridge-11 fix pass found 4 latent bugs in solution notes that had clearly never been compiled.
- Bridge 10's solution notes were completely rewritten during the fix pass; the pre-fix version deadlocked.

The project convention of "bridges have note-only solutions" is defensible (it keeps the format distinct from puzzles), but the CI gap means bridge solution rot is invisible. Two options: (a) extract and compile fenced code blocks from all bridge solution READMEs in ci.sh, or (b) add a note to `bridge/README.md` stating that solution notes are design sketches, not compiled reference implementations. Option (a) is better for correctness but requires more tooling.

## 5. Specific issues

1. **Bridge solution rot is invisible.** Every other code artifact in the project is compiled by `ci.sh`. Bridge solution notes are not. This is the single highest-ROI correctness improvement: compile-check bridge solution snippets.

2. **`.err` snapshots are gitignored.** Koan diagnostic verification in CI is no-oped on fresh clones. A koan that changes its first diagnostic (due to compiler version changes or exercise refactoring) will not be detected.

3. **Puzzle acceptance criteria are implicit.** Several puzzles describe their approach but not their exact test cases. The calculator is the clearest example: the solution tests `"1 @ 2" → no`, but the README never says it should. Standardise on explicit test cases per puzzle.

4. **The meta-interpreter does not warn about potential silent unsoundness from depth-based renaming.** The comment is honest but it does not describe a concrete failure scenario. A learner extending the interpreter beyond the two demo programs could get wrong answers without noticing.
