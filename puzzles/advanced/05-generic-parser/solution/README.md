# Solution notes

## The instance head restriction

The first obstacle is Mercury's restriction on instance declarations: all type
constructor arguments in the instance head must be type variables. This makes
the intuitive declaration illegal:

```mercury
% ILLEGAL — char is not a type variable
:- instance token_stream(list(char), char) where [...].
```

The workaround is a newtype wrapper — a single-constructor algebraic type that
holds the list:

```mercury
:- type cstream ---> cstream(list(char)).
:- instance token_stream(cstream, char) where [...].
```

Now `cstream` is a nullary type constructor (no type arguments), so the
instance head `token_stream(cstream, char)` is valid. The `next_token`
implementation pattern-matches inside the wrapper:

```mercury
:- pred cs_next(char::out, cstream::in, cstream::out) is semidet.
cs_next(C, cstream([C | Rest]), cstream(Rest)).
```

Call sites unwrap/rewrap explicitly:
```mercury
parse_number(N, cstream(string.to_char_list(Str)), cstream(Rem))
```

## Minimal constraints

`satisfy` requires `<= token_stream(S, T)` because it calls `next_token`, which
is a typeclass method. `many_p` does not call any typeclass method — it only
calls its predicate argument. Giving `many_p` the constraint would be wrong: it
would limit the combinator to token streams even though it works over any state.

The rule: add a typeclass constraint only when a predicate directly calls a
method of that typeclass (or calls another predicate that requires the
constraint).

## many_p — progress is not in the type

`many_p` has the same shape as puzzle 04's `many`, and the same hidden obligation.
Its parser-argument mode `pred(out, in, out) is semidet` fixes **cardinality** — at
most one solution per call — but not **progress**: nothing in the type or mode states
that a successful parser advances the stream.

`many_p` recurses on the stream P returns. If P can succeed without pulling a token
(handing back the same `S`), `many_p` calls it again on the identical stream and loops
forever. `det` does not rescue you — termination is not part of determinism.

The caller's invariant: **a parser passed to `many_p` consumes at least one token on
success.** `satisfy(...)` is safe because `next_token` is `semidet` and removes one
token; a parser that can succeed at zero width is not. Enforcing it is harder here
than for `many`: the stream `S` is abstract, so there is no generic `length` to
compare against. Real enforcement would need the `token_stream` class to expose a
remaining-size method (or a `measured_stream` subclass). Cardinality generalises
across every instance; progress does not — which is the deeper reason the
unconstrained `many_p` cannot police it.

## Instance resolution at higher-order call sites

When you write `many_p(satisfy(is_digit_char), ..., cstream(...), _)`, Mercury
resolves the typeclass instance before creating the closure for `satisfy`. The
stream type `cstream` — inferred from the list argument — selects the
`token_stream(cstream, char)` dictionary. That dictionary is embedded in the
`satisfy(is_digit_char)` closure. When `many_p` calls `call(P, V, !S)`, it
invokes the closure with the dictionary already baked in.

This is why `many_p` itself needs no constraint: the constraint is discharged at
the call site where the closure is formed, not inside `many_p`.

## Why there is no associated type

In Mercury, there is no way to declare "the token type of stream S" as a
function of S alone. Both `S` and `T` must appear explicitly in the typeclass
head:

```mercury
:- typeclass token_stream(S, T) where [...]
```

A consequence: any predicate using both `S` and `T` from the typeclass must
carry both as type parameters and declare the constraint
`<= token_stream(S, T)`. Languages like Haskell (with `TypeFamilies`) or Rust
(with associated types) let you write `type Token` inside the trait/typeclass,
making T implicit given S. Mercury's design keeps the type checker decidable by
avoiding such dependencies.

## Design question: push-back mode

Adding a second mode `next_token(in, in, out)` — push a token back — would
require a mode-specific implementation. For `list(char)` and `list(token)`, the
implementation would simply cons the token back:

```mercury
cs_next(C::in, cstream(Rest)::in, cstream([C | Rest])::out) :- true.
```

This is valid only if tokens are values (not positions in a file or network
stream). The typeclass contract would need `pragma promise_equivalent_clauses` to
assert that push-back + pull produces the same element. For lazy or IO-backed
streams it breaks down — another case where the list-backed instances are
simpler than the full generality suggests.
