# README quality — Big Pickle

## Overall: 7.5/10

The root README communicates ambition and the ore/heat metaphor well. The per-exercise READMEs have a consistent voice. The main ceiling is uneven "Why Mercury" framing across bridges and a few stale index claims.

## Strengths

- **Root README** — clear project identity, good navigation table, well-chosen metaphor.
- **Kata READMEs** are appropriately narrow (one concept, clear start state, enough to begin without giving away the answer).
- **Puzzle READMEs** generally follow a repeatable pattern: representation → implementation steps → checkpoint → reflection.
- **Bridge 05 (mode reversal)** has the clearest "Why Mercury" framing of any exercise: "One logical relation with two checked directions." Bridge 04, 06, and 11 also do this well.

## Weaknesses

- **Bridge "Why Mercury" sections are inconsistent.** Bridges 01–03 and 07–10 go straight to "Build and run it first" without stating what checked property the exercise exposes. Every bridge should have a mechanism-specific "Why Mercury" paragraph like bridges 04–06 and 11.
- **Root README "any order" claim (line 25–27).** "Tooling, Concurrency, and Advanced can be taken in any order" oversimplifies — advanced solvers require trailing grade and FFI knowledge, concurrency depends on determinism. Should recommend sub-paths.
- **Puzzle acceptance criteria are implicit.** Several puzzles describe their approach but not exact test cases (calculator: README never says `"1 @ 2"` should fail). Should standardise on explicit input/output pairs.
- **Expected-output blocks are missing from ~half of puzzles.** Only sudoku, meta-interpreter, and pipeline have them.

## Recent improvements

- Kata 01-rewrite README is clean and minimal. The `runtests` diff-based check matches the sibling katas' spirit.
- Koans 21–23 READMEs are well-structured (broken concept → prerequisite → task → cross-reference to sibling koans).
- The `00-reactivation/README.md` now correctly explains the "no solutions" principle and lists all 7 sub-katas.
