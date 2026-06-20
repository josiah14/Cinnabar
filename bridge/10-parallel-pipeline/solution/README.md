# Solution notes

## Task 1: parallel transform stage

Route items from the reader to two workers based on value parity:

```mercury
:- pred dispatch(channel(maybe(int))::in,
                 channel(maybe(int))::in,
                 channel(maybe(int))::in,
                 io::di, io::uo) is cc_multi.
dispatch(In, ChanA, ChanB, !IO) :-
    channel.take(In, Item, !IO),
    (
        Item = no,
        channel.put(ChanA, no, !IO),
        channel.put(ChanB, no, !IO)
    ;
        Item = yes(V),
        ( V rem 2 = 0 ->
            channel.put(ChanA, yes(V), !IO)
        ;
            channel.put(ChanB, yes(V), !IO)
        ),
        dispatch(In, ChanA, ChanB, !IO)
    ).
```

Each worker is the original `transformer` predicate, writing to a shared output
channel. Spawn dispatch and both workers; the writer collects from the shared
output channel.

The output order is non-deterministic: items from worker A and worker B interleave
based on scheduling. The total is still correct (addition is commutative) but the
order of items in the output channel is not guaranteed.

### The fan-in trap: the writer **must** change

The task text says "the writer does not need to change." That is wrong, and it is the
most important thing to get right here. `dispatch` shuts both workers down by sending
`no` to each, and every worker forwards its own `no` to the shared output. So the
output channel now carries **two** sentinels — one per worker. The original writer
stops at the *first* `no`:

```mercury
writer(Chan, Acc0, Acc, !IO) :-
    channel.take(Chan, Item, !IO),
    ( Item = no,      Acc = Acc0                                   % stops too early!
    ; Item = yes(V),  writer(Chan, Acc0 + V, Acc, !IO) ).
```

If worker A's `no` arrives while worker B still has results queued behind it, those
results are silently dropped — the total comes out low and non-deterministically so.

**Fix: count one sentinel per producer.** Carry the number of still-live workers and
only stop when the last one has signalled:

```mercury
:- pred fanin_writer(channel(maybe(int))::in, int::in, int::in, int::out,
                     io::di, io::uo) is det.
fanin_writer(Chan, Pending, Acc0, Acc, !IO) :-
    channel.take(Chan, Item, !IO),
    (
        Item = no,
        ( Pending =< 1 ->
            Acc = Acc0                              % last sentinel — done
        ;
            fanin_writer(Chan, Pending - 1, Acc0, Acc, !IO)
        )
    ;
        Item = yes(V),
        fanin_writer(Chan, Pending, Acc0 + V, Acc, !IO)
    ).
```

Call it with `Pending = 2` (the number of workers). Because each worker emits all its
`yes` items before its own `no`, waiting for both sentinels guarantees every result is
read regardless of interleaving. (Verified: total is `N*(N+1)` on every run; the
single-sentinel writer drops items.)

The alternative is a **merger** stage: give each worker its own output channel, and a
merger that reads both, emits a single `no` once both are drained, and feeds one clean
stream to an unchanged writer. The sentinel-counting writer is simpler when the workers
already share one output channel; a merger is worth it when downstream stages must not
know how many producers there were.

## Task 2: bounded-buffer channel

```mercury
:- import_module thread.semaphore.

:- type bounded_chan(T) ---> bounded_chan(
    chan  :: channel(T),
    slots :: semaphore
).

:- pred bounded_init(int::in, bounded_chan(T)::out,
                     io::di, io::uo) is det.
bounded_init(Capacity, bounded_chan(Chan, Slots), !IO) :-
    channel.init(Chan, !IO),
    semaphore.init(Slots, !IO),
    % Signal Capacity times to set the initial slot count
    int.fold_up(
        (pred(_::in, !.IO::di, !:IO::uo) is det :-
            semaphore.signal(Slots, !IO)),
        1, Capacity, !IO).

:- pred bounded_put(bounded_chan(T)::in, T::in,
                    io::di, io::uo) is det.
bounded_put(bounded_chan(Chan, Slots), Item, !IO) :-
    semaphore.wait(Slots, !IO),    % block if full
    channel.put(Chan, Item, !IO).

:- pred bounded_take(bounded_chan(T)::in, T::out,
                     io::di, io::uo) is det.
bounded_take(bounded_chan(Chan, Slots), Item, !IO) :-
    channel.take(Chan, Item, !IO),
    semaphore.signal(Slots, !IO).  % release a slot
```

The `semaphore.signal` in `bounded_take` must happen after `channel.take`, not
before — otherwise a slot is released before the space is actually freed.

`int.fold_up` threads `!IO` through Capacity signal calls to initialize the
semaphore count. Alternatively use a recursive predicate.

## Task 3: backpressure verification

Add a simulated delay to the transformer:

```mercury
:- pred busy_wait(int::in) is det.
busy_wait(0).
busy_wait(N) :- N > 0, busy_wait(N - 1).
```

