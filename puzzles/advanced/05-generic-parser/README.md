# Puzzle: generic parser

**Primary skills:** typeclasses, multi-parameter typeclasses, instance
declarations, constraint propagation

**Why Mercury:** typeclasses let you abstract over the *shape* of a stream —
the combinator code is written once and the compiler selects the right instance
at each call site. Determinism flows through unchanged.

## Prerequisites

- `katas/type-system/04-type-classes`
- `katas/type-system/06-typeclass-depth`
- `bridge/09-typeclass-refactor`
- `puzzles/advanced/04-combinator-library` (the parser combinators to generalize)

---

## The problem

In puzzle 04 you built combinators over `list(char)`. The stream type was
hardcoded. Now generalize: define a typeclass that abstracts over the stream,
then re-express the combinators so they work over any instance.

## The typeclass

```mercury
:- typeclass token_stream(S, T) where [
    pred next_token(T, S, S),
    mode next_token(out, in, out) is semidet
].
```

`S` is the stream type. `T` is the token type. `next_token` is the generalized
`item`: consume one token from the stream, fail on empty.

## Two instances

**Instance 1** — a character stream:
```mercury
:- instance token_stream(list(char), char) where [ ... ].
```

**Instance 2** — a pre-lexed token stream. Define a `token` type first:
```mercury
:- type token ---> tok_int(int) ; tok_plus ; tok_minus ; tok_star.
:- instance token_stream(list(token), token) where [ ... ].
```

## Generic combinators

Implement these; note which ones need the typeclass constraint and which do not:

```mercury
% Requires token_stream(S, T) — calls next_token
:- pred satisfy(pred(T), T, S, S) <= token_stream(S, T).
:- mode satisfy(in(pred(in) is semidet), out, in, out) is semidet.

% Does NOT require the constraint — only calls the passed predicate
:- pred many_p(pred(T, S, S), list(T), S, S).
:- mode many_p(in(pred(out, in, out) is semidet), out, in, out) is det.
```

Think about why `many_p` does not need `<= token_stream(S, T)` even though it is
always used with token streams in practice.

> **Termination caveat.** Like `many` in puzzle 04, `many_p` is `det` but not
> guaranteed to terminate. The `semidet` mode fixes cardinality (at most one solution
> per call), not progress (whether the stream advances). A parser that succeeds
> without pulling a token makes `many_p` loop forever. The invariant: a parser given
> to `many_p` consumes at least one token on success.

## Build on top

Using only the generic combinators:

1. A char-stream number parser (same logic as puzzle 04, but now calls
   `satisfy` + `many_p` rather than `item` directly)
2. A token-stream collector: given a list of tokens, collect all leading
   `tok_int` values, stopping at the first non-integer token

Both should be expressible with the same `many_p(satisfy(...), ...)` pattern.
The compiler selects the right instance from the stream argument type.

---

## Design questions

1. `satisfy` requires `<= token_stream(S, T)` but `many_p` does not. What is the
   minimal constraint a predicate needs? How do you decide?

2. Mercury does not support associated types (a type function on the typeclass
   parameters, e.g., `token_of(S) = T`). What limitation does this create when
   writing combinators that must relate `S` and `T`?

3. Could you add a second mode to `next_token` — `(in, in, out) is semidet` —
   that pushes a token back onto the stream? What implementation would that
   require for `list(char)` and `list(token)`?
