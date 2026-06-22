# TODO

Backlog derived from the four-model quorum synthesis (2026-06-21).
Source of truth and full reasoning: [`REVIEWS-SYNTHESIS/SYNTHESIS.md`](REVIEWS-SYNTHESIS/SYNTHESIS.md).
Individual passes in `QUORUM-REVIEWS/` (Big Pickle, Codex, DeepSeek, Laguna).

**Model-fit tags:**
- `[Opus]` — needs correct Mercury determinism/mode/type reasoning where a wrong fix
  silently propagates an authoritative error. Do these in the nix devShell, compile-verified with `mmc`.
- `[Sonnet]` — mechanical/editorial, clear acceptance criteria.
- `[DeepSeek]` — daily coding & Mercury fixes (79% SWE-bench).
- `[Big Pickle]` — orchestrator tasks, simple edits, script changes, reviews.
- `[User]` — interactive infra (SSH/keys) the model can't do; or needs `nix develop` access.
- `[any]` — any agent can pick it up; no special reasoning needed.

**Effort tags:**
- `{low}` — trivial, no `mmc` needed.
- `{medium}` — straightforward edit; verify with `mmc`.
- `{high}` — concrete refactor with clear acceptance criteria.
- `{xhigh}` — non-local correctness reasoning.
- `{max}` — open-ended research; must compile-fail/compile-pass for *exactly* the intended reason.

**Hard rule for any code/contract item:** work inside `nix develop` and verify with `mmc` —
koans must still fail for the documented reason, solutions/katas/bridges/puzzles must still
compile. "Looks plausible" is not done.

---

## P0 — trust (CI + navigation)

- [x] `[Big Pickle]` `{medium}` **Fix CI snapshot mismatch to FAIL.**
  `ci.sh:66-74`: when `all_found=false` (diagnostic differs), it now increments `fail`/appends to
  `failures` instead of incorrectly passing. *(Codex P1→P0; SYNTHESIS §3.1)*

- [x] `[Big Pickle]` `{medium}` **Fix Bridge 12 snippet CI failures.**
  `ci.sh §6` — expanded `BRIDGE_STD_IMPORTS` to cover `float`. *(DeepSeek P0; SYNTHESIS §3.3)*

- [x] `[Big Pickle]` `{low}` **Narrow `.gitignore` `!**/solution/*.err`.**
  Removed `!**/solution/*.err` — `compile_fail` never reads `.err` files from `solution/`
  directories (it reads `$dir/$module.err` for koans). Solution `.err` files are transient
  compiler logs, not tracked. *(Codex P1; SYNTHESIS §3.2)*

- [ ] `[User]` `{low}` **Enable CI workflow.**
  GitHub Actions workflow is `if: false`. Enabling it needs the flake SSH input `mise` wired
  up. Interactive infra — agent cannot do. *(Carried from old TODO.)*

- [ ] `[User]` `{low}` **Run `ci.sh` inside `nix develop` and verify.**
  All editorial fixes from old TODO are applied. Run the full gate and confirm clean pass
  (after P0 items 1–3 above). *(Carried from old TODO.)*

## P1 — correctness + documentation

