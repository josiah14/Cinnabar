# Kata: multi and nondet predicates

**Why Mercury:** in most languages determinism is a runtime property; in Mercury it is a
compile-time contract. `multi` and `nondet` are how that contract says "this relation has
more than one answer" — and the compiler then forces every caller to handle them in a
context prepared for multiple solutions.

You have used `det` and `semidet`. Mercury has two more categories that allow multiple solutions:

- `nondet` — may succeed zero or more times
- `multi` — succeeds at least once, may succeed more times

These are the backtracking categories. You can only call them from a context that is prepared to handle multiple solutions — which in practice means wrapping them with `solutions/2` or `aggregate/4`.

## Collecting solutions

```mercury
:- import_module solutions.

solutions(Generator, Sols)
```

`Generator` is a `pred(T)` with mode `pred(out) is nondet` (or `multi`). `solutions` runs the generator to completion and collects all solutions in a list. The call itself is `det`.

```mercury
:- pred in_range(int::in, int::out) is nondet.
in_range(Max, X) :-
    between(1, Max, X).   % Mercury has no built-in between/3; you write it

solutions(in_range(5), Xs),   % Xs = [1, 2, 3, 4, 5]
```

The predicate you pass to `solutions` is called a *generator*. The lambda form:

```mercury
solutions(pred(X::out) is nondet :- member(X, [3, 1, 4, 1, 5]), Xs)
```

## Steps

### 1. Write `between/3`

```mercury
:- pred between(int::in, int::in, int::out) is nondet.
```

Succeeds once for each integer in `[Lo, Hi]`. Use recursion.

### 2. Collect squares

```mercury
:- pred squares_to(int::in, list(int)::out) is det.
```

Use `solutions/2` with a `nondet` generator that calls `between` and maps to `X * X`.

### 3. Count solutions

```mercury
:- pred count_evens(int::in, int::out) is det.
```

Count the even integers in `1..N`. Use `solutions/2` then `list.length/1`, or use `aggregate/4`:

```mercury
aggregate(
    Generator,
    pred(_::in, Acc::in, Acc1::out) is det :- Acc1 = Acc + 1,
    0, Count
)
```

### 4. Pythagorean triples

```mercury
:- pred pythagorean(int::in, int::out, int::out, int::out) is nondet.
```

Generates all triples `(A, B, C)` with `1 ≤ A ≤ B ≤ C ≤ N` where `A*A + B*B = C*C`.

Then:

```mercury
:- pred all_triples(int::in, list({int, int, int})::out) is det.
```

Uses `solutions/2` to collect them all.

### 5. Mark the determinism correctly

Add explicit mode declarations to every predicate you write. If you declare `is nondet` and the predicate is actually `is multi` (at least one solution guaranteed), Mercury will warn. Understand what the distinction means.

## Getting started

```mercury
:- module multi_nondet.
:- interface.
:- import_module io.
:- pred main(io::di, io::uo) is det.
:- implementation.
:- import_module int.
:- import_module list.
:- import_module solutions.

main(!IO) :- true.
```
