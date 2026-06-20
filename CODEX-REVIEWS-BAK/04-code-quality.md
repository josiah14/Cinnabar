# Cinnabar reference-solution code quality review

## Scope and rating

Reviewed all 20 Mercury modules under `puzzles/*/solution/`. This assesses the code as
reference material a learner will imitate; it does not dispute the supplied verification
that the programs compile and produce their intended demonstration output.

**Overall teaching-code quality: 7/10.** The modules consistently use explicit modes,
state threading, compact pure helpers, and useful section comments. The strongest files
make Mercury's determinism and higher-order calling conventions visible. The score is
held back by a few examples that silently turn invalid input into a successful partial
parse, non-minimal `cc_multi` at the entry point, inefficient collection of all answers
when only one is needed, and a couple of deliberately limited algorithms that need
louder boundaries before learners copy them.

## Findings by module

| Module | Idiom / structure / teaching value | Naming, determinism, imports, comments |
|---|---|---|
| `advanced/01-generic_printer` | Strong, small RTTI example. `pretty/4` plus `pretty_arg/4` makes `foldl`'s IO threading explicit without clutter. | Good names and sectioning; comments are proportionate. |
| `advanced/02-memoized_search` | Clear recursive path enumerator and sensible separation of `path/5` from `shortest_path/5`. | Replace the `999999 - []` fold seed at lines 43–46: it is an unexplained sentinel and fails for a valid path costing at least 999999. Seed from the first path after pattern matching `AllPaths`, or use `maybe(pair(...))`. `maybe` is imported but not used. |
| `advanced/03-bidir` | Good `semidet` property predicates and helpful numeric-precision comment at lines 38–44. The bounded recursive scan makes the desired forward semantics evident. | `first_k_with/3` and `take_n/3` are cleanly named. The hardcoded `1..50` appears both in comments and code; make bounds an argument or a named constant if this is meant as reusable reference code. |
| `advanced/04-combinators` | Good separation of predicate types from higher-order insts, and `seq_det`/`seq_semidet` is a useful way to make determinism visible. | `many/4` (lines 86–95) has no progress invariant: any semidet parser that succeeds without consuming input loops. Add a comment and a check/precondition that `Mid` differs from `Input`, or limit the public teaching claim to consuming parsers. `choice_det/5` accepts and ignores `Q`; this is pedagogically odd API surface—omit it or label it as a determinism demonstration rather than a useful choice combinator. |
| `advanced/05-gen_parser` | The two newtype stream instances and minimal typeclass constraint are excellent teaching code. | `many_p/4` repeats the exact non-progress hazard of `many/4` (lines 63–71). It should share the invariant and, ideally, a common tested implementation. |
| `advanced/06-plugins` | Compact use of closure-valued record fields. The pipeline trace makes closure application easy to follow. | `run_pipeline/3` combines pure transformation with IO reporting. For teaching composition, expose `apply_pipeline(list(plugin), string) = string` and make tracing a separate presenter. Also qualify the “same open-world property as existential types” comment at lines 12–15: the record's method set is closed, unlike a constrained existential interface. |
| `advanced/07-meta_interp` | Best structured large example: clear phase separators, accurate determinism declarations, and helpful comments around unification and SLD resolution. | The terse constructors `a`, `n`, `f`, `v`, and `c` are compact but poor names for code learners will extend; `atom`, `integer`, `compound`, `variable`, and `clause` would be clearer. The code candidly admits its depth-based renaming is not globally fresh (lines 97–99); put a warning at `resolve/5` and do not present it as a reusable interpreter core. |
| `concurrent/01-parallel_sort` | Good use of `&` only between independent `det` computations, explicit threshold, and a sequential baseline. | `split_at/4` is a good total helper. The final “unreachable” fallback in `merge_sorted/3` (line 89) quietly returns a value rather than preserving an invariant; the preceding branches already characterize the states. Prefer a structure where the impossible branch is absent, or document why total fallback is required. |
| `concurrent/02-pipeline` | Strong baseline channel pipeline. `reader`, `transformer`, and `writer` have clear roles; `promise_equivalent_solutions [!:IO]` visibly contains spawned `cc_multi` calls. | Good stage names and comments. `list` and likely `string` appear unnecessary imports. More importantly, retain the `det` `main/2` pattern here as the canonical one. |
| `concurrent/03-stats_pipeline` | The accumulator state parameters and a single reporting stage are clear. The comments at lines 32–38 help explain why no mutable shared accumulator is needed. | `main/2 is cc_multi` is less minimal than the prior pipeline's `det` main with explicit containment. As teaching code, use the same `promise_equivalent_solutions [!:IO]` pattern or explain why this module deliberately exposes `cc_multi` at the entry point. `list` and likely `string` are unnecessary imports. Also avoid calling ordinary immutable argument threading “unique state”: it resembles linear evolution but is not enforced uniqueness. |
| `data-structures/01-anagrams` | Good functional map accumulation; `canonical/1`, `group_anagrams/2`, and `insert_word/3` are well factored. | Document that `[Word | Existing]` reverses group order and that `map.values/2` determines group order. `char` appears unused. |
| `data-structures/02-expr_eval` | Very good compact ADT interpreter. `bind_maybe` and `map_maybe` are used where they clarify failure propagation; `eval_and_print/3` keeps presentation out of `eval/2`. | Names and determinisms are strong. This is a reference-quality example. |
| `data-structures/03-graph` | Showing both explicit visited-state and `loop_check` versions is valuable. `reachable_manual/4` demonstrates state threading cleanly. | The two approaches are sufficiently separated and comments identify the grade condition. Consider renaming `reachable_node/3` to `reachable_node_tabled/3` or `..._loop_checked` so callers cannot miss the pragma-dependent behaviour. |
| `data-structures/04-histogram` | Strong applied standard-library example: fold into a map, sort for presentation, then render. `print_bar/5` carries its inputs clearly. | The local comparator and `foldl` function are idiomatic. A tie-breaking rule in the count sort would make output order deterministic and teach comparator completeness. |
| `logic/01-sudoku` | The nondet search plus semidet constraint checks correctly exposes generate-and-prune. Helper decomposition is clear. | `main` calls `solutions(solve(Puzzle), [Solution | _])` (lines 144–149), which collects **all** solutions only to print the first. Use committed choice directly for a first solution. Several helpers (`set_cell/5`, `set_nth/4`, `get_row/3`, `get_nth/3`) silently return `[]` or `0` on invalid indexes; their `det` signatures are honest only under undocumented representation invariants. For teaching code, use bounded index types/validation or clearly isolate the unsafe internal helpers. |
| `logic/02-nqueens` | Good compact nondet generator with incremental semidet pruning. `safe/3`'s distance parameter is a readable invariant. | Names are clear; comments explain the reverse construction. This is a good reference solution. |
| `logic/03-crypto` | Correctly direct generate-and-test code, suitable as a baseline against a future CLP implementation. | Eight scalar output parameters and repeated inequality chains are difficult to read and modify. A `letters` record/tuple plus `all_different` helper would make the problem mapping and constraint invariant more visible. Keep the direct version only if the README labels it as deliberately naive. |
| `parsing/01-calculator` | The DCG/accumulator structure models precedence and associativity well; explicit `semidet` parse layers are clear. | The lexer is incorrectly permissive as a teaching parser: `tokenize/2` is `det`, and `token_list/3` stops when `one_token/3` fails (lines 18–38). Thus invalid trailing input such as `"1 @ 2"` is silently discarded and can yield `yes(1)`. Return a lexical `maybe/result`, or require that tokenization consumes the complete character list. |
| `parsing/02-csv_reader` | The small DCG is well named and the unquoted-whitespace comment is exactly the right kind of design note. | `parse_csv/3` is `det` and treats a failed `row/1` as end-of-file (lines 20–31); `parse/1` then ignores the remaining characters (lines 89–92). Unterminated quotes and malformed input can become a successful truncated CSV. Either make parsing semidet with full consumption or return a structured result. `char` appears unused. |
| `parsing/03-config_parser` | Good public abstract type and clear line-level classifiers. `get/3` makes absence explicit with `maybe`. | `parse_lines/4` silently ignores every malformed nonblank line (lines 50–51). That can be a conscious forgiving-config policy, but the code needs a comment and tests; otherwise it models error loss. `string.string(get(...))` in `main` is convenient diagnostic output, but a dedicated formatter would better model use of the opaque API. |

