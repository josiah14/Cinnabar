# Solution: STM predicates require transaction context

## The fix

Wrap the `read_stm_var` call inside `atomic_transaction`:

```mercury
main(!IO) :-
    new_stm_var(42, Var, !IO),
    atomic_transaction(
        (pred(Val::out, S0::di, S::uo) is det :-
            read_stm_var(Var, Val, S0, S)
        ), Result, !IO),
    io.write_line(Result, !IO).
```

`atomic_transaction(Pred, Result, !IO)` — the predicate `Pred` has type
`pred(T, stm, stm)`. That `stm::di, stm::uo` pair is the transaction context
that `read_stm_var` requires. Inside the lambda, `S0` and `S` fill that role.

## The two-context pattern

| Where | State | Operations |
|---|---|---|
| IO context | `!IO` | `new_stm_var`, `atomic_transaction`, IO |
| Transaction context | `!STM` | `read_stm_var`, `write_stm_var`, `retry` |

`atomic_transaction` is the gate between them. You cannot reach into a
transactional variable without passing through that gate.

## Why the explicit S0/S naming

The lambda head `(pred(Val::out, S0::di, S::uo) is det :- ...)` uses explicit
names rather than `!STM`. Mercury's state-variable shorthand (`!Name`) works
in predicate heads and clause bodies, but in lambda heads the explicit
`!.Name::di, !:Name::uo` form is needed. Using `S0/S` avoids the syntax
ambiguity entirely and makes the threading visible — useful when learning STM.
