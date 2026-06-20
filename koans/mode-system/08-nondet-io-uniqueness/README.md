# Koan: `nondet` condition + IO branches → uniqueness mismatch

**Broken concept:** using a `nondet` predicate as the condition of an if-then-else
where `!IO` is threaded through the branches

## Prerequisites

- `katas/mode-system/03-uniqueness-deep` — unique/mostly_unique distinction
- `koans/determinism/07-nondet-condition-multi` — nondet condition → multi

---

```
mmc --make --grade asm_fast.par.gc.stseg nondet_io_koan
```

Two errors fire together:

```
error: determinism declaration not satisfied.
  Declared `det', inferred `multi'.
  Call to `any_even'(in, out) can succeed more than once.

mode error: variable `STATE_VARIABLE_IO_0' has
  instantiatedness `mostly_unique',
  expected instantiatedness was `unique'.
  This kind of uniqueness mismatch is usually caused by
  doing input/output or some other kind of destructive
  update in a context where it can be backtracked over,
  such as the condition of an if-then-else.
```

---

## What to observe

The `!IO` state token is **unique** — consumed and produced exactly once. In a `det`
or `semidet` if-then-else the token is safely threaded: the condition commits to one
outcome, then the chosen branch uses it once.

A `nondet` condition breaks this. Each solution of the condition would need its own
copy of the IO token — impossible, because unique values have exactly one owner.
Mercury describes this degradation as `mostly_unique`: the token exists, but is no
longer guaranteed to be the sole reference to it in a backtracking context.

The compiler reports *two* errors: the determinism mismatch (`det` vs `multi`) and
the resulting uniqueness mismatch on `STATE_VARIABLE_IO_0`. They come from the same
root cause.

---

## Your task

Do not change `any_even` — keep it `nondet`. Instead, move the nondeterminism
*outside* the IO context. Collect all solutions first, then pattern-match the list in
a `semidet` condition:

```mercury
solutions(any_even(List), [X | _])
```

`solutions/2` is `det` (always produces a list). The pattern `[X | _]` is `semidet`
(fails for an empty list). So the if-then-else condition is `semidet` — safe for IO.
