# Solution notes

## Task 1: reverse mode

Replace the single declaration with two mode declarations and two clause bodies:

```mercury
:- pred str_to_int(string, int).
:- mode str_to_int(in, out) is semidet.
:- mode str_to_int(out, in) is det.
:- pragma promise_equivalent_clauses(str_to_int/2).

str_to_int(S::in,  N::out) :- string.to_int(S, N).
str_to_int(S::out, N::in)  :- S = string.int_to_string(N).
```

Mode-specific syntax: each clause head annotates its arguments with `::mode`.
Mercury picks the correct clause at compile time based on which arguments are ground
at the call site.

The pragma is valid here because both clauses compute the same relation: `(S, N)` is
a valid pair iff `S` is the decimal representation of `N`. The relation is the same;
only the direction of computation differs.

In `main`, the reverse mode looks like any other call:
```mercury
str_to_int(SOf42, 42),  % SOf42 = "42"
io.format("Reverse: %d => \"%s\"\n", [i(42), s(SOf42)], !IO),
```

## Task 2: what the third mode actually demands

First, dispel a myth: a `(out, out) is nondet` mode is *not* rejected by the
compiler. You can add the mode and a generating clause, and it compiles and runs:

```mercury
:- mode str_to_int(out, out) is nondet.
str_to_int(S::out, N::out) :- gen_int(N), S = string.int_to_string(N).
```

The relation being infinite is no obstacle either. A nondet predicate enumerates its
solutions lazily, one per backtrack — it never has to materialise the whole set. What
*does* bite is **enumeration order**: the generator you pair with it must be
productive (yield a value before recursing). A left-recursive generator like
`gen_int(N) :- gen_int(M), N = M + 1.` type-checks but diverges at runtime before
producing anything. That is a property of the generator, not a prohibition on the
mode.

The real obligation is `promise_equivalent_clauses`. It asserts that **every** clause
computes the **same relation**, and the compiler does not check this — you must prove
it. That proof is where this predicate gets subtle, because the forward and reverse
clauses do not actually agree:

- `string.to_int` (the `in, out` clause) is lenient: `to_int("042")`, `to_int("+42")`,
  and `to_int("00")` all succeed. So the forward relation contains pairs like
  `("042", 42)`.
- `string.int_to_string` (the `out, in` clause, and any generator built on it) only
  ever *produces* the canonical form `"42"`. It never yields `"042"`.

So the forward clause's relation is strictly larger than the reverse clause's. The
pragma is already a promise about the *canonical* relation — one the `in, out` clause
slightly overshoots. A third clause built on `int_to_string` would match the reverse
clause but still not match the lenient forward one. Coercing all three under a single
`promise_equivalent_clauses` would assert an equivalence that does not hold.

In practice: write a separate predicate with a different name for generation. Keep
`promise_equivalent_clauses` for clauses whose relation you can actually prove
identical — and notice that even the two-mode version here trades a little rigour for
the convenience of accepting non-canonical input.

## Task 3: `version_array` round-trip

```mercury
:- import_module int.
:- import_module version_array.

:- pred strings_to_array(list(string)::in, version_array(int)::out) is det.
strings_to_array(Strings, Array) :-
    N = list.length(Strings),
    list.foldl2(
        (pred(S::in, Idx::in, NextIdx::out, VA0::in, VA::out) is det :-
            NextIdx = Idx + 1,
            ( str_to_int(S, V) ->
                VA = version_array.set(VA0, Idx, V)
            ;
                VA = VA0  % leave default 0
            )),
        Strings, 0, _, version_array.init(N, 0), Array).

:- pred array_to_strings(version_array(int)::in, list(string)::out) is det.
array_to_strings(Array, Strings) :-
    N = version_array.size(Array),
    list.map(
        (pred(Idx::in, S::out) is det :-
            V = version_array.lookup(Array, Idx),
            str_to_int(S, V)),  % reverse mode: V::in, S::out
        0 `..` (N - 1), Strings).
```

`0 `..` (N - 1)` uses the `int.(..)` range operator to produce `list(int)`.
Import `int` for this syntax.

The reverse mode call `str_to_int(S, V)` with `V::in` (ground) and `S::out` (free)
is selected automatically by Mercury based on instantiation. No special syntax needed
at the call site — Mercury resolves it at compile time.

`version_array.lookup(Array, Idx)` reads without consuming `Array`. With `array(T)`,
you would need to pass the array in `in` mode and write carefully — here the
persistent semantics make the code straightforward.
