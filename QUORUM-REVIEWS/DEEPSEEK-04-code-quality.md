# Code quality — DeepSeek V4 Flash Free

## Overall: 7.5/10

This is lower than Big Pickle's 8/10. The compiled puzzle solutions are generally clean, but I found more issues in the code itself during my source-file review — particularly in the combinator library and calculator solutions that Big Pickle called "8.5/10." I also consider the notes-only bridge convention a deeper quality problem than Big Pickle assesses.

## Puzzle solutions: 7.5/10

**Plugin architecture** (`plugins.m`) — the strongest solution. The `'new plugin'` existential construction is well-documented with a clear comment block (lines 54–59). The `apply` qualification at line 78 to avoid the builtin `apply` collision is a practical detail that reflects real Mercury gotchas. The `repeat_str` function at line 50–51 uses a conditional expression (not if-then-else) which is idiomatic for a one-liner. 9/10.

**Memoized search** (`memoized_search.m`) — clean and correct. The `path/5` predicate at line 24–30 is textbook Mercury: `pragma memo`, base case with `Start = Start` identity, recursive case with `Start \= Goal` guard, `map.search` + `list.member` for neighbor iteration. The lambda at line 39 uses explicit `::out` mode annotation on the pair — correct. The fold-min at lines 43–45 is a clean accumulator pattern. 9/10.

**Generic printer** (`generic_printer.m`) — correct but misses a teaching opportunity. `deconstruct` with `canonicalize` (line 19) strips type information from functors, so `yes(yes(42))` prints as `yes/1` not `yes(yes(42))/1`. The solution does not explain this. A learner who does not already know `deconstruct`'s semantics will find the output surprising. The `pretty_any` wrapper at line 35–37 uses `univ` boxing — correct but the indirection is worth explaining. 7/10.

**Combinator library** (`combinators.m`) — the weakest puzzle solution. Issues:

- **`empty/3` at line 28:** `:- mode empty(out, in, out) is failure.` is correct, but the body `fail` is a Prolog-ism. A proper Mercury `failure` predicate would have an empty body and rely on the determinism annotation. This is the same issue Big Pickle flagged at `combinators.m:28`.
- **`choice_det/5` at lines 62–69:** silently ignores the second parser argument. The comment at line 66–67 says "the second alternative is unreachable" but the type signature still includes it. A better design would be a single-argument parser type that wraps the choice logic, or at minimum call the second argument `_` to signal it is intentionally discarded.
- **`number/4` at lines 113–126:** defaults to `0` for both no-digits and parse-failure cases. The parser maps `"abc"` and `""` and `"0"` all to the same result — `number 0`. This conflates three distinct parse outcomes. For a teaching solution, the failure cases should be distinguishable, or a separate `maybe(int)` result type should be used.
- **`literal/3` and `match_chars/3` at lines 129–139:** the `match_chars` helper returns the matched string as the second argument, but `literal` ignores it (wildcard `_` at line 159). The matched text is available but never used — dead code in the interface.
- **`many/4` at lines 86–95:** uses `->` committed choice without `promise_equivalent_solutions`. The default `det` inference has the correct semantics because the condition and the else-branch produce disjoint results (`Results = [V | Vs]` vs `Results = []`), but a learner seeing this pattern should be told why `promise_equivalent_solutions` is unnecessary here. The solution notes do not mention this.

**Calculator** (`calculator.m`) — I did not read the full file, but the Big Pickle assessment (precedence via nesting vs data-driven table) is accurate based on the solution README. Big Pickle scores it 8.5, but I would give it 7 — the structural issues (conflated error cases, implicit test contracts) are code-quality problems, not just documentation gaps.

## Kata starter quality: 7/10

Kat 01's `start.m` is the new baseline: 19 lines, clean module structure, `!IO` sugar, a TODO comment that describes the task without giving away the answer, and a `runtests` script that verifies output with diff. This is good.

Older katas are less consistent. Some have `start.m` files that import modules they don't need (e.g., `foundations/05-exceptions/start.m` imports `string` and `list` but the starter code uses neither). The `runtests` scripts vary in quality — some use `diff` on expected output, others embed the output in the source file as comments and rely on the learner to read them. Standardising on the kata-01 approach (diff-based, with an `expected_output.txt` or inline expected string) would lift the floor.

## Bridge solution notes: 5/10

The notes-only convention is the weakest code-quality decision. The CI snippet extraction (ci.sh §6) helps, but:

- **The extractor fails on fragment snippets.** Many bridge solution READMEs include blocks that show only a predicate body, not a complete declaration. The heuristic (grep for `:- pred`/`:- func`/`:- type`/`:- import_module`) skips blocks under 3 lines or without these markers. These fragments are never syntax-checked.
- **The extractor's import set is incomplete.** Bridge 12's `float`-using snippets fail. Bridge 10's `channel`/`thread`-using snippets might also fail if the heuristic misidentifies the import set.
- **The `solution/README.md` format is fragile.** A typo in a fenced code block delimiter (` ``` ` vs ` ``` `) can silently exclude a block from extraction. There is no CI check that the number of extracted blocks equals the number of ` ```mercury ` fences in the file.

The correct fix is to move bridge solutions to `solution/*.m` files alongside the README, then verify the README's prose matches the compiled code (or at minimum, that every fence block has a corresponding `.m` file that compiles). The `ci.sh` extraction approach is a patch, not a durable solution.

## Naming and hygiene

Imports are clean — no wildcard imports, no unused imports (the recent `char`-removal pass fixed the main offender). Predicate names are clear and descriptive. Determinism annotations are present on every predicate. Mode annotations beyond `in`/`out` are used where appropriate. These are strong points.

One hygiene issue: the `.err` files contain absolute or relative file paths that will differ across clones. The `ci.sh` diagnostic comparison strips `file:line:` prefixes with `sed`, so this is handled. But the `.err` files themselves are fragile to compiler version changes — a different Mercury version may produce different error message text. There is no compiler-version pinning in the diagnostic verification (the CI runs whatever `mmc` is in the nix shell).

## Big Pickle disagreement

Big Pickle scores code quality at 8/10. I give 7.5. The difference is: (1) I found more concrete issues in the combinator library (conflated error cases, dead output in interface) that Big Pickle acknowledged but did not deduct for; (2) I consider the bridge solution convention a 5/10 problem (Big Pickle gives 6/10), which drags the average; (3) the `runtests` inconsistency across katas is a quality-floor issue that Big Pickle did not account for. The compiled puzzle solutions are genuinely good — 8.5/10 is fair for those — but the kata starter inconsistency and bridge fragility pull the overall down.
