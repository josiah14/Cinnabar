# Idiomatic Mercury — Laguna M.1

## Overall: 8/10

The curriculum consistently uses Mercury's distinctive features — mode
annotations, determinism declarations, higher-order insts, purity markers,
DCG threading, unique IO — and teaches them rather than avoiding them. The mode
and determinism tracks are the best Mercury teaching material I have seen in any
public resource. The ceiling is a residual bias toward predicate forms where
functions would be more natural, and a few Prolog-era patterns that survive in
otherwise strong solutions.

## What the curriculum gets right

**Determinism annotations are mandatory and correct.** Every predicate in every
puzzle solution has an explicit determinism annotation. The katas drill all six
categories and the boundary cases. The determinism katas 04 (multi/nondet), 05
(disjunction lattice), and 06 (negation) turn what was a shallow tour into a
working model of how Mercury reasons about control flow.

**Mode annotations beyond `in`/`out` are used consistently.** The combinator
library uses inst aliases for higher-order DCG predicates. The generic printer
uses unique IO threading through `deconstruct` with correct `di`/`uo` modes.
Memoized search uses an explicit lambda mode annotation
`(pred(Cost - P :: out) is nondet)`. The clause-selection kata (mode-system 07)
teaches that Mercury resolves modes at compile time — a non-obvious point.

**The purity system is correctly used.** Parallel conjunction wrappers use
`promise_pure`. `thread.spawn` closures are annotated `cc_multi`. The solver
types kata correctly explains the `any` inst / trailing grade / purity
interaction. Bridge 12 correctly demonstrates `impure`/`semipure` accessors and
`promise_pure` as a discharged obligation.

**DCG threading is handled properly.** The parsing katas use `-->` and
explicitly desugar it in kata 09. The combinator library correctly switches to
explicit DCG threading for higher-order arguments where `-->` cannot reach.
The calculator puzzle's DCG grammar is a clean example of precedence via
grammar structure.

## Residual issues

1. **`fail` for `failure` in combinators.m at line 28.**
   `empty(_, _, _) :- fail.` should use `:- mode empty(out, in, out) is failure.`
   with an empty clause body. The `fail` goal works but describes mechanism
   rather than intent. In a teaching resource, the `is failure` annotation is
   the more instructive choice because it names the determinism category.

2. **Function/predicate balance leans toward predicates.** Several katas ask
   learners to write predicates where functions would be more natural. The
   memoized search uses predicates for all core logic despite functional syntax
   suiting the fold-min pattern. The concurrency katas are the worst offenders —
   all exercises use predicates even when function composition would be cleaner.
   This is not a correctness bug but it means learners get less practice with
   Mercury's function syntax, which has subtle differences in determinism
   inference and error messages.

3. **Lambda syntax is inconsistent across puzzles.** Both
   `(pred(...) is det :- ...)` and `(pred(...::in) is det :- ...)` appear.
   The memoized search uses `(pred(Cost - P :: out) is nondet :- ...)` with
   `::` mode annotations in the lambda head. The config parser uses
   `(pred({Sec, Key}::in, !.IO::di, !:IO::uo) is det :- ...)`. Both are valid
   but a project convention would improve readability and teaching consistency.

4. **`promise_equivalent_clauses` teaches the right lesson about relation
   equivalence** but the bridge 05 notes are the only place where the
   learner is told to verify equivalence rather than trust the pragma. The
   mode-system katas 02 (multi-mode) and the mode-reversal bridge (05) cover
   the mechanics, but no exercise forces the learner to *prove* equivalence —
   the koan format could easily encode a "these clauses are NOT equivalent" trap
   with a compile-but-wrong-result pattern.

5. **Multi-module design is now in the curriculum** (puzzle 08) but no puzzle
   solution uses more than one module. The config library puzzle provides a
   multi-module *problem*, but the solution format (done by the learner) does
   not produce a canonical multi-module reference. A puzzle whose *solution*
   spans multiple `.m` files would close this gap.
