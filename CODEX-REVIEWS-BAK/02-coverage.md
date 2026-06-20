# Cinnabar coverage review: Mercury language breadth and depth

## Rating and scope

Surveyed the full `katas/`, `koans/`, `bridge/`, and `puzzles/` inventories, their
track/category READMEs, and representative exercises at the foundations, advanced, and
integration boundaries.

- **Breadth: 8/10.** Cinnabar covers nearly every major post-tutorial Mercury topic,
  including several topics many curricula omit: inst subtyping, committed-choice
  determinism, tabling, runtime type information, FFI attributes, STM, and solver-type
  mechanics.
- **Depth: 8/10.** The curriculum goes well beyond intermediate Mercury, particularly
  in modes, determinism, parsing, concurrency, and FFI. Its main depth limitation is
  that solver types/CLP stop at the language hook rather than a working solver, and a
  few advanced areas are isolated demonstrations rather than capstone-scale projects.

The ratings assume the exercise inventory is the curriculum. Several track README tables
are stale and materially underreport that inventory; this harms discoverability and the
effective sequence (section 3).

## 1. Breadth

### Strongly covered core areas

| Area | Evidence | Assessment |
|---|---|---|
| Determinism | Seven katas cover all six categories, committed choice, scope annotations, `multi`/`nondet`, disjunctions, negation, and `promise_equivalent_solutions`; seven koans reinforce call-site errors and `cc_*`; logic puzzles apply generate-and-test. | Exceptionally strong. `katas/determinism/01-six-categories/README.md:12-21` explicitly covers all six categories, not merely the tutorial's three. |
| Modes and insts | Eight katas include `bound` and parametric insts, multiple modes, mode-specific clauses, uniqueness, higher-order insts, inst hierarchy, compile-time clause selection, and `array`/`version_array`; seven mode koans provide compiler-error practice. | This is the curriculum's most distinctive strength. It teaches modes as an executable design system, not annotations to repair after the fact. |
| Type system | Ten katas progress through ADTs, parametric and abstract types, typeclasses, existentials, multi-parameter classes/functional dependencies, class design/coherence, phantom types, and GADT approximations. Koans and advanced puzzles add failure modes, generic parsing, and plugins. | Broad and unusually mature. `katas/type-system/06-typeclass-depth/README.md:10-107` gives real superclass, multi-parameter, FD, and coherence work, rather than stopping at a `show` class. |
| Higher order | Foundations covers `map`, `filter`, `filter_map`, `foldl2`, and stored predicates; modes covers higher-order insts; bridge 06 and the parser-combinator puzzle require higher-order API design. | Good layered coverage. It reaches the important Mercury-specific point—insts/determinism on higher-order values—rather than only list callbacks. |
| DCGs and parsing | Nine parsing katas cover basics, semantic actions, `parsing_utils`, determinism, left recursion, recovery, threaded state, packrat/tabling, and desugaring. Seven koans and three parser puzzles/bridges apply them. | Deep and well rounded. `katas/parsing/09-dcg-desugar` makes learners examine what DCG notation compiles into, which closes the conceptual loop. |
| Concurrency | Nine katas cover parallel conjunction, threads/channels, IO, granularity, deadlock, order-preserving map/fold, unique state, deterministic parallelism, and STM; koans and three puzzles add protocol design. | Strong breadth across both Mercury concurrency models. `katas/concurrency/README.md:1-20` clearly distinguishes `&` from threads/channels. |
| Standard library and IO | Foundations covers modules, `maybe`, strings/Unicode, maps, sets, error values/exceptions, numeric corners, records, collections (`bag`, `bimap`, arrays), file IO; puzzles exercise these in complete programs. | Good practical baseline. The map/set/string exercises are repeated in useful contexts rather than merely catalogued. |
| Tooling | Grades, debugger, profiler, tabling, unit-style checks, and property testing all have katas and related koans. | Better than typical language exercise repositories; this makes the curriculum usable for real work. |

### Advanced coverage

The advanced track is real Mercury material, not a generic algorithms appendix:

- FFI: all four major pragma forms, C interop, type mapping, exporting, purity and
  locking attributes, plus several koans. `katas/advanced/01-ffi-depth/README.md:12-19`
  enumerates `foreign_decl`, `foreign_type`, `foreign_proc`, and `foreign_export`.
