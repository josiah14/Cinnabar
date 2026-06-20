# Bridge exercises

These exercises sit between katas and puzzles. Each one gives you **working code as a
starting point** — a compilable Mercury program that does something useful — and asks
you to extend it.

The goal is to practice the design decisions that puzzles require, but with less
blank-page friction: you already have a structure to work within and extend.

## How to use these

1. Read the README to understand the starting program and what you are extending.
2. Read the starter `.m` file — make sure you understand every line before adding to it.
3. Work through the extension tasks in order. Each one builds on the last.
4. There is no single correct solution. The `solution/README.md` describes one approach
   and the tradeoffs, but your design choices are valid if the program is correct.

## Exercises

| # | Exercise | Skills | After |
|---|---|---|---|
| 01 | `01-maybe-extend` | `maybe`, chaining, validation | `katas/foundations/02-maybe` |
| 02 | `02-pipeline-extend` | higher-order, `map`, grouping | `katas/foundations/04-higher-order` |
| 03 | `03-dcg-extend` | DCGs, tokenizers, grammar extension | `katas/parsing/01-dcg-basics` |
| 04 | `04-determinism-ratchet` | determinism annotations, committed choice, `cc_multi`/`cc_nondet` | `katas/determinism/02-committed-choice` |
| 05 | `05-mode-reversal` | multi-mode predicates, `promise_equivalent_clauses` | `katas/mode-system/02-multi-mode` |
| 06 | `06-pipeline-parameterization` | higher-order insts, `pred` type annotations | `katas/foundations/04-higher-order` |
| 07 | `07-parser-hardening` | error handling, `maybe`, `io.res`, CSV parsing | `katas/parsing/03-parsing-utils`, `puzzles/parsing/02-csv-reader` |
| 08 | `08-expression-language` | lexer extension, AST construction, evaluation | `katas/parsing/02-dcg-goals`, `bridge/03-dcg-extend` |
| 09 | `09-typeclass-refactor` | typeclass instances, polymorphic evaluation | `katas/type-system/07-typeclass-design` |
| 10 | `10-parallel-pipeline` | `thread.spawn`, channels, fan-out/fan-in, `maybe` sentinel | `katas/concurrency/02-threads`, `puzzles/concurrent/02-pipeline` |
| 11 | `11-error-handling` | `maybe`, custom error types, `io.res`, exceptions | `katas/foundations/02-maybe`, `katas/foundations/07-exceptions` |
