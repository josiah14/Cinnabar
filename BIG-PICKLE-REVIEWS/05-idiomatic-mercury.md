# Cinnabar idiomatic Mercury review: how well the code uses Mercury's native strengths

## Scope and rating

Assessed the 10 compiled puzzle solutions, the kata `start.m` patterns, bridge solution notes, and the katas/koans track structures for how deeply they exercise Mercury-specific idioms rather than generic logic-programming patterns. The standard is: does this code read as Mercury, or could it be Prolog/OCaml/Haskell in Mercury clothing?

**Idiomatic Mercury: 8/10.** The puzzle solutions consistently use mode annotations, determinism declarations, higher-order insts, DCGs, purity markers, and unique-threading where appropriate. The curriculum *teaches* Mercury's distinctive features (inst hierarchy, committed choice, uniqueness, mode-based overloading) rather than avoiding them. The ceiling is that some puzzle solutions use Prolog-era patterns (implicit `in`/`out` without full mode exploitation), and the teaching material does not always explain *why* a given idiom is the Mercury way.

## 1. What the curriculum gets right

### 1a. Determinism annotations are everywhere and correct

Every predicate in every puzzle solution has an explicit determinism annotation. This is non-negotiable in Mercury, and the curriculum never slips. The katas drill all six categories and the boundary cases (`cc_multi`, `cc_nondet`, `erroneous`, `failure`). The determinism track is the strongest in the repo and the code reflects it: there is no single-function solution where determinism was omitted or defaulted.

The determinism-ratchet bridge (04) is a genuinely Mercury-specific design pattern — it forces learners to think about determinism *propagation* through call chains, which is not a concept in other languages. The solution notes correctly handle the `semidet` → `det` ratchet via `promise_equivalent_solutions`.

### 1b. Mode annotations beyond `in`/`out`

Several puzzle solutions use Mercury's advanced mode system:

- **Combinator library** (`combinators.m` lines 16-17): inst aliases `parser_det` and `parser_semidet` parameterise higher-order predicates with DCG threading. This is a quintessentially Mercury pattern — no other language has mode insts for higher-order arguments.
- **Generic printer** (`generic_printer.m`): The `pretty/4` predicate uses proper `(in, in, di, uo)` threading through `deconstruct` — unique IO threading with mode-specific output.
- **Memoized search** (`memoized_search.m`): The `path/5` predicate is declared `nondet` and uses `pragma memo`. The `shortest_path/5` wrapper uses `solutions` with a higher-order lambda that has an explicit mode annotation `(pred(Cost - P :: out) is nondet)`. This is correct and idiomatic.

The earlier reviewers' concern about inconsistent mode annotations has been largely resolved. I found no puzzle solution where modes were omitted.

### 1c. Purity system

The concurrency track correctly uses:
- `promise_pure` for parallel conjunction wrappers
- `cc_multi` for `&` (parallel conjunction always requires committed choice)
- `thread.spawn` with explicit `di`/`uo` threading

The solver-types kata (advanced 02) explains the `any` inst, trailing grade, and purity/impurity interaction — conceptually correct even without a working implementation.

The FFI katas use `pragma foreign_proc` with will-not-call-mercury/purity annotations consistently. The FFI-depth puzzle solves all four pragma forms (decl, code, export, enum) with proper mode annotations.

### 1d. DCG threading in parsing

The parsing katas use DCG syntax (`-->`) for the parser track and then explicitly desugar it in kata 09 (dcg-desugar) to show what `-->` compiles into. The combinator library uses explicit DCG threading (`(pred(out, in, out) is ...)`) rather than `-->` because it builds higher-order parser combinators — the right choice, since `-->` only works with named predicates, not higher-order arguments.

The calculator puzzle uses DCG syntax properly. The CSV reader uses `parsing_utils` with the correct mode annotations for `semiparse`/`parse`.

## 2. Where the code could be more Mercurian

### 2a. Function vs predicate under-utilization

Mercury distinguishes functions from predicates syntactically and semantically — functions are just sugar for predicates with a return-value argument, but the compiler's error messages and determinism inference treat them differently. The curriculum is biased toward predicates:

- The memoized search and config parser both use functional syntax for simple operations (`example_graph = map.from_assoc_list(...)`, `Result = yes(V)`) but use predicates for all core logic.
- The config parser's `get/3` is coded as a function (line 79: `get(config(M), Section, Key) = Result`), which is correct, but the `parse_config/1` function body uses predicate-style unification (line 25: `parse_config(Input) = config(SectionMap) :- ...`). This is the idiomatic transformation from predicate to function and is well-executed.
- Several katas ask learners to write predicates where functions would be more natural. Determinism kata 03 (`det`) asks for a function returning `int` but wraps it as a predicate with `int::out`. This may be deliberate (teaching uniformity) but misses a chance to teach function syntax.

