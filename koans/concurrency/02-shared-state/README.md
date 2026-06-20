# Koan: parallel conjunction and unique state

## Prerequisites
- `katas/concurrency/01-parallel-conjunction`
- `koans/mode-system/04-uniqueness-violation`

The `&` operator runs goals in parallel. For that to be sound, no branch may *consume* a value another branch also needs — and `io.state` is **unique**, so it can be consumed only once, by one branch.

The koan writes the IO state explicitly — `IO0` handed to *both* branches — instead of with the usual `!IO` shorthand. That is deliberate. `!IO` auto-threads the state through the conjuncts one after another, so `( ... !IO & ... !IO )` *compiles* — but only by serializing the two branches into a chain, which is no longer parallel. Naming the state shows what genuinely sharing it would mean, and the uniqueness checker rejects it.

Compile this:

```
mmc --make shared_state_koan
```

The compiler rejects both branches consuming the same IO token.

---

`&` is safe for **pure** goals that share no unique variables. The solution is to separate computation from IO: run pure computations in parallel with `&`, then do IO sequentially once both results are ready.

```mercury
( A = compute_a() & B = compute_b() ),
io.format("A=%d B=%d\n", [i(A), i(B)], !IO).
```

Here the two computations share no state. IO happens after both complete.

---

## What to observe

The error names the unique variable being consumed by multiple branches. Mercury catches
this statically — the uniqueness checker is part of the mode system, not a runtime check.
Notice the error fires even if the branches would never actually run concurrently.

---

## Your task

Separate the pure computation from the IO in the broken code. Run the pure parts in
parallel with `&`, then sequence the IO afterward. If the original code has no pure part
to extract, restructure it so the parallel conjunction only touches non-unique values.

Note: simply rewriting the two writes back into `!IO` form is *not* the fix. It compiles,
but only because Mercury serializes the branches — you get no parallelism. The point is to
parallelize the work that actually *can* run independently (the pure goals), and keep the
unique IO state on a single sequential thread.
