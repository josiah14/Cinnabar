# Cinnabar overall assessment: BIG-PICKLE synthesis

## Final rating: 7.5/10

This is a serious Mercury curriculum — the most thorough post-tutorial resource for the language that exists in public. It covers nearly every language feature through four complementary exercise formats with a well-considered difficulty progression. The recent fix pass (bridge 10/11 rewrites, index-drift correction, parser-contract tightening, determinism kata expansion, existential construction fix) addressed nearly every P0 and P1 issue identified across three earlier review passes. What remains are design-level choices and durability gaps rather than bugs.

## Dimensional summary

| Dimension | Score | Verdict |
|---|---|---|
| **01-readme-quality** | 7/10 | Track READMEs are clear and well-structured; katan/koan READMEs lack content; root README undersells the curriculum's actual depth |
| **02-coverage** | 7.5/10 | Breadth is 8+, depth in mode/determinism tracks is exceptional; solver types are conceptual-only, multi-module capstone absent |
| **03-correctness** | 7.5/10 | Post-fix state is clean for compiled puzzles and koans; bridge solution rot is invisible to CI; `.err` snapshots gitignored, so koan diagnostic verification is no-oped on fresh clones |
| **04-code-quality** | 8/10 | Puzzle solutions are clean, well-commented, correct Mercury; kata starters are consistent; bridge solutions are notes-only and never compiled — the weakest link |
| **05-idiomatic-mercury** | 8/10 | Mode/determinism annotations are exemplary; some Prolog-era patterns survive; function/predicate balance leans too far toward predicates; single-module ceiling |

## What this curriculum does better than any other Mercury resource

1. **Mode + determinism as a unified checked property.** No other public curriculum teaches the inst hierarchy, committed choice semantics, determinism propagation through call chains, and clause selection as an interconnected system. This is Mercury's real differentiator from Prolog, and cinnabar is the only resource that drives it home through exercises rather than prose.

2. **Repetition across formats for fluency.** Katas drill one concept. Koans teach one diagnostic. Bridges combine concepts in constrained extension tasks. Puzzles require full design. A learner who works through all four formats for a given topic (say, determinism) encounters it in 7 katas, 8 koans, 1 bridge, and 3+ puzzles that use it — the repetition is deliberate and pedagogically effective.

3. **Compiler diagnostic pedagogy.** The koan format (broken file + expected error + repair) is uniquely Mercury-appropriate because the compiler's error messages are unusually precise (determinism errors, mode errors, inst errors). Teaching learners to read and trust those messages is the fastest path to fluency, and no other Mercury resource does it systematically.

4. **Truth in advertising.** The READMEs accurately describe prerequisites. The root REVIEW.md and COMPILER-LESSONS.md exist. The CI is real and runs on commits (when the flake input is wired up). The TODO.md tracks known issues transparently. The earlier reviews are preserved for comparison. This level of project hygiene is rare in educational repos.

## What holds it back from 9+/10

1. **Bridge solution rot is structurally invisible.** The notes-only bridge convention means solution snippets are never compiled. Bridge 11 had four latent bugs discovered during the fix pass. Until `ci.sh` extracts and compiles code blocks from bridge solution READMEs, this will recur silently. This is the single highest-ROI durability improvement.

2. **Katas lack reference solutions.** Only 1 of ~70 katas has a solution file. The design choice (katas are muscle-memory drills, not puzzles) is defensible, but it means self-study learners who get stuck have no canonical answer. A `solution/` directory with one compiled solution per kata would substantially increase the curriculum's standalone value.

3. **No multi-module capstone.** Every exercise is a single module. Module design, interface/implementation boundaries, `use_module` vs `import_module`, `.mh` files, and multi-module build setup are covered in one foundations kata and never applied again. A learner who finishes cinnabar can solve a problem in Mercury but cannot architect a Mercury package.

5. **Koan diagnostic snapshots are not tracked.** The `.err` files that enable CI to verify koans fail for the right reason are gitignored. On a fresh clone, CI skips diagnostic verification entirely. This is a correctness gap in the CI pipeline that should be fixed with git exclude rules before the next release.

## Comparison to earlier reviews

| Reviewer | Score | Their emphasis | Big Pickle delta |
|---|---|---|---|
| **Opus** | ~6.5-7/10 | Identified contract bugs, missing determinism depth, import errors | Agreed on bugs (now fixed); underrated the mode track depth and the conceptual value of the koan format |
| **Codex** | ~6/10 (harshest) | Line-cited corrections, import hygiene, prolog-isms | Harshest on the pre-fix state; many corrections applied; some critiques (e.g., `solutions/2` sort order) were wrong and acknowledged as such in synthesis |
| **Ring** | ~7.5/10 (most lenient) | Praised the ambition, missed several real defects (bridge 10, bridge 11 bugs) | Overgenerous on bridge correctness; correctly flagged the multi-module gap as significant |
| **Synthesis** | 7/10 (adjudicated) | Adopted 2/3 Opus positions, 1/3 Codex mode-track position | In agreement on the post-fix state; synthesis is the most balanced of the prior assessments |

The synthesis score of 7/10 reflected the pre-fix state. My 7.5/10 reflects the current state after the bridge 10/11 rewrites, determinism kata expansion (05, 06), index-drift correction, and existential construction fix. Without those fixes, the score would be ~6.5/10.

## Most important actions by impact

| Priority | Action | Impact |
|---|---|---|
| P0 | Add `.err` negation rules to `.gitignore` so koan diagnostics are tracked by git | CI correctness for koan verification |
| P0 | Extract and compile fenced code blocks from bridge solution READMEs in `ci.sh` | Eliminates the only uncatchable rot vector |
| P1 | Write solution `.m` files for katas (can be done incrementally, one track at a time) | Enables self-study without a tutor |
| P2 | Add a multi-module capstone puzzle | Closes the largest architectural gap |
| P3 | Standardise puzzle READMEs with explicit acceptance test cases | Clarifies what "done" means per puzzle |

## Final assessment

Cinnabar is a B+/A- project with real ambition and solid execution. Its strengths (mode/determinism depth, koan diagnostics, multi-format repetition, four-track alignment) are playbook-worthy for language curriculum design. Its gaps (bridge rot, kata solutions, multi-module) are the predictable result of a single-author project reaching the limits of solo capacity. With the CI fully wired (mise input resolved) and the five actions above addressed, it would be an A-grade resource — the definitive Mercury curriculum for post-tutorial learners.

**Rating: 7.5/10 — recommended with reservations. If you are learning Mercury after the first tutorial, work this curriculum in order and treat bridge solution code as provisional. The mode/determinism/parsing tracks are the best Mercury teaching material I have seen. The multi-module gap means you will want a project of your own to develop fluency in module design.**
