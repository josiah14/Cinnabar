# TODO

Last major work: Ring review sweep 2026-06-18 (14 action items completed).
Items below are open work, ordered by priority tier.

---

## Tier 1 — Fix before community release

These are correctness issues, trust-breaking gaps, and the minimum editorial pass
a new user landing on the repo would notice immediately.

### Factual / correctness

- [x] **`busy_wait` optimization hazard** (`bridge/10-parallel-pipeline` solution README)
  — note added; also added `koans/tooling/03-pure-predicate-optimization`.

- [x] **`bridge/09-typeclass-refactor` float instance ambiguity** — note added to task 3 explaining `//` vs `/` per instance.

- [x] **`csv_reader.m` silent strip** — comment added to both bridge/07 and puzzles/parsing/02 copies.

- [x] **`nqueens.m` list representation** — comment added above `queens_acc`.

### Discoverability / navigation

- [x] **Link `COMPILER-LESSONS.md` from root README** — added Reference section before Setup.

- [x] **Root README getting-started path** — "Recommended order" promoted to top-level section directly after "Who this is for".

### Content accuracy

- [x] **Concurrent pipeline Why Mercury too generic** — rewritten to name `!IO` uniqueness, `channel(T)` as the only shared-state mechanism, and `maybe` as natural sentinel.

- [x] **Formatting standardization** — audited all READMEs; fixed missing `---` dividers between `##` sections in `puzzles/advanced/06-plugin-architecture`; the `---------` in crypto-arithmetic is in a code block (intentional). Rest of codebase is consistent.

---

## Tier 2 — Koan density

Target: **1:1 koans to katas** per track. Currently 29 / 62 (0.47).
For small tracks (tooling 5, advanced 5): either expand katas to ~8 then add 8 koans,
or just write ~8 koans against the existing kata set if more katas have diminishing
returns.

| Track | Katas | Koans | Target | Need |
|---|---|---|---|---|
| determinism | 6 | 4 | 6 | +2 |
| mode-system | 7 | 5 | 7 | +2 |
| foundations | 12 | 7 | 12 | +5 |
| concurrency | 8 | 2 | 8 | +6 |
| parsing | 9 | 3 | 9 | +6 |
| type-system | 10 | 4 | 10 | +6 |
| tooling | 5 | 2 | 8 (expand or overshoot) | +6 |
| advanced | 5 | 2 | 8 (expand or overshoot) | +6 |

Do in this order (quick wins first, then biggest gaps):

- [x] **Koan density pass (research-first)** — researched Mercury docs; wrote 4 quality
  koans across 4 tracks: `determinism/05-promise-equivalent-solutions`,
  `mode-system/06-negation-bindings`, `tooling/04-require-complete-switch`,
  `advanced/03-impure-foreign-proc`. All koan.m files produce correct errors;
  all solution/fixed.m files compile clean. COMPILER-LESSONS.md updated with 4
  new entries.

- [x] **Foundations koans** (+5) — wrote 5 quality koans: `08-res-constructors`
  (`ok`/`error` vs `yes`/`no`), `09-array-unique` (array chaining), `10-foldl-accumulator`
  (`!X` in lambda head), `11-state-var-direction` (`!:N` used as input), `12-map-io-capture`
  (`list.map` + IO). All koan.m files produce correct errors; all solution/fixed.m compile
  clean. COMPILER-LESSONS.md updated with 5 new entries.

- [x] **Concurrency koans** (+3 strong candidates found, not 6) — wrote 3 quality
  koans: `03-spawn-det` (spawn callback needs `cc_multi`), `05-spawn-propagate`
  (`cc_multi` propagation), `06-channel-sentinel` (channel element type encodes sentinel).
  Other TODO patterns were runtime errors, already covered, or didn't produce clean
  compile errors. COMPILER-LESSONS.md updated. 3 is the right number.

- [x] **Parsing koans** (+3 strong found) — wrote 3 quality koans: `04-dcg-nondet`
  (multi-clause DCG → nondet; use if-then-else for semidet), `05-phrase-string`
  (string ≠ list(char)), `06-phrase-det` (semidet DCG propagates to caller). Also
  discovered: Mercury has no `phrase/2` — DCG rules called directly. COMPILER-LESSONS.md
  updated with 4 new parsing entries.

- [x] **Type-system koans** (+4 strong candidates found, not 6) — wrote 4 quality
  koans: `05-missing-instance` (no instance for concrete type), `06-missing-constraint`
  (missing `<= show(T)` on pred signature), `07-superclass-instance` (subclass instance
  without superclass), `08-phantom-mismatch` (phantom unit mismatch). Also discovered:
  comma inside `where [...]` is item separator, not conjunction — multi-goal instance
  method bodies must delegate to module-level predicates. COMPILER-LESSONS.md updated.

- [x] **Tooling + advanced koans** (+3 each, strong candidates only) — Tooling:
  `05-memo-io` (memo with unique-mode IO args), `06-tail-rec-pragma` (require_tail_recursion
  [error] on non-tail-rec pred), `07-test-det` (test pred uses semidet unification).
  Advanced: `04-univ-det` (univ_to_type in det context), `05-export-arity` (foreign_export
  arity mismatch), `06-foreign-enum` (incomplete constructor mapping). All koan.m produce
  correct errors; all solution/fixed.m compile clean. COMPILER-LESSONS.md updated.

