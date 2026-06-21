# Puzzle: expression evaluator with variables

**Primary skills:** discriminated unions, `map(string, int)`, `maybe(int)`, recursive interpreter

**Why Mercury:** this is a miniature interpreter — the shape of recursive ADT processing
in Mercury is clean and direct. The `maybe` threading mirrors what a QBN engine does with
optional / fallible lookups.

## Prerequisites

- `katas/foundations/02-maybe` — `bind_maybe`, `map_maybe`, chaining optional values
- `katas/type-system/01-discriminated-unions` — recursive ADTs, pattern matching on constructors

---

## The problem

Evaluate arithmetic expressions that may contain variables. Return `maybe(int)`: `yes(N)`
on success, `no` if any variable is unbound or division by zero occurs.

---

## The expression type

```mercury
:- type expr
    --->    lit(int)
    ;       var(string)
    ;       add(expr, expr)
    ;       sub(expr, expr)
    ;       mul(expr, expr)
    ;       div(expr, expr)
    ;       neg(expr).
```

---

## The evaluator signature

```mercury
:- type env == map(string, int).

:- func eval(env, expr) = maybe(int).
```

---

## Approach: `maybe` threading

Every recursive call can return `no`. Thread `maybe` through the recursion without
explicit if-then-else at every level, using a locally-defined `bind_maybe`:

```mercury
:- func bind_maybe(maybe(T), func(T) = maybe(U)) = maybe(U).
bind_maybe(no, _) = no.
bind_maybe(yes(X), F) = F(X).
```

Then the evaluator cases:

```mercury
eval(Env, add(A, B)) =
    bind_maybe(eval(Env, A), (func(VA) =
        map_maybe((func(VB) = VA + VB), eval(Env, B))
    )).

eval(Env, div(A, B)) =
    bind_maybe(eval(Env, A), (func(VA) =
        bind_maybe(eval(Env, B), (func(VB) =
            ( VB = 0 -> no ; yes(VA // VB) )
        ))
    )).

eval(Env, var(Name)) =
    ( map.search(Env, Name, V) -> yes(V) ; no ).
```

---

## What to observe

The `bind_maybe` chain is analogous to `do`-notation in Haskell or `flatMap` in Scala.
Each bind step: if the previous result is `no`, propagate `no`; if it is `yes(V)`,
continue with `V`.

This is precisely the shape of a QBN eligibility check: a chain of conditions where any
`no` (condition fails) short-circuits the whole expression.

---

---

## Acceptance criteria

With environment `Env = {"x" -> 10, "y" -> 3}`:

| Expression | Expected result | Why |
|---|---|---|
| `lit(7)` | `yes(7)` | literal |
| `var("x")` | `yes(10)` | bound variable |
| `var("z")` | `no` | unbound variable |
| `add(lit(3), lit(4))` | `yes(7)` | addition |
| `sub(lit(10), lit(3))` | `yes(7)` | subtraction |
| `mul(lit(3), lit(4))` | `yes(12)` | multiplication |
| `div(lit(10), lit(3))` | `yes(3)` | integer division |
| `div(lit(10), lit(0))` | `no` | division by zero |
| `neg(lit(5))` | `yes(-5)` | negation |
| `add(var("x"), lit(5))` | `yes(15)` | the sample |
| `div(var("x"), var("y"))` | `yes(3)` | 10/3 = 3 |
| `add(var("x"), var("z"))` | `no` | z unbound |
| `mul(add(var("x"), lit(2)), var("y"))` | `yes(36)` | (10+2)×3 |

## Extensions

- Add `let(string, expr, expr)` — bind a variable in scope for the body expression
- Add `if_then_else(expr, expr, expr)` — condition must evaluate to 0 (false) or non-zero (true)
- Use `map(string, expr)` instead of `map(string, int)` to allow lazy bindings
