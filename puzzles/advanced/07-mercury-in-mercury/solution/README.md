# Solution notes

## The core loop

`resolve` picks a clause from the program, renames its variables, unifies the
clause head with the current goal, then calls `solve` on the clause body.
`solve` loops through a list of goals, calling `resolve` for each one. Both are
`nondet` — backtracking over `list.member` in `resolve` is what generates
multiple solutions.

```mercury
resolve(prog(Clauses), Goal0, N0, N, Env0, Env) :-
    deref(Goal0, Env0, Goal),
    list.member(Raw, Clauses),
    rename_clause(Raw, string.int_to_string(N0), rule(Head, Body)),
    unify(Goal, Head, Env0, Env1),
    solve(prog(Clauses), Body, N0 + 1, N, Env1, Env).
```

The `N0 -> N` pair is a freshness counter threaded through the whole
derivation; see "Variable freshness" below for why a plain depth counter is
not enough.

The `nondet` of `list.member` is the source of all nondeterminism. Mercury's
`solutions/2` forces `solve` to enumerate all branches and collect the resulting
environments.

## Unification: semidet by if-then-else

A two-clause `unify_d` with variable patterns is inferred `nondet`:

```mercury
unify_d(v(X), T, Env0, [X - T | Env0]).          % clause 1
unify_d(T, v(X), Env0, [X - T | Env0]) :- T \= v(_). % clause 2
```

When both arguments are variables, only clause 1 applies (clause 2's guard
`T \= v(_)` fails since the first arg IS a var). But Mercury can't prove the
mutual exclusion statically — it must assume both could apply, inferring `nondet`.

The fix: a single clause with if-then-else. Mercury commits to the first
matching branch:

```mercury
unify_d(D1, D2, Env0, Env) :-
    ( D1 = v(X) -> Env = [X - D2 | Env0]
    ; D2 = v(X) -> Env = [X - D1 | Env0]
    ; D1 = a(S), D2 = a(S) -> Env = Env0
    ; ...
    ; fail ).
```

This is `semidet` — exactly one branch fires, or the predicate fails.

## lookup_v: same multi-clause problem

```mercury
lookup_v(X, [X - T | _], T).           % can succeed if first key matches
lookup_v(X, [Y - _ | Rest], T) :- X \= Y, lookup_v(X, Rest, T).
```

Mercury infers `nondet` because when X matches the key in the first element,
both clauses can fire (clause 2 may also recurse). The guard `X \= Y` is
`semidet`, but Mercury doesn't prove that it's the logical negation of `X = Y`.

Fix: single-clause if-then-else:

```mercury
lookup_v(X, [Key - Val | Rest], T) :-
    ( X = Key -> T = Val ; lookup_v(X, Rest, T) ).
```

Semidet: succeeds at most once. ✓

## term_str: overlapping f/2 patterns → multi

Multiple function clauses matching `f/2` with different string literals in
the first argument:

```mercury
term_str(f("[]", [])) = "[]".
term_str(f("[|]", [H, T])) = ...
term_str(f(F, Args)) = ...   % catches everything else
```

Mercury cannot prove these patterns are mutually exclusive without evaluating
the string arguments — it infers `multi`. The fix is the same: one clause, one
if-then-else.

## Variable freshness — why depth is not enough

Each time a clause is used, its variables must be renamed to a *fresh* set, or
two independent uses of the same clause (or two clauses that happen to share a
variable name) will alias each other. We get freshness by threading one
monotonic counter `N0 -> N` left-to-right through the entire derivation and
using its current value as the rename suffix. Every instantiation therefore
gets a distinct suffix.

Threading an `(int::in, int::out)` counter through `nondet` code is safe, and
the reason is worth internalizing: within a *single successful derivation* the
counter only increases, so no two live instantiations share a suffix.
Reusing a value across *alternative* (backtracked) branches is harmless,
because Mercury restores the prior `Env` on backtracking — the two
instantiations never coexist in one environment.

