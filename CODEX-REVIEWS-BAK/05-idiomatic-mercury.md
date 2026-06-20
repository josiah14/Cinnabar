# Idiomatic Mercury review of puzzle reference implementations

## Verdict

**Idiomatic Mercury quality: 7/10.** The reference code usually reads like Mercury:
relations have explicit modes and determinisms, effects are threaded through `!IO`,
maps and folds are used functionally, DCG notation is used for grammars, and concurrency
uses channels rather than shared mutation. The most important departure is a recurring
pattern of manufacturing `det` by accepting/truncating invalid input. That is valid
Mercury syntax but not the idiom a learner should generalize.

## Where the code is strongly idiomatic

### Relations state their direction and cardinality

The best modules distinguish deterministic transformation, semidet validation, and nondet
generation instead of treating everything as a function:

- `puzzles/data-structures/02-expression-evaluator/solution/expr_eval.m:29-46` uses a
  pure function for total evaluation-to-`maybe`, reserving `maybe` for missing variables
  and division by zero. `bind_maybe`/`map_maybe` expresses dependent failure propagation
  directly; this is good functional Mercury.
- `puzzles/logic/02-n-queens/solution/nqueens.m:12-31` correctly models search as
  `queens/2 is nondet` and conflict checking as `safe/3 is semidet`. The accumulator
  and `Dist` parameter document the geometric invariant without disguising search as a
  list-building function.
- `puzzles/data-structures/03-graph-reachability/solution/graph.m:26-47` offers both a
  `det` visited-set traversal and a `nondet` relational traversal under `loop_check`.
  That contrast is specifically Mercury-like and worthwhile.
- `puzzles/advanced/05-generic-parser/solution/gen_parser.m:57-71` correctly puts the
  `token_stream(S, T)` constraint on `satisfy/4`, which invokes the method, but not on
  `many_p/4`, which only invokes its higher-order argument. This is precise constraint
  placement rather than blanket typeclass decoration.

### Effects and higher-order code are generally expressed well

- `anagrams.m:18-32` and `histogram.m:13-24` use `list.foldl` with a map accumulator;
  `!Map`/`!.Map`/`!:Map` makes the update flow readable without pretending the map is
  mutable.
- `pipeline.m:62-75` is a good idiomatic concurrency baseline: `main/2` remains `det`,
  and `promise_equivalent_solutions [!:IO]` explicitly contains the `cc_multi` effect
  from `thread.spawn`. The channel element type communicates the end-of-stream protocol.
- `parallel_sort.m:50-68` uses `&` only for independent, `det` recursive calls and then
  rejoins with a sequential merge. This is the intended fork-join shape for parallel
  conjunction.
- `calculator.m:85-131` uses DCG notation for grammar structure and accumulator
  nonterminals for left-associative operators. That is clearer and more idiomatic than
  manually passing token lists through ordinary predicates.

## Patterns that are non-idiomatic or teach the wrong default

### Do not use `det` as a reason to swallow invalid input

`det` means the operation yields exactly one result; it does not mean malformed input
should silently become a plausible result.

- In `calculator.m:18-38`, `tokenize/2` is `det` because `token_list/3` returns `[]`
  whenever `one_token/3` fails. Since its remaining input is discarded at line 22,
  lexical junk can be accepted as a valid prefix. A more idiomatic interface is
  `tokenize(string) = parse_result(list(token))` (or a semidet predicate with full
  consumption). Then `calculate/1` can distinguish lexing and parsing failure.
- `csv_reader.m:20-31` treats inability to parse a row as ordinary end-of-file, and
  `parse/1` ignores the remainder at lines 89–92. A seasoned Mercury parser either
  exposes semidet parsing through `phrase/2`/an empty remainder check, or returns a
  `parse_result(T)` with an error position. A total parser that returns a partial value
  must be explicitly named and documented as recovery-oriented.
- `config_parser.m:34-52` likewise ignores malformed nonblank lines. Forgiving config
  syntax can be reasonable, but it should be an explicit policy such as
  `parse_config_lenient`, with a strict `parse_config` or collected diagnostics.

This is the single highest-value idiomatic change: teach learners to make the failure
contract visible in the type/determinism, rather than hiding it in a fallback branch.

### Preserve invariants in representation and API

