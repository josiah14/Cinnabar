# Kata: `promise_equivalent_solutions` — two forms

**Why Mercury:** in most languages determinism is a runtime property; in Mercury it is a
compile-time contract. `promise_equivalent_solutions` is you signing that contract by
hand — promising the compiler that a `cc_multi`/`cc_nondet` goal's solutions are
observationally equivalent for the listed variables, so the goal may be treated as
deterministic.

## Concept

`promise_equivalent_solutions` suppresses `cc_multi` or `cc_nondet` propagation by
asserting that all solutions of the inner goal produce observationally equivalent
values for the listed variables.

**Form 1 — `[Var, ...]`:** used when a `cc_nondet`/`cc_multi` goal produces a
logically unique result (all solutions agree). Commits to one solution, letting
the outer context be `det`.

```mercury
promise_equivalent_solutions [Winner]
    pick_winner(Winner)
```

**Form 2 — `[!:IO]`:** used when `thread.spawn` (which is `cc_multi`) appears
inside a predicate that must stay `det`. Asserts that all IO states after spawning
are equivalent — true because the spawned thread runs independently.

```mercury
promise_equivalent_solutions [!:IO]
    thread.spawn(my_task, !IO)
```

## Prerequisites

- `katas/determinism/02-committed-choice` — `cc_multi`, `cc_nondet`, committed choice
- `katas/concurrency/03-basic-spawning` — `thread.spawn`
- `koans/concurrency/05-spawn-propagate` — `cc_multi` propagation
- `koans/concurrency/08-promise-equiv-io` — `[!:IO]` form koan

## Exercises

**Task 1:** Implement `first_even/1` as `det` using `promise_equivalent_solutions [N]`
to wrap `gen_first_even/1`. The stub returns `0` — replace the body with the wrapper.

**Task 2:** Fix `launch/3` so it is `det` instead of `cc_multi`. Add
`promise_equivalent_solutions [!:IO]` around the `thread.spawn` call, then
change the declaration from `cc_multi` to `det`.

After both fixes, `main` will compile as `det`.

## Run the tests

```
./runtests
```

Expected output (worker lines may appear in any order):
```
first even: 4
worker 1
worker 2
done
```
