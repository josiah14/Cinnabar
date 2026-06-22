# Coverage breadth + depth — Laguna M.1

## Breadth: 8.5/10, Depth: 8/10

The curriculum has closed its most significant gaps since the Big Pickle and
Quorum reviews. The multi-module capstone (`puzzles/advanced/08-multi-module-config`)
now exists and provides a genuine multi-module design exercise with opaque types,
interface boundaries, `use_module` vs `import_module` choices, and a clean DAG
build. Bridge 12 (currying and impurity) fills the currying/purity gap. The
puzzle acceptance-criteria tables are in place. What remains is thin in specific
corners rather than absent.

## Closed gaps

1. **Multi-module architecture** — CLOSED. Puzzle 08 (config library with `cfg`,
   `parser`, `validator`, `printer`, `config_demo`) requires the learner to
   design module boundaries, manage qualification, and build a multi-module
   DAG. The module interface files (`cfg.m`, `parser.m`, etc.) are structured
   correctly with opaque types in `cfg` and accessor-based rendering in
   `printer` that cannot see the representation. This was the curriculum's most
   significant gap and it is now adequately addressed.

2. **Currying and purity** — CLOSED. Bridge 12 exercises partial application,
   currying for `list.filter`, chaining with the `ground`-closure wall, and
   impure mutable design with `semipure`/`impure`/`promise_pure`. The solution
   notes correctly explain the stored-closure restriction and why `apply(F, X)`
   fails on a `ground`-inst closure. This fills what was previously a genuine
   gap between the reactivation kata on purity and the mode-system katas.

3. **Bridge solution rot** — MITIGATED. `ci.sh §6` now extracts and compiles
   fenced Mercury code blocks from bridge solution READMEs. All 12 bridges pass
   syntax checking. The extraction heuristic (skip blocks <3 lines or without
   `:- pred/func/type/import_module`) is conservative and will miss some
   snippets, but the primary rot vector is addressed.

## Remaining thin areas

1. **Mutable state beyond `mutable`.** `store`/`store_mutvar`/`io.mutvar` are
   not covered. The only mutable-state exercise is `00-reactivation/06-pure-randomness`,
   which is flagged "advanced recall; defer." A dedicated kata on threaded
   mutable state with `io.mutvar` and/or `store_mutvar` would round out the
   concurrency track and address a pattern that appears in real Mercury code.

2. **Library depth.** `bag`, `bimap`, `version_array` are covered in
   foundations 11. Missing: `queue`, `cord`, `digraph`, `bitmap`, `stream`,
   term I/O, `rbtree`. The earlier reviewer suggestion of a "choose the right
   container" bridge is still a good idea. The collection kata (foundations 11)
   is well-structured but is a survey rather than a fluency-builder.

3. **STM depth.** The concurrency track has an STM kata and a koan, but there is
   no puzzle or bridge that requires designing a nontrivial STM transaction
   (e.g., concurrent transfer with rollback, multi-TVar invariant checking).
   The existing materials cover the mechanics correctly but do not push the
   learner to design STM-based protocols.

4. **Typeclass design at scale.** The typeclass katas cover instances,
   constraints, FDs, superclasses, and existential types. But no exercise
   requires designing a typeclass hierarchy from scratch or balancing method
   count against instance burden. The plugin puzzle uses existential
   quantification but the typeclass itself is two methods with no laws. A
   bridge that asks the learner to extract a numeric typeclass with law-like
   method constraints (building on bridge 09's typeclass refactor) would be a
   natural extension.

## Sequencing

The root-recommended order is sound and the puzzle-specific prerequisites are
accurate. The only sequencing weakness is the root's "any order" claim, which
overstates the independence of the tooling/concurrency/advanced tracks.
