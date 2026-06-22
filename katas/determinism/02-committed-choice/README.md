# 02 — Committed choice: `cc_multi` and `cc_nondet`

**Concept:** committed-choice nondeterminism, `cc_multi`/`cc_nondet` determinism categories,
`promise_equivalent_solutions`, `main/2` as `cc_multi`

**Why Mercury:** in most languages determinism is a runtime property; in Mercury it is a
compile-time contract. Committed choice is where you tell that contract "one solution is
enough" — `cc_multi`/`cc_nondet` let the compiler discharge a multi-solution goal in a
deterministic context without quietly dropping the guarantee.

**Not in the Mercury tutorial.**

---

## The problem

A `nondet` or `multi` predicate has multiple solutions and can backtrack. But sometimes
you want exactly *one* solution — the first one found — without providing a collector
(`solutions/2`). You want to commit to the first result.

Mercury's answer: `cc_multi` (committed-choice multi) and `cc_nondet` (committed-choice
nondet). These say "this predicate has multiple solutions, but we commit to the first and
throw away the rest."

The restriction: `cc_*` predicates can only be called from `cc_*` or `det` contexts.
This prevents committed-choice from contaminating pure backtracking code.

---

## Exercise 1: Generator wrapped as committed choice

Write a generator:
```mercury
:- pred gen_string(string::out) is multi.
gen_string("apple").
gen_string("banana").
gen_string("cherry").
```

Call it with committed choice:
```mercury
:- pred first_string(string::out) is cc_multi.
first_string(S) :- gen_string(S).
```

Call `first_string` from `main` (which is `cc_multi`):
```mercury
main(!IO) :-
    first_string(S),
    io.write_string(S ++ "\n", !IO).
```

This always prints `"apple"` — the first solution is committed to.

## Exercise 2: `main/2` is `cc_multi`

The standard `main/2` has mode `(di, uo) is cc_multi`. Why not `det`? Because Mercury
allows `main` to be called with a constraint-solving runtime that may have multiple
solutions for the initial state — `cc_multi` permits this generality without requiring
`main` to collect all solutions.

In practice, writing `main` as `det` also works (det is a subset of cc_multi). Try:
```mercury
:- pred main(io::di, io::uo) is det.
```
The compiler accepts it.

## Exercise 3: `promise_equivalent_solutions`

When you know that a `nondet` predicate always produces equivalent solutions (e.g., all
solutions compute the same value), you can use this scope to call it from a `det` context:

```mercury
:- pred compute(int::out) is nondet.
compute(42).   % all "solutions" are the same value

:- pred get_value(int::out) is det.
get_value(N) :-
    promise_equivalent_solutions [N] (compute(N)).
```

`promise_equivalent_solutions [N] (Goal)` tells the compiler: within this scope, all
solutions for the variables listed (`N`) are equivalent. You take responsibility for this
claim — the compiler does not verify it.

Write a case where this is genuinely true (all solutions return the same computed value)
and one where it would be a lie (the implementation returns different values). The lying
case compiles but gives nondeterministic behavior at runtime.

---

## Checkpoint

- Exercise 1: `first_string` always commits to `"apple"`
- Exercise 2: `main` declared as `det` compiles correctly
- Exercise 3: `promise_equivalent_solutions` used correctly on a genuinely-equivalent predicate
- You can explain: what is the difference between `cc_nondet` and `semidet`?
