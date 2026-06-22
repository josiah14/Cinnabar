# Tooling

Mercury's compiler and runtime are controlled through *grades* — compile-time switches that
enable or disable features (garbage collection, parallelism, debugging, profiling, tabling).
Getting the right grade is prerequisite to using `mdb`, the profiler, or tabling. This track
covers the tooling layer that most Mercury documentation assumes you already know.

| Kata | Topic |
|---|---|
| `01-grades/` | Grade anatomy, feature table, mismatch errors (reference guide, no code) |
| `02-debugging-mdb/` | Compile with `.debug`, 4-port tracing, declarative debugging |
| `03-profiling/` | `.prof` and `.profdeep` grades, flat vs deep profiling, hotspot identification |
| `04-tabling/` | `pragma memo`, `pragma loop_check`, memoized Fibonacci |
| `05-testing/` | assertion pattern with `check/2`, `check_equal/3`, `check_solutions/3` |
| `06-property-testing/` | property-based testing: bounded generators, semidet properties, runner with `solutions/2` |

---

**Adding a kata?** See [`docs/TEMPLATES.md`](../../docs/TEMPLATES.md) for the canonical section order (the *Kata* template).
