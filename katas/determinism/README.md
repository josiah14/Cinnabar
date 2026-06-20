# Determinism

Mercury's determinism system is the other half of the mode system. It classifies every
predicate by how many solutions it can have and whether it can fail. The six categories
form a lattice; the compiler checks that callers respect the constraints imposed by callees.

The track moves from naming the six categories through committed choice (`cc_multi`/`cc_nondet`), which is essential for parallel conjunction and spawning IO threads, and ends at `promise_equivalent_solutions` — the bridge between nondeterminism and the `det` world. After this track, determinism annotations will read as design decisions rather than compiler appeasements.

| Kata | Topic |
|---|---|
| `01-six-categories/` | One predicate per determinism class: det, semidet, multi, nondet, erroneous, failure |
| `02-committed-choice/` | `cc_multi`/`cc_nondet`, `promise_equivalent_solutions`, `main/2` as `cc_multi` |
| `03-scope-annotations/` | `require_complete_switch`, `require_det`, catching missing cases at compile time |
| `04-multi-nondet/` | `multi` and `nondet` predicates, multiple-solution contexts |
| `05-determinism-in-disjunctions/` | The determinism lattice; how Mercury combines determinisms across disjunction branches |
| `06-determinism-and-negation/` | `\+` is always `semidet`; variable-binding rules for negation |
| `07-promise-equiv-solutions/` | `promise_equivalent_solutions [Var]` (commit to one cc_nondet result) and `[!:IO]` (spawn in det predicate) |

**Tutorial cross-reference:** Mercury Tutorial §3 covers `det`/`semidet`/`nondet`. This
track names and exercises all six categories and covers the committed-choice subset, which
the tutorial does not address.