- [x] `[Sonnet]` `{medium}` **Bridge "Why Mercury" sections: add to bridges 01–03, 07–09, 12.**
  Added mechanism-specific `**Why Mercury:**` blocks to bridges 01, 02, 03, 07, 08, 09 (after
  the `**After:**` line, bridge 05's format). Bridge 12 already had one — left as is.
  *(All 4 models; SYNTHESIS §1.4)*

- [x] `[Sonnet]` `{low}` **Root README "any order" → sub-path recommendations.**
  Replaced the "any order" line with "Tooling → Concurrency → Advanced; within Advanced,
  01 (FFI) → 02 (solver) → 03–07 (any order)." *(All 4 models; SYNTHESIS §1.5)*

- [x] `[Sonnet]` `{medium}` **Reactivation sub-katas 02–07: add individual READMEs.**
  Already done — `02-fibonacci` through `07-zookeeper-puzzle` each carry a complete
  predict/verify one-pager in the `01-hello-world` style. No new pages needed.
  *(DeepSeek P1; SYNTHESIS §2.11)*

- [x] `[Sonnet]` `{low}` **Bridge 10 README: choose "lost-work" semantics explicitly.**
  Added a "Delivery semantics: this is lost-work, not at-least-once" note to Task 4 of the
  bridge 10 README, stating the in-flight item is not retried and pointing to the solution
  notes for why the skip falls out of the take/throw ordering. *(BP + Laguna; SYNTHESIS §3.4)*

- [ ] `[User]` `{low}` **Verify error-message quoting in koan READMEs against actual `mmc`.**
  Some koan READMEs paraphrase compiler output rather than quoting verbatim. Run koans through
  `mmc` in the dev shell and update any paraphrased quotes to verbatim transcripts. *(Laguna;
  SYNTHESIS §3.5)*

## P2 — polish

- [x] `[Sonnet]` `{low}` **Link TEMPLATES.md from track READMEs.**
  Added an "Adding a …? See `docs/TEMPLATES.md`" footer to the 4 format READMEs
  (katas/koans/puzzles/bridge) and all 8 kata track READMEs, each naming its template.
  *(Laguna; SYNTHESIS §1.9)*

- [x] `[Big Pickle]` `{low}` **Fix parser quadratic append.**
  `parser.m:28-35`: `Acc ++ [Key - Val]` → `[Key - Val | Acc]` with a single `reverse` on
  success. Interface unchanged — consumers unaffected. *(Codex; SYNTHESIS §2.15)*

- [x] `[Sonnet]` `{low}` **Document generic printer `canonicalize` erasure.**
  Added a "Type-name erasure" section to the solution README: `deconstruct` returns the
  constructor's functor name + arity but erases the owning type, so `yes(yes(42))` is worked
  from `yes/1` and `type_of`/`type_name` is what recovers the type. *(Laguna; SYNTHESIS §2.13)*

- [x] `[Sonnet]` `{medium}` **Meta-interpreter: add concrete failure demo for depth version.**
  Already done (option a) — `capture_prog` in `meta_interp.m` is the minimal capture trigger,
  `main` runs it under "variable freshness" as a regression guard, and the solution README
  carries the mmc-verified `false`-vs-`test(7, 9)` contrast table. *(Laguna; SYNTHESIS §2.14)*

- [x] `[Sonnet]` `{medium}` **Add "Why Mercury" framing to determinism kata READMEs.**
  Added a `**Why Mercury:**` opener to all 7 determinism katas (01–07), each leading with the
  "runtime property vs. compile-time contract" line plus a kata-specific tie-in. Extension to
  other kata tracks left as optional follow-up. *(DeepSeek; SYNTHESIS §2.16)*

- [x] `[Opus]` `{high}` **`combinators.m:28`: replace `fail` body with empty body — REJECTED, reviewers were wrong.**
  mmc-verified: `empty(_, _, _).` does **not** compile under `:- mode empty(out, in, out) is failure` —
  a fact body asserts success and must bind the `out` arg, giving `mode error: argument 2 did not get
  sufficiently instantiated` (`HeadVar__1` `free`, expected `ground`). The `:- fail.` body is correct
  and required: with no success path the output is legitimately unbound. Kept `:- fail.`, added a durable
  explanatory comment in `combinators.m`, a "The `empty` predicate" expansion in the solution README, and
  a new Mode-system lesson in `COMPILER-LESSONS.md`. *(All 4 models flagged this; all 4 were mistaken about
  Mercury — the `[Opus]` "wrong fix silently propagates" case. SYNTHESIS §1.6)*

## P3 — scope expansion (post-release)

- [x] `[Opus]` `{xhigh}` **Function-vs-predicate kata or bridge.**
  Added `katas/mode-system/09-func-vs-pred/` (start.m + README + runtests, index row added).
  Three forced cases — total/det (func), partial/semidet (pred vs maybe-returning func),
  multi-valued/nondet (pred only) — plus a pointer to `05-mode-specific-clauses` for reverse
  modes and `bridge/12` for currying. Stub compiles; worked reference verified green via `mmc`.
  *(DS, Laguna)*

- [x] `[Opus]` `{high}` **IO design patterns kata.**
  Added `katas/foundations/12-io-patterns/` (start.m + README + runtests, foundations index
  row added → 13; root README chart 12→13). Three exercises: `read_lines` (the ok/eof/error
  three-way read loop folded into `io.res(list)`), `load_lines` (open/read/close with
  error-as-value propagation + the missing-file → error(_) path), and a pure `count_nonblank`
  (IO-vs-logic separation). Hermetic: `main` writes a fixture, runs the checks, removes it.
  Stub start.m compiles & runs (4 expected FAILs); identical-structure reference verified
  build+run all-PASS via `mmc` (asm_fast.par.gc.stseg). *(DeepSeek)*

- [x] `[Opus]` `{xhigh}` **Mutable state kata (`store`/`store_mutvar`/`io.mutvar`).**
  Added `katas/advanced/08-mutable-state/` (start.m + README + runtests, index row added).
  Covers `store(S)` heaps with `generic_mutvar` threaded `di`/`uo` (private `!S` and io-tied
  `!IO`), the `<= store.store(S)` helper constraint, the uniqueness-as-compile-error story
  (real mode-error message quoted), and when a pure accumulator is the better tool. Stub
  compiles; worked reference verified green via `mmc`. *(DS, Laguna)*

- [ ] *(see `CLP-PLAN.md`)* **Solver types / CLP(FD) engine.**
  The solver-types kata is correctly marked conceptual-only. `CLP-PLAN.md` tracks the
  ecosystem path. No curriculum action needed beyond what the kata already does. *(Carried.)*

## Advisory (no effort required, awareness only)

- [ ] `[any]` **DO NOT touch `solutions/2` sort/dedup note.**
  `koans/determinism/02-nondet-in-det/solution/README.md` — Mercury's universal term order
  guarantees sorted, deduplicated results from `solutions/2`. This is correct. Codex's earlier
  flagged "fix" would introduce a bug. *(Old TODO, reaffirmed by synthesis.)*
