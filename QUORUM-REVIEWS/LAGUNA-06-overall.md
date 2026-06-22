# Overall synthesis — Laguna M.1

## Score: 8/10

The curriculum is in substantially better shape than any of the earlier reviews
reflect. The three-reviewer synthesis (Opus/Codex/Ring) and subsequent Big Pickle
pass identified 15+ bugs and structural gaps; the TODO shows nearly all P0/P1
items and several P2/P3 items as completed. The current tree compiles, CI
validates index integrity and bridge snippets, `.err` snapshots are tracked,
and the most significant conceptual gap (multi-module architecture) has been
addressed with puzzle 08.

## Dimensional summary

| Dimension | Score | Key factors |
|-----------|-------|-------------|
| README quality | 7.5/10 | Strong root and koan READMEs; bridge "Why Mercury" format still inconsistent |
| Coverage | 8.5/10 breadth, 8/10 depth | Multi-module gap closed; mutable state, STM depth, library breadth still thin |
| Correctness | 8/10 | Systematic bugs fixed; CI now catches bridge rot; meta-interpreter and printer docs have minor imprecision |
| Code quality | 8/10 | Puzzle solutions are clean; bridge snippets now compiled; kata starters consistent but unreferenced |
| Idiomatic Mercury | 8/10 | Mode/determinism teaching is best-in-class; function bias and Prolog-ism residuals are minor |

## What has improved since earlier reviews

The earlier reviews (Opus ~6.5-7, Codex ~6, Ring ~7.5, consensus ~7) reflected a
pre-fix state where bridge solutions had latent bugs, puzzle acceptance criteria
were implicit, index drift was unchecked, and the multi-module gap was the most
significant missing piece. The current tree has:

- **Bridge 10/11 rewrites** that fixed deadlocks and error-swallowing
- **ci.sh §6** that extracts and compiles bridge solution snippets
- **Puzzle acceptance tables** in all 21 puzzle READMEs
- **Multi-module capstone** (puzzle 08) with 5-module config library
- **Bridge 12** (currying and impurity) filling the purity-design gap
- **`.err` tracking** via `.gitignore` negation
- **Index integrity** enforced by ci.sh `check_index` across all 9 track indexes
- **Koans 21-23** adding IO-uniqueness diagnostics
- **Systematic import/compilation fixes** across 15+ files

## Remaining priorities

| Priority | Item | Why |
|----------|------|-----|
| P1 | Bridge "Why Mercury" consistency | Every bridge should name the checked property. 01-03, 07-09 are missing it. |
| P1 | Meta-interpreter concrete failure demo | Depth-based renaming can give silent wrong answers. A demonstration test would prevent this. |
| P2 | Mutable state kata | `store`/`store_mutvar`/`io.mutvar` are not covered. One kata. |
| P2 | Generic printer `canonicalize` explanation | The erasure of type names from functors is non-obvious and undocumented in the solution. |
| P3 | Function/predicate balance in new katas | Bias toward predicates limits function-syntax practice. |
| P3 | Library depth bridge | A "choose the right container" bridge covering `queue`, `cord`, `digraph`, `rbtree`. |

## Calibration against earlier reviews

The Big Pickle review (7.5/10) was the most recent and the most accurate for its
time, but it pre-dated the multi-module capstone and the CI bridge-snippet
extraction. My 8/10 reflects that both of those fixes are now in the tree.
The Quorum review (7.5/10, same content) also pre-dates these fixes. Codex's 6/10
was a fair assessment of the pre-fix state — the current tree has addressed
every systematic issue Codex identified. Ring's 7.5/10 was too generous for the
pre-fix state but would be about right for the current tree if you factor in
the bridge rot that Ring did not catch.

## Verdict

Cinnabar is a strong B+/A- resource that is now genuinely close to being the
definitive post-tutorial Mercury curriculum. The mode and determinism tracks
are best-in-class, the koan format is well-executed, the bridge puzzles fill
real gaps, and the CI infrastructure catches regressions. The remaining issues
are polish (README consistency, documentation completeness) and minor gaps
(mutable state library coverage, STM depth) rather than structural defects.
With the five items in the priority table above addressed, this would be a
9/10 resource.
