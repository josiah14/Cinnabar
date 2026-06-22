# Cinnabar quorum synthesis (2026-06-21)

*Synthesized by Big Pickle from four independent review passes:*

- **Big Pickle** (`QUORUM-REVIEWS/01-06`) — self-review, 7.5/10 overall.
- **Codex** (`QUORUM-REVIEWS/CODEX-01-06`) — harshest grader, line-cited, 7/10 overall. Verified CI behavior directly (ran dev-shell CI).
- **DeepSeek V4 Flash Free** (`QUORUM-REVIEWS/DEEPSEEK-01-06`) — most thorough code-quality analysis, 7.5/10 overall.
- **Laguna M.1** (`QUORUM-REVIEWS/LAGUNA-01-06`) — most generous, 8/10 overall. Best coverage assessment.

**This is a NEW synthesis.** The earlier `SYNTHESIS.md` (2026-06-19, by Opus) adjudicated a different review set (Opus/Codex/Ring) and described a pre-fix state. The present document adjudicates the current 4-model quorum, which reviewed the post-fix tree — nearly all bugs from the earlier cycle are resolved.

---

## Scorecard

| Dimension | Big Pickle | Codex | DeepSeek | Laguna | **Adjudicated** |
|-----------|-----------|-------|----------|--------|-----------------|
| README quality | 7.5/10 | 7/10 | 7/10 | 7.5/10 | **~7/10** |
| Coverage breadth | 8/10 | 8/10 | 8/10 | 8.5/10 | **8/10** |
| Coverage depth | 7.5/10 | 7.5/10 | 7/10 | 8/10 | **~7.5/10** |
| Correctness | 7.5/10 | 6.5/10 | 8/10 | 8/10 | **7.5/10** |
| Code quality | 8/10 | 7.5/10 | 7.5/10 | 8/10 | **~7.5/10** |
| Idiomatic Mercury | 8/10 | 8/10 | 7.5/10 | 8/10 | **8/10** |
| **Overall** | **7.5/10** | **7/10** | **7.5/10** | **8/10** | **~7.5/10** |

### Score adjudication notes

- **Correctness (6.5–8 spread).** Codex's 6.5 is driven by a real CI bug (snapshot mismatch prints "PASS" — see §3.1). DeepSeek and Laguna score 8/10 for post-fix code state, treating CI as infrastructure not content. Ruling: 7.5/10 — CI is part of the deliverable; a gate that doesn't gate should be fixed, but it doesn't make the curriculum itself wrong.

- **Coverage depth (7–8).** DeepSeek's 7 is the outlier, driven by "plateau before fluency" in several tracks. Laguna's 8 credits the multi-module capstone, bridge 12, and koans 21–23. Ruling: 7.5/10 — the new additions close real gaps, but IO design patterns and mutable state remain uncovered.

- **Code quality (7.5–8).** DeepSeek found more concrete issues in the combinator library (conflated error cases, dead output) than Big Pickle or Laguna accounted for. Ruling: 7.5/10 — DeepSeek's combinator analysis is the most thorough.

---

## 1. Consensus findings (all 4 reviewers, or uncontested)

Highest confidence. Fix first.

1. **Mode + determinism tracks are best-in-class.** The inst hierarchy kata, clause selection kata, and determinism lattice kata form a progression no public Mercury resource attempts. This is the curriculum's crown jewel.

2. **Koan format is innovative.** "One file, one diagnostic, one fix" across 76+ files. The `.err` snapshot verification (when git tracks them) is a genuine CI+pedagogy innovation.

3. **Multi-module capstone (puzzle 08) closes the biggest gap.** Five-module config library with opaque types, `use_module` vs `import_module`, and a clean DAG build. All reviewers agree this was the most significant missing piece.

4. **Bridge "Why Mercury" sections are inconsistent.** Bridges 01–03, 07–09, and 12 lack mechanism-specific framing. Bridge 05 is the exemplar — every bridge should name the checked property.

5. **Root README "any order" claim is misleading.** "Tooling, Concurrency, and Advanced can be taken in any order" ignores that solver types need FFI, concurrency needs determinism, and the advanced track has internal ordering. Fix: replace with concrete sub-path recommendations.

6. **`combinators.m:28` — `fail` for `failure` is a Prolog-ism.** `empty(_, _, _) :- fail.` should use `is failure` determinism with an empty body. The `fail` goal teaches the wrong lesson in a resource that should demonstrate Mercury's determinism system.

7. **Function/predicate balance is skewed.** The curriculum is predicate-heavy. Learners practice the clunky form and may not internalize when functions are better. Bridge 12 (currying) is the exception.

