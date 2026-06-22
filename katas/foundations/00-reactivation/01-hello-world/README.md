# 01 — Hello World

**Concept:** bare module skeleton, `io.di`/`io.uo` mode annotations, `!IO` state
threading

Make `start.m` print exactly these four lines:

```
Hello, World!
Hello, Mercury!!
IO token threaded: write_string 2
IO token threaded: write_string 3
```

The starter prints only the first line. Add the other three by threading the IO
state through each `io.write_string` call.

---

## Two ways

There are two idiomatic solutions, and they compile to the same thing:

- **Explicit threading** (`start_explicit.m`) — name each intermediate IO state
  and chain them: `io.write_string(S1, IO0, IO1), io.write_string(S2, IO1, IO2), ...`,
  with the output of one call feeding the next. This is the IO state threaded by
  hand, the way a pure functional language would.
- **`!IO` sugar** (`start_bang.m`) — write `!IO` in every call and let the
  compiler insert the intermediate `IO0, IO1, IO2, …` for you. Less typing,
  identical result.

Implement both approaches (edit `start_bang.m` and `start_explicit.m`), then run
`runtests` to compile both and check your output against the four lines above.
(If you get stuck on the threading itself, the fixed program in
`koans/foundations/21-io-uniqueness/solution/fixed.m` shows the shape.)

> If you see `unique-mode error: ... variable 'IO0' is still live`, you reused a
> consumed IO state in two calls. That mistake — and why the mode system forbids
> it — is its own exercise: `koans/foundations/21-io-uniqueness`.

---

## Expected output

```
Hello, World!
Hello, Mercury!!
IO token threaded: write_string 2
IO token threaded: write_string 3
```
