# Cinnabar correctness review: pedagogical and technical alignment

## Scope and rating

Reviewed a cross-section of bridge, puzzle, and koan READMEs alongside their solution
READMEs and, where needed, the broken/starter source. The supplied premise that source
files compile under Mercury 22.01.8 does not establish that every *explanation* or every
proposed extension has the semantics it claims.

**Correctness: 6/10.** The curriculum's normal standard is high: many exercises tightly
connect a compiler error to its semantic cause, and several solution notes explain a
design trade-off rather than merely display code. However, there are a handful of precise
technical errors and contradictions. Two of them concern determinism/solutions—the
curriculum's central subject—and bridge 10's documented solution does not satisfy its
own stream-completion contract. Correct these before public release.

## 1. Pedagogical alignment

### Exercises that force the stated concept

- `koans/determinism/05-promise-equivalent-solutions` is well aligned. The broken program
  can only become `det` by accounting for the empty-list failure case; the explanation
  correctly distinguishes eliminating multiple solutions from eliminating failure
  (`solution/README.md:32-40`). A learner cannot fix the declared determinism honestly
  without engaging with `cc_multi` versus `cc_nondet`.
- `koans/advanced/04-univ-det` cleanly forces a determinism decision. The source calls a
  semidet dynamic cast from a `det` wrapper, and the solution has the learner either
  expose or handle possible type mismatch. Its compiler diagnostic and the reason for
  `univ_to_type/2` failure are accurately connected (`solution/README.md:3-35`).
- `koans/concurrency/07-stm-context` has a single pedagogically useful mismatch: IO state
  is passed where STM state is required. The solution's `atomic_transaction` closure
  makes the missing context concrete (`solution/README.md:5-29`), rather than merely
  changing an annotation.
- `bridge/04-determinism-ratchet` is a strong bridge. Its first task requires committed
  choice, its second requires containing a nondet generator in `solutions/2` before `&`,
  and its third exercises a semidet higher-order criterion. The solution explains the
  conjunction-level commitment (`solution/README.md:54-68`) rather than treating `->`
  as a magic syntax fix.

### Exercises that permit or encourage a sidestep

- `koans/mode-system/03-higher-order-inst` claims to teach storing a predicate with a
  callable higher-order inst. Its stated task is to make stored predicates callable,
  and the README says the solution uses “a wrapper type with the inst information encoded
  in the wrapper” (`README.md:38-41`). The actual solution instead converts the API from
  `pred(int, int)` to `func(int) = int` (`solution/README.md:1-28`). That is a valid
  design alternative, but it sidesteps the named predicate-inst lesson. Provide both:
  the required fix should use an inst-bearing wrapper/appropriate mode declaration; the
  function conversion can be an explicit alternative when the operation is inherently
  total and single-result.
- `puzzles/advanced/04-combinator-library` accepts any semidet parser in `many`, but the
  solution asserts that `many` “always terminates with a list” (`solution/README.md:42-61`).
  That is not forced by `parser_semidet`: a parser can succeed without consuming input,
  causing non-termination. State and test the progress invariant (“P must consume input
  on success”), or represent progress in the combinator contract. Without it, the exercise
  teaches an unsafe combinator as universally valid.
- The concurrent pipeline puzzle gives complete stage bodies in its problem README
  (`puzzles/concurrent/02-pipeline/README.md:54-84`). The later solution explanation is
  good, but the task can be completed by copying it. Keep signatures, dataflow, and
  termination invariants in the main text; put complete stages in an optional hint.

## 2. Technical accuracy

### Errors requiring correction

1. **`solutions/2` does not sort or deduplicate.**

   `koans/determinism/02-nondet-in-det/solution/README.md:3-14` says `solutions/2`
   “collects all its solutions into a sorted `list`” and “sorts them (removing
   duplicates).” This is incorrect. `solutions/2` is polymorphic and does not require
   its result type to be orderable, so it cannot perform a general sort/deduplication.
   It collects the solutions produced by the goal; callers that need set semantics must
   explicitly sort/deduplicate or use a `set`. This misconception matters for both
   program results and complexity reasoning.

2. **The bridge 05 explanation of `(out, out) is nondet` is wrong.**

   `bridge/05-mode-reversal/solution/README.md:31-45` says that an infinite relation has
   “no finite way to enumerate … in Mercury” and that a nondet mode is “not the same
   logical object” as semidet/det modes. Infinite nondeterministic generation is normal;
   each finite prefix can be generated. More importantly, determinism is a property of a
   *calling mode*, not the logical relation. A third mode can have a different
   determinism while computing the same relation, provided an implementation and the
   `promise_equivalent_clauses` promise are actually valid. The real issue is that an
   unbounded generator needs a deliberate enumeration order and that the exercise must
   prove relation equivalence—not that the promise is categorically inapplicable.

3. **The bidirectional-search explanation needs its committed-choice distinction made
   precise.**

   `puzzles/advanced/03-bidirectional-search/solution/README.md:30-44` calls a nondet
   generator in an if-then-else condition an error “inferred nondet” and recommends a
   recursive scan. The recursive scan is appropriate because `first_with/2` is required
   to be `semidet`: a first-solution conditional over a nondet generator introduces a
   committed-choice (`cc_*`) effect that cannot simply be declared semidet. But the text
   is too broad and conflicts in wording with
   `bridge/04-determinism-ratchet/solution/README.md:5-21`, where the same kind of
   condition is valid inside a `det` result-producing wrapper. Explain the context rule:
   conditional commitment is useful and legal in an appropriate `det`/committed-choice
   context; it is not a route to a plain `semidet` procedure. Do not describe it as
   ordinary `nondet` propagation.

