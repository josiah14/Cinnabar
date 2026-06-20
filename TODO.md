# TODO

Backlog derived from the three-reviewer synthesis (2026-06-19).
Source of truth and full reasoning: [`REVIEWS-SYNTHESIS/SYNTHESIS.md`](REVIEWS-SYNTHESIS/SYNTHESIS.md).
Individual passes in `OPUS-REVIEWS/`, `CODEX-REVIEWS/`, `RING-REVIEWS/`.

**Model-fit tags** (set 2026-06-19):
- `[Sonnet]` — mechanical/editorial, clear acceptance criteria. Cheaper path.
- `[Opus]` — needs correct Mercury determinism/mode/type reasoning where a wrong fix
  silently propagates an authoritative error (cf. the `solutions/2` episode). Do these in
  the nix devShell, compile-verified with `mmc`.
- `[User]` — interactive infra (SSH/keys) the model can't do.

**Effort tags** (set 2026-06-20, on open `[Opus]` corrections) — set the model's effort
dial before starting each:
- `{max}` — open-ended research; must compile-fail/compile-pass for *exactly* the intended
  reason. Highest wrong-fix risk.
- `{xhigh}` — non-local correctness reasoning (e.g. concurrency); not a localized edit.
- `{high}` — concrete refactor or judgment call with clear acceptance criteria.

**Hard rule for any code/contract item:** work inside `nix develop` and verify with `mmc` —
koans must still fail for the documented reason, solutions/katas/bridges/puzzles must still
compile. "Looks plausible" is not done.

---

## P0 — release blockers (trust + navigation)

- [x] `[Sonnet]` **Complete every stale index.** katas/README.md, type-system (10),
  parsing (9), mode-system (8), determinism (7), foundations (12), bridge (11),
  puzzles/README.md (concurrent + advanced). All counts verified by ci.sh check_index.
- [x] `[Sonnet]` **Fix broken/misleading nav.** `bridge/README.md` prereq
  `07-io-error-handling` → `07-exceptions`; root README bridge-02 label fixed to
  "Higher-order filter/map/fold pipeline grouping".
- [x] `[Sonnet]` **Add a CI path/count check** — `check_index()` in ci.sh section 0;
  verified all 9 checks pass (8 kata tracks + bridge).
