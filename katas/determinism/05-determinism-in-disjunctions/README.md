# 05 — Determinism in disjunctions

**Concept:** the determinism lattice, how Mercury combines determinisms across disjunction
branches using least upper bound (lub)

**Why Mercury:** in most languages determinism is a runtime property; in Mercury it is a
compile-time contract. A disjunction's determinism is computed, not assumed: the compiler
takes the least upper bound of the branches, so the contract for the whole follows
mechanically from the contracts of its parts.

**Not in the Mercury tutorial.**

---

## The determinism lattice

Mercury assigns a determinism to every predicate. When two branches of a disjunction have
different determinisms, Mercury takes the *least upper bound* — the weakest determinism
that covers both:

```
failure < semidet < det
failure < nondet  < multi
semidet and nondet are incomparable
```

The rules for `(A ; B)`:

| Left \ Right | `det`    | `semidet` | `multi` | `nondet` |
|---|---|---|---|---|
| `det`        | `det`    | `det`     | `multi` | `multi`  |
| `semidet`    | `det`    | `semidet` | `multi` | `nondet` |
| `multi`      | `multi`  | `multi`   | `multi` | `multi`  |
| `nondet`     | `multi`  | `nondet`  | `multi` | `nondet` |

Key observations:
- `det ; det → det` — two guaranteed-success branches guarantee success
- `semidet ; nondet → nondet` — the possibility of 0 solutions dominates
- `det ; nondet → multi` — the det branch guarantees at least one solution

---

## If-then-else vs disjunction

`( Cond -> Then ; Else )` is *not* a disjunction — it commits to `Then` once `Cond`
succeeds. Its determinism is calculated differently:

- If `Cond` is `semidet` and both branches are `det`: result is `det`
- If `Cond` is `nondet`: Mercury reports an error (nondet condition in if-then-else)

This is why `( X > 0 -> abs(X) ; -X )` is `det` even though it uses `;`.

---

## What you will build

### `abs_int(int) = int`

If-then-else that is `det`: returns `N` if `N >= 0`, else `-N`.

### `safe_div(int, int) = int`

If-then-else that is `det`: returns `0` if divisor is 0, else `X // Y`.

### `in_either_range(int) is semidet`

A disjunction of two semidet goals. Succeeds if `X` is in `[1, 10]` or `[100, 200]`.
Both branches are `semidet`; the disjunction is `semidet`.

```mercury
in_either_range(X) :-
    ( X >= 1, X =< 10
    ; X >= 100, X =< 200
    ).
```

### `zero_or_elem(list(int), int) is multi`

A disjunction where one branch is `det` (always produces 0) and another is `nondet`
(generates elements from the list). Result: `multi`.

```mercury
zero_or_elem(_List, 0).          % det — always succeeds
zero_or_elem(List, X) :-         % nondet — may produce many
    list.member(X, List).
```

The `det` branch guarantees at least one solution, making the whole predicate `multi`.

---

## The common mistake

```mercury
:- pred wrong(int::in) is semidet.
wrong(N) :-
    ( N > 0
    ; N = 0    % this makes it det, not semidet
    ).
```

Mercury infers `det` here because `(N > 0 ; N = 0)` always succeeds for non-negative `N`
— but the declared `semidet` is then too weak. The compiler will warn or error.
The fix: either tighten the annotation to `det`, or make the disjunction genuinely
`semidet` by removing the exhaustive alternative.

---

## Checkpoint

- `in_either_range` compiles as `semidet`
- `zero_or_elem` compiles as `multi`; collecting via `solutions/2` gives correct results
- You can read a disjunction and predict its determinism from the table
- You can explain: why is `det ; nondet → multi` rather than `nondet`?
