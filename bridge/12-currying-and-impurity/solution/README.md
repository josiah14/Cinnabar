# Solution notes

One worked approach. All snippets compile against the starter (grade
`asm_fast.par.gc.stseg`).

## 1 & 3 — partial application and chaining

Because every transform takes its config first, supplying that one argument
yields a unary closure. The fixed pipeline collapses to:

```mercury
:- func scale(float, float) = float.
scale(Factor, X) = X * Factor.

:- func shift(float, float) = float.
shift(By, X) = X + By.

:- func clamp(float, float, float) = float.
clamp(Lo, Hi, X) =
    ( if X < Lo then Lo else if X > Hi then Hi else X ).

:- func run(list(float)) = list(float).
run(Xs) = list.map(clamp(0.0, 1.0), list.map(shift(0.1), list.map(scale(2.0), Xs))).
```

`scale(2.0)`, `shift(0.1)`, `clamp(0.0, 1.0)` are each `func(float) = float`.
The chaining is just nested `list.map`; order is significant — here we scale,
then shift, then clamp, so the clamp sees the already-transformed value.

The list-of-transforms version does **not** work:

```mercury
% REJECTED: Fs has inst list_skel(ground), so apply(F, X) is a call on a
% ground value, which the mode checker forbids.
Fs = [scale(2.0), shift(0.1), clamp(0.0, 1.0)],
Y  = list.foldl(func(F, Acc) = apply(F, Acc), Fs, X)
```

Storing the closures loses their higher-order inst (they become `ground`), and a
`ground` value is not callable. Same wall as the record-of-functions in bridge
06. Keep the transforms as direct partial applications, or compose them with a
combinator that takes them as inst-annotated arguments rather than storing them.

## 2 — currying a predicate

```mercury
:- pred above(float::in, float::in) is semidet.
above(Threshold, X) :- X > Threshold.

    % above(0.5) : pred(float::in) is semidet
filter_above(Threshold, Xs) = Kept :-
    list.filter(above(Threshold), Xs, Kept).
```

`list.filter` declares its predicate argument's inst (`pred(in) is semidet`), so
the partially applied `above(0.5)` is accepted at the call site without an extra
annotation.

## 4 — the impure counter, and why the pure version wins

The `mutable`, with impure accessors (no `attach_to_io_state`):

```mercury
:- mutable(apply_count, int, 0, ground, [untrailed]).

:- impure pred bump_count is det.
bump_count :-
    semipure get_apply_count(N),
    impure set_apply_count(N + 1).
```

`bump_count` cannot be called from a pure `func` used by `list.map` — impurity
does not appear in pure goals. Quarantine it inside IO-threaded code, and use
`promise_pure` to assert it has no declarative effect:

```mercury
:- pred count_and_scale(float::in, io::di, io::uo) is det.
count_and_scale(X, !IO) :-
    promise_pure ( impure bump_count ),
    Y = scale(2.0, X),
    io.format("  scaled %.2f -> %.2f\n", [f(X), f(Y)], !IO).
```

Read it back, again under `promise_pure`:

```mercury
promise_pure ( semipure get_apply_count(Count) ),
io.format("count: %d\n", [i(Count)], !IO)
```

The pure alternative drops the mutable entirely and threads the count as an
accumulator:

```mercury
:- pred count_pure(float::in, int::in, int::out) is det.
count_pure(_X, N, N + 1).

% list.foldl(count_pure, sample, 0, Count)
```

**Which to ship.** The accumulator. It has the same result with no global
state, no `impure` annotations, and no `promise_pure` obligation to keep correct
as the code evolves. The mutable earns its place only when the state is genuinely
global and cross-cutting (a process-wide id source, a cache) and threading it
would distort every signature in between — and even then, the impurity is wrapped
behind a pure interface, exactly as the koan
`koans/foundations/00-reactivation` chain and `06-pure-randomness` show. The
discipline is the lesson: keep impurity at the smallest possible scope, and make
`promise_pure` a claim you can actually defend.
