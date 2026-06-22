# Code quality — Laguna M.1

## Overall: 8/10

The compiled puzzle solutions are clean, well-structured Mercury code. The bridge
CI compilation fix removes the only structural rot vector. The multi-module
config puzzle is a genuine step up in code-organisation ambition. Katas remain
intentionally without reference solutions, which is a defensible pedagogical
choice but limits the code-quality assessment surface.

## Puzzle solutions: 8.5/10

**Strengths.** The plugin architecture (`plugins.m`) is the strongest solution
in the repo: clean existential encapsulation, correct `'new plugin'(...)`
construction, proper module qualification to dodge the `apply` collision, and
separate factory functions. The meta-interpreter (`meta_interp.m`) is impressive
for its domain — the rename/deref/unify/solve pipeline is decomposed correctly
even if the module is long. The config parser uses abstract types properly with
an opaque constructor.

**Weaknesses.** The combinator library (`combinators.m`) is 179 lines in one
module with no interface section beyond `main`. It would benefit from a
separate `parser` type and explicit predicate/function distinction. The
calculator's precedence is encoded in nesting order rather than a data-driven
table — teachable but not the cleanest reference. The generic printer does not
explain the `canonicalize` erasure that makes `yes(yes(42))` print as `yes/1`.

## Kata starter code: 7.5/10

The `start.m` convention is consistent across all 8 tracks: module skeleton,
imports, hook comment, self-checking `main` with PASS/FAIL output. The
consistent format is valuable. The self-checking pattern is pedagogically
strong.

The main limitation remains the absence of reference solutions. The design
rationale (katas are muscle-memory drills, derivation is the work) is stated
in the root README and the TODO CLOSED the reference-solutions item in favour
of a separate `cinnabar-work` project. This is consistent but means learners
who get stuck have no fallback. The two exceptions (`concurrency/09-stm`,
`tooling/06-property-testing`) prove the format works well as a reference.

## Bridge solution notes: 7.5/10

The CI compilation fix (`ci.sh §6`) has improved the quality floor
significantly — snippets that previously rotted are now syntax-checked. The
quality ceiling remains variable:

- **Bridge 05** (mode reversal): excellent notes with clear multi-mode
  explanation and the valuable insight about `string.to_int` lenience breaking
  `promise_equivalent_clauses`.
- **Bridge 10** (parallel pipeline): comprehensive restart-loop design with
  supervisor architecture and sentinel counting. The most technically detailed
  bridge solution.
- **Bridge 01** (maybe extend): one paragraph, minimal code snippets. The
  simplest bridge but the notes are thin.
- **Bridge 12** (currying and impurity): well-structured with the
  stored-closure wall explained and the pure-alternative recommendation.

## Hygiene and naming

Imports are clean across all solutions. Predicate names are clear and
descriptive. Determinism annotations are present on every predicate. The one
hygiene slip that persists is the `combinators.m:empty(_, _, _) :- fail.`
pattern, which uses a Prolog-era `fail` goal when the `is failure` determinism
annotation would be more explicit. This is a teaching resource — the annotation
is the teaching moment.
