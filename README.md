# Cinnabar

This is a personal fork of the [Cinnabar](https://github.com/josiah14-language-learning/Cinnabar) curriculum, maintained while working through the exercises. It serves three purposes:

1. **Learning** — working through each kata, koan, bridge, and puzzle to build Mercury fluency.
2. **Testing and polishing** — exercising each problem to refine it based on firsthand experience as a learner.
3. **Reference** — providing a complete, worked-through example of the curriculum for other learners and educators.

> **Pre-alpha work in progress.** This is an AI-assisted ("vibe-coded") curriculum I am building for my own path from the Mercury tutorial toward practical fluency. It is public to document the process and invite corrections, not yet as a polished or authoritative learning resource.
>
> You are welcome to use the curriculum as it is, adapt it for your own learning, and contribute corrections or exercises. Expect incomplete material, changing structure, and occasional technical mistakes; verify examples against the nix devShell's installed Mercury version provided by instantiating the flake.nix using `nix develop`.

*Ore for the Mercury programmer*

![Cinnabar: Ore for the Mercury programmer](docs/images/cinnabar-banner.png)

Cinnabar (HgS) is the red mineral from which mercury is smelted. You bring raw material; the heat does the work.

This repository contains katas, koans, bridges, and puzzles for programmers who have completed the [official Mercury tutorial](https://mercurylang.org/documentation/tutorial.html) and want to develop genuine fluency — the kind built by writing, breaking, and rewriting programs rather than reading about them.

## License

© 2026 Cloyd Garrett Berkebile. Licensed under [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/).

## Who this is for

You've worked through the tutorial. You can follow a Mercury program when someone else has written it.

Now you want to *think* in Mercury — to reach for modes and determinism as tools rather than obstacles, and to feel the difference between logic programming and everything else.

## Recommended order

Foundations → Type system → Mode system → Determinism → Parsing. After those five: Tooling → Concurrency → Advanced; within Advanced, 01 (FFI) → 02 (solver) → 03–08 (any order). Puzzles work well between tracks as a change of pace — `puzzles/logic/` and `puzzles/data-structures/` pair naturally with Foundations. Bridges sit between katas and puzzles; bridge 01–03, 11, and 12 after Foundations, bridge 04–06 after Mode system and Determinism, bridge 07–10 after Parsing and Advanced.

Start at the beginning of each track even if it feels easy. The early exercises establish habits the later ones depend on.

## What's here

Four exercise formats, each working different muscles:

- **Katas** — focused repetitions on a single concept: modes and determinism, higher-order predicates, `map`/`set`/`assoc_list` idioms, threading state with `!`, generate-and-test. Do them more than once. The second pass is where the wiring forms. Run `runtests` to verify your implementation.
- **Koans** — broken Mercury programs with one specific flaw. The compiler is the teacher; read its errors before looking at the `solution/` subdirectory.
- **Bridges** — each gives you a working Mercury file as a starting point and asks you to extend it. Use these when the jump from katas to puzzles feels steep. Key patterns are documented in `solution/README.md`.
- **Puzzles** — open-ended problems (constraint solving, search, parsing, concurrency, meta-programming) that make Mercury's declarative engine earn its keep. Each has a working solution in `solution/`.

### Tracks

Katas and koans are organized into tracks. Puzzles draw on multiple tracks and live separately under `puzzles/`.

| Track | Katas | Koans | Start here |
|---|---|---|---|
| Foundations | 13 | 23 | `katas/foundations/00-reactivation/01-hello-world` |
| Type system | 10 | 10 | `katas/type-system/01-discriminated-unions` |
| Mode system | 9 | 8 | `katas/mode-system/01-insts-and-modes` |
| Determinism | 7 | 8 | `katas/determinism/01-six-categories` |
| Parsing | 9 | 7 | `katas/parsing/01-dcg-basics` |
| Tooling | 6 | 9 | `katas/tooling/01-grades` |
| Concurrency | 9 | 7 | `katas/concurrency/01-parallel-conjunction` |
| Advanced | 8 | 8 | `katas/advanced/01-ffi-depth` |

### Bridges

Twelve bridges in `bridge/`, each handing you a working file and asking you to extend it:

| Bridge | Concept |
|---|---|
| `01-maybe-extend` | Maybe chaining, option handling |
| `02-pipeline-extend` | Higher-order filter/map/fold pipeline grouping |
| `03-dcg-extend` | DCG grammars and token parsers |
| `04-determinism-ratchet` | First solution of a `nondet` goal three ways (`solutions`/`find_first_match`/`cc_multi`); committed choice; parallel conjunctions |
| `05-mode-reversal` | Multi-mode predicates, `promise_equivalent_clauses` |
| `06-pipeline-parameterization` | Higher-order predicates with inst annotations |
| `07-parser-hardening` | Error recovery, structured error types |
| `08-expression-language` | Recursive descent, precedence, evaluators |
| `09-typeclass-refactor` | Extracting a numeric typeclass |
| `10-parallel-pipeline` | Bounded channels, backpressure, supervisors |
| `11-error-handling` | `maybe`, custom error types, `io.res`, exceptions — choosing the right mechanism |
| `12-currying-and-impurity` | Partial application, currying, `impure`/`semipure` predicates |

### Puzzles

Twenty-one puzzles in `puzzles/`, organized by topic:

| Topic | Puzzles |
|---|---|
| `logic/` | Sudoku, N-queens, crypto-arithmetic |
| `data-structures/` | Anagram finder, expression evaluator, graph reachability, frequency histogram |
| `parsing/` | Calculator, CSV reader, config parser |
| `concurrent/` | Parallel sort, pipeline, pipeline with unique state |
| `advanced/` | Generic printer, memoized search, bidirectional search, combinator library, generic parser, plugin architecture, Mercury meta-interpreter, multi-module config library |

## Reference

**[`COMPILER-LESSONS.md`](COMPILER-LESSONS.md)** — annotated compiler errors collected while building this curriculum. When Mercury gives you a cryptic error, check here before digging through documentation. It is the most practically useful file in the repository for day-to-day work.

## Setup

A `flake.nix` at the project root provides a development shell with the Mercury toolchain:

```
nix develop
```

From inside the shell, build any exercise with `mmc --make <module>`, where `<module>` is the filename without `.m`. For example, to try a koan:

```
cd koans/foundations/01-maybe/
mmc --make maybe_koan
./maybe_koan
```

Individual exercise directories note any grade flags or alternative build steps where needed. The full suite was developed and tested against Mercury 22.01.8.

## What's not here

A reintroduction to Mercury basics. If you haven't worked through the official tutorial, start there. This repository picks up where that one ends.

Kata solutions are also not here — by design. The `runtests` script in each kata directory tells you whether your implementation is correct; the derivation is the work. Koans, bridges, and puzzles include solutions because they center on specific patterns worth studying after you've attempted the exercise.

## Contributing

Additional exercises, corrections, and problem sets are welcome. Open an issue describing what gap you're trying to fill, or submit a pull request with an exercise and its solution in a `solution/` subdirectory.

## The name

Cinnabar is the ore. The exercises are the heat. What you make of it is up to you.
