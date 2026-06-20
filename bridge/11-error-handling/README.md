# Bridge: error-handling patterns

**After:** `katas/foundations/02-maybe`, `katas/foundations/07-exceptions`

**Why Mercury:** the type system makes the error contract part of the signature.
A `maybe(T)` return is `det` — it never fails, it just carries absence. An `io.res(T)`
is also `det` — it carries OS errors as values. Exceptions are for invariant violations,
not recoverable failures. Mercury forces you to decide which semantics you intend.

`error_patterns.m` is a working user-record parser. It reads from a hardcoded list of
key-value pairs and uses `maybe(T)` for optional fields.

Build and run it first:

```
mmc --make error_patterns
./error_patterns
```

You should see four lines, with fields present where the data has them.

---

## Extension tasks

### 1. `maybe` chaining

`maybe(T)` is the right tool when absence is normal and the reason doesn't matter.

Add:

```mercury
:- func email_domain(user) = maybe(string).
```

If `email` is `no`, return `no`. If `email` is `yes(E)` but `E` has no `@`, return `no`.
If `email` is `yes(E)` and `E` has an `@`, return `yes(Domain)` where `Domain` is
everything after the `@`. Use `string.sub_string_search(E, "@", Pos)` (semidet)
to find the position, and `string.right(E, string.length(E) - Pos - 1)` to extract
the domain.

Then add:

```mercury
:- func contact_handle(user) = maybe(string).
```

Return `yes("username@domain")` only when the username is not `"(unknown)"` and
`email_domain` returns a domain. Return `no` otherwise.

Notice: two levels of optional data collapse cleanly without any explicit checking for
every combination. This is the monad-like property of `maybe` — absence propagates.

---

### 2. Custom error type for validation

`maybe(T)` loses the reason for failure. When a user with a bad email reaches reporting
code, `no` does not tell you whether the email was absent or malformed.

Define:

```mercury
:- type validation_error
    --->    missing_username
    ;       invalid_email(string)     % the offending address
    ;       invalid_age(int).         % the offending value

:- type validation_result(T)
    --->    ok(T)
    ;       error(validation_error).
```

Write:

```mercury
:- func validate_user(user) = validation_result(user).
```

Rules:
- If `username` is `"(unknown)"`, return `error(missing_username)`.
- If `email` is `yes(E)` and `E` does not contain `@`, return `error(invalid_email(E))`.
- If `age` is `yes(A)` and `A =< 0`, return `error(invalid_age(A))`.
- Otherwise return `ok(U)`.

Write a `describe_validation_error(validation_error) = string` function and update `main`
to print either the user (on `ok`) or the error description (on `error`).

Notice: the type encodes all the ways validation can fail. A reader of the type knows
what to expect without reading the implementation.

---

### 3. `io.res` for file loading

`io.res(T)` is the right tool when an IO operation can fail with an OS-level error —
one that carries a human-readable message. `maybe(T)` would discard that message.

Write:

```mercury
:- pred load_users(string::in, io.res(list(user))::out,
    io::di, io::uo) is det.
```

Use `io.open_input(Filename, OpenResult, !IO)`. Its result is `io.res(io.text_input_stream)`:

```mercury
(
    OpenResult = ok(Stream),
    read_lines(Stream, Lines, !IO),
    io.close_input(Stream, !IO),
    ...
;
    OpenResult = error(Err),
    Result = error(Err)
)
```

Write a helper that reads the lines and reports failure honestly. Give it the signature
`read_lines(Stream, io.res(list(string)), !IO)` and call
`io.read_line_as_string(Stream, LineResult, !IO)` in a loop. `io.result(string)` is
`ok(Line) | eof | error(io.error)` — stop with `ok(Lines)` on `eof`, and on an IO error
return `error(Err)` so the failure **propagates** to `load_users` instead of vanishing.
Returning a plain `list(string)` and mapping `error(_)` to `[]` would hand back a
truncated `ok` — the exact silent-failure `io.res` exists to prevent.

File format: one record per line, `key=value` pairs separated by commas. Parse each line
into an assoc_list and pass it to the existing `parse_user`. Hint:
`string.split_at_char(',', Line)` splits a line into pairs; `string.split_at_char('=', Pair)`
gives `[Key, Value]` when `=` is present.

Test with a file that does not exist and one that does. Use `io.error_message(Err)` to
get the human-readable string from an `io.error`.

---

## What you are practising

- `maybe(T)` for optional data: absence propagates without explicit checking
- Custom error types when failure reasons matter
- `io.res(T)` for IO operations that can fail with OS-level error messages
- Recognising when each mechanism is appropriate
