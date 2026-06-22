# 01 — The six determinism categories

**Concept:** `det`, `semidet`, `multi`, `nondet`, `erroneous`, `failure` — one predicate
per category

**Why Mercury:** in most languages determinism is a runtime property — you find out how
many answers a routine has by running it. In Mercury it is a compile-time contract: each
of these six categories is a promise the compiler checks, so "how many solutions, and can
it fail?" is settled before the program ever runs.

**Tutorial cross-reference:** Mercury Tutorial §3 covers `det`, `semidet`, and `nondet`.
This kata names and exercises all six categories explicitly, including the three the
tutorial omits.

---

## The six categories

| Category | Solutions | Can fail? | Notes |
|----------|-----------|-----------|-------|
| `det` | exactly 1 | no | The default for total functions |
| `semidet` | 0 or 1 | yes | Boolean tests, searches that may find nothing |
| `multi` | 1 or more | no | Always has at least one solution, may have many |
| `nondet` | 0 or more | yes | May fail, may backtrack |
| `erroneous` | 0 (throws) | no | Cannot return normally |
| `failure` | 0 (always fails) | yes (always) | Useful as a "dead end" in disjunctions |

---

## One predicate per category

**`det`** — an arithmetic expression evaluator (from `katas/type-system/01-discriminated-unions`):
```mercury
:- func eval(expr) = int.
:- mode eval(in) = out is det.
```

**`semidet`** — safe list head (fails on empty list):
```mercury
:- pred safe_head(list(T)::in, T::out) is semidet.
safe_head([H | _], H).
```

**`multi`** — coin denominations summing to N pence (always at least one: all 1p):
```mercury
:- pred coin_combo(int::in, list(int)::out) is multi.
```
Use denominations `[1, 2, 5, 10]`. The combination of all 1p coins guarantees at
least one solution, making it `multi` rather than `nondet`.

**`nondet`** — factor finder (may have 0, 1, or many factors):
```mercury
:- pred factor(int::in, int::out) is nondet.
factor(N, F) :-
    between(2, N - 1, F),
    N mod F = 0.
```
`between/3` is a predicate that generates integers in a range — write it or use the
standard library. For N=1 or N prime, there are no factors, so this is `nondet`.

**`erroneous`** — controlled abort:
```mercury
:- pred abort(string::in) is erroneous.
abort(Msg) :- throw(software_error(Msg)).
```
`erroneous` means "this call never returns normally — it always throws." The compiler
uses this to reason about unreachable code after the call.

**`failure`** — explicit dead end:
```mercury
:- pred always_fails is failure.
always_fails :- fail.
```
`failure` is useful in a disjunction when you want to document that one branch is
intentionally unreachable, or in tests for exhaustiveness.

---

## Wire them together

Write a `main` that:
1. Evaluates a hardcoded `expr` (det)
2. Gets the head of a list, printing "empty" if it fails (semidet)
3. Collects all `coin_combo(10, _)` solutions via `solutions/2` (multi via solutions → det)
4. Collects all factors of 12 (nondet via solutions → det)
5. Calls `abort` in a `catch_any` to show the erroneous path
6. Calls `always_fails` in a `( always_fails ; io.write_string("dead end caught\n", !IO) )` disjunction

---

## Checkpoint

- All six predicates compile with the correct determinism annotation
- The compiler rejects if you misclassify one (e.g., calling `nondet` from a `det` context
  without `solutions`)
- You can state the determinism of each and explain why
