# Cinnabar coverage review: Mercury language breadth and depth

## Rating and scope

Surveyed the full `katas/`, `koans/`, `bridge/`, and `puzzles/` inventories at the current tree state (post-synthesis fixes). Tracks are: Foundations, Type system, Mode system, Determinism, Parsing, Tooling, Concurrency, Advanced — 8 tracks across 4 exercise formats.

- **Breadth: 8/10.** Nearly every post-tutorial Mercury topic is represented: all six determinism categories, the full mode/inst system (user-defined insts, uniqueness, higher-order insts, clause selection, subtyping), DCGs through desugaring, type classes with superclasses/FDs/multi-parameter, existential types, FFI (all four pragma forms), RTTI, concurrency (both `&` and threads), tabling, solver types conceptually, debugging/profiling grades, and property testing.

- **Depth: 7.5/10.** The mode and determinism tracks go genuinely deep — deeper than any public Mercury resource I know. The advanced puzzles (combinator library, generic parser, plugin architecture, meta-interpreter) give real design work. The depth ceiling is that solver types/CLP stops at the language hook without a runnable implementation, and there is no multi-module capstone that makes learners manage interfaces, build definitions, and module boundaries at production scale.

## 1. Breadth

### Strongly covered core areas

| Area | Evidence | Assessment |
|---|---|---|
| Determinism | 7 katas covering all categories + committed choice + scope annotations + disjunction lattice + negation + `promise_equivalent_solutions`; 8 koans; logic puzzles apply generate-and-test; bridge 04 is dedicated to determinism ratcheting. | The curriculum's strongest pillar. The recent addition of determinism-in-disjunctions (kata 05) and determinism-and-negation (kata 06) fills gaps the earlier reviews flagged. |
| Modes and insts | 8 katas include user insts, multi-mode, uniqueness, higher-order insts, clause selection, inst hierarchy, and array-threading. `katas/mode-system/06-inst-hierarchy` explicitly teaches the inst lattice (`free` < `ground` < `any`; `unique` as separate axis), which is material almost no Mercury resource covers. | Unusually thorough. The clause-selection kata (07) is a particularly good deep cut — it teaches that Mercury resolves modes at compile time, not runtime, which is a non-obvious point that trips up Prolog transplants. |
| Type system | 10 katas: ADTs, parametric types, abstract types, typeclasses, typeclass depth (superclasses, FDs, multi-parameter), existential types, phantom types, GADT approximations. | Broad and well-sequenced. The GADT kata honestly treats Mercury's limitations rather than pretending it has full GADTs. |
| DCGs and parsing | 9 parsing katas covering DCG basics, semantic actions, `parsing_utils`, determinism in DCGs, left recursion, recovery, threaded state, packrat/tabling, and desugaring. 7 parsing koans. 3 parser puzzles. | Deep coverage. Kata 09 (dcg-desugar) makes learners examine what `-->` compiles into, closing the conceptual loop. |
| Concurrency | 9 katas covering parallel conjunction, threads/channels, deadlock, granularity, order-preserving fold/map in parallel, deterministic parallelism, STM. Koans and 3 puzzles add channel protocol design and parallel sort. | Both Mercury concurrency models are covered. The distinction between `&` (deterministic parallel conjunction) and `thread.spawn` (independent IO threads) is made explicit in `katas/concurrency/README.md`. |
| Standard library | Foundations covers `maybe`, maps, sets, `assoc_list`, strings/Unicode, exceptions, `io.res`, records, `bag`, `bimap`, arrays vs version arrays. Puzzles apply these in complete programs. | Good practical baseline. The `bag`/`bimap`/`array` vs `version_array` kata (foundations 11) is a useful addition that fills a gap the earlier reviews noted. |
| Tooling | 6 katas: grades, trace goals, `mdb` debugging, profiling, tabling, property testing. 9 koans reinforce grade/feature dependencies. | Better than most language exercise repos. The profiling and mdb katas are unusual in a curriculum at this scale. |

### Thinner areas

1. **Solver types / CLP is correctly flagged as read-only.** `katas/advanced/02-solver-types` is explicitly labelled as a "reference kata — no working build." This is the honest and correct response to a Mercury-ecosystem limitation: the solver type machinery exists in the language, but no maintained CLP(FD) backend ships with the standard distribution, so no educational material can make it hands-on. The kata covers the `any` inst, trailing grade, and purity interaction conceptually. The logic puzzles use generate-and-test (the correct choice given the constraint backend situation). The `CLP-PLAN.md` documentation is appropriate context — not a curriculum deliverable.

2. **Multi-module architecture is underdeveloped.** Modules, interface/implementation split, `import_module` vs `use_module`, and abstract types appear in foundations 01 and type-system 03, but there is no exercise where a learner designs module boundaries, manages namespace imports/qualification, writes an `.mh` interface file, or creates a multi-module build with a clean `Mmakefile` or `MMC_ARGS` setup. This is the most gap between "can read Mercury" and "can ship a Mercury package."

3. **Mutable state design has only one exercise.** `katas/foundations/00-reactivation/06-pure-randomness` covers `:- mutable`, `impure`/`semipure`, and FFI initialization, but it's positioned as a reactivation/review exercise and marked "advanced recall" by the README notice. There is no dedicated kata on `store`/`store_mutvar`, `io.mutvar`, or the design trade-offs between mutable state, unique threading, and STM.

