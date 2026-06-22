# Coverage breadth + depth — DeepSeek V4 Flash Free

## Breadth: 8/10 — Depth: 7/10

The curriculum covers nearly every Mercury feature through 4 exercise formats. The mode track and determinism track are genuinely deeper than any other public Mercury resource. The multi-module capstone (puzzle 08, recently added) closes the biggest architectural gap. But I find the depth score slightly lower than Big Pickle's 7.5 — several tracks plateau before reaching genuine fluency.

## What the curriculum does best

The mode track (8 katas + 8 koans + bridges 05/06) is the crown jewel. It progresses through user insts → `promise_equivalent_clauses` → uniqueness → higher-order insts → clause selection → inst hierarchy lattice. The inst-hierarchy kata (mode-system/06) covers material that has no analogue in any Mercury tutorial or textbook.

The determinism track (7 katas + 8 koans + bridge 04) is similarly strong. The recent expansion (katas 04 multi/nondet, 05 disjunction lattice, 06 negation) turns what was a six-category tour into a working model of how Mercury reasons about control flow.

The koan format — one file, one diagnostic, one fix — is the most innovative pedagogical device in the repo. With 76 koans across all tracks, it is the most systematic compiler-diagnostic curriculum I have seen for any language.

## Notable gaps

1. **IO design patterns are under-covered.** The foundations track has 23 koans but only 3 deal with IO (21–23, just added). There is no kata dedicated to `io.file`, `io.dir`, `io.environment`, or `io.make_temp`. The bridges cover `io.res` (bridge 11) and concurrency IO (bridge 10), but a learner who finishes the curriculum will know how to thread IO state and how `!IO` desugars without knowing how to read a file's lines into a list (that specific pattern is only in bridge 11's solution notes, not in any kata or koan).

2. **`store` and `store_mutvar` are absent.** Mutable state design has exactly one exercise (`06-pure-randomness` in reactivation). The `store` and `store_mutvar` modules (Mercury's thread-safe shared-state mechanism) have no dedicated exercise. This is a gap because `store` is the idiomatic Mercury alternative to global mutable state when `io.mutvar` is not available.

3. **Library coverage is collection-heavy, IO-light.** `bag`, `bimap`, `set`, `map`, `assoc_list`, `array`, `version_array` are all covered. But `queue`, `cord`, `digraph`, `bitmap`, `stream`, `term`, `term_to_xml`, `parser`, `getopt` are not. A "choose the right container" bridge or kata would be more valuable than one kata per collection type.

4. **Property-based testing is taught but not applied.** `katas/tooling/06-property-testing` and `koans/tooling/08-property-generator` teach `prop` module mechanics, but no puzzle or bridge uses property-based tests in its solution. An exercise that requires writing property tests (e.g., "verify that your config parser round-trips") would close the gap between "can invoke `prop.quickcheck`" and "would use property testing in a real project."

5. **Module system coverage still has conceptual gaps despite the new capstone.** The capstone (puzzle 08) is excellent — it teaches `use_module` vs `import_module`, opaque types, and DAG dependencies. But it does not cover: sub-modules (`:- include_module`), `:- interface` visibility beyond `public`/`private` (e.g., `:- type config ---> ...` with `:- pragma type_spec`), or the difference between `.int`/`.int2`/`.int3` interface files. The TODO mentions `.mh` is auto-generated, which is correct, but the `.int` file hierarchy is unaddressed.

## Depth assessment by track

| Track | Depth | Ceiling |
|-------|-------|---------|
| Foundations | 7/10 | Practical Mercury but no IO design patterns |
| Type system | 8/10 | Good; existential types + GADT approximations are well-handled |
| Mode system | 9/10 | Best-in-class; inst hierarchy is unique material |
| Determinism | 8.5/10 | Strong; the new disjunction/negation katas fill previous gaps |
| Parsing | 7.5/10 | DCG coverage is thorough; error recovery is thin (bridge 07 only) |
| Tooling | 6/10 | Grades and debugging covered; property testing not applied |
| Concurrency | 7/10 | Both `&` and `thread.spawn` covered; STM kata is correct but minimal |
| Advanced | 7/10 | FFI/RTTI/tabling are done well; solver types are conceptual-only (honest) |

## Big Pickle disagreement

Big Pickle scores coverage depth at 7.5. I score it 7.0. The difference is in two areas: (1) the reactivation katas are counted as "foundations depth" but are review exercises, not new material — they reactivate concepts from earlier katas rather than adding depth; (2) the concurrency track covers both models but neither model has an exercise where the learner must debug a real deadlock or race condition. The koans use mode/determinism errors, not concurrency bugs. A deadlock koan would add real depth.
