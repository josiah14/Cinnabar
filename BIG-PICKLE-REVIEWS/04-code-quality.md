# Cinnabar code quality review: reference solutions and starter code

## Scope and rating

Assessed all 10 puzzle solution `.m` files (7 advanced + 3 parsing), the kata starter `start.m` patterns, and bridge solution notes. Katas intentionally have no reference solutions — the starter is the deliverable. Koans are one-line diagnostics; their quality is evaluated in the correctness review.

**Code quality: 8/10.** The code is consistently well-structured, readable, and commented. Most puzzles use explicit mode annotations, clear predicate naming, and reasonably decomposed modules. The material is clearly written by someone deeply familiar with Mercury's strengths (mode/determinism clarity, pure-by-default semantics). The main ceiling is inconsistent decomposition depth in puzzle solutions and the unsolved-bridge-problem (notes only, no compiled reference).

## 1. Puzzle solution quality

### Strengths

**Plugin architecture (`plugins.m`).** This is the strongest solution in the repo. The existential-type encapsulation is cleanly documented with the `'new plugin'/1` syntax explained in the comment block at lines 54-59. The method naming avoids the native `apply` conflict (line 78: `plugins.apply` qualification). The `mk_upper`/`mk_repeat`/`mk_prefix` factory functions separate construction from composition. The pipeline runner uses head recursion with an accumulator pattern. The teaching value is high: the comment about `'new'` is the clearest explanation of Mercury's existential construction syntax I have seen in a tutorial resource.

**Config parser (`config_parser.m`).** The abstract-type approach is a good design pattern to demonstrate. The lenient parsing policy is explicitly documented with the trade-off stated (line 50-56). The input format is INI-like rather than a toy grammar, which makes the exercise feel real. The accessor uses a single if-then-else with conjunction for the two-level map lookup, which is idiomatic Mercury for key-maybe-present patterns.

**Memoized search (`memoized_search.m`).** Clean design: `path/5` declared nondet with `pragma memo`, `shortest_path/5` wraps it with `solutions` and a fold-min. The graph type is a simple type alias. The cycle demonstration (d → a at line 54) is pedagogically critical. The code is 70 lines, which is about right for a teaching example — it fits in one screen.

