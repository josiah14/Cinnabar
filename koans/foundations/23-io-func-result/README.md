# Koan: `!IO` as a function result

**Broken concept:** `!IO` is used in the result position of a function
(`hello(!IO) = !IO`), but a function returns a single value.

## Prerequisites

- `koans/foundations/21-io-uniqueness` — IO state threading and `!IO`

---

```
mmc --make func_result_koan
```

It will fail. The key error:

```
func_result_koan.m:015: Error: !IO cannot be a function result.
func_result_koan.m:015:   You probably meant !:IO.
```

You will also see cascade errors about `hello'/1` and `hello'/2` — they all stem
from the same confusion: `!IO` expanded to two arguments, so the compiler saw
two different arities for `hello`.

---

## What to observe

`!IO` desugars to *two* variables — the "before" state (`!.IO`) and the "after"
state (`!:IO`). A function returns exactly one value, so there is no result slot
for a pair. The compiler's hint "You probably meant `!:IO`" points at the single
out-state, but the real issue is structural: IO threading is inherently
two-ended, and a function result has room for only one end.

This is the second of exactly two places `!IO` is rejected (the other is a
lambda head — `koans/foundations/22-io-lambda-head`).

---

## Your task

Name the IO states explicitly. You can keep `hello` a function that takes one io
and returns the next — `hello(IO0) = IO :- io.write_string(..., IO0, IO)` —
called as `!:IO = hello(!.IO)`. More idiomatically, IO-effecting code is written
as a predicate, where the two-ended threading is natural. See `solution/fixed.m`.
