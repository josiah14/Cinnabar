# 09 — function vs predicate

**After:** `katas/foundations/04-higher-order`, `katas/mode-system/05-mode-specific-clauses`

Mercury has both functions (`:- func f(int) = int`) and predicates
(`:- pred p(int::in, int::out)`). They are not two styles for the same thing:
the choice constrains *determinism*, *modes*, and *composability*, and the
relation you are encoding usually decides it for you. This kata makes that
forcing function explicit.

---

## A function is a det predicate with sugar

`:- func double(int) = int` is, to the mode and determinism system, exactly:

```mercury
:- pred double(int::in, int::out) is det.
```

A function is **always** `det`, **always** moded `(in, …, in) = out`, and its
result can be **nested in an expression** — `double(double(X))`,
`area(W, H) * 2`. That is the entire upside, and it is real: expression nesting
is why arithmetic and pipelines read cleanly. The downside is everything that
`det` and the single fixed mode rule out. The interesting cases are precisely
the relations that are *not* total single-valued functions.

---

## When the relation is partial

A division that may be undefined is a **partial** relation. As a predicate it is
just `semidet` — the goal either binds the quotient or fails:

```mercury
:- pred safe_div(int::in, int::in, int::out) is semidet.
safe_div(N, D, Q) :- D \= 0, Q = N // D.
```

The guard `D \= 0` comes **before** `Q = N // D` on purpose. Writing the result
into the clause head — `safe_div(N, D, N // D) :- D \= 0` — evaluates `N // D`
during head unification, *before* the guard runs, so `safe_div(1, 0, _)` throws
a division-by-zero exception instead of failing. Order matters because the head
is not a guard.

A **function** cannot fail, so it has to widen its result type to carry the
"undefined" case:

```mercury
:- func checked_div(int, int) = maybe(int).
checked_div(N, D) = ( if D \= 0 then yes(N // D) else no ).
```

Now every caller must pattern-match `yes(Q)` / `no`, and you can no longer nest
the call in an arithmetic expression — the composability advantage is gone. The
predicate kept failure in the determinism system; the function pushed it into
the data.

---

## When the relation is multi-valued

"`F` divides `N`" relates one `N` to *many* `F`. No function can return many
values without packaging them into a list (eager, and a different interface). A
`nondet` predicate yields them as solutions:

```mercury
:- pred divides(int::in, int::out) is nondet.
divides(N, F) :- nondet_int_in_range(1, N, F), N rem F = 0.
```

The caller chooses how many it wants — one (`semidet` context), all
(`solutions/2`), or a fold. A function form forecloses that choice.

---

## When the relation runs backwards

The sharpest predicate-only capability is multi-moded reversibility: one
relation, several modes. That is the subject of
`05-mode-specific-clauses` (`my_append/3` running forwards, backwards, and as a
generator). A function is locked to its one forward mode. Keep that kata in mind
as the fourth case here — it is the reason "make it a predicate" is the safe
default when you are not sure.

(Currying cuts across both forms: a function *and* a predicate can be partially
applied — see `bridge/12-currying-and-impurity`. That is orthogonal to the
determinism question this kata is about.)

---

## Why Mercury

The function/predicate decision is checked, not stylistic. Declare `checked_div`
as a plain `int`-returning function and the partiality has nowhere to live;
declare `divides` as a function and the compiler rejects the many-solutions
body. The determinism of the relation is a typed, compile-time property, and it
picks the shape for you.

---

## Tasks

Work in `start.m`. Each predicate/function has a stub body; replace it so the
checks pass.

**Task 1 — `area/2`:** make the function return `W * H`. Confirm it nests: the
check calls `area(3, 4)` directly inside the comparison.

**Task 2 — `safe_div/3`:** make it `semidet` — fail when `D = 0`, otherwise bind
the quotient. Guard before you divide.

**Task 3 — `checked_div/2`:** the function version of Task 2. Return
`yes(N // D)` when defined, `no` otherwise. Notice how the call site changes.

**Task 4 — `divides/2`:** enumerate the divisors of `N` as a `nondet` predicate.
`nondet_int_in_range(1, N, F)` (from `int`) generates the candidates; keep those
where `N rem F = 0`. `solutions/2` collects them in sorted order.

---

## Expected output

```
PASS: area 3x4 = 12
PASS: safe_div 10/2 = 5
PASS: safe_div 1/0 fails
PASS: checked_div 10/2 = yes(5)
PASS: checked_div 1/0 = no
PASS: divisors of 12 = [1,2,3,4,6,12]
```

---

## Checkpoint

- You can state the one-line rule: a function is a `det`, single-mode predicate
  whose result nests in expressions.
- You can name what a function *cannot* express that a predicate can: failure
  (`semidet`), multiple solutions (`nondet`/`multi`), and reverse modes.
- You can explain why `checked_div` needs `maybe` and what it costs the caller.