> **Note:** In `asm_fast` grade (the default), Mercury tail-call-optimizes
> `busy_wait` away entirely because it has no IO. The delay is a silent no-op and
> the backpressure demo appears not to work. Use `io.write_string` +
> `io.flush_output(!IO)` to force IO on each iteration, or `time.sleep` for a
> real delay:
>
> ```mercury
> :- pred busy_wait(int::in, io::di, io::uo) is det.
> busy_wait(0, !IO).
> busy_wait(N, !IO) :- N > 0,
>     io.write_string(".", !IO), io.flush_output(!IO),
>     busy_wait(N - 1, !IO).
> ```

Call `busy_wait(100000)` before processing each item. With an unbounded channel,
the reader enqueues all N items instantly and then the transformer processes them
slowly. With the bounded channel (capacity 10), the reader blocks after 10 items
until the transformer consumes some.

For timing, use the real-time clock via `time.clock` or simply observe the
behaviour with printed progress messages.

## Task 4: supervisor thread

The natural first attempt does not work, and the reason is instructive. If the
transformer both `throw`s on failure **and** is the thing that reports to `Report`,
then the moment it throws it stops — it never reaches the `channel.put(Report, ...)`
line, the thread dies, and the supervisor's `channel.take(Report, ...)` blocks forever.
A `throw` cannot also be its own crash report.

The fix is to separate the three concerns into three predicates:

**1. Business logic — throws, catches nothing.** It does not know the supervisor exists.

```mercury
:- pred transform_loop(channel(maybe(int))::in, channel(maybe(int))::in,
                       io::di, io::uo) is cc_multi.
transform_loop(In, Out, !IO) :-
    channel.take(In, Item, !IO),
    (
        Item = no,
        channel.put(Out, no, !IO)              % only a clean run reaches here
    ;
        Item = yes(V),
        ( V rem 7 = 0 ->
            throw(software_error("bad item: " ++ string.int_to_string(V)))
        ;
            channel.put(Out, yes(V * 2), !IO),
            transform_loop(In, Out, !IO)
        )
    ).
```

**2. Crash detection — a wrapper run in the spawned thread** that catches the exception
with `exception.try_io` and turns it into a message on `Report`:

```mercury
:- import_module exception.   % try_io/4, exception_result/1, software_error/1
:- import_module univ.        % univ_to_type/2
:- import_module unit.        % the result type carried by try_io here

:- pred run_transformer(channel(maybe(int))::in, channel(maybe(int))::in,
                        channel(maybe(string))::in, io::di, io::uo) is cc_multi.
run_transformer(In, Out, Report, !IO) :-
    try_io(
        (pred(unit::out, !.IO::di, !:IO::uo) is cc_multi :-
            transform_loop(In, Out, !IO)),
        Result, !IO),
    (
        Result = succeeded(_),
        channel.put(Report, no, !IO)                       % clean finish
    ;
        Result = exception(Univ),
        ( univ_to_type(Univ, software_error(Msg)) ->
            channel.put(Report, yes(Msg), !IO)
        ;
            channel.put(Report, yes("unknown error"), !IO)
        )
    ).
```

`try_io` needs a goal that produces a value, so the business logic is wrapped in a
lambda returning `unit`. On exception it hands back `exception(Univ)`; `univ_to_type`
recovers the original `software_error` and its message.

**3. The supervisor — restart on crash, stop on clean finish:**

```mercury
:- pred supervise(channel(maybe(int))::in, channel(maybe(int))::in,
                  channel(maybe(string))::in, int::in, io::di, io::uo) is cc_multi.
supervise(In, Out, Report, Restarts, !IO) :-
    channel.take(Report, Status, !IO),
    (
        Status = no,
        io.format("supervisor: clean finish after %d restart(s)\n",
            [i(Restarts)], !IO)
    ;
        Status = yes(Err),
        io.format("supervisor: crash (%s) -- restarting\n", [s(Err)], !IO),
        thread.spawn(run_transformer(In, Out, Report), !IO),
        supervise(In, Out, Report, Restarts + 1, !IO)
    ).
```

Restart works **because the bad item was already taken** from `In` before the `throw`
fired, so the re-spawned `run_transformer` resumes on the next item and skips it. The
partial output produced before each crash is already on `Out` and is not lost. Only a
clean run reaches `channel.put(Out, no)`, so `Out` carries exactly one sentinel no
matter how many restarts happen — the writer needs no special handling.

**Orchestration.** Run `supervise` on the main thread (so all of its logging is one
sequential stream) and run the writer on a spawned thread that returns its total
through a result channel; or vice-versa. Either way, `run_transformer` and `supervise`
must be `cc_multi`, because `thread.spawn` only accepts a `cc_multi` closure — a `det`
one is a mode error, even when the body happens to be deterministic.

Verified end to end (`mmc`, parallel grade): with `N = 20`, the transformer crashes on
`14` and `7`, the supervisor restarts twice, and the final total is `378`
(`2 × (sum 1..20 − 7 − 14)`) — the bad items skipped, everything else accounted for.