4. **The existential-type lessons contradict one another.**

   `puzzles/advanced/06-plugin-architecture/solution/README.md:3-27` says Mercury 22.01
   cannot construct existential values from regular clause positions and replaces the
   design with closures. `koans/advanced/02-existential-escape/README.md:14-32` teaches
   exactly the construction syntax for that situation: `'new tagged'(Label, Value)`.
   The puzzle should use/assess `'new plugin'` for the constrained existential case, or
   identify the *specific additional restriction* that makes it fail. The current broad
   claim is false or, at minimum, irreconcilably incomplete.

5. **Bridge 10's fan-in solution loses work.**

   Its documented dispatch sends `no` to both workers
   (`bridge/10-parallel-pipeline/solution/README.md:13-26`); each unchanged transformer
   then sends a `no` to the shared output. The existing writer exits at the first `no`.
   Therefore the statement “The total is still correct” (`:29-35`) is not guaranteed:
   it can stop while the other worker still has values. The solution needs a completion
   protocol: for example a writer that counts two worker sentinels, or an explicit
   merger that emits exactly one terminal sentinel after both workers finish.

6. **Bridge 11 silently converts read failures into successful empty files.**

   The task says IO errors should be propagated. Yet `read_lines` maps
   `LineResult = error(_)` to `Lines = []`
   (`bridge/11-error-handling/solution/README.md:111-125`), after which `load_users`
   returns `ok(Users)` (`:96-109`). The solution neither preserves the `io.error` nor
   distinguishes a read failure from EOF. Make `read_lines` return `io.res(list(string))`
   and propagate the `error(Err)` case.

### Accurate explanations worth retaining

- The `promise_equivalent_solutions` table in koan 05 correctly says that a
  `cc_multi` inner goal can become `det`, but a `cc_nondet` inner goal remains
  `semidet` (`koans/determinism/05-promise-equivalent-solutions/README.md:24-42`).
- The STM solution accurately separates IO and transaction contexts and explains why the
  initial type error cascades (`koans/concurrency/07-stm-context/README.md:24-45`).
- The graph-reachability solution usefully presents manual state and loop checking as
  trade-offs instead of claiming a universal winner
  (`puzzles/data-structures/03-graph-reachability/solution/README.md:3-30`).
- The meta-interpreter solution accurately notes that freshening by recursion depth can
  collide across sibling branches and explains the need for globally fresh names
  (`puzzles/advanced/07-mercury-in-mercury/solution/README.md:86-97`).

## 3. Koan quality

Most sampled koans have one focused defect, a readable compiler error, and a repair that
teaches the intended boundary. The best use the compiler's exact inferred/declared
determinism difference, rather than just saying “it does not compile.” The univ, STM,
typeclass-superclass, and promise-equivalent-solution koans are good models.

There is one concrete violation of the “one flaw” rule:

- In `koans/determinism/02-nondet-in-det/nondet_koan.m`, `find_factor/2` produces an
  `int` (`:10-13`), but `all_factors/2` passes its `list(int)` output variable directly
  as the second argument (`:16-19`). This creates a type error in addition to the
  intended determinism error. A learner may see the type mismatch first and never reach
  the lesson about containing nondeterminism. Replace the call with a correctly typed
  intermediate, or make the broken code use a scalar `Factor::out` and then change only
  the determinism context.

Also repair the mismatch between the higher-order-inst koan README and its supplied
function-based solution (section 1). It is not a compiler flaw, but it violates the
koan's promised lesson.

## 4. Solution quality

The best solution notes explain alternatives and semantic reasons:

- Bridge 01 distinguishes validation-at-parsing from validation-at-use and explains when
  the missing/invalid distinction matters (`bridge/01-maybe-extend/solution/README.md:20-32`).
- Bridge 04 explains why `solutions/2` turns the worker computations into `det` values
  eligible for `&`, and warns that result ordering changes (`solution/README.md:23-52`).
- Bridge 11's decision table (`solution/README.md:161-176`) is a useful mechanism-choice
  framework, once the read-error implementation is fixed.

The weaker solution notes either prescribe an implementation without enforcing its
invariants (the parser `many` progress rule) or label an incomplete sketch as a solution.
Bridge 10 task 4 says the supervisor restarts a crashed transformer, but the solution
only prints “would restart here” (`bridge/10-parallel-pipeline/solution/README.md:109-151`).
Either provide the loop/restart and item-loss semantics, or label it a design sketch and
reduce the task's acceptance claim.

## Release actions

1. Correct the six technical/documentation errors above, especially `solutions/2`,
   committed-choice, existential construction, and fan-in termination.
2. Add a review test for every koan: compile the broken program and assert that the first
   diagnostic is the intended category, then compile its fixed version.
3. Add protocol tests for concurrent exercises: exactly-once output, worker completion,
   and error propagation. “Compiles” is insufficient for channel topology changes.
4. Make solution notes state preconditions explicitly—e.g., parser progress, nonempty
   inputs, ordering guarantees, and IO-error behavior—where correctness depends on them.