8. **Bridge 10 acceptance criteria underspecified.** The puzzle README uses both "at-least-once" and "lost-work" semantics without choosing one. The solution admits lost work. State the trade-off explicitly.

9. **Bridge solution convention is the weakest structural decision.** The `ci.sh` snippet extraction (§6) is a clever patch but not a durable solution: it fails on fragment snippets, incomplete import heuristics (Bridge 12 `float`), and missing blocks count verification.

10. **CI provides index integrity and compilation gates.** `check_index()` catches directory drift. Compilation gates prevent the worst rot. This is a genuine improvement over the pre-CI state.

---

## 2. Majority findings (3 of 4, or strong 2)

Medium-high confidence.

11. **Reactivation sub-katas 02–07 lack individual READMEs.** `01-hello-world` has one; `02-maybe` through `07-*` have at most a line in the parent README. (BP, DS, Laguna flag this; Codex silent.)

12. **`.err` diagnostic snapshots are fragile to compiler version changes.** No compiler-version pinning. A different `mmc` version may change error message text. (DS, Laguna; BP silent, Codex flags CI handling not versioning.)

13. **Generic printer `canonicalize` erasure is undocumented.** `yes(yes(42))` prints as `yes/1`, not `yes(yes(42))/1`. The solution does not explain this. (Laguna, DS; BP silent.)

14. **Meta-interpreter freshness: depth version as on-ramp still lacks concrete failure demo.** The counter-based fix is implemented and verified, but the puzzle README still presents the depth version as the starting point without a test that demonstrably fails because of it. (Laguna, BP; Codex rates fix sound.)

15. **Parser quadratic append.** `parser.m:28-35` uses `Acc ++ [Key - Val]` — should use `[Key - Val | Acc]` with final reverse. (Codex, DS; BP/Laguna silent.)

16. **Kata READMEs lack "Why Mercury" framing.** Determinism katas are the biggest miss: "In most languages determinism is a runtime property; in Mercury it is a compile-time contract" should be the first sentence. (DS, BP; Codex flags it narrower.)

---

## 3. Contested findings — adjudicated

### 3.1 CI snapshot mismatch does NOT fail CI — **Codex is CORRECT; fix this**

`ci.sh:66-74` prints `PASS (broke, diagnostic differs ...)` and still increments `pass`. Codex labels this P1; I (Big Pickle) confirm the code. DeepSeek and Laguna did not flag it — a miss. **Ruling: the snapshot mismatch should increment `fail`, not `pass`.** This undermines the claim that CI verifies diagnostic output.

### 3.2 `.gitignore` `!**/solution/*.err` is too broad — **Codex is correct; narrow it**

The negation rule un-ignores all `solution/*.err` files, exposing transient compiler logs. `compile_fail` only reads `$dir/$module.err` for koan files (never in `solution/`), so the broad exception is unnecessary. **Ruling: narrow to `!**/*_koan.err` only.** Remove the `!**/solution/*.err` line unless a concrete need for solution `.err` snapshots arises.

### 3.3 Bridge 12 snippet CI failures — **DeepSeek is correct; fix CI imports**

Bridge 12's `mercury` code blocks fail `ci.sh §6` because the heuristic import set omits `float`. The TODO acknowledges this as "known broken gate." **Ruling: expand the heuristic import set** to cover all library modules used in bridge snippets. The lazy option: `io, int, string, list, maybe, char, bool, exception, require, float, map, set, version_array, channel, thread, thread.semaphore, univ, unit` covers every known bridge. Better option: auto-detect imports from `:- import_module` declarations in the snippet content (the code already tries this — fix the fallback).

### 3.4 Bridge 10 "at-least-once vs lost-work" — **Big Pickle + Laguna are correct; it's still underspecified**

The solution was fixed (real restart loop, sentinel counting), but the README still uses both phrases without choosing. DeepSeek also flags this. **Ruling: the puzzle README should state "lost-work semantics (items in flight when a worker crashes are not retried)."**

### 3.5 Templated error message quoting — **Laguna is correct; verify and fix**

Laguna notes that koan READMEs quote compiler output from memory rather than verbatim transcripts. Small wording differences between Mercury versions could produce false mismatches. **Ruling: re-verify error messages against the actual `mmc` in the nix dev shell** and update any paraphrased quotes to verbatim. This is a `[User]` task (needs `nix develop` access).

---

## 4. What each reviewer missed

### Big Pickle missed
- CI snapshot mismatch not failing CI (Codex caught it; I should have caught my own CI code).
- Broad `.gitignore` solution exception polluting worktree (Codex).
- Parser quadratic append (Codex).
- TEMPLATES.md not linked from READMEs (Laguna).
- Error-message quoting is paraphrased (Laguna).

