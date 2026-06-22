# Concurrency

Mercury supports two concurrency models: **parallel conjunction** (`&`) for
fork-join parallelism over `det` computations, and **threads** (`thread.spawn`,
`thread.channel`) for independent concurrent tasks communicating through channels.

The track begins with the safest form (`&` over det goals), then moves to manual thread/channel programming, resource hazards (deadlock, granularity, uniqueness at thread boundaries), and ends at software transactional memory (STM) for coordinated multi-variable access. The payoff is understanding *which tool to reach for*: `&` when you need parallel speedup with no coordination; channels when tasks need to communicate; STM when multiple shared variables need to change atomically.

Both require the `.par` grade.

| Kata | Topic |
|---|---|
| `01-parallel-conjunction/` | `&` operator, `det`/`cc_multi` requirement, timing comparison |
| `02-threads/` | `thread.spawn`, `thread.channel`, producer-consumer |
| `03-concurrent-io/` | IO across threads; child thread's independent IO token |
| `04-granularity/` | Parallel conjunction overhead; when not to parallelize |
| `05-deadlock/` | Waiting-for graph; semaphore mutexes; resource ordering |
| `06-parallel-map-fold/` | Order-preserving parallel map using channels |
| `07-uniqueness-and-threads/` | Unique modes across thread boundaries; `version_array` |
| `08-deterministic-parallelism/` | `&` for deterministic parallelism; when `&` is safe |
| `09-stm/` | Software transactional memory: `stm_var`, `atomic_transaction`, `retry`, `or_else` |

**Not in the Mercury tutorial.**

---

**Adding a kata?** See [`docs/TEMPLATES.md`](../../docs/TEMPLATES.md) for the canonical section order (the *Kata* template).