4. **Library breadth beyond collections.** The curriculum covers `bag`, `bimap`, `array`, `version_array`, `set`, `map`, and `assoc_list` but not `queue`, `cord`, `digraph` (beyond its use in graph reachability), `bitmap`, `stream`, or term I/O (`term_to_xml`, `write_term`). A "choose the right container" bridge would address this more effectively than one kata per module.

## 2. Depth and progression

The difficulty curve is well-considered for a post-tutorial resource:

1. Foundations: practical Mercury — modules, maybe, strings, higher-order, maps, sets, exceptions, stdlib collections.
2. Type and mode tracks: compile-time invariants — representation hiding, inst subtyping, multi-mode relations, uniqueness.
3. Determinism and parsing: control-flow and grammar design as checked properties.
4. Tooling, concurrency, advanced: runtime concerns — grades, debugging, parallelism, FFI, RTTI, tabling.
5. Bridges and puzzles: integration — parser hardening, typeclass refactoring, concurrent pipelines, meta-interpreter.

The mode track is the most impressive for depth. It doesn't stop at "here's what `in` and `out` mean." It progresses through user insts (`bound`, `ground`, `free`), multi-mode predicates with `pragma promise_equivalent_clauses`, uniqueness and the aliasing problem, higher-order insts (with the critical point that `ground`-inst predicates cannot be called), compile-time clause selection, and the full inst hierarchy lattice. I am not aware of any other Mercury curriculum that reaches this depth.

The determinism track similarly benefits from recent expansions: katas 04 (multi/nondet), 05 (disjunction lattice), and 06 (negation and `\+`) turn what was a shallow tour of the six categories into a working model of how Mercury reasons about control flow. The `promise_equivalent_solutions` kata (07) addresses the earlier concern that committed-choice lessons appeared too repetitively without a stated progression.

The one plateau: between the track exercises and the advanced puzzles, there is no intermediate project that forces a learner to integrate types + modes + determinism in a single non-trivial design. Bridges partially fill this role (especially 04, 05, 06, 11), but they are bounded in scope. A "medium puzzle" tier — between bridges and advanced puzzles — could fill this.

## 3. Sequencing

The root recommended order (Foundations → Type → Mode → Determinism → Parsing → Tooling/Concurrency/Advanced) is sound. The "any order" caveat for the last three is the weakest sequencing advice. Specific corrections:

- `katas/advanced/02-solver-types` requires trailing grade and FFI knowledge from `01-ffi-depth` and `07-ffi-pragma-attrs`. The README now includes an `**After:**` block pointing to these, which fixes the earlier gap.
- `katas/concurrency/01-parallel-conjunction` requires determinism knowledge (the `det`/`cc_multi` constraint on `&`). This depends on determinism katas 01–02.
- The advanced puzzles list specific prerequisites in their own READMEs — this is the right pattern and most do it well.

The index drift that all three earlier reviewers flagged has been addressed programmatically via `ci.sh check_index`. Each of the 8 kata track READMEs and `bridge/README.md` are now validated against on-disk directory counts. This is a structural fix that prevents the problem recurring.

## 4. Most important gap

The **multi-module capstone** is the most actionable gap the curriculum could address. There is no exercise where a learner designs module boundaries, manages namespace imports/qualification, writes an `.mh` interface file, or creates a multi-module build with a clean build definition. Something like: implement a configuration library with opaque `config` type, parser module, validation module, and printer module — with explicit `use_module` interface boundaries, a clean build definition, and unit tests. This would exercise module design in a way no current exercise does and is fully within the existing Mercury toolchain's capabilities.

The solver-type situation is a Mercury-ecosystem limitation that the curriculum handles correctly (honest labelling, conceptual coverage, generate-and-test as the available technique). No curriculum action is needed beyond what the kata already does.

## 5. Redundancy and balance

The deliberate repetition of determinism (in its own track, modes, DCGs, testing, concurrency, logic puzzles) is justified — determinism is central to Mercury and the repetition across contexts is where fluency forms. The same holds for mode concepts appearing in parsing (DCG mode propagation) and concurrency (unique IO state across threads).

Two areas are slightly overrepresented relative to their learner impact:

1. **FFI/purity error cases**: The advanced track includes FFI depth (01), FFI pragma attributes (07), and solver FFI interaction (solver kata). The advanced koans cover missing `will_not_call_mercury`, impure foreign procedures, export arity, foreign enums, solver/FFI interactions, and a mutex case. That's 8+ distinct FFI-focused exercises for a feature most post-tutorial learners will use rarely. The quality is high, but consolidation would free capacity for the multi-module capstone.

2. **`promise_equivalent_*` and committed-choice**: These appear in determinism katas 02 and 07, multiple determinism koans, mode-specific clauses (kata 05), and `bridge/04-determinism-ratchet`. The new sequencing (katas 02 → committed choice basics, 07 → promise_equivalent_solutions) improves on the pre-fix state where it felt repetitive. The remaining risk is that a learner doing the full track may still feel they've seen the same `cc_multi` containment lesson three times.

The overall balance is good. Do not reduce repetition in modes, determinism, or parsing — those repetitions are the mechanism by which the curriculum achieves fluency rather than a checklist.
