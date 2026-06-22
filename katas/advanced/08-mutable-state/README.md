# 08 — mutable state

**After:** `katas/advanced/05-assoc-list-env`,
`katas/foundations/00-reactivation/06-pure-randomness`

Mercury is pure: there is no ambient mutable cell you can just assign to. When
you genuinely need a mutable reference — a counter, a union-find parent array, a
cyclic structure — you reach for the `store` module. A `store(S)` is a typed
heap threaded through your code with unique (`di`/`uo`) modes, and `mutvar`
handles point into it. The threading is not ceremony: it is how the compiler
proves, statically, that there is never more than one live version of the heap.

---

## The store and its handles

Two things, kept separate:

- the **store** `store(S)` — the mutable heap, a single-threaded *state*;
- a **mutvar** `generic_mutvar(T, S)` — a first-class *handle* naming one cell of
  type `T` inside a store of state-type `S`.

The four operations all thread the store as their last two arguments
(`di, uo` — destructive-in, unique-out):

```mercury
store.init(S0),                          % some [S] store(S), unique
store.new_mutvar(0, Ref, S0, S1),        % allocate a cell holding 0
store.get_mutvar(Ref, V, S1, S2),        % read
store.set_mutvar(Ref, V + 1, S2, S3).    % write
```

`store.init` is existentially typed (`:- some [S] pred init(store(S)::uo)`): it
mints a *fresh* state type `S` so cells from one store can never be confused with
another's. You never write `S` yourself — it is inferred and threaded.

When you factor the loop into a helper, declare the store-state polymorphically,
the way the library declares its own operations:

```mercury
:- pred add_all(list(int), store.generic_mutvar(int, S), S, S) <= store.store(S).
:- mode add_all(in, in, di, uo) is det.
```

The `<= store.store(S)` constraint is the dictionary that makes `get_mutvar` /
`set_mutvar` type-check for the abstract `S`. Drop it and the call is an
"unsatisfiable typeclass constraint" error.

---

## The IO state is a store

The store does not have to be private. `store.io_mutvar(T)` is a handle whose
state-type *is* the IO state, and the very same `new_mutvar` / `get_mutvar` /
`set_mutvar` thread `!IO` in place of a private `!S`:

```mercury
store.new_mutvar(0, Ref, !IO),
store.set_mutvar(Ref, 1, !IO),
store.get_mutvar(Ref, V, !IO).
```

This is the bridge between a private heap and the program's real-world state:
one mechanism, two state types (`store(S)` and `io.io`), selected by which
variable you thread.

---

## Why Mercury — uniqueness makes aliasing a compile error

The store is threaded `di`/`uo`, so each version is consumed exactly once. Try
to write through a version and then reach back for the *same* one:

```mercury
store.new_mutvar(0, Ref, S0, S1),
store.set_mutvar(Ref, 1, S1, _S2),   % consumes S1
store.get_mutvar(Ref, Out, S1, _).   % reuse S1 — rejected
```

The compiler rejects it at the write, because that call needs to clobber `S1`
while the later read still holds it:

```
unique-mode error: the called procedure would clobber its
argument, but variable `S1' is still live.
```

"Two live aliases to a mutable heap" is exactly the bug that makes mutable state
hard to reason about in other languages, and here it is a *mode error at compile
time*, not a runtime surprise. That static single-threading is what buys you
mutation without giving up purity.

---

## When NOT to reach for `store`

Most "mutable" loops in Mercury are better expressed as **pure state threading**
— carry the value as an accumulator (`list.foldl`, a `!Acc` pair) and never
allocate a cell at all. `sum_store` in this kata is deliberately a case where the
pure version is simpler:

```mercury
list.foldl((pred(X::in, A0::in, A::out) is det :- A = A0 + X), Xs, 0, Total)
```

Doing it through a store is the *exercise*, not the recommendation. Reach for `store` only when you
need genuine sharing or cycles that an accumulator cannot express. For the impure
global-variable alternative (a `:- mutable(...)` with `promise_pure`), see
`bridge/12-currying-and-impurity`, which also argues for threading over impurity.

---

## Tasks

Work in `start.m`.

**Task 1 — `add_all/4`:** replace the stub with two clauses that walk `Xs`,
reading the accumulator with `get_mutvar`, writing back `Cur + X` with
`set_mutvar`, and threading `!S` through the recursion. `sum_store [3,4,5,6]`
must reach `18`.

**Task 2 — `bump_twice/3`:** set the io mutvar to `1`, read it, set it to
`V + 1`, and read the final value — threading `!IO` throughout — so `Final` ends
at `2`.

**Task 3 — observe the uniqueness check (no code to keep):** temporarily reuse an
earlier store version (pass `S1` to two operations, as in the "Why Mercury"
block) and read the mode error. Then revert.

---

## Expected output

```
PASS: sum_store [3,4,5,6] = 18
PASS: io mutvar bumped to 2
```

---

## Checkpoint

- You can separate the two ideas: the `store(S)` is the threaded *state*; a
  `generic_mutvar` is a first-class *handle*.
- You can explain what the `<= store.store(S)` constraint on a helper is for.
- You can say why the `di`/`uo` threading turns aliasing into a compile-time
  error — and why a pure accumulator is usually the better tool anyway.
