# Overall synthesis — Big Pickle

## Score: 7.5/10

The curriculum is in strong shape. The systematic bug fixes from the earlier Opus/Codex/Ring synthesis have been applied. The recent additions (koans 21–23, kata 01 rewrite, runtests improvements) are well-executed and fill specific gaps.

## What's working

- The mode and determinism tracks are best-in-class for a public Mercury resource — deeper than any other tutorial material.
- The koan format (one file, one diagnostic, one fix) is well-executed and now has 3 new IO-focus entries.
- The writing voice is direct, technical, and consistent — a genuine strength.
- Puzzle solutions compile and produce correct output for their declared test cases.
- The `ci.sh` index validation prevents the directory drift that plagued earlier versions.

## What needs attention

| Priority | Item | Effort |
|----------|------|--------|
| P0 | Bridge solution rot — solution notes are never compiled by CI. Either extract-and-compile or add a disclaimer. | {high} |
| P1 | `.err` snapshots gitignored in cinnabar — koan diagnostic verification is no-oped on fresh clones. | {high} |
| P2 | Root README "any order" claim oversimplifies dependencies. | {low} |
| P3 | Bridge "Why Mercury" sections are inconsistent (01–03, 07–10 missing them). | {medium} |
| P4 | Puzzle acceptance criteria should be explicit (input/output pairs) not just approach descriptions. | {medium} |
| P5 | Multi-module capstone exercise — the biggest conceptual gap in the curriculum. | {xhigh} |

## Summary of scores by dimension

| Dimension | Score |
|-----------|-------|
| README quality | 7.5/10 |
| Coverage | 8/10 breadth, 7.5/10 depth |
| Correctness | 7.5/10 |
| Code quality | 8/10 |
| Idiomatic Mercury | 8/10 |
| **Overall** | **7.5/10** |