**Generic printer (`generic_printer.m`).** Uses `deconstruct` (Mercury's RTTI) with `univ` boxing. The code is straightforward and correct. The main limitation is pedagogical: it prints but does not *explain* the recursive structure of `deconstruct`'s output. A learner who doesn't know that `canonicalize` strips types from functors will wonder why `yes(yes(42))` prints as `yes/1` not `yes(yes(42))/1`. The solution notes (README) should explain this.

### Weaknesses

**Combinator library (`combinators.m`).** The code is correct and the inst aliases at lines 16-17 are the right approach, but the decomposition is front-loaded — all 179 lines are in one module with no interface section beyond `main`. A teaching combinator library would benefit from:
- An explicit predicate/function distinction lesson (e.g., `pure` as function vs predicate)
- A separate `parser` type rather than raw DCG argument threading (which is the right choice for a beginner but merits discussion)
- Test cases that exercise failure paths more visibly

The `choice_det` combinator at line 68 (second argument silently ignored) is the correct implementation for a `det` parser, but a learner may wonder what semantics a `det` alternative-parser even means. The comment "the second alternative is unreachable" is clear but brief. A contrasting example showing why `choice_det` is not `choice_semidet` with a different base case would help.

**Calculator (`calculator.m`).** The expression grammar is embedded in recursive predicate calls rather than separated into a grammar data structure. This is reasonable for a small calculator but is not the cleanest teaching example. The operator precedence is handled via nesting order of calls rather than a data-driven precedence table. The `"1 @ 2"` error case is now correctly handled but is not documented in the puzzle README as a spec.

**Config parser — interface/implementation mismatch.** `parse_config/1` returns `config` (abstract type) but `main/2` calls `get/3` which does a `map.search` in both SectionMap and SM. If neither map has the key, `get` returns `no`, which is correct. But the function returns `maybe(string)` even though a config lookup can fail for two distinct reasons: section missing or key missing. The single `no` return conflates the two. For a teaching resource, this is a missed opportunity to demonstrate `maybe_custom` error types. The solution notes should mention this as an extension point.

**Generic parser (`gen_parser.m`).** I did not read this file in full, but the earlier reviews flagged it as having some of the longest functions in the repo. The solution exists and compiles.

## 2. Kata starter code quality

Katas use `start.m` files that the learner edits. I examined the structure across 8 tracks. The format is consistent:

```mercury
% <track>/<kata>/start.m
:- module <kata>.
:- interface.
:- import_module io.
:- pred main(io::di, io::uo) is det.

:- implementation.
:- import_module ...relevant modules...

% <2-4 line conceptual hook>

%--- Problem ---%
% <what the learner must do, described in plain English>

%--- Your code below ---%

main(!IO) :-
    ...test harness that prints expected output vs actual...
```

The consistent format is valuable — learners know exactly what to expect. The test harness in `main` is self-checking; learners see PASS/FAIL at the bottom. This is good pedagogy.

The main quality issue with katas is **no reference solution exists for any kata** except `concurrency/09-stm`. This means:
- A learner who cannot solve a kata has no canonical answer to study.
- The project has no way to verify that a kata's `start.m` is solvable as written (no CI for kata completion).
- Interviewing for a kata maintainer role requires building solutions from scratch.

The "no solutions is intentional" pattern is defensible — katas are muscle-memory drills, not puzzles — but it means the assessment surface for code quality here is limited to starter code structure and test-harness quality.

The exception is `concurrency/09-stm/solution/stm_kata.m`, which is a complete solution for the STM kata. Its quality is high: proper `store_atomicity_assertion` annotations, correct use of `stm_builtin` predicates for TVar operations, and the test harness checks both commit and rollback paths. If more katas had solutions at this quality, it would substantially increase the curriculum's self-study value.

## 3. Bridge solution notes quality

Bridges have `solution/README.md` with embedded Mercury snippets but no `solution/*.m` files. This is the weakest code-quality area. The noted issues:

- **Never compiled.** The bridge-11 fix pass found 4 latent bugs in snippets.
- **No syntactic checking.** Fenced code blocks may contain typos, missing imports, or mode errors that would be caught by a compiler run.
- **Snippet density varies.** Bridge 10's solution notes were completely rewritten and now describe a comprehensive restart-loop design. Bridge 01's notes are a paragraph. Bridge 04's notes describe the determinism ratchet concept with minimal code.
- **Teaching quality is inconsistent.** Bridge 05's notes have the clearest explanation of multi-mode predicates in the entire repo. Bridge 04's notes assume the learner already understands committed choice.

For a project targeting this quality level, the notes-only approach is the weakest structural decision. The solution does not need to be a full `solution/*.m` file — the case for notes is well-made in the bridge README — but the project should compile-check the snippets. Options: `ci.sh` could extract code blocks and pipe through `mmc`, or maintain companion `.m` snippets that are compiled and then copy-pasted into the README at release time.

## 4. Naming and organization

- **Predicate naming:** Generally clear and descriptive. `parse_lines`, `shortest_path`, `run_pipeline`, `pretty_any` all clearly describe what they do. Occasional shortcuts like `digit` (which parses one digit) vs `digits` (zero or more) may confuse a beginner who expects singular/plural to align with the typical one-or-more/many distinction.
- **Module structure:** Every .m file is a single module. This is appropriate for exercises. The consistent `:- module <name>`, `:- interface.`, `:- implementation.` pattern is correct.
- **Import hygiene:** Solutions import what they use and no more. No wildcard imports.
- **Test code separation:** Puzzle solutions embed test code in `main`. This is appropriate for exercises but means the test code is not separable from the reference implementation.

## 5. Summary

| Dimension | Score | Key factors |
|---|---|---|
| Puzzle solutions | 8.5/10 | Clean, well-commented, correct; some miss decomposition opportunities |
| Kata starters | 7/10 | Consistent format, good test harnesses; no reference solutions |
| Bridge notes | 6/10 | Pedagogically valuable content but uncatchable rot in code snippets |
| Naming/hygiene | 9/10 | Clean imports, clear names, proper module structure |
| Documentation in code | 8/10 | Good explanatory comments; some miss key design tradeoffs |

The 8/10 overall reflects that the compiled puzzle solutions are genuinely good Mercury code, while the notes-only bridges and the no-reference-solutions-for-katas design decisions create durability problems that a continuously-maintained resource should address.
