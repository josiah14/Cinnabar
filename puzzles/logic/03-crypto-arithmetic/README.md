# Puzzle: SEND + MORE = MONEY

**Primary skills:** `nondet` generate-and-test, `aggregate/4` vs `solutions/2`, arithmetic

**Why Mercury:** crypto-arithmetic puzzles are pure constraint problems. The declarative
generate-and-test idiom is direct. The interesting Mercury question: when should you use
`solutions/2` (collect all) vs `aggregate/4` (fold without accumulating)?

## Prerequisites

- `katas/determinism/01-six-categories` — `nondet` generate-and-test, `solutions/2` vs `aggregate/4`
- `puzzles/logic/02-n-queens` — similar incremental generate-and-test pattern

---

## The problem

Solve the classic alphametic:

```
  S E N D
+ M O R E
---------
M O N E Y
```

Each letter represents a unique digit (0–9). Leading digits S and M cannot be zero.

---

## The constraint

```
1000*S + 100*E + 10*N + D
+ 1000*M + 100*O + 10*R + E
= 10000*M + 1000*O + 100*N + 10*E + Y
```

---

## Approach

Generate all permutations of 8 distinct digits from 0–9 (assigned to S, E, N, D, M, O, R, Y)
and test the arithmetic constraint.

```mercury
:- pred solve(int::out, int::out, int::out, int::out,
              int::out, int::out, int::out, int::out) is nondet.
solve(S, E, N, D, M, O, R, Y) :-
    % Generate 8 distinct digits
    int.nondet_int_in_range(0, 9, S), S \= 0,    % leading digit
    int.nondet_int_in_range(0, 9, E), E \= S,
    int.nondet_int_in_range(0, 9, N), N \= S, N \= E,
    int.nondet_int_in_range(0, 9, D), D \= S, D \= E, D \= N,
    int.nondet_int_in_range(0, 9, M), M \= 0, M \= S, M \= E, M \= N, M \= D,
    int.nondet_int_in_range(0, 9, O), O \= S, O \= E, O \= N, O \= D, O \= M,
    int.nondet_int_in_range(0, 9, R), R \= S, R \= E, R \= N, R \= D, R \= M, R \= O,
    int.nondet_int_in_range(0, 9, Y), Y \= S, Y \= E, Y \= N, Y \= D, Y \= M, Y \= O, Y \= R,
    % Test the arithmetic
    1000*S + 100*E + 10*N + D
    + 1000*M + 100*O + 10*R + E
    = 10000*M + 1000*O + 100*N + 10*E + Y.
```

---

---

## Acceptance criteria

The constraint `SEND + MORE = MONEY` has exactly one solution:

| Variable | Value | Constraint |
|---|---|---|
| S | 9 | S ≠ 0 |
| E | 5 | |
| N | 6 | |
| D | 7 | |
| M | 1 | M ≠ 0 |
| O | 0 | |
| R | 8 | |
| Y | 2 | |

| Check | Expected |
|---|---|
| SEND | 9567 |
| MORE | 1085 |
| SEND + MORE | 10652 |
| MONEY | 10652 |
| Number of solutions | 1 (verified: `solutions/2` returns list of length 1) |

## `solutions/2` vs `aggregate/4`

For SEND + MORE = MONEY, there is exactly one solution — `solutions` is fine.

For puzzles with many solutions (e.g., a relaxed version), `aggregate/4` avoids building
a large list:

```mercury
aggregate(solve(S, E, N, D, M, O, R, Y),
          (pred(solution(S,E,N,D,M,O,R,Y)::in, C0::in, C::out) is det :- C = C0 + 1),
          0, Count).
```

---

## Extensions

- Solve FORTY + TEN + TEN = SIXTY
- Find all 4-letter + 4-letter = 5-letter alphametics with a solution
- Measure performance: how does the order of the `\=` checks affect speed?
