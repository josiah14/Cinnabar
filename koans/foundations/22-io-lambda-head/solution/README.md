# Solution notes

`!IO` is rejected in a lambda head because the head must take the form
`pred(<args>) is <determinism>`, and there is nowhere to give `!IO`'s two
implied parameters their `di`/`uo` modes.

The fix names them explicitly and threads them in the body:

```mercury
greet((pred(IO0::di, IO::uo) is det :-
    io.write_string("Ahoy!\n", IO0, IO)
), !IO).
```

Only the lambda *head* is restricted. The surrounding `main` still uses `!IO`,
and the explicit `IO0`/`IO` are local to the lambda body — the inst on `greet`'s
argument, `in(pred(di, uo) is det)`, is what requires those exact modes.
