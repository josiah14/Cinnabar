# Bridge: parser hardening

**After:** `katas/parsing/03-parsing-utils` and `puzzles/parsing/02-csv-reader`

**Why Mercury:** Mercury draws a line the determinism system enforces — a parser that
*fails* (`semidet`, producing no output) is a different thing from one that *returns*
an `error(Line, Msg)` value (`det`, with a structured result). Silent failure and
reported failure cannot be confused, because they have different determinisms and
different types. Threading a line counter through the DCG is likewise mode-checked:
the compiler verifies the state is produced before it is consumed at every rule.

`csv_reader.m` is a working CSV parser built with DCG rules. It handles quoted fields
(including embedded commas) and CRLF/LF line endings.

Build and run it first:

```
mmc --make --grade asm_fast.par.gc.stseg csv_reader
./csv_reader
```

The tasks add line number tracking, structured error reporting, and RFC 4180 edge
case handling.

---

## Extension tasks

### 1. Line number tracking

Add a position counter to the parse. Thread an `int` (current line number, starting
at 1) through every DCG rule as an extra argument.

The DCG hidden arguments are the input/output list pair. Adding a state argument
makes rules take the form `rule(ExtraIn, ExtraOut, ListIn, ListOut)` — but in DCG
notation you write:

```mercury
:- pred parse_csv(int, int, csv, list(char), list(char)).
:- mode parse_csv(in, out, out, in, out) is det.
parse_csv(Line0, Line, Rows) --> ...
```

The `!` notation also works: `parse_csv(!Line, Rows) --> ...`

Increment the line counter in the `newline` rule. By the end of a successful parse,
the line counter equals the number of lines parsed.

Return the final line number as part of the top-level result.

### 2. Structured error reporting

The current parser silently ignores malformed input (the `_ -->` case in
`parse_csv` returns an empty list). Add explicit error tracking.

Define a parse result type:

```mercury
:- type parse_result(T) ---> ok(T) ; error(int, string).
```

where the `int` is the line number where the error occurred and the `string`
describes the problem.

Change the top-level `parse` function to return `parse_result(csv)`. On a field
parse failure, produce `error(Line, "malformed field at line N")`.

Test with:
- A valid CSV (should return `ok(...)`)
- A field that opens a quote but never closes it (should return an error)

### 3. RFC 4180 edge cases

RFC 4180 (the closest thing to a CSV standard) specifies:
- Line endings must be CRLF (`\r\n`). A bare `\r` is not a valid line ending.
- Files with no trailing newline are valid (the last record may not end with CRLF).
- A file may have zero records.

The current `newline` rule accepts both CRLF and bare LF. Fix it to:
- Accept `\r\n` (CRLF) as a valid line ending
- Accept `\n` (bare LF) as a valid line ending (common Unix extension to RFC 4180)
- Reject bare `\r` as a line ending (it should be treated as content)

Also verify that a CSV with no trailing newline parses correctly. The current
`parse_csv` rule returns `[Row]` when there is no following newline — confirm this
handles the no-trailing-newline case.

Write three test inputs in `main` that demonstrate all three cases.

---

## What you are practising

- Stateful DCGs: threading extra state through rules via additional arguments
- Structured error values vs. silent failure in parsers
- The difference between a parser that fails and one that returns an error value
- Reading an RFC and translating its requirements into grammar rules
