# Puzzle: Sudoku

**Primary skills:** `nondet` generate-and-test, `solutions/2`, `set`, early constraint pruning

**Why Mercury:** the declarative generate-and-test idiom maps directly onto Sudoku. The
interesting design question is *when* to apply constraints — early pruning dramatically
reduces the search space.

## Prerequisites

- `katas/determinism/01-six-categories` — `nondet`, `solutions/2`, generate-and-test
- `katas/foundations/06-set` — `set(T)` for constraint checking

---

## The problem

Solve a 9×9 Sudoku puzzle. Given a partially-filled grid (zeros represent empty cells),
find a completion where:
- Each row contains each digit 1–9 exactly once
- Each column contains each digit 1–9 exactly once
- Each 3×3 box contains each digit 1–9 exactly once

Input: a `list(list(int))` of 9 rows, with 0 for empty cells.
Output: a completed grid, or failure if no solution exists.

---

## Representation

```mercury
:- type grid == list(list(int)).
:- type row  == list(int).
```

A grid is 9 rows; each row is 9 integers.

---

## Approach: generate-and-test with early pruning

The naive approach — fill all empty cells, then check all constraints — is exponential
in practice. The key insight: check constraints *after each placement*, not at the end.
When a placement violates a row, column, or box, fail immediately rather than exploring
millions of dead branches.

The top-level shape is a `nondet` predicate that finds the first empty cell, tries each
digit 1–9, checks constraints, and recurses. When no empty cells remain, the grid is solved.

---

## Key predicates to write

- `first_empty(Grid, Row, Col)` — find the first cell with value 0
- `place(Grid, Row, Col, Digit, Grid1)` — return a new grid with one cell filled
- `valid_placement(Grid, Row, Col)` — check constraints for the row, column, and box
  containing (Row, Col)
- `row_valid(list(int))` — no duplicates among non-zero values
- `box_at(Grid, Row, Col, list(int))` — extract the 3×3 box containing (Row, Col)

---

## What to observe

Time the solver with and without `valid_placement` called after each placement (vs.
checking all constraints only at the end). The difference is dramatic.

---

## Sample puzzle

```mercury
example_puzzle = [
    [5, 3, 0, 0, 7, 0, 0, 0, 0],
    [6, 0, 0, 1, 9, 5, 0, 0, 0],
    [0, 9, 8, 0, 0, 0, 0, 6, 0],
    [8, 0, 0, 0, 6, 0, 0, 0, 3],
    [4, 0, 0, 8, 0, 3, 0, 0, 1],
    [7, 0, 0, 0, 2, 0, 0, 0, 6],
    [0, 6, 0, 0, 0, 0, 2, 8, 0],
    [0, 0, 0, 4, 1, 9, 0, 0, 5],
    [0, 0, 0, 0, 8, 0, 0, 7, 9]
].
```

Expected: exactly one solution.

---

## Design questions

1. Constraint checking happens after each cell is placed (`valid_placement`). What
   would happen if you checked all constraints only when the grid was full? Estimate
   how many more nodes the search would explore for the sample puzzle.

2. `no_dups` is called on rows, columns, and boxes. Could you replace the set-based
   duplicate check with a sorting approach? What are the trade-offs in code clarity
   and performance for a 9-element list?

3. This solver finds the first solution and stops. How would you modify it to count
   all solutions without storing them all in memory?

---

## Expected output

```
[[5, 3, 4, 6, 7, 8, 9, 1, 2], [6, 7, 2, 1, 9, 5, 3, 4, 8], [1, 9, 8, 3, 4, 2, 5, 6, 7], [8, 5, 9, 7, 6, 1, 4, 2, 3], [4, 2, 6, 8, 5, 3, 7, 9, 1], [7, 1, 3, 9, 2, 4, 8, 5, 6], [9, 6, 1, 5, 3, 7, 2, 8, 4], [2, 8, 7, 4, 1, 9, 6, 3, 5], [3, 4, 5, 2, 8, 6, 1, 7, 9]]
```
