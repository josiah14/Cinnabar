# Bridge: parallel pipeline

**After:** `katas/concurrency/02-threads` and `puzzles/concurrent/02-pipeline`

`pipeline.m` is a working three-stage pipeline:

1. **Reader** — sends integers N down to 1 via a channel, then a sentinel `no`
2. **Transformer** — doubles each value, forwards the sentinel
3. **Writer** — accumulates the total until it sees the sentinel

The reader and transformer run in spawned threads; the writer runs on the main thread.

Build and run it first:

```
mmc --make --grade asm_fast.par.gc.stseg pipeline
./pipeline
```

The tasks add parallelism within stages, backpressure, and a supervisor.

---

## Extension tasks

### 1. Parallel transform stage

The transformer currently processes one item at a time. Replace the sequential
doubling with two parallel workers that each handle half the input stream.

Split the channel after the reader: route even-numbered items to worker A and
odd-numbered items to worker B, using a dispatch predicate. Each worker doubles
its items and sends results to a shared output channel.

Both workers must be `cc_multi` (they call `channel.put`, which threads `!IO`).
Spawn each with `thread.spawn`.

The output channel receives results from two senders in interleaved order —
document this in a comment. **The writer does need to change**: with two workers the
output now carries two sentinels (one per worker), so a writer that stops at the first
`no` drops the other worker's tail. Make the writer count one sentinel per producer
(or add a merger stage). See the solution notes for the fan-in fix.

### 2. Bounded-buffer channel

Mercury's `thread.channel` is unbounded: the producer can enqueue indefinitely
without blocking. Add a bounded buffer between the reader and transformer.

Implement a bounded channel using a `channel` plus a `semaphore`:

```mercury
:- type bounded_chan(T) ---> bounded_chan(
    chan :: channel(T),
    slots :: semaphore
).
```

- `bounded_put(BC, Item, !IO)`: wait on `slots` (blocks if buffer full),
  then put to the channel.
- `bounded_take(BC, Item, !IO)`: take from the channel, then signal `slots`
  (releases one slot).

Use `thread.semaphore.wait` and `thread.semaphore.signal`. Initialize `slots` with
the buffer capacity (e.g., 10).

Replace the raw channel between reader and transformer with a `bounded_chan`.

### 3. Backpressure

With the bounded buffer from Task 2, the reader blocks when the transformer cannot
keep up. This is backpressure: the slow stage signals back to the fast stage to slow
down.

Verify this works by adding a simulated delay to the transformer (a busy-wait loop
or `io.sleep`) and confirming the reader blocks at the buffer limit rather than
sending all N items immediately.

Add timing: print how long `main` takes with and without the bounded channel.

### 4. Supervisor thread

Add a supervisor that monitors the transformer thread for failure. If the transformer
crashes (raises an exception), the supervisor:
- Detects the failure via a `channel(maybe(string))` where the transformer sends
  `no` on clean exit and `yes(ErrorMsg)` on failure
- Logs the error
- Restarts the transformer

To simulate failure: add a case in the transformer that throws a `software_error`
when it sees an item divisible by 7. The supervisor catches this and restarts,
skipping the failing item.

Use `exception.try` inside the transformer's main loop to catch exceptions and
report them to the supervisor channel.

---

## What you are practising

- Splitting a sequential pipeline stage into parallel workers
- The unbounded channel problem and why backpressure is needed in real pipelines
- Building bounded channels from semaphores and raw channels
- Supervisor patterns: separating crash detection from business logic