### Codex missed
- Root puzzle index logic row is **already fixed** (claimed P2, but the README now includes it).
- Bridge 10 acceptance criteria still ambiguous (did not re-check after fix pass).
- Reactivation sub-katas lack individual READMEs (DeepSeek).
- Kata "Why Mercury" framing absent (DeepSeek).
- `.err` fragility to compiler version (DeepSeek, Laguna).

### DeepSeek missed
- CI snapshot mismatch not failing CI (Codex).
- `.gitignore` solution `.err` broadness (Codex).
- Generic printer `canonicalize` erasure undocumented (Laguna).
- TEMPLATES.md not linked (Laguna).

### Laguna missed
- CI snapshot mismatch not failing CI (Codex).
- `.gitignore` solution `.err` broadness (Codex).
- Bridge 12 snippet CI failures (DeepSeek — Laguna said "all 12 bridges pass," which is wrong for the snippet check).
- Parser quadratic append (Codex).
- Reactivation sub-katas lack individual READMEs (DeepSeek).

---

## 5. Calibration notes

- **Codex** is the most valuable reviewer for CI correctness and git hygiene. Its 6.5/10 correctness score over-weighs infrastructure bugs that do not affect curriculum content, but the individual findings are real.
- **DeepSeek** is the most valuable for code quality and idiomatic Mercury. Its combinator library analysis is the most thorough. It is less reliable on README polish items (over-weights reactivation sub-katas).
- **Laguna** is the most generous scorer and the best reviewer of coverage. Its 8/10 reflects genuine improvements but under-weights the CI and code-quality issues that Codex and DeepSeek found.
- **Big Pickle** (self-review) sits in the middle. Most accurate on the curriculum's pedagogical structure; weakest on CI implementation details (should have caught the snapshot bug).

---

## 6. Priority action backlog

### P0 — trust (CI + navigation)
1. **Fix CI snapshot mismatch to FAIL.** Change `ci.sh:66-74` so diagnostic difference increments `fail` and appends to `failures`. Either regenerate stale snapshots or remove the check. *(Codex P1 → P0; §3.1)*
2. **Fix Bridge 12 snippet CI failures.** Expand heuristic import set to cover `float` (and any other missing module). Verify all 12 bridges pass `ci.sh §6` cleanly. *(DeepSeek P0; §3.3)*
3. **Narrow `.gitignore` `!**/solution/*.err`** to `!**/*_koan.err` only. *(Codex P1; §3.2)*
4. **Enable CI workflow** (`[User]` — needs SSH/mise wiring). *(Carried from old TODO.)*

### P1 — correctness + documentation
5. **Bridge "Why Mercury" sections for 01–03, 07–09, 12.** Every bridge should name the checked property. Follow bridge 05's format. *(All 4; §1.4)*
6. **Root README "any order" → sub-path recommendations.** Replace line 27 with concrete ordering. *(All 4; §1.5)*
7. **Reactivation sub-katas 02–07: add individual READMEs.** Each needs a 5-minute one-pager. *(DeepSeek P1; §2.11)*
8. **Bridge 10 README: choose "lost-work" semantics explicitly.** *(BP + Laguna; §3.4)*
9. **Verify and fix error-message quoting in koan READMEs** against actual `mmc` output. *(Laguna; §3.5)*

### P2 — polish
10. **Link TEMPLATES.md from track/format READMEs.** *(Laguna; §1.9)*
11. **Fix parser quadratic append.** `parser.m:28-35`: `[Key - Val | Acc]` + final reverse. *(Codex; §2.15)*
12. **Document generic printer `canonicalize` erasure** in solution README. *(Laguna; §2.13)*
13. **Add concrete failure demo for meta-interpreter depth version** (or rename on-ramp to counter version). *(Laguna; §2.14)*
14. **Add kata "Why Mercury" framing** to determinism katas (at minimum). *(DeepSeek; §2.16)*

### P3 — scope expansion (post-release)
15. **Function-vs-predicate kata or bridge.** *(DeepSeek, Laguna)*
16. **IO design patterns kata** (file I/O, `io.res`, reading lines). *(DeepSeek)*
17. **Mutable state kata** (`store`/`store_mutvar`/`io.mutvar`). *(DeepSeek, Laguna)*
18. **Solver types / CLP** — tracked in `CLP-PLAN.md`. *(Carried from old TODO.)*

### Advisory (no effort required)
19. **DO NOT touch `solutions/2` sort/dedup note** — Codex's earlier flagged "fix" is incorrect; Mercury's universal term order guarantees sorted, deduplicated results. *(Old TODO, reaffirmed.)*
