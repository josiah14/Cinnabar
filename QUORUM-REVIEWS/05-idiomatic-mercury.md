# Idiomatic Mercury — Big Pickle

## Overall: 8/10

Puzzle solutions consistently use mode annotations, determinism declarations, higher-order insts, DCGs, purity markers, and unique threading. The curriculum teaches Mercury's distinctive features rather than avoiding them.

## What it gets right

- **Determinism annotations everywhere.** Every predicate in every puzzle solution has an explicit determinism annotation. No slips.
- **Mode annotations beyond `in`/`out`.** Combinator library uses inst aliases for higher-order predicates. Generic printer uses unique IO threading through `deconstruct`. Memoized search uses explicit lambda mode annotations.
- **Purity system.** Parallel conjunction wrappers use `promise_pure`. `thread.spawn` uses explicit `di`/`uo` threading. FFI katas use all four pragma forms with correct annotations.
- **DCG threading.** Parser katas use `-->` and explicitly desugar it in kata 09. Combinator library correctly uses explicit DCG threading for higher-order arguments.

## Room for improvement

1. **Function vs predicate under-utilisation.** Curriculum is biased toward predicates even when functions would be more natural. Several katas ask for predicates where functions fit better.
2. **Lambda syntax inconsistency.** Both `(pred(...) is det :- ...)` and `(...::in) is det :- ...` forms appear across puzzles. A project convention would help.
3. **Prolog-era `fail` for `failure`.** `combinators.m:28`: `empty(_, _, _) :- fail.` Should use `:- mode empty(out, in, out) is failure.` The `is failure` determinism is a Mercury innovation — using `fail` misses the teaching opportunity.
4. **No multi-module exercises.** Every solution is a single `.m` file. No exercise requires module design despite the curriculum covering the mechanics (foundations 01).

## New additions (koans 21–23)

- Koan 21: correctly uses `!IO` sugar — idiomatic Mercury.
- Koan 22: correct explicit lambda head with `pred(IO0::di, IO::uo) is det`. Notes that only the lambda head is restricted; outer call still uses `!IO`.
- Koan 23: correct function form with explicit threading. Solution README also gives the idiomatic predicate form as the preferred alternative — good pedagogical touch.
