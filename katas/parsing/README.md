# Parsing

Mercury has first-class DCG (Definite Clause Grammar) support and a `parsing_utils`
library for combinator-style parsing. This track builds from DCG basics to real-world
string parsing.

| Kata | Topic |
|---|---|
| `01-dcg-basics/` | DCG syntax, `-->`, alternatives, list-of-token input |
| `02-dcg-goals/` | `{Goal}` semantic actions, why `()` is wrong |
| `03-parsing-utils/` | `parsing_utils.whitespace`, `next_char`, `literal`, config file parser |
| `04-dcg-determinism/` | Why multi-clause DCG rules infer `multi`/`nondet`; if-then-else to force `semidet` |
| `05-left-recursion/` | Why left-recursive DCG rules loop; accumulator-based refactoring |
| `06-error-recovery/` | Structured parse errors as values; `parse_result(T)` ADT |
| `07-stateful-dcg/` | Threading extra state through DCG rules; the `!State` pattern |
| `08-packrat/` | Memoizing DCG rules with `pragma memo` to prevent re-parsing |
| `09-dcg-desugar/` | What `-->` compiles to; implementing a DCG desugarer |

**Not in the Mercury tutorial.**
