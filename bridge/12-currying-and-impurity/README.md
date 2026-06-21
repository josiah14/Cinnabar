# Bridge: currying and impurity

**After:** `katas/foundations/04-higher-order`,
`katas/foundations/00-reactivation/06-pure-randomness`

**Why Mercury:** two of Mercury's higher-order corners meet here. Partial
application produces a value whose *inst* the compiler tracks — a partially
applied `scale(2.0)` is a callable `func(float) = float`, but the same value
stored in a list becomes `ground` and is no longer callable. And because Mercury
is purely declarative, a side effect must be either threaded through the IO
state or explicitly marked `impure`/`semipure` and quarantined with
`promise_pure`. This bridge pairs the two: currying to build specialised
transforms, and impurity to instrument them — and the friction between them is
the point.

`transforms.m` is a working program. It defines three general numeric transforms
(`scale`, `shift`, `clamp`), each taking its configuration first and the value
last, and applies a fixed two-step pipeline — but written *without* partial
application: each step wraps a transform in a lambda that supplies the fixed
config.

Build and run it first:

```
mmc --make --grade asm_fast.par.gc.stseg transforms
./transforms
```

---

## Extension tasks

### 1. Partial application

The transforms take their config argument first precisely so they can be
*curried*. Replace the lambdas in `main` with direct partial applications:

```mercury
Scaled  = list.map(scale(2.0), sample),
Clamped = list.map(clamp(0.0, 1.0), Scaled),
```

`scale(2.0)` supplies only the first of `scale`'s two arguments, yielding a
`func(float) = float` closure. Confirm the output is unchanged. Note how much
noise the lambda wrappers were adding.

### 2. Curry a predicate for filtering

Partial application works on predicates too. Add a threshold predicate, config
first:

```mercury
:- pred above(float::in, float::in) is semidet.
above(Threshold, X) :- X > Threshold.
```

Then `above(0.5)` is a `pred(float::in) is semidet` you can hand to
`list.filter`. Filter the pipeline output to the values above `0.5` and print
the count. (As in bridge 06, the predicate value needs its inst known at the
call site — `list.filter`'s own mode declaration supplies it here.)

### 3. Chain several curried transforms

Build a three-step pipeline — scale, then shift, then clamp — by composing
`list.map` calls, each given a partially applied transform. Decide the order and
say why it matters (clamping before scaling is not the same as after).

You may be tempted to put the transforms in a `list((func(float) = float))` and
fold over it. Try it — and watch Mercury reject the call. Stored in a list, each
transform has inst `ground`, and a `ground` higher-order value is not callable.
This is the same inst limitation bridge 06 hits with a record of functions; note
it in a comment rather than fighting it.

### 4. Instrument the pipeline with an impure counter

Count how many times a transform runs, using a global `mutable`:

```mercury
:- mutable(apply_count, int, 0, ground, [untrailed]).
```

Without `attach_to_io_state`, the generated accessors are **impure**: reading is
`semipure get_apply_count`, writing is `impure set_apply_count`. Write an
`impure pred bump_count` that reads and increments, and a reporter that displays
the total.

Now try to call `bump_count` from inside a pure `list.map` transform. You can't:
an `impure` goal cannot appear in a pure context, and `func`s are pure. This is
the design lesson — impurity does not compose into declarative code for free.
Two honest resolutions:

- **Quarantine it.** Do the counting in an IO-driven loop (`list.foldl` over the
  IO state), wrapping the `impure bump_count` in `promise_pure`. `promise_pure`
  is a promise *you* make that the goal has no observable effect on declarative
  meaning — keep it true.
- **Thread it purely.** Drop the mutable entirely and carry the count as an
  accumulator (`list.foldl(..., 0, Count)`). No impurity, no promise to keep.

Implement both and compare. Decide which you would ship, and why.

---

## What you are practising

- Partial application / currying of both functions and predicates, and the
  config-first argument order that enables it
- How a higher-order value's inst (callable vs `ground`) limits where it can be
  stored and called
- `impure` / `semipure` accessors on a `mutable`, and `promise_pure` as a
  discharged proof obligation
- The design choice between quarantined impurity and pure state threading —
  and why the pure version is usually the one to ship
