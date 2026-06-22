# Solution notes

## Task 1: first solution of a `nondet` goal

`valid_coloring/1` is `nondet` — it yields colorings on backtracking. Taking *one* of
them deterministically is the whole point of this bridge, and Mercury does not hand it
to you for free.

### The trap

It is tempting to reach for an if-then-else, since its condition "commits to the first
solution":

```mercury
% WRONG: inferred `multi` ("valid_coloring can succeed more than once"),
% and a function's primary mode cannot be `multi`.
first_coloring = Result :-
    ( valid_coloring(C) -> Result = yes(C) ; Result = no ).
```

An if-then-else commits its condition **only for the existence test**. Here the witness
`C` escapes into `yes(C)`, so Mercury must keep every solution and the whole thing is
`multi`. This is exactly `koans/determinism/07-nondet-condition-multi`, and
`koans/determinism/03-committed-choice` shows the companion rule: committed choice needs
a committed *context*. Two honest ways out here (a third, `list.find_first_match`, needs
a match predicate, so it appears in Task 3).

### Option 1 — `solutions/2` + head (eager, `det`)

Materialise the solutions, then deconstruct the list. The if-then-else now commits on a
`semidet` list match, so the function is `det`:

```mercury
:- func first_coloring = maybe(coloring).
first_coloring = Result :-
    solutions(valid_coloring, Cs),
    ( Cs = [C | _] ->
        Result = yes(C)
    ;
        Result = no
    ).
```

This is what `search.m`'s `main` already does. The cost: it computes *every* solution
even though you want one — fine for this six-coloring space, wasteful (or
non-terminating) for a large or infinite one.

### Option 3 — committed choice in a `cc_multi` context (lazy)

The genuine "first solution via committed choice." Put the same if-then-else in a
`cc_multi` predicate: a committed-choice context *is* allowed to commit a `nondet`
goal's first witness, so it never enumerates the rest.

```mercury
:- pred first_coloring_cc(maybe(coloring)::out) is cc_multi.
first_coloring_cc(Result) :-
    ( valid_coloring(C) -> Result = yes(C) ; Result = no ).
```

Same body that failed as a `det` function above — it is the *context* determinism that
licenses the commit (contrast koan 07's `det` context). The cost is the mirror image of
Option 1: lazy and early-stopping, but `cc_multi` is now part of the interface and
propagates to every caller.

## Task 2: parallel search

```mercury
:- pred colorings_with_c1(color::in, list(coloring)::out) is det.
colorings_with_c1(C1, Colorings) :-
    solutions(
        (pred(C::out) is nondet :-
            valid_coloring(C),
            C = coloring(C1, _, _)),
        Colorings).

:- pred par_search(list(coloring)::out) is det.
par_search(All) :-
    ( colorings_with_c1(red,   Reds)  &
      colorings_with_c1(green, Greens) &
      colorings_with_c1(blue,  Blues) ),
    All = Reds ++ Greens ++ Blues.
```

The lambda inside `solutions` captures `C1` from the outer scope. Each call to
`colorings_with_c1` is `det` (returns a list), which satisfies `&`'s requirement.

**Mercury 22.01.8 note:** If you use `All` (a variable produced by `&`) in an
if-then-else condition in the same clause, you may hit backend bug 1 from
`COMPILER-LESSONS.md`. Avoid this by extracting the `&` call into a named predicate
(`par_search`) and using its output only in sequential code.

The parallel result is equivalent to the sequential result but with colorings
grouped by node-1 color rather than the depth-first ordering of `solutions`. If order
matters, sort both lists before comparing.

## Task 3: parameterized early exit — three ways

Now parameterise the search by a caller-supplied `semidet` `Criterion`. With a match
predicate in hand, all three first-solution idioms apply — and Option 2 finally fits.
They agree on the answer and differ only in *when they stop* and *what determinism they
cost the caller*.

One declaration detail first: the higher-order argument's inst goes in the *mode*
position — `pred(coloring)::in(pred(in) is semidet)` — not inside the type as
`pred(coloring::in) is semidet`, which Mercury rejects ("higher order inst information
... not allowed in a predicate's argument").

```mercury
% Option 1 — solutions + head. Eager, det.
:- pred first_where(pred(coloring)::in(pred(in) is semidet),
                    maybe(coloring)::out) is det.
first_where(Criterion, Result) :-
    solutions(
        (pred(C::out) is nondet :- valid_coloring(C), call(Criterion, C)),
        Cs),
    ( Cs = [First | _] -> Result = yes(First) ; Result = no ).
```

```mercury
% Option 2 — generate all, then lazily scan with list.find_first_match.
% This is the fix koans/determinism/07-nondet-condition-multi hands you.
:- pred first_where_ffm(pred(coloring)::in(pred(in) is semidet),
                        maybe(coloring)::out) is det.
first_where_ffm(Criterion, Result) :-
    solutions(valid_coloring, All),
    ( list.find_first_match(Criterion, All, First) ->
        Result = yes(First)
    ;
        Result = no
    ).
```

```mercury
% Option 3 — committed choice. Lazy: never generates past the first match.
:- pred first_where_cc(pred(coloring)::in(pred(in) is semidet),
                       maybe(coloring)::out) is cc_multi.
first_where_cc(Criterion, Result) :-
    ( valid_coloring(C), call(Criterion, C) -> Result = yes(C) ; Result = no ).
```

| Option | Generation | Scan | Result | Caller cost |
|---|---|---|---|---|
| 1. `solutions` + head | eager (all) | — | `det` | clean |
| 2. `solutions` + `find_first_match` | eager (all) | stops at first match | `det` | clean |
| 3. `cc_multi` if-then-else | lazy (stops at first) | — | `cc_multi` | committed choice propagates |

Only Option 3 is genuinely *early exit*: it never generates a coloring past the first
match. Options 1 and 2 build the whole solution list first — `find_first_match` only
makes the *scan* lazy, not the generation. The trade is interface cleanliness: Options
1–2 stay `det`, while Option 3 makes every caller a committed-choice context too. Choose
by the size of the search space and whether the caller can absorb `cc_multi`.

Usage:
```mercury
first_where((pred(C::in) is semidet :- C = coloring(_, _, blue)), R1),
first_where((pred(C::in) is semidet :- C^node1 = C^node3), R2),
```

The second criterion (node 1 = node 3) demonstrates that C1 and C3 can be the same
color — the graph has no edge between them. The first result is `yes(coloring(red, green, blue))`.