- Purity and mutable state: `00-reactivation/06-pure-randomness` covers `mutable`,
  `impure`, `semipure`, `promise_pure`, initialization, and FFI (`:3-21`). This is
  valuable material that is often absent.
- Reflection/meta-programming: RTTI, `univ`, `type_desc`, `deconstruct`, a generic
  printer, and a meta-interpreter. The latter incorporates renaming, unification,
  environment substitution, nondeterministic resolution, and `solutions/2`.
- Tabling/memoization: tooling, parsing, advanced kata, graph puzzle, and memoized-search
  puzzle distinguish deterministic memoization from tabled search/fixed-point work.
- Solver types: the `any` inst, trailing grade, and purity interaction are represented,
  with one koan for the key mode error.

### Thin or absent areas

1. **Working constraint logic programming is the largest advanced gap.** The solver-types
   kata is intellectually honest—“There is no bundled CLP(FD) engine”
   (`katas/advanced/02-solver-types/README.md:71-76`)—but it consequently supplies only
   declaration/mode/FFI exercises. The `domain`, `#=`, and `labeling` API is aspirational
   (`:78-98`), not curriculum code. A learner never builds or uses a backtrackable
   constraint store. This is the most conspicuous capability gap because the logic-puzzle
   track repeatedly uses brute-force generate-and-test where CLP would be the natural
   advanced comparison.
2. **Effect and state design is thin outside one reactivation exercise and FFI.** The
   repository names `mutable`, `impure`, and `semipure`, but does not give a sustained
   post-tutorial exercise in designing a safe impure boundary, testing it, and comparing
   it to explicit `!IO`, `stm`, or uniqueness-threaded state. The random-number exercise
   is valuable, but it is positioned as recall material before the Foundations sequence.
3. **Large-program module architecture is comparatively light.** Modules, abstract types,
   `use_module`/`import_module`, and an abstract-module kata are present, but there is no
   multi-module capstone that makes learners manage interfaces, namespaces, dependency
   boundaries, and an Mmakefile over a realistic package. That is a likely next need for
   a programmer transitioning from the tutorial to production Mercury.
4. **Library breadth has a long tail missing by design.** The course covers the high-value
   collections, but not dedicated exercises for queues/cords, bitmaps, digraphs, streams,
   or serialization/term I/O. This is not a release blocker; one applied stdlib survey or
   a “choose the representation” bridge would be more useful than one kata per module.

## 2. Depth and progression

Difficulty generally rises in a defensible way:

1. Foundations starts with everyday types, modules, optional values, collections, IO, and
   mode inference.
2. Type and mode tracks then expose compile-time invariants: representation hiding,
   instantiation, multi-mode relations, uniqueness, and higher-order modes.
3. Determinism and parsing turn those invariants into control-flow and grammar design.
4. Tooling/concurrency/advanced add runtime grades, debugging/profiling, parallelism,
   STM, FFI, RTTI, and solver types.
5. Bridges and puzzles combine concepts: parser hardening, typeclass refactoring,
   bounded pipelines, generic parsers/plugins, and the meta-interpreter.

There is no intermediate plateau. In particular:

- The mode track progresses from user insts to mode-specific implementations and
  compile-time clause selection. `katas/mode-system/07-clause-selection/README.md:10-15`
  teaches the non-obvious point that Mercury selects the applicable procedure at compile
  time, not by Prolog-style runtime clause choice.
- Parsing reaches algorithmic and compiler-level depth with left-recursion elimination,
  stateful grammars, tabled/packrat parsing, and desugaring.
- Concurrency reaches beyond “spawn a thread” into deadlock, granularity, deterministic
  parallelism, unique state, and STM transactions with `retry`/`or_else`.
- The advanced type track does not pretend Mercury has GADTs; it asks learners to compare
  three approximations and their lost invariants (`katas/type-system/10-gadts/README.md:93-131`).

The weak spot is solver types. `katas/advanced/02-solver-types` explicitly cannot provide
a functioning constraint engine, so it becomes partly a reading/reference kata. It is
still useful, but it is less hands-on than the rest of the advanced path. An optional
small, deliberately limited finite-domain solver—domains, equality/inequality, choice,
and trailing—would turn this from language awareness into advanced practice.