- `sudoku.m:11` aliases `grid` to `list(list(int))`, and its indexing/update helpers
  return `[]` or `0` out of bounds (`:67-90`, `:121-131`). The code is adequate for a
  closed 9×9 example but is not a model for reusable Mercury. Prefer an opaque grid
  module or validate dimensions at construction; if helpers rely on internal preconditions,
  name/comment them as such instead of giving them apparently total public shapes.
- `memoized_search.m:43-46` uses `999999 - []` as a minimum fold seed. This is an
  imperative-style sentinel rather than an algebraic representation of “no candidate
  yet.” Pattern-match the first solution as the initial accumulator, or fold to a
  `maybe(pair(int, list(node)))`.
- `meta_interp.m:97-115` knows its depth suffix is not globally fresh but still makes it
  the core resolution identity. The comment is honest; idiomatic teaching code should
  either thread a fresh-name supply or visibly fence this as a deliberately incomplete
  miniature. The terse `a`, `n`, `f`, `v`, and `c` constructors compound that risk by
  optimizing for compactness over maintainability.

### Higher-order repetition needs a progress contract

Both `combinators.m:86-95` and `gen_parser.m:63-71` define `many` over a semidet parser
without requiring consumption. A parser may succeed with `Mid = Input`, so recursion
does not terminate. This is a standard parser-combinator invariant, and a strong Mercury
example should make it visible:

- document that the supplied parser must consume input on success;
- test an empty parser and explain why it is invalid for `many`; or
- compare `Mid` and `Input` (where an appropriate equality/representation constraint is
  available) and fail/report a non-consuming parser.

The higher-order inst declaration tells Mercury about success cardinality, not semantic
progress; learners need to see that distinction.

## Determinism and state-threading refinements

- `stats_pipeline.m:4` declares `main/2 is cc_multi`, whereas the preceding pipeline
  demonstrates the more contained idiom: retain a `det` entry point and bracket spawned
  computations with `promise_equivalent_solutions [!:IO]`. `cc_multi` is legal here, but
  it is not the strongest declaration and weakens the lesson about containing effects.
- `stats_pipeline.m:35-38` calls count/sum/max “unique state.” These are ordinary
  immutable values passed to a tail call. This is a useful analogy to linear evolution,
  but it is not Mercury uniqueness (`di`/`uo`) and should not be described as if the mode
  system enforces it.
- `sudoku.m:144-149` collects every solution with `solutions/2` and uses only the first.
  For “find one solution,” an if-then-else around `solve/2` is the idiomatic committed
  choice. Use `solutions/2` only when the list of answers is the required value, as in
  `nqueens.m:45-54` where the count is displayed.

## Naming and structure

The general style is good: `reachable_manual`, `first_empty`, `valid_so_far`,
`count_words`, and `print_histogram` say what each predicate does; `*_0`/`*_1` accumulator
names are conventional and readable. Section dividers make multi-concept examples easy
to navigate.

The main improvement is to avoid names and comments that record a previous compiler
fight rather than a stable design reason. Finished source contains comments such as
“FIX: multiple clauses → if-then-else” in `calculator.m:18,28,40` and `pipeline.m:16-17`.
Rewrite them as the invariant being maintained:

- “Maximal-munch lexing is expressed as a deterministic conditional chain.”
- “The callback must have the `cc_multi` higher-order inst required by `thread.spawn`.”

Similarly, prefer domain adapters such as `rename_with_suffix` over mechanical names
like `rename_2`, and `apply_environment_to_term` over `apply_env_f` in the
meta-interpreter. Small helper names matter disproportionately in code intended for
study.

## Recommended standard for future reference solutions

1. Use `det` for a total operation only when every input has a meaningful result; use
   `semidet`, `maybe`, or a dedicated result type for validation/parsing failures.
2. Let modes and determinism describe the real relation; do not weaken `main/2` merely
   to accommodate a call that can be explicitly contained.
3. Prefer `maybe`, tagged result types, and first-element folds to magic sentinels.
4. Put semantic preconditions—parser progress, collection ordering, index validity, and
   channel shutdown ownership—in code comments next to the predicate that relies on them.
5. Keep the existing strengths: direct `list.foldl`/`map` state threading, DCG grammar
   structure, explicit higher-order insts, and clear `nondet` generators with semidet
   pruning.