- [ ] `[User]` + `[Sonnet]` **Make CI authoritative.** Workflow is `if: false`; enabling it
  needs the flake SSH input `mise` wired up (`[User]` — interactive). The per-koan
  expected-diagnostic check is scripting (`[Sonnet]`).
  - **BLOCKER found (2026-06-20):** the `.err` diagnostic snapshots are **gitignored and
    untracked** (`git ls-files '*.err'` → 0; `.gitignore` even says `*.err` is "never
    meaningful to track"). But `ci.sh` `compile_fail` reads `$dir/$module.err` for the
    per-koan diagnostic check — so on a fresh clone / in CI there are no snapshots and that
    check silently no-ops (falls through to "PASS broke as expected" without verifying the
    diagnostic). To make the diagnostic check real in CI, either force-add the koan `.err`
    snapshots or un-ignore them by path (e.g. a `!**/*_koan.err` + bridge/solution patterns
    negation). Both are commit/policy decisions → `[User]` to choose; wiring is `[Sonnet]`.
  - **GAP found (2026-06-20):** `ci.sh` does not compile **bridge solution code** — bridges
    are notes-only (no `solution/*.m`), and the solution snippets in `bridge/*/solution/README.md`
    are never built. As a result Bridge 11's notes had **four** latent bugs that had clearly
    never compiled (`read_lines` error-swallow, `filter_map` func/pred-form mismatch, a spurious
    `list.reverse`, and a missing `int` import), and Bridge 10's supervisor stub deadlocked. Same
    root cause as the `.err` gap: anything CI does not actually build rots silently. Options
    (`[Sonnet]`): (a) add real `solution/*.m` files for bridges and compile them like puzzle
    solutions; or (b) keep notes-only but extract+compile the fenced ```mercury``` blocks in a CI
    check. Until then, treat bridge solution snippets as unverified. (Note: `csv_reader.m` also
    failed to compile in-repo from a bad "unused import" cull — see `char` caution in
    COMPILER-LESSONS §2; ci.sh *does* build puzzle solutions, so enabling CI would have caught it.)
- [x] `[Sonnet]` **Retire stale `REVIEW.md`** — marked historical with banner pointing
  to REVIEWS-SYNTHESIS/ and ci.sh as authoritative gate.
- [x] `[Opus]` `{high}` **Bridge 11 read-error propagation** — DONE. `read_lines` now returns
  `io.res(list(string))` and propagates `error(Err)` up the recursion (and out through
  `load_users`) instead of swallowing it into a truncated `ok`. Found the notes were never
  compiled — fixed THREE more latent bugs while making the full Task 1–3 solution compile +
  run via the AGENTS.md dev shell: `parse_line` used `filter_map`'s function form with a `pred`
  lambda (→ named `parse_pair` + 3-arg predicate form); a spurious `list.reverse` reversed
  already-ordered lines; and Tasks 1–2 need `:- import_module int.` (the starter omits it).
  Also corrected the main README's "discard any partial lines" instruction.
- [x] `[Opus]` `{xhigh}` **Bridge 10 fan-in loses work** — DONE. Both halves fixed in the
  solution notes (bridges are notes-only by convention; all code verified end-to-end via the
  AGENTS.md dev shell, parallel grade). (1) Fan-in: added a sentinel-counting `fanin_writer`
  (one `no` per worker) and corrected the main README's false "writer does not need to change";
  verified total `N*(N+1)` every run vs. the lossy single-sentinel writer. (2) Supervisor:
  finished it properly — the old stub deadlocks (a `throw` can't also report its own crash, so
  `take(Report)` blocks forever). Split into `transform_loop` (throws), `run_transformer`
  (`try_io` catches → reports to `Report`), and `supervise` (restart-respawn loop). Verified:
  N=20 crashes on 14 & 7, restarts twice, total `378` (bad items skipped). Also documented
  that `thread.spawn` requires a `cc_multi` closure (det is a mode error).
- [x] `[Opus]` **Existential contradiction** — RESOLVED. Compile-checked: `'new plugin'(...)`
  constructs the typeclass-constrained existential fine (the `=> formatter(T)` constraint does
  not block it); only bare `plugin(upper)` fails. Rewrote `plugins.m` to use the existential
  type (the puzzle's actual subject) with `'new plugin'(...)`; module-qualified the `apply`
  call to dodge the builtin-`apply` collision. Corrected the solution README (closure approach
  reframed as an alternative, not a necessity; compose extension verified), the puzzle README
  (construction syntax + `apply` heads-up), and the false COMPILER-LESSONS §4 entry.
- [x] `[Opus]` `{high}` **`nondet_koan.m` double-flaw** — DONE
  (`koans/determinism/02-nondet-in-det`). Body changed to `find_factor(N, F), Factors = [F]`
  so the call is type-correct and the *determinism* error fires alone (verified via dev shell:
  only `Declared det, inferred nondet ... can fail and can succeed more than once`, no type
  error, no binary). Regenerated `.err`; solution still compiles + runs (`[2,3,4,6]`), cleaned
  its `FIX:` comment; the `solutions/2` sort/dedup note in the solution README left untouched.
- [ ] `[User]` **`ci.sh` — run inside `nix develop` and verify remaining 1 failure:**
  The 9 editorial fixes below are applied; one requires mmc to diagnose:
  - `[x]` `koans/concurrency/07-stm-context/solution/fixed.m` — module name fixed → `fixed`
  - `[x]` `koans/foundations/04-modules/solution/fixed_client.m` + `fixed_utils.m` — module names updated to match filenames
  - `[x]` `koans/tooling/08-property-generator/solution/fixed.m` — module name fixed → `fixed`
  - `[x]` `koans/type-system/03-abstract/solution/fixed_client.m` — module name → `fixed_client`; `stack.m` added to solution/
  - `[x]` `katas/advanced/07-ffi-pragma-attrs/start.m` — `[promise_pure]` stub so starter compiles
  - `[x]` `katas/concurrency/09-stm/start.m` — module name → `start`; stm stubs use `S, S`
  - `[x]` `katas/tooling/06-property-testing/start.m` — module name → `start`
  - `[x]` `puzzles/parsing/03-config-parser/solution/config_parser.m` — duplicate `parse_config` and `get` declarations removed; compiles clean
  - `[x]` ci.sh: skip library modules (no `:- pred main(`) in koan solution pass — prevents linker failures on `fixed_utils.m` and other helper modules
  - `[x] [Opus]` `{max}` `koans/concurrency/02-shared-state/shared_state_koan.m` — DONE. Root
    cause: `!IO` auto-threads through `&` (dependent parallel conjunction), so the old `!IO`
    form compiles by serializing. New koan hands the SAME explicit IO state (`IO0`) to both
    `&` branches → fails with `unique-mode error: ... would clobber its argument, but variable
    `IO0' is still live`. Verified via the AGENTS.md dev shell: koan fails (no binary),
    solution compiles + runs. Captured `.err` snapshot; cleaned solution's `FIX:` comment;
    README now explains the `!IO`-auto-threading subtlety + why reverting to `!IO` isn't the fix.


## P1 — correctness of reference material

- [x] `[Opus]` **Reword bidirectional if-then-else determinism note** — DONE.
  Confirmed against `mmc`: the conclusion (`first_with` is nondet) is correct, but the
  *explanation* was wrong. The real mechanism: if-then-else commits the condition's
  nondeterminism only for variables local to the condition; `N0` is exported to the
  then-branch (`N = N0`), so `gen`'s multiplicity propagates. Verified the contrast case
  (discarded binding → det). Reworded; added a COMPILER-LESSONS §3 entry.
- [x] `[Opus]` **Tighten bridge-05 `(out,out) is nondet` note** — DONE. Compile-checked:
  the `(out,out) is nondet` mode *does* compile and produce correct pairs (with a productive
  generator); the real issues are enumeration order and `promise_equivalent_clauses` requiring
  proven relation equivalence. Also found `string.to_int` is lenient (`"042"`, `"+42"`, `"00"`)
  while `int_to_string` is canonical — so the forward/reverse relations already differ.
  Reworded solution README + main README Task-2 prompt around these accurate points.
- [x] `[Opus]` `{high}` **Parser failure contracts** — DONE (all three verified via dev shell).
  Calculator: `tokenize` made strict (semidet, requires `Rest = []`); `"1 @ 2"` now → `no`,
  not `yes(1)` — and this matches the puzzle README's own pipeline, from which the solution
  had drifted. CSV: `parse` returns `maybe(csv)` requiring full consumption; a malformed row
  (e.g. unterminated quote) → `no` instead of silent truncation. **Also fixed a P2 regression:
  csv_reader.m did not compile** — the "unused import" pass wrongly removed `char` (needed for
  the `char` type); re-added it (anagrams.m checked — fine without `char`). Config: lenient
  line-skipping is a legitimate policy, so named + documented it explicitly in code and README
  (with the alternative: thread skipped lines out). READMEs updated to state each failure
  contract. COMPILER-LESSONS: added `filter_map` func/pred form + `char`-import caution.
- [x] `[Sonnet]` **Sudoku collect-all** — `solutions/2` is the correct Mercury idiom here.
  Committed-choice `( solve(P,S) -> ... ; ... )` is rejected by the mode checker (uniqueness
  mismatch: nondet condition with IO in branches violates unique-state rules). Reverted;
  compiles and solves correctly.
- [x] `[Opus]` **`many`/`many_p` progress invariant** — DONE. Compile-checked both claims:
  unguarded `many` over a non-consuming parser diverges (runs until killed); a length-guard
  version (`list.length(Mid) < list.length(Input)`) compiles `det` and stops cleanly.
  Documented the cardinality-vs-progress distinction in both solution READMEs (with the guard
  snippet; the generic `many_p` notes that an abstract stream has no generic length, so
  enforcement needs a size method) plus termination caveats in both puzzle READMEs. Also fixed
  two pre-existing imprecisions in the combinator README ("det because it terminates"; "nondet
  cond still commits").
- [x] `[Sonnet]` **`memoized_search.m`** — `999999` seed replaced with
  `AllPaths = [First | Rest]` fold; `maybe` import removed. Compiles (tabling+par warning
  is non-fatal in Mercury 22).
- [x] `[Sonnet]` **`stats_pipeline.m`** — `is cc_multi` → `is det`;
  both spawns wrapped with `promise_equivalent_solutions [!:IO]`; "unique state" comment fixed.
  Compiles clean.
- [ ] `[any]` **DO NOT touch the `solutions/2` sort/dedup note** in `koans/determinism/02` —
  it is correct (Mercury's universal term order). Codex's flagged "fix" would introduce a bug.

## P2 — polish  *(all `[Sonnet]`)*

- [x] Rewrite `FIX:` comments (calculator.m, pipeline.m) as durable invariants.
- [x] Expand bare track overviews (foundations, determinism, concurrency, advanced) with arc sentences.
- [x] Standardize prereq notation; added `**After:**` to STM kata `09-stm/README.md`.
- [x] Tool-driven unused-import pass: removed `char` from anagrams.m + csv_reader.m;
  `maybe` from memoized_search.m (done with P1 fix). Compile-verified.
- [x] Demote in-prompt full implementations to optional hints (`puzzles/concurrent/02-pipeline`):
  stage bodies moved into `<details>` hint block; signatures left visible; N corrected 1000→100.
- [x] Add expected-output blocks: pipeline, sudoku, meta_interp READMEs updated.
- [x] Finish documenting sudoku's unsafe index helpers: `first_empty`, `set_cell`, `set_nth`,
  `get_row` all have precondition/invariant comments; remaining `FIX:` comments removed.
- [x] `meta_interp.m` naming: `a`→`atom`, `n`→`int_lit`, `f`→`compound`, `v`→`logic_var`,
  `c`→`rule`; `rename_2` and `apply_env_f` helpers inlined as lambdas. Compile-verified.
  Puzzle README updated to match.
- [x] Recommend explicit subpaths: solver-types README adds `**After:**` pointing to
  `01-ffi-depth` and `07-ffi-pragma-attrs` before Tasks 2 and 3.
- [x] Mark `00-reactivation/06-pure-randomness` "advanced recall; defer" — blockquote notice
  added at top of README, referencing `katas/advanced/01-ffi-depth`.
- [x] Adopt a per-format README template: `docs/TEMPLATES.md` created with canonical section
  order for koan, kata, bridge, and puzzle formats.

## P3 — scope expansion (post-release)  *(all `[Opus]` / design)*

- [ ] Finite-domain constraint-store engine to make solver types runnable (`CLP-PLAN.md`).
- [ ] Multi-module capstone (interfaces, opaque types, build definition, tests).
- [ ] A concurrency bridge; cover partial application/currying and impure-predicate design.

---

## Done (this session)

- 14 COMPILER-LESSONS koans + 3 katas (Tier 3); `foundations/20-int-comparison-import`;
  `advanced/07-solver-any-inst`; `katas/advanced/02-solver-types` rewritten; `ci.sh` gate;
  GitHub CI workflow scaffold (disabled); Ring review run; Opus 6-review pass;
  three-reviewer synthesis. Committed `c52d89a` (push pending SSH unlock).
- Already-addressed review items (do not re-action): `choice_det` comment, `get_nth` comment,
  `parallel_sort` unreachable-branch comment, pipeline-puzzle "Why Mercury" rewrite,
  csv_reader strip-policy comment, accurate root table + advanced/concurrency/tooling indexes.
