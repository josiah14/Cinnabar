# Solution notes

> **Imports:** the starter (`error_patterns.m`) does not import `int`, but the extension
> tasks do integer arithmetic and comparison (`string.length(E) - Pos - 1` in Task 1,
> `A =< 0` in Task 2). Add `:- import_module int.` or those lines fail — `-` resolves to
> the `pair` constructor and `=<` is undefined without it. (Verified: the full Task 1–3
> solution compiles and runs with `int` imported.)

## Task 1: `maybe` chaining

```mercury
:- func email_domain(user) = maybe(string).
email_domain(U) = Domain :-
    ( U^email = yes(E),
      string.sub_string_search(E, "@", Pos)
    ->
        Domain = yes(string.right(E, string.length(E) - Pos - 1))
    ;
        Domain = no
    ).

:- func contact_handle(user) = maybe(string).
contact_handle(U) = Handle :-
    ( U^username \= "(unknown)",
      email_domain(U) = yes(Domain)
    ->
        Handle = yes(U^username ++ "@" ++ Domain)
    ;
        Handle = no
    ).
```

`email_domain` uses an if-then-else with a conjunction in the condition: both the email
field must be present *and* the `@` search must succeed. Either failure sends it to the
else branch (`no`).

`contact_handle` chains on top: if `contact_handle` returns `no`, the caller gets `no`
without needing to inspect the intermediate steps. This is `maybe`'s key property —
absent propagates without case analysis at every stage.

---

## Task 2: Custom error type

```mercury
:- type validation_error
    --->    missing_username
    ;       invalid_email(string)
    ;       invalid_age(int).

:- type validation_result(T)
    --->    ok(T)
    ;       error(validation_error).

:- func validate_user(user) = validation_result(user).
validate_user(U) = Result :-
    ( U^username = "(unknown)" ->
        Result = error(missing_username)
    ; U^email = yes(E), not string.contains_char(E, '@') ->
        Result = error(invalid_email(E))
    ; U^age = yes(A), A =< 0 ->
        Result = error(invalid_age(A))
    ;
        Result = ok(U)
    ).

:- func describe_validation_error(validation_error) = string.
describe_validation_error(missing_username) = "username required".
describe_validation_error(invalid_email(E)) = "invalid email: " ++ E.
describe_validation_error(invalid_age(A))  =
    "invalid age: " ++ string.int_to_string(A).
```

In `main`, pattern-match on `validation_result`:

```mercury
list.foldl(
    (pred(Fields::in, !.IO::di, !:IO::uo) is det :-
        parse_user(Fields, U),
        ( validate_user(U) = ok(Valid) ->
            io.write_string(display_user(Valid) ++ "\n", !IO)
        ; validate_user(U) = error(Err) ->
            io.write_string("Skipped: " ++ describe_validation_error(Err) ++ "\n", !IO)
        ;
            true
        )
    ),
    Rows, !IO).
```

The custom error type is better than `maybe(user)` here because the downstream code
can distinguish `missing_username` from `invalid_email` — it can report the problem,
log it, or route to different handlers. With `maybe`, the distinction is gone.

---

## Task 3: `io.res` file loading

```mercury
:- pred load_users(string::in, io.res(list(user))::out,
    io::di, io::uo) is det.
load_users(Filename, Result, !IO) :-
    io.open_input(Filename, OpenResult, !IO),
    (
        OpenResult = ok(Stream),
        read_lines(Stream, LinesResult, !IO),
        io.close_input(Stream, !IO),
        (
            LinesResult = ok(Lines),
            NonEmpty = list.filter((pred(L::in) is semidet :- L \= ""), Lines),
            Users = list.map(parse_line, NonEmpty),
            Result = ok(Users)
        ;
            LinesResult = error(Err),
            Result = error(Err)
        )
    ;
        OpenResult = error(Err),
        Result = error(Err)
    ).

% read_lines returns io.res(list(string)). An IO error part-way through is
% propagated as error(Err); it is NOT swallowed into a truncated ok. The lines
% come back in file order, so load_users needs no reverse.
:- pred read_lines(io.text_input_stream::in, io.res(list(string))::out,
    io::di, io::uo) is det.
read_lines(Stream, Result, !IO) :-
    io.read_line_as_string(Stream, LineResult, !IO),
    (
        LineResult = ok(Line),
        read_lines(Stream, RestResult, !IO),
        (
            RestResult = ok(Rest),
            Result = ok([string.rstrip(Line) | Rest])
        ;
            RestResult = error(Err),
            Result = error(Err)
        )
    ;
        LineResult = eof,
        Result = ok([])
    ;
        LineResult = error(Err),
        Result = error(Err)
    ).

:- func parse_line(string) = user.
parse_line(Line) = U :-
    Parts = string.split_at_char(',', Line),
    list.filter_map(parse_pair, Parts, Pairs),
    parse_user(Pairs, U).

:- pred parse_pair(string::in, pair(string, string)::out) is semidet.
parse_pair(S, K - V) :-
    string.split_at_char('=', S) = [K, V].
```

**Why the `io.res` return matters.** The obvious first version makes `read_lines`
return a plain `list(string)` and turns an IO error into `[]`:

```mercury
LineResult = error(_),
Lines = []          % WRONG — error vanishes, load_users still returns ok
```

That contradicts the whole point of this bridge: `io.res` exists so OS-level errors
travel as *values* the caller must handle. Swallowing the error into a truncated `ok`
hands back a silently-incomplete user list — exactly the bug `io.res` is meant to
prevent. Returning `io.res(list(string))` and propagating `error(Err)` up the recursion
(and out through `load_users`) keeps the contract honest: a partial read becomes
`error(Err)`, not a short `ok`.

Two further fixes the original snippet needed: `parse_line` must use the **predicate**
form of `list.filter_map/3` (the `= list` function form expects a `func` lambda, not a
`pred`), so the pair-splitter is pulled out into `parse_pair`; and `string.right`'s
`length - Pos - 1` and `validate_user`'s `A =< 0` are integer operations, so the module
needs `:- import_module int.` (see the note at the top).

Usage in `main`:

```mercury
load_users("users.txt", LoadResult, !IO),
(
    LoadResult = ok(Users),
    list.foldl(
        (pred(U::in, !.IO::di, !:IO::uo) is det :-
            io.write_string(display_user(U) ++ "\n", !IO)
        ),
        Users, !IO)
;
    LoadResult = error(Err),
    io.write_string("Error: " ++ io.error_message(Err) ++ "\n", !IO)
).
```

`io.res(T)` is right here because `io.open_input` can fail with "no such file",
"permission denied", etc. These are OS-level strings. `maybe` would lose that
information; `io.res` carries it as `io.error`, and `io.error_message/1` retrieves it.

---

## When to use which

| Mechanism | Use when | Example |
|---|---|---|
| `maybe(T)` | Absence is normal; reason doesn't matter | Optional config fields |
| Custom error type | Failure has structured reasons the caller acts on | Validation with multiple failure modes |
| `io.res(T)` | IO can fail with an OS-level error message | File open, network connect |
| Exception (`error/1`, `throw`) | Invariant violation — should not happen in correct code | Missing required field in already-validated data |

The key question: **does the caller need to know why it failed, and can they recover?**

- No reason needed, absence is ok → `maybe`
- Reason matters, caller handles it → custom error type or `io.res`
- Should never fail in correct usage → exception

Avoid using exceptions for recoverable failures — they bypass the type system's
enforcement that you handle the error case.