The concurrency katas are the worst offenders — all exercises use predicates even when the natural Mercury expression would be a function (e.g., `foldl` over channels could use function composition more cleanly).

### 1b. (yes, second 1b — the curriculum uses 1a/1b/1c in comments)

### 2b. Lambda syntax consistency

Puzzle solutions use both `(pred(...) is det :- ...)` and `pred(...::in) is det :- ...` lambda syntax. The memoized search (line 39) uses `(pred(Cost - P :: out) is nondet :- ...)` with `::` for mode annotations in the lambda head. The config parser (line 107) uses `(pred({Sec, Key}::in, !.IO::di, !:IO::uo) is det :- ...)`. Both are valid Mercury, but the inconsistency across puzzles is noticeable. A style guide for the project (or a coding-standards section in `docs/TEMPLATES.md`) would help.

More critically, the bridge solution notes occasionally use an older lambda syntax (`pred(...) is det --> ...` or `closure(...)`) that was deprecated in Mercury 20.01. The fix pass for bridge 11's snippets corrected these, but other bridge notes may still contain pre-22.01 syntax.

### 2c. Typeclass pattern completeness

The plugin architecture puzzle uses existential types with typeclasses (`some [T] plugin(T) => formatter(T)`) — correct and well-documented. But the typeclass instances use only instance methods, not instance constants or functional dependencies that Mercury supports. The `formatter` typeclass (plugins.m lines 14-17) is a two-method interface with no laws or superclasses. For teaching purposes, a typeclass with a FD (e.g., `formatter(T, Config)`) would demonstrate Mercury's type-level computation capability. The curriculum's typeclass katas cover FDs and superclasses conceptually, but the puzzle solutions don't apply them.

### 2d. Unique mode array threading

The array-threading kata (mode-system 08) teaches `array` with unique modes — a Mercury-specific pattern that is virtually absent from puzzles. Puzzle solutions use lists everywhere. The data-structures-bench puzzle (advanced 04) compares `array` vs `list` vs `version_array` in principle, but the solution uses lists because the puzzle is about asymptotic complexity rather than unique-threading practice. A puzzle whose solution forces unique array threading (e.g., a particle simulation or pixel buffer) would exercise this idiom in a problem context.

### 2e. Module design at scale

No puzzle solution uses multiple modules. Every solution is a single `.m` file with a flat import list. The abstract type in the config parser (`:- type config ---> config(map(...))` with an opaque interface) demonstrates the pattern, but no exercise requires a learner to split code across modules. The multi-module kata (foundations 01) covers the mechanics but provides no problem that *demands* module design.

## 3. Prolog-isms that survived

A few patterns in the codebase that would be written differently by a native Mercury programmer:

1. **`fail` for `failure` predicates.** `combinators.m` line 28: `empty(_, _, _) :- fail.` This should use the `failure` determinism annotation with an empty body: `:- mode empty(out, in, out) is failure.` The `fail` goal works but describes the *mechanism* rather than the *intent*. The `is failure` determinism is a Mercury innovation over Prolog — using `fail` misses the teaching opportunity.

2. **If-then-else with side-effect-free conditions.** Several puzzle solutions chain if-then-else in ways that would be cleaner as `switch` on a discriminated union. The config parser's `parse_lines` (lines 35-57) chains four if-then-else conditions when a `promise_equivalent_solutions` approach with a separate classification predicate would be more Mercury-idiomatic. This is a minor point — the current code is correct and readable — but it reflects a Prolog-era pattern.

3. **`\=` in conditions.** The memoized search (line 26: `Start \= Goal`) uses Prolog-style inequality in a condition. In Mercury, this imposes a `nondet` context (since `\=` has multiple solutions at compile time: the two terms are either equal or not). The `path/5` predicate is already `nondet`, so it works, but a Prolog transplant might not recognise that `Start \= Goal` is what forces `nondet` here (a pure `dif`), whereas `Start = Goal` would produce `det` in the base case. This is idiomatic Mercury *and* the correct teaching point — it's one of the few places where nondeterminism is not immediately obvious. Keep it.

## 4. The idiomatic Mercury score by component

| Component | Score | Notes |
|---|---|---|
| Puzzle solutions | 8.5/10 | Determinism + mode annotations excellent; could use more functions, typeclass FDs, multi-module |
| Katas (conceptual) | 9/10 | Best in class for mode/determinism/inst curriculum; solver-types is conceptual-only ceiling |
| Bridge solution notes | 7/10 | Correct in intent; occasional pre-22.01 syntax and Prolog-era patterns |
| Starter code (start.m) | 7.5/10 | Clean and consistent; over-relies on predicates where functions would teach |

The 8/10 overall reflects that the curriculum is uncommonly strong on Mercury's distinctive features (mode system, determinism, purity, uniqueness, inst hierarchy) and the puzzle solutions consistently use correct Mercury idioms. The two biggest idiomatic gaps are the function/predicate balance and the single-module ceiling.
