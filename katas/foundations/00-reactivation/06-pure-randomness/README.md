# 06 — Pure Randomness

> **Advanced recall — defer.** This kata uses Mercury's impure/foreign sub-system
> (`mutable`, `foreign_proc`, `:- initialize`) before those tools are introduced.
> Skip it in a first reactivation pass and return after `katas/advanced/01-ffi-depth`.

**Concept:** `mutable` global state, `impure`/`semipure` annotations, `pragma promise_pure`, `foreign_decl`/`foreign_proc`, `:- initialize`

**Before you open `roll.m`:** this program generates random numbers using Mercury's impure corner — the part of the language that steps outside the pure declarative model. Write down what you remember about how Mercury handles code that has side effects outside of the `!IO` threading discipline.

---

## What to look for

Mercury's purity system has three levels: `pure`, `semipure`, and `impure`. Most Mercury code is `pure` — referentially transparent, safe to reorder, safe to eliminate. Impure code breaks those guarantees.

- `impure` — may have arbitrary side effects; cannot be reordered or eliminated by the compiler.
- `semipure` — may read global state but not write it; can be called multiple times without changing the world, but the result may vary.
- `pragma promise_pure` — tells the compiler "trust me, this is actually pure from the outside even though its internals are not." Used to wrap an impure implementation in a pure interface.

`foreign_proc` calls C code directly. `foreign_decl` declares C-level declarations (types, headers). Together they are how Mercury talks to the outside world when the standard library does not have what you need.

`:- initialize` marks a predicate to be called at program startup — before `main` runs. Used here to seed the random number generator once.

`mutable` declares a global mutable cell — a named, typed piece of global state that can be read (`get_<name>`) and written (`set_<name>`) using `impure`/`semipure` predicates.

## After reading

Could you say:
- Why is `semipure` sufficient for reading a mutable, rather than `impure`?
- What does `pragma promise_pure` buy you, and what responsibility does it put on you as the programmer?
- Why is `:- initialize` necessary here instead of just initializing in `main`?
