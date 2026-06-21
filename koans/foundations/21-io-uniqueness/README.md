# Koan: reusing a consumed IO state

**Broken concept:** the same `di` IO state variable is handed to three
sequential `io.write_string` calls; once the first call consumes it, it is dead.

## Prerequisites

- `katas/foundations/00-reactivation/01-hello-world` — `io.di`/`io.uo`, `!IO`

---

```
mmc --make io_uniqueness_koan
```

It will fail. Read the error carefully:

```
io_uniqueness_koan.m:013: unique-mode error: the called procedure would
io_uniqueness_koan.m:013:   clobber its argument, but variable `IO0' is still live.
```

---

## What to observe

Three terms to understand:

- **`clobber`** — `di` ("destructive input") means the incoming value is
  consumed and cannot be referenced again. The predicate *clobbers* it.
- **`still live`** — `IO0` appears again on the next two lines. The compiler
  checked every use and found more than one reference to a variable that should
  have been consumed and never seen again.
- **`unique-mode error`** — this is the class of errors that enforce
  single-threadedness. Mercury's mode system, not runtime checks, prevents you
  from using a consumed value.

The bug: `IO0` is passed to all three `io.write_string` calls as the "current
IO state" argument, but after the first call consumes it, the compiler won't let
you hand it out again. (Each call also names `IO` as its *output* state; a `uo`
result can't be produced three times either — but the compiler stops at the
first error, the still-live `IO0`.)

This is the most basic IO mistake in Mercury, and it is the reason `!IO` exists:
the sugar threads a fresh variable through every call so you cannot reuse a
consumed one by accident.

---

## Going further

The mode system rejects `!IO` in exactly two other places — each is its own
koan:

- **`koans/foundations/22-io-lambda-head`** — `!IO` as a parameter in a lambda
  head. There is no syntax to give its two implied parameters their `di`/`uo`
  modes.
- **`koans/foundations/23-io-func-result`** — `!IO` as a function result. `!IO`
  is two variables, but a function returns one value.

Everywhere else — sequencing, if-then-else, disjunction, parallel conjunction —
`!IO` is safe to reach for.

---

## Your task

Thread the IO state so each call gets its own token: give the first call an
input/output pair, feed its output into the second, and that into the third
(`io.write_string(S1, IO0, IO1), io.write_string(S2, IO1, IO2),
io.write_string(S3, IO2, IO)`). Or — the idiomatic fix — use the `!IO` sugar,
which expands to exactly that chain. After fixing, the program should compile
and print all three lines. See `solution/fixed.m`.
