# Coverage breadth + depth — Big Pickle

## Breadth: 8/10
## Depth: 7.5/10

Nearly every post-tutorial Mercury topic is represented: all six determinism categories, full mode/inst system, DCGs, typeclasses (superclasses/FDs/multi-parameter), existential types, FFI, RTTI, concurrency, tabling, solver types, property testing. The mode and determinism tracks go deeper than any public Mercury resource.

## Strong coverage

| Area | Evidence |
|---|---|
| Determinism | 7 katas + 8 koans + logic puzzles. New katas 04 (multi/nondet), 05 (disjunction lattice), 06 (negation) fill previous gaps. |
| Modes/insts | 8 katas covering user insts, multi-mode, uniqueness, higher-order insts, clause selection, inst hierarchy. |
| DCGs/parsing | 9 katas + 7 koans + 3 parser puzzles. Kata 09 (dcg-desugar) closes the loop. |
| Concurrency | 9 katas + koans + 3 puzzles. Both `&` and `thread.spawn` models covered. |
| Tooling | 6 katas: grades, trace/mdb, profiling, tabling, property testing. |

## Thinner areas

1. **Multi-module architecture.** No exercise requires designing module boundaries, managing `use_module` vs `import_module`, or writing an `.mh` interface. This is the biggest actionable gap.
2. **Mutable state.** Only one exercise (`06-pure-randomness` in reactivation). No dedicated kata on `store`/`store_mutvar`/`io.mutvar`.
3. **Library breadth.** Covers `bag`, `bimap`, `array`, `version_array`, `set`, `map`, `assoc_list` but not `queue`, `cord`, `digraph`, `bitmap`, `stream`, term I/O.
4. **Solver types.** Correctly labelled as conceptual-only (no maintained CLP(FD) backend). Honest handling of an ecosystem limitation.

## Depth highlights

- Mode track is the curriculum's strongest pillar. Progresses through user insts → multi-mode with `promise_equivalent_clauses` → uniqueness → higher-order insts → compile-time clause selection → inst hierarchy.
- Determinism track now has a clear progression: categories → committed choice → disjunction lattice → negation → `promise_equivalent_solutions`.
- Koans 21–23 add focused IO-uniqueness diagnostics that fill a gap in the uniqueness track.

## Sequencing

The root-recommended order (Foundations → Type → Mode → Determinism → Parsing → Tooling/Concurrency/Advanced) is sound. The "any order" caveat for the last three is the weakest sequencing advice. Specific corrections noted in the existing BIG-PICKLE-REVIEWS.
