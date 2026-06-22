# 12 — IO design patterns

**Concept:** `io.open_input`/`io.close_input`, the three-way result of
`io.read_line_as_string`, `io.res(T)` as errors-carried-as-values, and separating
IO from pure logic

**Why Mercury:** in most languages a file read either returns data or throws. Mercury
makes the *failure* a value you must pattern-match: `io.res(T)` and the `ok`/`eof`/`error`
result of a line read are ordinary discriminated unions, and the determinism/type system
will not let you reach the data without first handling the error case. "Forgot to check
the error" becomes a compile-time gap, not a runtime surprise.

---

## `io.res(T)` — the result of an IO action that can fail

```mercury
:- type io.res(T)
    --->    ok(T)
    ;       error(io.error).
```

`io.open_input` returns one of these. You cannot use the stream without first
deconstructing the result and handling `error`:

```mercury
io.open_input(FileName, OpenResult, !IO),
(
    OpenResult = ok(Stream),
    % ... use Stream ...
    io.close_input(Stream, !IO)
;
    OpenResult = error(Err),
    % io.error_message(Err) is the OS-level message ("No such file...")
    ...
).
```

`io.error_message/1` turns the `io.error` into a human-readable string.

---

## `io.read_line_as_string` — a *three*-way result

Reading a line is not "line or no line." It is one of three outcomes, and a correct
reader handles all three:

```mercury
:- type io.result(T)
    --->    ok(T)        % a line (including its trailing '\n')
    ;       eof          % end of file — normal termination
    ;       error(io.error).
```

The classic mistake is folding `error` into `eof` (stop and return what you have). That
turns an OS-level read failure into a silently-truncated result. Keep them distinct:
`eof` ends the list with `ok([])`; `error` propagates as `error(Err)`.

---

## Errors travel as values, not exceptions

The recurring pattern: a helper that can fail returns `io.res(...)`, and the caller
propagates `error(Err)` upward rather than throwing. A partial read becomes
`error(Err)` — never a short `ok`. This is the whole point of `io.res`: the type
system forces every caller to decide what to do with the failure.

(Contrast with `exception.throw`, which is for invariant violations that should never
happen in correct code. A missing file is *expected* — model it as a value. See
`katas/foundations/07-exceptions` and `bridge/11-error-handling` for choosing between
`maybe`, custom error types, `io.res`, and exceptions.)

---

## Separate IO from pure logic

Read the file into a `list(string)` once, then process the list with ordinary pure
functions. `count_nonblank` takes no `!IO` — it is a plain `func` over the data. Pushing
IO to the edges and keeping the core pure is what makes the core testable and reusable.

---

## What you will build

`start.m` writes a known three-line fixture, then exercises three predicates you
implement:

### Exercise 1 — `read_lines`

```mercury
:- pred read_lines(io.text_input_stream::in, io.res(list(string))::out,
    io::di, io::uo) is det.
```

Read every line from an open stream into a list, in file order, trailing newline
stripped (`string.rstrip`). Handle all three `read_line_as_string` outcomes; propagate
`error(Err)` rather than truncating.

### Exercise 2 — `load_lines`

```mercury
:- pred load_lines(string::in, io.res(list(string))::out, io::di, io::uo) is det.
```

Open a named file, read it with `read_lines`, close the stream. A failed open returns
`error(Err)` — do not swallow it into an empty `ok`.

### Exercise 3 — `count_nonblank`

```mercury
:- func count_nonblank(list(string)) = int.
```

A pure function: count the lines that are not `""`. `list.filter` then `list.length`.

---

## Checkpoint

- `read_lines` returns lines in file order, not reversed
- A missing file makes `load_lines` return `error(_)`, and the test for it passes
- `count_nonblank` is pure — it has no `io::di, io::uo` arguments
- You can state: why is `io.read_line_as_string`'s result `ok`/`eof`/`error` and not
  just `maybe(string)`? What does collapsing `error` into `eof` cost you?

Run `runtests` to compile and check all four assertions.
