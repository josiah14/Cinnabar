# Puzzle: parallel mergesort

**Primary skills:** `&` parallel conjunction, `list`, divide-and-conquer, timing

**Requires:** `.par` grade

**Why Mercury:** parallel conjunction is the most natural way to express "sort the left half
and the right half simultaneously." The granularity question — when is parallelism worth the overhead? — is the interesting lesson.

## Prerequisites

- `katas/concurrency/01-parallel-conjunction` — `&`, determinism requirements, `.par` grade, granularity

---

## The problem

Implement mergesort that uses `&` to sort the two halves in parallel. Compare its
performance against the sequential version for lists of various sizes.

---

## The structure

```mercury
:- pred mergesort(list(int)::in, list(int)::out) is det.
mergesort(List, Sorted) :-
    ( List = [] ->
        Sorted = []
    ; List = [X] ->
        Sorted = [X]
    ;
        list.length(List, Len),
        Half = Len // 2,
        split_at(Half, List, Left, Right),
        % Parallel: sort both halves concurrently
        mergesort(Left, SortedLeft)
        &
        mergesort(Right, SortedRight),
        merge_sorted(SortedLeft, SortedRight, Sorted)
    ).
```

Note: `list.take` and `list.drop` are `semidet` in Mercury 22.01.8 (they fail if the
list is too short) and cannot be called from a `det` context. Use a custom `split_at`
predicate instead:

```mercury
:- pred split_at(int::in, list(T)::in, list(T)::out, list(T)::out) is det.
split_at(N, List, Left, Right) :-
    ( N =< 0 ->
        Left = [], Right = List
    ; List = [H | T] ->
        split_at(N - 1, T, L0, Right),
        Left = [H | L0]
    ;
        Left = [], Right = []
    ).
```

:- pred merge_sorted(list(int)::in, list(int)::in, list(int)::out) is det.

---

## The granularity question

For small sublists, spawning a parallel task costs more than just sorting sequentially.
Add a threshold:

```mercury
mergesort(List, Sorted) :-
    list.length(List, Len),
    ( Len =< Threshold ->
        insertion_sort(List, Sorted)
    ;
        ... parallel split ...
    ).
```

Find the threshold where parallel starts to win. This depends on your hardware (number
of cores) and the grade's parallel overhead.

---

## Measurement

```mercury
io.clock(T1, !IO),
mergesort(LargeList, _, !IO),
io.clock(T2, !IO),
io.format("Time: %d ms\n", [i((T2 - T1) // 1000)], !IO).
```

---

## Acceptance criteria

| Input list | Sequential result | Parallel result | Match? |
|---|---|---|---|
| `[]` | `[]` | `[]` | yes |
| `[5]` | `[5]` | `[5]` | yes |
| `[3,1,2]` | `[1,2,3]` | `[1,2,3]` | yes |
| `make_descending(500)` | `1..500` | `1..500` | yes (below threshold → sequential) |
| `make_descending(2000)` | `1..2000` | `1..2000` | yes (above threshold → parallel) |
| `make_descending(10000)` | `1..10000` | `1..10000` | yes (the sample) |

The program must print `"Results match."` to confirm correctness. Timing output may vary by hardware.

## What to observe

- For N < 1000, sequential is almost always faster
- For N > 100,000, parallel starts to win (assuming multiple cores)
- The speedup is bounded by the number of cores and the merge step (sequential bottleneck)
