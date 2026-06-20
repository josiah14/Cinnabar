# Solution notes

## The bidirectionality

The forward and reverse directions are implemented as two separate predicates:

```mercury
first_with(property::in, int::out) is semidet    % forward
properties_of(int::in, property::out) is nondet  % reverse
```

The relation is: `{(P, N) | N has property P, N ∈ 1..50}`. In the forward direction
the relation is many-to-one from the integer side (many N for each P) — we use a
recursive scan to commit to the first match. In the reverse direction it's
one-to-many from the integer side — one N can have several properties.

## Why `pragma promise_equivalent_clauses` does not apply here

The pragma requires both clause bodies to compute the **same relation**. Here:
- `first_with` computes `{(P, min_N_with_P) | ...}` — only the smallest N per P.
- `properties_of` computes `{(P, N) | has_property(N, P)}` — all (P, N) pairs.

These are different relations. The pragma would be a lie.

For the pragma to be valid, both clause bodies must implement the exact same logical
set of pairs. The classic examples are predicates like `append/3` (the same clauses
work in both directions) or `str_to_int` (two different algorithms that both compute
the bijection between decimal strings and integers).

## Forward: recursive scan instead of nondet generator in condition

A tempting but wrong approach: drop a nondet generator into an if-then-else
condition and expect `->` to commit to the first solution:

```mercury
first_with(P, N) :-
    ( gen(1, 50, N0), has_property(N0, P) ->  % inferred nondet — see below
        N = N0
    ; fail ).
```

The commit does not work the way the shape suggests. Mercury's if-then-else prunes
the condition's nondeterminism **only for variables that are local to the condition**
— existentially quantified, i.e. bound inside it and not used afterwards. Here `N0`
is bound in the condition and then *exported* to the then-branch (`N = N0`), so its
multiplicity is not pruned: every integer `gen` produces and `has_property` accepts
flows out through `N`, and the predicate inherits `gen`'s nondeterminism. The
compiler says exactly this, and the reason it gives points at the `gen` call, not at
the `->`:

```
first_with'(in, out): determinism declaration not satisfied.
  Declared `semidet', inferred `nondet'.
  Call to `gen'(in, in, out) can succeed more than once.
```

The commit is real — it just applies to *existence*, not to a value you carry out.
`( gen(1, 50, _) -> ... ; ... )`, which discards the binding, collapses to a single
"does a solution exist" test, and the if-then-else is deterministic. The moment you
export the binding, the multiplicity comes with it.

The correct pattern returns the first match with a semidet recursive scan, where
each step's condition has at most one solution to begin with:

```mercury
first_from(Lo, Hi, P, N) :-
    Lo =< Hi,
    ( has_property(Lo, P) ->
        N = Lo
    ;
        first_from(Lo + 1, Hi, P, N)
    ).
```

Each `has_property(Lo, P)` call is `semidet` — at most one solution — so there is no
multiplicity to export. The if-then-else is `semidet`, the recursion is `semidet`,
and Mercury infers the whole predicate as `semidet`. ✓ (The other idiom is
`solutions(generate_and_filter, [First | _])`: collect every match, then take the
head — see `first_k_with` in the solution, which uses `gen` exactly that way.)

## Fibonacci check

A positive integer N is Fibonacci iff 5N²+4 or 5N²-4 is a perfect square. The
disjunction is implemented with if-then-else rather than `;` to keep the
determinism `semidet`:

```mercury
is_fibonacci(N) :-
    N >= 0,
    ( is_perfect_square(5 * N * N + 4) ->
        true
    ;
        is_perfect_square(5 * N * N - 4)
    ).
```

Using `;` directly would cause Mercury to infer `nondet` (two semidet branches in
disjunction = nondet, since Mercury cannot prove mutual exclusion statically).

## Output check

- 1: square, fibonacci, triangular — all three; 1 is special
- 3: prime, fibonacci, triangular — the only prime triangular fibonacci
- 36: square and triangular (not in 1..20 but worth verifying with the predicate)
- 12 has no properties in our list — confirms non-empty output filter works
