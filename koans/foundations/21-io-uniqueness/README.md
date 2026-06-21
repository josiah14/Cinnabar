# Solution notes

The koan handed the same consumed IO state (`IO0`) to every call. The fix gives
each call its own input/output pair so the chain is single-threaded.

`fixed.m` uses the `!IO` sugar, which is the idiomatic form:

```mercury
main(!IO) :-
    io.write_string("Hello, world!\n", !IO),
    io.write_string("Hello, Mercury!\n", !IO),
    io.write_string("The world of Mercury says hello!\n", !IO).
```

`!IO` is purely syntactic: the compiler rewrites each `!IO` occurrence into a
distinct `(in, out)` pair — `IO0, IO1`, then `IO1, IO2`, then `IO2, IO` — so it
desugars to the same explicit threading:

```mercury
main(IO0, IO) :-
    io.write_string("Hello, world!\n", IO0, IO1),
    io.write_string("Hello, Mercury!\n", IO1, IO2),
    io.write_string("The world of Mercury says hello!\n", IO2, IO).
```

Both compile and print the same three lines. The explicit form is what you must
fall back to where `!IO` is not allowed — lambda heads
(`koans/foundations/22-io-lambda-head`) and function results
(`koans/foundations/23-io-func-result`).