## 3. Sequencing

The root order is broadly sound: Foundations → Type System → Mode System → Determinism →
Parsing, then Tooling/Concurrency/Advanced (`README.md:21-25`). Dependencies in individual
advanced puzzles are usually specific: the combinator-library puzzle requires higher-order,
determinism, and higher-order-inst knowledge; the plugin puzzle builds on typeclasses and
existentials; the meta-interpreter names determinism and higher-order insts.

The major sequencing failure is not conceptual—it is the documentation's incomplete maps.
Track/category indexes omit existing later exercises:

- `katas/type-system/README.md` lists only 01–05, omitting 06–10.
- `katas/mode-system/README.md` omits 06 and 07.
- `katas/determinism/README.md` lists 01–03 and 07, omitting 04–06.
- `katas/parsing/README.md` lists 01–03, omitting 04–09.
- `bridge/README.md` lists only 01–03 and 11, omitting 04–10.
- `puzzles/README.md` omits most advanced puzzles and the third concurrent puzzle.
- `katas/README.md` says “More tracks will follow” despite the eight current tracks.

This means learners who follow the per-directory README do not see the intended advanced
sequence, even though the exercises exist. Update every index before release and make the
root/table data generated or validation-tested.

There are two more ordering concerns:

- The reactivation exercise “Pure Randomness” introduces mutables, purity annotations,
  FFI, and initialization (`katas/foundations/00-reactivation/06-pure-randomness/README.md:3-21`)
  before the main Foundations track teaches modules, IO/error handling, and higher-order
  work. It is acceptable as optional active recall for an already experienced learner,
  but should be explicitly marked “advanced recall; defer until Advanced/FFI” or moved.
- The root says Tooling, Concurrency, and Advanced can be taken “in any order.” The
  advanced solver kata requires a non-default trailing grade and FFI knowledge, while
  concurrency depends heavily on modes/determinism. “Any order after the core” is too
  loose. Offer recommended subpaths: Tooling → Concurrency, and Advanced 01 (FFI) → 02
  (solver) → 03–07, with explicit exceptions for independent topics.

## 4. Most important gap

Add a **working constraint-store / finite-domain mini-project**. It is the clearest
missing post-tutorial Mercury experience: persistent constraints with the `any` inst,
trailing/backtracking semantics, search/labeling, and a comparison against the existing
generate-and-test Sudoku or crypto-arithmetic puzzles.

The full Rust CLP(FD) plan need not be a prerequisite. A small in-Mercury or narrowly
scoped FFI-backed implementation that supports finite domains and `=/2`/`!=/2` would be
enough. This would make solver types concrete, demonstrate why the trailing grade matters,
and connect an otherwise isolated advanced topic to visible problem-solving payoff.

If that is intentionally out of scope, the next highest-value addition is a multi-module
capstone (for example, a configuration tool or library) with public interfaces, opaque
types, `use_module` boundaries, testing, profiling, and a clean build definition.

## 5. Redundancy and balance

There is healthy deliberate repetition: determinism appears in its own track, modes,
DCGs, testing, concurrency, and logic puzzles because it is central to Mercury. Likewise,
the dense DCG material is justified: parsing is where modes, determinism, state threading,
and backtracking become operationally visible.

Two areas are relatively overrepresented:

- **FFI/purity error cases:** advanced includes FFI depth and FFI attributes; the advanced
  koans include missing `will_not_call_mercury`, impure foreign procedures, export arity,
  foreign enums, solver/FFI interaction, and a mutex case, in addition to the purity/
  randomness reactivation kata. That is excellent specialist coverage, but is more
  exercise real estate than solver types or module-scale architecture receive. Keep the
  koans, but consolidate their learning map and redirect one future FFI exercise toward
  a practical integration project.
- **`promise_equivalent_*` and committed-choice mechanics:** they occur in determinism
  katas 02/07, multiple determinism koans, mode-specific clauses, a bridge, and
  concurrency spawn. This is defensible but needs a stated progression: first learn the
  guarantee, then the procedure-level promise, then `!IO`/thread consequences. Without
  that map, it can read as repeated compiler trivia.

The overall balance is good. Do not reduce the mode, determinism, or parsing repetition;
those repetitions are where Cinnabar achieves fluency rather than a topical checklist.
