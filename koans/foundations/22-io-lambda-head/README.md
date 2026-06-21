# Koan: `!IO` in a lambda head

**Broken concept:** `!IO` is used as a parameter in a lambda head
(`pred(!IO) :- ...`), where there is no syntax to give its two implied
parameters their modes.

## Prerequisites

- `koans/foundations/21-io-uniqueness` — IO state threading and `!IO`
- `bridge/06-pipeline-parameterization` — higher-order predicates with
  inst/mode annotations

---

```
mmc --make lambda_head_koan
```

It will fail. Read the error:

```
lambda_head_koan.m:013: Error: the clause head part of a lambda expression
lambda_head_koan.m:013:   should have one of the following forms:
lambda_head_koan.m:013:   `pred(<args>) is <determinism>'
   ...
```

---

## What to observe

A lambda head must be a concrete form like `pred(<args>) is <determinism>` —
both the argument list *and* the determinism are required. `!IO` is sugar for
*two* arguments whose modes are `di` and `uo`, but a lambda head has nowhere to
write those modes, and `pred(!IO)` also omits the `is det` the compiler is
asking for. So `!IO` is forbidden in a lambda head specifically.

This is one of exactly two places `!IO` is rejected (the other is a function
result — `koans/foundations/23-io-func-result`). Everywhere else — sequencing,
if-then-else, disjunction, parallel conjunction — it is safe.

---

## Your task

Write the lambda's two IO parameters explicitly, with their modes, and thread
them by hand inside the body:
`(pred(IO0::di, IO::uo) is det :- io.write_string(..., IO0, IO))`. The outer
call can still use `!IO`. See `solution/fixed.m`.
