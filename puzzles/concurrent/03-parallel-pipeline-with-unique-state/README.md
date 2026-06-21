# Puzzle: parallel pipeline with unique state

**Primary skills:** channel-based pipelining, state threading in concurrent
contexts, unique type semantics

**Why Mercury:** each thread in a Mercury concurrent pipeline "owns" its
accumulation state exclusively. The state is threaded as explicit parameters
through recursive calls — the same linearity enforced by `array_di` / `array_uo`
for actual mutable structures. Understanding the connection between explicit
parameter threading and Mercury's unique types is the goal.

## Prerequisites

- `katas/concurrency/01-spawn`
- `katas/concurrency/03-pipeline`
- `puzzles/concurrent/02-pipeline` (the two-stage pipeline base)

---

## The problem

Extend the puzzle 02 pipeline to three stages. The second stage is an
**accumulator** — it does not just forward each item; it holds private state
across items and sends a single summary when it receives the sentinel.

```
Producer → [Chan1] → Accumulator → [Chan2] → Reporter
```

**Stage 1 — Producer:** sends integers 1..N down Chan1, then a sentinel.

**Stage 2 — Accumulator:** receives each integer; tracks running count, sum,
and maximum. Threads these as explicit arguments through its recursive calls.
When it receives the sentinel, sends the collected stats to Chan2.

**Stage 3 — Reporter:** blocks on Chan2 for the single stats record, then
prints count, total, and average.

---

## State threading within a concurrent stage

Within Stage 2, the accumulation is:

```mercury
:- pred acc_loop(channel(maybe(int))::in, channel(stats)::in,
                 int::in, int::in, int::in,   % count, sum, max
                 io::di, io::uo) is cc_multi.
acc_loop(In, Out, Count0, Sum0, Max0, !IO) :-
    channel.take(In, Item, !IO),
    ( Item = no ->
        channel.put(Out, stats(Count0, Sum0, Max0), !IO)
    ;
        Item = yes(V),
        acc_loop(In, Out, Count0 + 1, Sum0 + V, max(Max0, V), !IO)
    ).
```

`Count0`, `Sum0`, `Max0` are in-parameters on each call and new values
(`+1`, `+V`, etc.) are passed to the next recursive call. No mutation occurs —
the "state" is the function argument chain. Mercury's `array_di` / `array_uo`
pattern enforces the same linearity: `set(Idx, V, OldArr, NewArr)` consumes
`OldArr` and produces `NewArr`, preventing the old reference from being used.

---

## The stats record

```mercury
:- type stats ---> stats(count :: int, total :: int, maximum :: int).
```

---

## Unique IO threading across threads

Each thread spawned by `thread.spawn` gets its own continuation of the IO state.
The parent's `!IO` token advances past the spawn call and the child receives
a fresh `!IO` token. This means:

- Thread A's IO operations cannot interleave with Thread B's IO operations
  at the Mercury level — the type system enforces exclusive ownership
- In practice the OS scheduler may interleave, so all user-visible output
  should happen in a single thread (the Reporter)

Make Stage 2 do no IO (no `io.format` calls) — all printing is in Stage 3.

---

---

## Acceptance criteria

With `N = 20` (producer sends 20, 19, ..., 1 followed by sentinel):

| Metric | Expected value |
|---|---|
| Count | 20 |
| Total | 210 (sum of 1..20) |
| Maximum | 20 |
| Average | 10 (210 / 20, integer division) |
| Output format | `count: 20`, `total: 210`, `maximum: 20`, `average: 10` |

Edge cases:

| N | Count | Total | Max | Average |
|---|---|---|---|---|
| 0 | 0 | 0 | 0 | (none) |
| 1 | 1 | 1 | 1 | 1 |
| 5 | 5 | 15 | 5 | 3 |

## Design questions

1. Stage 2 sends `stats(Count0, Sum0, Max0)` when it sees the sentinel. What
   would change if Stage 2 needed to send partial updates after every K items?
   What would Chan2's element type become?

2. If the accumulation buffer were an `array(int)` instead of three ints, Stage 2
   would use `array.set(Idx, V, Arr0, Arr1)` to update. What Mercury mode
   annotation would `Arr0` have? Why can't you alias `Arr0` and `Arr1`?

3. Mercury's `cc_multi` vs `multi` — which determinism is required for a
   predicate that calls `thread.spawn`, and why does `multi` not suffice?
