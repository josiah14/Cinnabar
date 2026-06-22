# 06 — Determinism and negation

**Concept:** `\+` is always `semidet`; the variable-binding rules for negation; the classic
pitfall of trying to use `\+` as a filter

**Why Mercury:** in most languages determinism is a runtime property; in Mercury it is a
compile-time contract. Negation has a fixed place in that contract — `\+` is always
`semidet` — which is exactly why it cannot bind variables, and why misusing it as a filter
fails to compile rather than misbehaving at runtime.

**Not in the Mercury tutorial.**

---

## `\+` is always `semidet`

`\+ Goal` succeeds if `Goal` fails and fails if `Goal` succeeds. The argument's
determinism doesn't matter — the result is always `semidet`:

```mercury
:- pred nonzero(int::in) is semidet.
nonzero(N) :- \+ N = 0.
```

Even if `Goal` is `nondet`, `\+` only asks "does at least one solution exist?" — it
commits to failure (if yes) or success (if no) without producing solutions.

---

## Variables must be bound before `\+`

`\+` cannot generate bindings. Any variable used inside `\+` must already be bound at
the point of the `\+` call:

```mercury
% WRONG — X is not bound; \+ cannot bind it
:- pred broken(int::in) is semidet.
broken(Max) :- \+ between(1, Max, _X).
```

This is a mode error. The fix is to either:
1. Bind the variable before `\+` (use it as `in`)
2. Move the negation to wrap the entire goal that contains the binding

---

## Correct use of `\+` with existential goals

`\+` *can* be applied to a goal that internally generates candidates — as long as the
generated variable is not used outside `\+`:

```mercury
:- pred no_even_in_range(int::in) is semidet.
no_even_in_range(N) :-
    \+ (between(1, N, X), X mod 2 = 0).
```

`X` is generated inside the `\+` and never escapes. Mercury accepts this because the
mode of `\+` only cares about success/failure, not what `X` was bound to.

---

## The classic pitfall: `\+` as a filter

```mercury
% WRONG — this does NOT filter odds from a list
:- pred odd_filter(int::in, list(int)::out) is nondet.
odd_filter(Max, X) :-
    between(1, Max, X),
    \+ X mod 2 = 0.
```

This looks correct but is a mode error: `X` in `\+ X mod 2 = 0` is used as `in` (it was
bound by `between`), and the predicate body is actually fine here — the issue is declaring
it `nondet` when `between/3` makes it `nondet` and `\+` makes the guard `semidet`. This
example compiles. The pitfall version is:

```mercury
% The thing you should NOT write:
:- pred broken_filter(int::in) is nondet.
broken_filter(Max) :- \+ between(1, Max, _X).
% ERROR: _X is free inside \+ — \+ cannot bind _X
```

The correct pattern for filtering via negation: generate first, negate the condition on
the already-bound value.

---

## What you will build

### `nonzero(int) is semidet`

Succeeds iff `N ≠ 0`. Use `\+ N = 0`.

### `no_even_in_range(int) is semidet`

Succeeds iff there is no even integer in `1..N`. Use `\+ (between(1, N, X), X mod 2 = 0)`.

### `no_small_factor(int) is semidet`

Succeeds iff `N > 1` and `N` has no factor in `2..N-1`. This is a primality test via
negation.

### `odd_integers(int, list(int)) is det`

Collect all odd integers from `1` to `N`. Use `solutions/2` with `between` and a `\+`
filter. The lambda for `solutions` must be `nondet`:
```mercury
solutions((pred(X::out) is nondet :- between(1, N, X), \+ X mod 2 = 0), Odds)
```

### `exclude_list(list(int), list(int), list(int)) is det`

Filter the first list to exclude any element appearing in the second. Use
`list.filter` with `\+ list.member(X, Excluded)`.

---

## Checkpoint

- All predicates compile with correct determinism annotations
- `no_small_factor` correctly identifies primes
- `odd_integers(10, Odds)` gives `[1, 3, 5, 7, 9]`
- You can state: why is `\+` always `semidet` regardless of its argument's determinism?
- You can state: what is the mode error that occurs when `\+` contains a free variable?
