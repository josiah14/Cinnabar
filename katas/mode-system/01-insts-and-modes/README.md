# 01 — Insts and modes: beyond `in` and `out`

**Concept:** user-defined insts, `bound(...)` instantiation patterns, parametric insts,
inst checking at call sites

**Tutorial cross-reference:** Mercury Tutorial §4 introduces `in`/`out`. User-defined
insts are not covered.

---

## Background

An *inst* describes how instantiated a value is — not its type, but its *shape* at a
particular point. `in` is short for `ground` (fully instantiated). `out` is `free`
(not yet bound). User-defined insts let you be more precise.

---

## Exercise 1: Bounded integer inst

A die face is a value in {1, 2, 3, 4, 5, 6}. Encode this as an inst:

```mercury
:- inst die_face
    ==  bound(1 ; 2 ; 3 ; 4 ; 5 ; 6).
```

Write `roll_die`:
```mercury
:- pred roll_die(int::out(die_face), io::di, io::uo) is det.
```

The output mode `out(die_face)` promises that after the call, the output is not just any
`int` — it is bound to one of the six values. A caller that expects `out(die_face)` mode
gets a guarantee from the compiler.

For the implementation, use a hardcoded value or a random selection. The key part is
ensuring the returned value satisfies the inst. Try returning 7 — the compiler may or
may not catch this depending on how the check is implemented; note what happens.

## Exercise 2: `maybe(int)` requiring `yes`

```mercury
:- inst present == bound(yes(ground)).
```

Write:
```mercury
:- pred require_present(maybe(int)::in(present), int::out) is det.
require_present(yes(N), N).
```

Now call it with `no` and observe the mode error. The mode checker knows the argument
must be `bound(yes(ground))` and rejects the `no` value at compile time — not at runtime.

## Exercise 3: Parametric inst

```mercury
:- inst list_of(I) == bound([] ; [I | list_of(I)]).
```

This is a recursive inst. `list_of(ground)` matches a list where every element is fully
instantiated. `list_of(die_face)` matches a list of die faces.

Write:
```mercury
:- pred first_element(list(T)::in(list_of(ground)), T::out) is det.
first_element([H | _], H).
```

Try calling `first_element` with `[]`. You might expect a mode error — after all, the
function only handles the non-empty case. But `list_of(ground)` matches `[]` (the inst
includes `bound([] ; ...)`), so the mode checker accepts it and you get a runtime
`software_error` instead. **The inst describes what values are *shaped correctly*, not
which cases the predicate handles.** To forbid the empty list, construct a non-empty-only
inst (hint: `bound([ground | list_of(ground)])`).

---

## Checkpoint

- Exercise 1: `roll_die` compiles with `out(die_face)` mode annotation
- Exercise 2: call with `no` gives a mode error at compile time
- Exercise 3: parametric inst declared and used correctly
- You can state: what is the difference between a *type* and an *inst*?
