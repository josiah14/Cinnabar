# 03 — Scope annotations: catching mistakes at compile time

**Concept:** `require_complete_switch`, `require_det`, `require_switch_arms_det`,
using compiler-enforced exhaustiveness as a safety net

**Why Mercury:** in most languages determinism is a runtime property; in Mercury it is a
compile-time contract. These scope annotations let you tighten that contract locally —
asking the compiler to *prove* a switch is complete or a goal is `det`, and to fail the
build the moment it is not.

**Not in the Mercury tutorial.**

---

## The problem

Pattern matching on a discriminated union is exhaustive *at the time you write it*. But
when you add a new constructor later, every existing switch becomes incomplete. In a large
codebase, this is a common source of bugs that only appear at runtime.

Mercury provides scope annotations that turn these runtime bugs into compile-time errors.

---

## Exercise 1: `require_complete_switch`

Define a traffic light ADT:
```mercury
:- type light ---> red ; amber ; green.
```

Write a function without the scope:
```mercury
:- func action(light) = string.
action(red) = "stop".
action(green) = "go".
% Missing: amber
```

The compiler may warn about this, but depending on settings may not error. Add the scope:

```mercury
:- func action(light) = string.
action(Light) = Action :-
    require_complete_switch [Light]
    (
        Light = red,    Action = "stop"
    ;
        Light = green,  Action = "go"
    ).
```

Compile — the compiler errors on the missing `amber` case. Add `amber`, confirm it compiles.

Now add a new constructor:
```mercury
:- type light ---> red ; amber ; green ; flashing_amber.
```

Recompile without adding the `flashing_amber` case to `action`. The scope annotation
catches it immediately.

## Exercise 2: `require_det`

Inside a `semidet` predicate, you may know that a specific sub-goal is actually `det`.
Use `require_det` to assert this:

```mercury
:- pred process(list(int)::in, int::out) is semidet.
process([_ | _] = List, Sum) :-
    require_det (list.foldl(int.plus, List, 0, Sum)).
```

`list.foldl` is `det`, so `require_det` succeeds. Now try it on a `semidet` sub-goal:
```mercury
require_det (list.head(List, _)).
```
`list.head` is `semidet` — the compiler rejects the `require_det` scope.

This is useful for documentation: you are asserting to future readers (and the compiler)
that this sub-goal cannot fail. If a future refactor makes it possibly-failing, the
compiler catches the regression.

## Exercise 3: Combine both

Write a `classify` predicate over the `light` type that:
1. Uses `require_complete_switch` to ensure all constructors are handled
2. Has one arm that uses `require_det` on an internal computation
3. Confirm that adding a new `light` constructor breaks the build immediately

---

## Checkpoint

- `require_complete_switch` catches a missing constructor at compile time
- Adding a new constructor without updating the switch causes a build failure
- `require_det` on a `semidet` sub-goal is rejected by the compiler
- You can explain: why is this better than relying on compiler warnings alone?
