# Koan: STM predicates require transaction context

## What to observe

Compile `stm_context_koan.m`:

```
mmc --make stm_context_koan
```

The errors:

```
stm_context_koan.m:13:   type error: variable `STATE_VARIABLE_IO_9' has type
stm_context_koan.m:13:     `io.state',
stm_context_koan.m:13:   expected type was
stm_context_koan.m:13:     `stm_builtin.stm'.
stm_context_koan.m:14:   type error: variable `STATE_VARIABLE_IO_10' has type
stm_context_koan.m:14:     `stm_builtin.stm',
stm_context_koan.m:14:   expected type was
stm_context_koan.m:14:     `io.state'.
```

Two errors, not one. The state variable gets "mis-typed" at the first call
(`io.state` fed into `stm`), then the corrupted output (`stm`) propagates to
the next call that expected `io.state`. The cascade is Mercury showing you the
exact location where the wrong type enters and where it re-surfaces.

## Your task

Fix `main` so that `read_stm_var` runs in a transaction context.

The function `new_stm_var` creates the transactional variable — it runs in IO
context and is correct as-is. The read must run inside `atomic_transaction`,
which provides the `stm` state.

## What to learn

Mercury enforces the IO/STM boundary statically. `io.state` and `stm_builtin.stm`
are distinct types — there is no implicit coercion, no dynamic check, no runtime
penalty. The transaction boundary is a compile-time guarantee, not a discipline
you enforce yourself.

The two-error cascade is a common pattern: fixing the first call at line 13
automatically fixes the cascade error at line 14, because both errors share the
same mis-threaded state variable.
