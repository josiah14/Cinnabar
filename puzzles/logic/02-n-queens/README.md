# Puzzle: N-queens

**Primary skills:** `nondet`, `solutions/2`, arithmetic constraints, incremental solution building

**Why Mercury:** N-queens is the canonical demonstration that building partial solutions
incrementally and pruning early is vastly more efficient than generating all placements
and filtering. Mercury's backtracking handles the pruning automatically.

## Prerequisites

- `katas/determinism/01-six-categories` — `nondet`, `solutions/2`, incremental generation with pruning

---

## The problem

Place N queens on an N×N chessboard so that no two queens attack each other. Queens
attack along rows, columns, and diagonals.

Input: `N :: int`
Output: a `list(int)` of length N, where `Queens[i]` is the column of the queen in row i.
(One queen per row is assumed — representing a complete N-tuple.)

---

## Representation

Represent a placement as `list(int)` — position `i` in the list is the column (1..N)
of the queen in row `i`. Since we place one queen per row by construction, row conflicts
are impossible. We only need to check column and diagonal conflicts.

---

## Approach: incremental left-to-right

Build the queen list one row at a time. For each new queen in row `i`, check that it
does not conflict with any queen already placed in rows `1..i-1`.

```mercury
:- pred queens(int::in, list(int)::out) is nondet.
queens(N, Qs) :-
    queens_acc(N, N, [], Qs).

:- pred queens_acc(int::in, int::in, list(int)::in, list(int)::out) is nondet.
queens_acc(N, Row, Placed, Qs) :-
    ( Row =< 0 ->
        Qs = Placed
    ;
        int.nondet_int_in_range(1, N, Col),
        safe(Col, Placed, 1),
        queens_acc(N, Row - 1, [Col | Placed], Qs)
    ).
```

---

## Key predicate: `safe`

```mercury
:- pred safe(int::in, list(int)::in, int::in) is semidet.
safe(_, [], _).
safe(Col, [Q | Qs], Dist) :-
    Col \= Q,
    abs(Col - Q) \= Dist,
    safe(Col, Qs, Dist + 1).
```

`Dist` is the row distance between the new queen and the previously-placed queen.
Diagonal conflict: `abs(Col - Q) = Dist`.

---

---

## Acceptance criteria

| N | Number of solutions | Notes |
|---|---|---|
| 1 | 1 | `[1]` — trivial |
| 2 | 0 | Impossible (two queens always attack) |
| 3 | 0 | Impossible |
| 4 | 2 | `[2,4,1,3]` and `[3,1,4,2]` |
| 5 | 10 | |
| 6 | 4 | |
| 7 | 40 | |
| 8 | 92 | Canonical case |
| 9 | 352 | |
| 12 | 14200 | |

Each solution `Qs` must satisfy: `length(Qs) = N`, every integer in `1..N` appears at most
once (no column conflict), and no two queens share a diagonal.

## What to observe

Run `solutions(queens(8), Qs), list.length(Qs, N)` — there are 92 solutions for 8-queens.
Time the solver for N=10, N=12, N=15. Observe the growth rate.

Compare: how many solutions does N=1 have? N=2? Why?

---

## Extensions

- Find only the first solution (use committed choice or take first from `solutions`)
- Count solutions without storing them all (use `aggregate/4`)
- Visualize a solution as a board printed with ASCII art