---

## Tier 3 — Coverage gaps

New content that fills real holes in what the curriculum teaches. Not release blockers
but would lift the curriculum from "solid" to "comprehensive."

- [x] **`cc_nondet` dedicated exercise** — `koans/determinism/06-cc-nondet-solutions`:
  `cc_nondet` passed to `solutions/2` (inst mismatch); teaches that `cc_nondet ≠ nondet`
  even though both produce at most one result. COMPILER-LESSONS.md updated.

- [x] **Error-handling patterns bridge** — `bridge/11-error-handling`: starter file
  with `maybe(T)` for optional fields; tasks add custom error type (validation with
  reasons), then `io.res` file loading; solution README includes decision table for
  `maybe` / custom error / `io.res` / exceptions. Starter compiles and runs clean.

- [x] **Nested / accumulator-passing DCG** — katas 05 (accumulator/left-recursion) and
  07 (stateful DCG with position/symbol table) cover the kata side. Added
  `koans/parsing/07-stateful-branch`: mode mismatch when state variable not threaded
  through all disjunction branches; also teaches why disjunction → if-then-else for
  semidet DCG. COMPILER-LESSONS.md updated.

- [x] **STM coverage** — `katas/concurrency/09-stm`: bank transfer kata covering
  `new_stm_var`, `read_stm_var`, `write_stm_var`, `atomic_transaction`, `retry`,
  and `or_else` for non-blocking fallback; `koans/concurrency/07-stm-context`:
  `read_stm_var` called with `!IO` — type error `io.state` vs `stm_builtin.stm`.
  COMPILER-LESSONS.md updated (section 6e).

- [ ] **Solver types** — `advanced/02-solver-types` is a broken reference kata. Near-term
  plan in `CLP-PLAN.md`: update kata with honest CLP situation + working `solver type`
  declaration, add `koans/advanced/07-solver-any-inst` (mode checker enforcing `any` vs
  `ground` without a constraint engine). Long-term: Rust CLP(FD) engine via FFI.

- [x] **Property-based testing** — `katas/tooling/06-property-testing`: bounded generator
  (`int.nondet_int_in_range`), semidet property, runner with `solutions/2` +
  `find_counterexample`; shows passing and failing properties with counterexample output.
  `koans/tooling/08-property-generator`: det generator passed to solutions — mode error.
  COMPILER-LESSONS.md updated (section 7c): `int.between` → `int.nondet_int_in_range`,
  det generator mode mismatch, `list.length` type ambiguity.

- [x] **Module system depth** — `katas/advanced/06-abstract-module`: implement a `mset(T)`
  (multiset) abstract module; exercises cover abstract type enforcement, `use_module` vs
  `import_module` in interface sections, and swapping the implementation from `list(T)`
  to `assoc_list(T, int)` without touching the client. Compiles clean against stubs.

---

## Tier 4 — Infrastructure

- [ ] **CI gate** — script that compiles every `.m` file; koan solutions + puzzle
  solutions + bridge starters must pass; broken koan files must fail for the documented
  reason only.

---

## Completed (Ring review sweep 2026-06-18)

### Bugs / factual errors
- [x] Sudoku prerequisite wrong (`05-map` → `06-set`)
- [x] `div_safe` / `num_div` name mismatch in bridge/09 solution README
- [x] `with_inst` red herring removed from bridge/06

### Structural gaps
- [x] Koan solution audit — 28 koans checked; created missing `koans/tooling/01-grade/solution/README.md`
- [x] Difficulty scaffolding added to `puzzles/advanced/07-mercury-in-mercury/README.md`
- [x] Difficulty scaffolding added to `puzzles/advanced/03-bidirectional-search/README.md`
- [x] Advanced kata track: added `04-pragma-memo` to track README, fixed prereq paths
  in puzzles 05/06, wrote and compiled `05-assoc-list-env` kata

### Content improvements
- [x] Sudoku approach: removed `fill_first_empty` skeleton, replaced with conceptual description
- [x] Why Mercury added to bridge/04, bridge/05, bridge/06
- [x] `## What to observe` / `## Your task` added to 5 koan READMEs missing them
- [x] Design questions added to `puzzles/logic/01-sudoku`, `puzzles/concurrent/02-pipeline`,
  `bridge/05-mode-reversal`

### Code quality
- [x] `anagrams.m` — algorithm comment added
- [x] `bidir.m` — float precision comment added
- [x] `sudoku.m` — `get_nth` out-of-bounds comment added
- [x] `combinators.m` — `choice_det` commit behavior comment added

---

## Completed (earlier work)

- [x] `puzzles/parsing/01-calculator/solution/calculator.m` — full DCG rewrite (2026-06-17)
- [x] `puzzles/data-structures/02-expression-evaluator/solution/expr_eval.m` — removed dead import (2026-06-17)
- [x] All kata `start.m` skeletons + `runtests` scripts — all tracks complete (2026-06-18)
- [x] `koans/parsing/03-dcg-mode` — `phrase/2` and dead if-then-else removed (2026-06-17)
- [x] 36-source-file fix sweep (2026-06-17)