## Cross-cutting assessment

### Idiom and determinism

Most declarations are appropriately tight. The `semidet` parser predicates and constraint
checks are correctly identified; `nondet` is used for genuine solution generation; IO is
threaded consistently with `!IO`; and higher-order insts are explicit where that is the
lesson. The two exceptions worth changing are:

- `stats_pipeline.m:4`: `main/2 is cc_multi` is non-minimal relative to the reference
  pattern already shown in `pipeline.m:62-75`.
- The parsing modules obtain `det` by choosing a successful fallback rather than by
  representing invalid input. That is technically a valid determinism declaration for
  the implemented functions, but it is the wrong habit for parsers whose names imply
  validation.

### Imports

Imports are generally grouped correctly in the implementation section. Perform an
unused-import pass before release. Obvious candidates are `maybe` in `memoized_search`,
`list`/`string` in the two concurrent pipeline modules, `char` in `anagrams` and
`csv_reader`, and `string` in `crypto`. Removing noise matters in a curriculum where
learners infer module dependencies from examples.

### Comments and naming

Section dividers and comments are consistently useful. The best comments state a
non-obvious invariant or language constraint, such as the float rounding guard in
`bidir.m:38`, the explicit stream-typeclass constraint in `gen_parser.m:53-55`, and the
CSV whitespace-policy note in `csv_reader.m:60-63`.

Avoid “FIX:” comments in finished reference solutions where they merely narrate a past
failed attempt (for example `calculator.m:18,28,40`). Rewrite them as durable reasons:
“This is an if-then-else to make the maximal-munch lexer deterministic.” Reference code
should explain the invariant, not the edit history.

## Release priorities

1. Fix the calculator and CSV full-consumption/error contracts. These are the most
   damaging examples to imitate because they call malformed input success.
2. Replace Sudoku's all-solutions collection when only the first solution is needed;
   remove the magic shortest-path seed; and make internal index assumptions explicit.
3. Document/enforce the progress precondition for both `many` combinators.
4. Make concurrent entry-point determinism consistent and remove unused imports.
5. Add a lightweight source-quality check for unused imports and a test suite containing
   malformed parser inputs, multiple Sudoku solutions, and high-cost paths.
