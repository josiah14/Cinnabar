# Koan: `det` declared, else-branch calls `semidet` → inferred `semidet`

**Broken concept:** declaring a predicate `det` when its else-branch contains a call
to a `semidet` predicate — Mercury infers `semidet` even when the call logically
cannot fail

## Prerequisites

- `katas/determinism/01-six-categories` — det, semidet, and their meaning
- `koans/determinism/01-det-mismatch` — basic det/semidet mismatch

---

```
mmc --make --grade asm_fast.par.gc.stseg det_semidet_koan
```

```
error: determinism declaration not satisfied.
  Declared `det', inferred `semidet'.
  The reason for the difference is the following.
  Call to `det_semidet_koan.pop'(in, out, out) can fail.
```

---

## What to observe

`is_empty/1` and `pop/3` together cover all constructors of `stack(T)`:
`is_empty` succeeds on `empty`, `pop` succeeds on `node(Top, Rest)`.
Logically, if `is_empty` fails (we're in the else branch), then `pop` cannot fail.

Mercury's determinism checker does not reason about this. It checks each call
independently: `pop/3` is `semidet`, so any context containing a call to `pop/3`
is at least `semidet`, regardless of what the surrounding if-then-else has already
established. The declared `det` is rejected.

This is not a bug — it is a deliberate design. Mercury's type system is not powerful
enough to express "non-empty stack", so the compiler cannot prove `pop` is safe in
this context.

---

## Your task

Use a 3-way if-then-else so that `pop/3` appears in a *condition* position rather
than a goal position. A `semidet` call in condition position is expected to potentially
fail — that is not an error. The third (unreachable) branch makes the whole expression
`det`:

```mercury
( is_empty(S) ->
    ...
; pop(S, Top, Rest) ->
    ...
;
    true  % unreachable — add a comment explaining why
).
```
