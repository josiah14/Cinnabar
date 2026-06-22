# Overall synthesis — DeepSeek V4 Flash Free

## Score: 7.5/10

I agree with Big Pickle on the overall score but arrive there via different weights. Big Pickle gives 8/10 for code quality and idiomatic Mercury; I give 7.5/10 for both. Big Pickle gives 7.5/10 for correctness; I give 8/10. The averages converge to the same number.

This is a serious curriculum — the best post-tutorial Mercury resource in existence. The mode track, determinism track, and koan format are genuinely innovative for language pedagogy. The multi-module capstone closes the largest gap. The CI now catches bridge solution rot. The recent additions (koans 21–23, kata 01 rewrite, bridge 12) are well-executed.

## Dimensional scores

| Dimension | Big Pickle | DeepSeek | Key delta |
|-----------|-----------|----------|-----------|
| README quality | 7.5/10 | 7/10 | Reactivation sub-katas lack individual READMEs; kata "Why Mercury" sections absent |
| Coverage breadth | 8/10 | 8/10 | Agree |
| Coverage depth | 7.5/10 | 7/10 | Several tracks plateau before fluency; no IO design patterns |
| Correctness | 7.5/10 | 8/10 | Post-fix state is genuinely clean; bridge snippet CI resolves rot issue |
| Code quality | 8/10 | 7.5/10 | Combinator library conflates error cases; bridge solution convention is fragile; runtests inconsistency |
| Idiomatic Mercury | 8/10 | 7.5/10 | `fail` for `failure` in combinators is a Prolog-ism; predicate bias is deeper than assessed |
| **Overall** | **7.5/10** | **7.5/10** | Convergent score, divergent reasoning |

## What holds it back from 9/10

1. **Kata "Why Mercury" framing is absent.** Every kata describes the concept but rarely explains why Mercury's treatment differs from other languages. The determinism katas are the biggest miss: "In most languages determinism is a runtime property; in Mercury it is a compile-time contract" should be the first sentence of every determinism kata README. Without this framing, a learner can complete all 7 determinism katas and still not understand what makes Mercury's approach distinctive.

2. **Reactivation sub-katas are under-documented.** The 00-reactivation track has 7 sub-katas but only 01-hello-world has an individual README. The remaining 6 (maybe, maps/sets, purity, array threading, pure randomness, DCG warm-up) have at most a line in the parent README. A learner landing directly on `02-maybe/` gets a `start.m` and no context.

3. **Function/predicate balance is skewed.** The curriculum is predicate-heavy to the point where learners may not recognize when functions are the idiomatic choice. The config parser and bridge 12 are the exceptions that prove the rule. A kata titled "when to use a function vs a predicate" would address this directly.

4. **Bridge solution convention is patched, not solved.** The ci.sh snippet extraction works for simple cases but fails on fragment snippets and modules outside the default import set. Bridge 12's snippets fail CI (known, acknowledged). The durable fix is `solution/*.m` files per bridge, with the README referencing them. The extraction approach is clever engineering — and the TODO was right to implement it quickly — but it is not a permanent architecture.

5. **No concurrency debugging exercise.** The concurrency track covers both `&` and `thread.spawn` models, STM, and channels. But there is no exercise where the learner must diagnose a real deadlock or race condition. The koans use mode/determinism errors for their diagnostics; a concurrency koan that requires recognizing a deadlock pattern from compiler output or runtime behavior would add depth that no current exercise provides.

## What no other Mercury resource does better

- **Mode + determinism as a unified checked property.** The inst hierarchy kata, clause selection kata, and determinism lattice kata form a progression that no other public Mercury resource attempts. This is the curriculum's crown jewel.
- **Compiler diagnostic pedagogy.** 76 koans, each with one focused diagnostic, one fix, and one explanation. The `.err` snapshot verification (when `.gitignore` allows it) is an innovation in CI-driven language teaching.
- **Multi-format repetition.** A learner encounters determinism in 7 katas, 8 koans, 1 bridge, and 3+ puzzles. The repetition across formats, not within them, is where fluency forms. The curriculum deliberately designs for this, and it works.
- **Honest labelling of ecosystem limitations.** The solver-types kata is correctly marked as conceptual-only. The `CLP-PLAN.md` is documentary, not curriculum-padding. The root README's "Pre-alpha work in progress" banner is accurate and appropriately humble.

## Most impactful next actions

| Priority | Action | Rationale |
|----------|--------|-----------|
| P0 | Fix bridge snippet CI false positives (expand import heuristic or add `solution/*.m` files) | CI noise erodes trust; bridge 12 failures are a known regression |
| P0 | Verify `.err` negation rules work on fresh clone | Koan diagnostic verification is the most innovative CI feature; if it is no-oped, the entire koan format loses its automated quality gate |
| P1 | Add individual READMEs to reactivation sub-katas 02–07 | Each is a 5-minute prose task; the 6 together close a documentation gap that affects every learner starting the foundations track |
| P2 | Add "Why Mercury" framing paragraph to kata READMEs | Highest-leverage prose investment: ~70 katas, each getting 2–4 lines of distinctive-value framing |
| P3 | Add a function-vs-predicate kata or bridge | Directly addresses the largest idiomatic gap |
| P4 | Replace `fail` body with empty body in `combinators.m:28` | Teaches the wrong determinism lesson |

## Final assessment

Cinnabar is a B+/A- project with genuine pedagogical innovation — the mode/determinism tracks and koan format are contributions to language teaching, not just to Mercury. The post-fix state is the cleanest the codebase has been. The remaining issues are documentation completeness (kata framing, reactivation READMEs), a fragile-but-functional CI patch (bridge snippets), and idiomatic consistency (function/predicate balance, Prolog-isms). None of these are release blockers. All are addressable with focused effort.

**Rating: 7.5/10 — the definitive post-tutorial Mercury curriculum. The mode/determinism tracks are essential reading for any serious Mercury learner. Complete in order with the understanding that bridge solution notes are design sketches verified by CI but not equivalent to compiled reference implementations. The multi-module capstone (puzzle 08) should be required for anyone who wants to ship Mercury packages.**