### The bug the depth counter had

An earlier version used the resolution `Depth` as the suffix. That is **not**
globally unique. The collision is not between backtrack alternatives (those are
safe, as above) — it is *within a single derivation*, across a conjunction:

> In `solve([G1, G2], D)`, the body subgoals of `G1` run at depths
> `D+1, D+2, …`, while `G2` itself is also resolved at `D+1`. So a subgoal of
> `G1` and the clause chosen for `G2` get the **same** suffix `_{D+1}`. If both
> clauses use the same variable name, the renamed variables are identical and
> capture each other.

`capture_prog` in `meta_interp.m` is the minimal trigger:

```
g1(X) :- s(X).   s(X) :- u(X).   u(7).
g2(X) :- t(X).   t(9).
test(A, B) :- g1(A), g2(B).
```

Resolving `test(A, B)`: `g1(A)` descends one step to its subgoal `s(A)` at
depth 1, and `g2(B)` is also resolved at depth 1. The `s` clause and the `g2`
clause both rename `X` to `X_1`, so `B` is captured to the `7` that flowed in
through `s`/`u`. Then `t(X_1) = t(9)` becomes `t(7) = t(9)`, which fails — and
the whole query **wrongly yields `false`**.

This was verified against `mmc` (grade `asm_fast.par.gc.stseg`):

| renaming scheme        | `?- test(A, B)` |
| ---------------------- | --------------- |
| depth as suffix (old)  | `false`         |
| fresh counter (fixed)  | `test(7, 9)`    |

The "variable freshness" section of the program's output runs exactly this
query, so the fix is a permanent regression guard, not just prose.

## Answering the design questions

**Q1: det compilation of a Mercury predicate**

A `det` Mercury predicate with pattern matching is compiled to a single-pass
switch: the compiler generates a C `switch` on the functor tag. Each arm runs
at most once and doesn't backtrack. The "choice point" stack used during
nondeterministic resolution is entirely absent for `det` code — that's the
fundamental difference between the interpreter (which builds explicit choice
points via `list.member`) and compiled Mercury (which elides them by
static determinism analysis).

**Q2: Depth-counter collision**

A subtle one, and easy to mis-diagnose. The tempting wrong answer is
"backtracking leaves stale bindings behind." It does *not*: the environment is
threaded functionally (`Env0 -> Env`), so when Mercury backtracks over
`list.member` it restores the earlier `Env` and any binding the failed branch
added is gone. Two clauses tried as *alternatives* at the same depth never
share a live environment, so a shared suffix between them is harmless.

The real collision is **within one derivation**, across a conjunction. In
`solve([G1, G2], D)`, the subgoals of `G1` run at `D+1, D+2, …` while `G2` is
also resolved at `D+1`; a subgoal of `G1` and the clause for `G2` then share
suffix `_{D+1}` and capture each other if they reuse a variable name. See
"Variable freshness" above for the worked `capture_prog` example and the
`mmc`-verified `false`-vs-`test(7, 9)` contrast. The fix is to thread one
monotonic counter `int::in, int::out` through the whole solver so every
instantiation gets a globally distinct suffix.

**Q3: Occurs check**

`unify` binds `v(X)` to any term, including one containing `v(X)` itself.
If a query produces a circular substitution (e.g., `X = f(X)`), then
`apply_env` would loop forever following `X → f(X) → f(f(X)) → ...`.
The occurs check would go in `unify_d`, in the `D1 = v(X)` branch:

```mercury
D1 = v(X) ->
    ( occurs(X, D2, Env0) -> fail ; Env = [X - D2 | Env0] )
```

where `occurs/3` checks whether `X` appears anywhere in `D2` after dereffing.
Standard Prolog omits the occurs check for performance; Mercury programs compiled
with the mode system don't need it because the type system prevents circular terms
at the source level.
