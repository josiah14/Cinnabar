# Idiomatic Mercury — DeepSeek V4 Flash Free

## Overall: 7.5/10

Big Pickle gives 8/10. I find the Prolog-ism issue and the function/predicate imbalance more significant. The curriculum teaches Mercury's distinctive features well — determinism annotations, mode annotations, purity markers, DCG threading — but several puzzle solutions and bridge snippets use patterns that a Mercury native would not write.

## What the curriculum gets right

**Determinism annotations everywhere.** Every predicate in every compiled puzzle solution has an explicit determinism annotation. No exceptions. This is the non-negotiable baseline for idiomatic Mercury, and the curriculum never slips.

**Mode annotations beyond `in`/`out`.** The combinator library's `inst parser_det == (pred(out, in, out) is det)` (line 16) and `inst parser_semidet` (line 17) are genuinely advanced Mercury — higher-order insts that parameterize parser combinators. No other Mercury resource teaches this pattern. The generic printer's `di`/`uo` threading through `deconstruct` is correct and idiomatic (lines 17–29).

**Purity system.** The concurrency katas use `promise_pure` for parallel conjunction wrappers, `cc_multi` for `&`, `thread.spawn` with `di`/`uo` threading. The solver-types kata conceptually covers `any` inst even without a working CLP(FD) backend. Bridge 12's handling of `mutable` with `impure`/`semipure` accessors and `promise_pure` as a discharged obligation is pedagogically correct.

**DCG threading.** The parsing katas use `-->` correctly and explicitly desugar it in kata 09. The combinator library uses explicit DCG threading (`(pred(out, in, out) is ...)`) because `-->` cannot be used with higher-order arguments — the correct design choice.

## What is less idiomatic

### 1. `fail` for `failure` determinism (`combinators.m:28`)

`:- mode empty(out, in, out) is failure.` combined with `empty(_, _, _) :- fail.` The `fail` body is a Prolog idiom. In Mercury, the `is failure` determinism annotation should be sufficient — the body can be empty:

```mercury
:- pred empty(T, list(char), list(char)).
:- mode empty(out, in, out) is failure.
empty(_, _, _).
```

An empty body has the same effect as `fail` — both produce `failure` determinism — but the empty body signals "this predicate is *defined* to have no solutions" while `fail` signals "this predicate computes `fail`." The distinction matters because Mercury's determinism system checks that the annotation matches the body: `is failure` on an empty body is a compile-time guarantee; `fail` on `is failure` is redundant.

This is a small issue but pedagogically significant: the whole point of the combinator library is to teach Mercury's determinism-in-mode-annotations feature, and using `fail` undermines the lesson.

### 2. Predicate bias

Several katas ask for predicates where functions would be more natural. Determinism kata 03 (`det`) asks for a predicate returning `int` via `int::out` instead of a function returning `int`. This is a consistent pattern throughout the curriculum. The practical cost is small (Mercury functions are predicates with a return-value argument), but the pedagogical effect is that learners practice the clunky form and may not internalize when the elegant form applies.

The exception is bridge 12 (currying and impurity), which explicitly teaches partial application with functions — `scale(2.0)` as `func(float) = float`. This is the right approach, but it is one bridge out of 68+ exercises.

### 3. If-then-else chains instead of switches

Several puzzle solutions chain if-then-else where a `switch` on a discriminated union would be more idiomatic. The config parser's `parse_lines` and the calculator's expression evaluation both use nested if-then-else. Mercury's `switch` is not as syntactically compact as Haskell's pattern matching, but it is the idiomatic way to dispatch on a DU, and the compiler checks exhaustiveness — something if-then-else chains lose.

### 4. Lambda syntax inconsistency

The curriculum uses both `(pred(...) is det :- ...)` and `pred(...::in) is det :- ...` and occasionally `(pred(...) --> ...)` for DCG lambdas. The memoized search uses `(pred(Cost - P :: out) is nondet :- ...)` with `::` for mode annotations in the lambda head. The config parser uses `(pred({Sec, Key}::in, !.IO::di, !:IO::uo) is det :- ...)`. The solution notes use yet another variant.

Both major forms are valid Mercury, but the inconsistency across exercises is noticeable for a learner. A project convention (e.g., "use `pred(Args::modes) is det :- ...` for all lambdas, with `(...)` parentheses") would help.

### 5. `solutions/2` sort claim

The `solutions/2` documentation in `koans/determinism/02-nondet-in-det/solution/README.md` claims solutions are returned in sorted, deduplicated order. This is correct for Mercury's universal term order (as the consensus confirmed). But it is worth noting that this behavior is compiler-version-dependent for user-defined types unless they implement `compare/3` via `pragma comparable`. The solution notes should mention this caveat — not all predicates produce term-order-comparable solutions.

## Prolog-isms that survived

1. `fail` in `combinators.m:28` (discussed above).
2. `\=` in conditions (`memoized_search.m:26`: `Start \= Goal`). This is actually idiomatic Mercury here (forces `nondet` context correctly), but a Prolog transplant would not recognize that it is the `\=` that makes the predicate `nondet` rather than `det`.
3. `not` vs `\+` — both appear in the codebase. Mercury accepts `\+` but not `not`. The curriculum consistently uses `\+`, which is correct.
4. Implicit `in`/`out` in a few bridge snippets — the `ci.sh` extractor's default import set would catch mode annotation errors, but a few solution READMEs still use Prolog-style bare arguments without mode annotations in prose descriptions.

## Big Pickle disagreement

Big Pickle scores idiomatic Mercury at 8/10. I give 7.5. The specific deltas:

- The `fail` for `failure` pattern (combinators.m) is a Prolog-ism that teaches the wrong lesson. Big Pickle acknowledges it but does not deduct for it. I deduct a full point from the puzzle-solutions sub-score because the combinator library is the highest-profile puzzle that demonstrates Mercury's determinism system.
- The predicate bias is more significant than Big Pickle assesses. Of the ~25 referenced puzzle solutions and bridge solution snippets, exactly 2 use function syntax for core logic (config parser's `get/3` and `parse_config/1`). The rest use predicates. A learner who completes the curriculum will be comfortable writing Mercury predicates but will not have a clear instinct for when functions are the better choice.
- Bridge 12 (currying and impurity) partially addresses the function/predicate balance, but it is a single exercise. The pattern of "function for arity-return, predicate for everything else" should be established earlier and more consistently.
