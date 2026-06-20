# Mode System

Mercury's mode system does more than track which variables are bound. It reasons about
instantiation states (insts), uniqueness, and the full spectrum of how values flow through
a predicate. This track makes the mode system explicit rather than just a background
constraint solver.

| Kata | Topic |
|---|---|
| `01-insts-and-modes/` | User-defined insts, `bound(...)` patterns, parametric insts |
| `02-multi-mode/` | Mode-specific clauses, `pragma promise_equivalent_clauses` |
| `03-uniqueness-deep/` | Arrays, `di`/`uo`, uniqueness loss in disjunctions, `version_array` |
| `04-higher-order-insts/` | Dispatch tables, inst annotations on higher-order values |
| `05-mode-specific-clauses/` | `my_append/3` with three modes |
| `06-inst-hierarchy/` | User-defined `bound(...)` insts, parametric insts, inst subtyping |
| `07-clause-selection/` | How Mercury selects clause bodies by calling mode |
| `08-array-threading/` | `array(T)` (unique, di/uo threading) vs `version_array(T)` (persistent, aliasable): histogram exercise |

`09-mode-inference` in the foundations track is prerequisite.
