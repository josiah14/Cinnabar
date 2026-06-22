# Solution notes

## The inst-in-type error

The first obstacle when building this library is that Mercury forbids inst
information inside a type declaration:

```mercury
% WRONG — inst info in the type position
:- pred satisfy(pred(char::in) is semidet, char, list(char), list(char)).
```

The error: "the type `((pred (char :: in)) is semidet)' contains higher order
inst information, but this is not allowed in a predicate's argument."

The fix is always the same: separate type and mode declarations.

```mercury
% CORRECT
:- pred satisfy(pred(char), char, list(char), list(char)).
:- mode satisfy(in(pred(in) is semidet), out, in, out) is semidet.
```

The same applies to `seq_det`, `seq_semidet`, `choice_det`, `choice_semidet`,
`many`, and any other combinator that takes a higher-order argument. Define the
`pred(T)` type separately, then attach insts in `:- mode` declarations.

## inst aliases for parser shapes

Defining inst aliases up front keeps mode declarations readable:

```mercury
:- inst parser_det     == (pred(out, in, out) is det).
:- inst parser_semidet == (pred(out, in, out) is semidet).
```

Mode declarations then read like contracts:
```mercury
:- mode seq_semidet(in(parser_semidet), in(parser_semidet), out, in, out) is semidet.
```

## many — the determinism argument

`many` runs P in an if-then-else condition and recurses on the residual input:

```mercury
many(P, Results, Input, Rest) :-
    ( call(P, V, Input, Mid) ->
        many(P, Vs, Mid, Rest),
        Results = [V | Vs]
    ;
        Results = [],
        Rest = Input
    ).
```

The combinator is `det` because every call has exactly one outcome: P either
succeeds (extend the list, recurse) or fails (stop with what we have). The
`parser_semidet` inst is what makes this hold — P has at most one solution, and that
single binding `V` flows into the then-branch (`Results = [V | Vs]`) without
multiplying. If P were `nondet`, exporting `V` into the then-branch would carry P's
multiplicity out with it and `many` would no longer be `det` — an if-then-else only
commits the condition's nondeterminism for variables that *stay* in the condition (see
the bidirectional-search solution notes for the full account).

## many — the progress invariant (must consume on success)

`det` counts *solutions*, not *steps*: it does not promise termination. `many` is
`det` and can still loop forever. The inst `parser_semidet` declares **cardinality**
(P yields at most one solution); it says nothing about **progress** (whether a
successful P shortens the input).

`many` recurses on `Mid`, the input P hands back. If P can succeed *without consuming
a token* — returning `Mid = Input` — the next call sees the identical input, succeeds
again, and the recursion never bottoms out. `many(pure(V))` type-checks and diverges;
so does `many` of any parser with a zero-width success. No inst rules this out:
cardinality is statically checkable, progress is not. (Verified — the unguarded
`many` over a non-consuming parser runs until killed.)

The invariant the caller must uphold: **a parser passed to `many` consumes at least
one token whenever it succeeds.** Every consuming primitive here goes through `item`,
which strips one character, so `satisfy(...)`, `digit`, and `literal` are safe; `pure`
is not.

To enforce the invariant rather than assume it, make `many` require the residual to
shrink before recursing:

```mercury
many(P, Results, Input, Rest) :-
    ( call(P, V, Input, Mid), list.length(Mid) < list.length(Input) ->
        many(P, Vs, Mid, Rest),
        Results = [V | Vs]
    ;
        Results = [],
        Rest = Input
    ).
```

A zero-width success now falls through to the base case instead of looping, at the
cost of a length comparison per step. (Compile-checked: `det`, and it terminates on
both consuming and non-consuming parsers.)

## choice_det vs choice_semidet

`choice_det` ignores its second argument entirely — if P is `det` it never fails,
so Q is dead code. Mercury will still type-check Q's inst.

`choice_semidet` uses if-then-else to implement the committed-choice OR:

```mercury
choice_semidet(P, Q, V, Input, Rest) :-
    ( call(P, V0, Input, Rest0) ->
        V = V0, Rest = Rest0
    ;
        call(Q, V, Input, Rest)
    ).
```

This is semidet: P or Q each have at most one solution, and the if-then-else
commits to whichever branch fires. The combined predicate fails only if both fail.

## Why determinism-polymorphic combinators require dependent types

`seq` is det when given two det parsers, and semidet when given two semidet
parsers. Mercury cannot express this as a single predicate because determinism is
not a type variable — it lives in the mode system, not the type system.

For determinism-polymorphic combinators to work, the determinism of a
higher-order argument would need to be a first-class parameter that other
declarations can reference — essentially a dependent type where the declared mode
depends on the value (or class) of an argument. Mercury's design trades this
expressiveness for a mode system that is decidably checkable at compile time.

Languages like Liquid Haskell or Idris can express such constraints through
refinement types or dependent types, but the decidability cost is higher.

## The `empty` predicate

`empty` has determinism `failure` — it always fails. The `out` argument in:

```mercury
:- pred empty(T, list(char), list(char)).
:- mode empty(out, in, out) is failure.
```

is never bound because the predicate never produces a solution. Mercury accepts
this. `empty` is the identity of `choice_semidet` (analogous to `[]` for lists)
and is included for algebraic completeness of the API.

The body **must** be `fail`, and an empty fact body is *not* an equivalent
Mercury idiom here — a tempting "cleanup" that does not compile:

```mercury
:- mode empty(out, in, out) is failure.
empty(_, _, _).        % WRONG
```

A fact body asserts the predicate *succeeds*, which obliges it to bind the `out`
argument. It doesn't, so mmc reports a mode error, not `failure`:

```
mode error: argument 2 did not get sufficiently instantiated.
Final instantiatedness of `HeadVar__1' was `free',
expected final instantiatedness was `ground'.
```

With the `fail` body there is no success path, so the unbound output is
legitimate and the `is failure` determinism is satisfied. The `is failure`
annotation is the Mercury innovation worth noticing; the `fail` goal in the body
is what the mode checker requires to make it hold, not a Prolog vestige to be
removed.
