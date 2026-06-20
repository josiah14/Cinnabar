# Cinnabar README and conceptual-quality review

## Scope and rating

Reviewed the root README; kata indexes and representative Foundations, Determinism,
Mode System, Parsing, and Concurrency katas; koans from Foundations, Determinism,
Mode System, Parsing, Type System, and Tooling; all bridge introductions; and puzzles
from logic, data structures, parsing, concurrency, and advanced. This is a README and
curriculum-design review, not a verification of every exercise implementation.

**Overall README quality: 6/10.** The best exercise READMEs are unusually good: they
give a learner a concrete starting state, precise success criteria, and a Mercury-specific
conceptual payoff. The public-release score is pulled down by a broken/stale prerequisite
graph, a root-level bridge description that contradicts the exercise, and uneven framing
and scope in the bridges. A learner following the advertised route will encounter dead
links and misleading expectations.

## 1. Clarity and self-containment

Most individual exercises are clear enough to begin without external help, provided the
named prerequisite has been completed. The format is especially effective when it gives:

- a representation or starting signature;
- a small ordered set of implementation steps;
- a concrete input/output or compile-time checkpoint; and
- one question that connects the result to Mercury's semantics.

Examples:

- `katas/foundations/02-maybe/README.md` is an excellent guided kata. It supplies a
  compilable module skeleton, defines the desired `config` type, explains why
  `string.to_int/2` must become a `maybe`, and asks the learner to compare an explicit
  conditional with `bind_maybe`. The checkpoint asks an explanatory question rather
  than merely “does it compile.”
- `koans/determinism/01-det-mismatch/README.md:12-14` makes the causal chain explicit:
  “A `det` predicate must succeed exactly once” and a one-armed conditional can fail.
  Its final question (“What should happen when the condition is false?”) directs the
  learner to derive the fix from the signature.
- `puzzles/advanced/07-mercury-in-mercury/README.md:40-162` is exemplary. The task is
  decomposed into rename, dereference, unification, and solve; each has a signature and
  the first three have isolated checkpoints. That prevents an advanced learner from
  debugging a meta-interpreter as one opaque unit.

The main qualification is that “self-contained” currently depends on a working local
navigation graph. Ten sampled README prerequisite references point to paths that do not
exist (details in section 4), so the content may be clear but the stated next step is not
reachable. The root setup section is also Nix-only (`README.md:85-101`); the compiler
command is explained, but learners who installed Mercury another way are not told that
this is supported.

## 2. “Why Mercury” framing

The strongest puzzle framing explains a language property that changes the design, not
just an implementation convenience:

- `puzzles/advanced/04-combinator-library/README.md:6-8`: “Each combinator's
  determinism is a function of its argument combinators' determinisms — and Mercury
  verifies this.” This precisely states the learning outcome.
- `puzzles/concurrent/02-pipeline/README.md:7-13` connects unique `!IO`, channels as
  the communication boundary, and `maybe(T)` as the closure protocol. This is a
  specific Mercury lesson, not generic pipeline rhetoric.
- `bridge/05-mode-reversal/README.md:5-9` correctly motivates one logical relation
  with two checked directions. That is the right reason to make this a Mercury bridge.
- `bridge/11-error-handling/README.md:5-8` directly contrasts `maybe(T)`, `io.res(T)`,
  and exceptions as different *typed error contracts*.

Coverage is inconsistent in bridges: only 04, 05, 06, and 11 have an explicit
`**Why Mercury:**` section. Bridges 01–03 and 07–10 go straight from “After” to the
existing program. For example, bridge 09 says it will generalize an evaluator
(`bridge/09-typeclass-refactor/README.md:16-18`), but never says what Mercury's
typeclass constraints, instance resolution, or interface/module model teach that a
generic evaluator in another language would not. Add a 2–4 sentence, mechanism-specific
framing to every bridge.

Two puzzle framings should also be more exact:

- `puzzles/data-structures/03-graph-reachability/README.md:5-7` calls
  `pragma loop_check` “the correct” and “more elegant” replacement for a visited set.
  It should say what is sacrificed or preserved (termination checking versus explicit
  traversal state, result behaviour, and performance), because the README itself later
  presents the manual set approach as a legitimate alternative.
- The CSV framing (`puzzles/parsing/02-csv-reader/README.md:5-6`) says only that DCGs
  make lookahead natural. Mention the actual payoff learners will practice: threaded
  input state, declarative failure, and a parser's determinism contract.

## 3. Task scope

The usual scope is good. Koans correctly isolate one compiler lesson; bridges offer a
working base; puzzles leave implementation choices while fixing observable behaviour.
`bridge/04-determinism-ratchet/README.md:27-86` is particularly strong: its three tasks
escalate from committed choice, to collecting nondeterminism before parallel execution,
to a semidet higher-order criterion. Each asks a question the preceding code makes
answerable.

Some READMEs cross the line from scaffold to solution:

- `puzzles/concurrent/02-pipeline/README.md:54-84` supplies complete implementations
  of all three required stages immediately after specifying the task. For a puzzle,
  this leaves mostly transcription. Move this behind a collapsible hint or replace it
  with signatures, sentinel invariants, and one partial stage.
- The meta-interpreter's “Suggested build order” is detailed but appropriate because the
  component boundaries are the lesson; retain that level of scaffolding there.

Bridge 10 is not currently a coherent extension specification. In task 1, two workers
share one output channel (`bridge/10-parallel-pipeline/README.md:26-39`), yet the text
says “The writer does not need to change.” With two producers, the protocol must state
how each worker terminates and how the writer waits for *both* completions; one `no`
sentinel causes an unchanged writer to stop early. Task 4 then introduces failure,
restart, exception handling, channel protocol, and at-least-once/lost-work semantics at
once (`:77-91`). Split it into a narrowly specified shutdown/fan-in bridge and a separate
supervision puzzle, with explicit guarantees for the item that crashes.

## 4. Prerequisite chains and navigation

The conceptual ordering in the root is sensible: Foundations → Type System → Mode System
→ Determinism → Parsing (`README.md:21-25`), followed by optional specialisations. Most
individual prerequisites are specific and helpful, for example the combinator puzzle's
higher-order, determinism, and inst prerequisites (`puzzles/advanced/04-combinator-library/README.md:10-14`).

However, the published graph is not release-ready. These README references are stale or
nonexistent in the current tree:

| README | Broken prerequisite | Existing likely target |
|---|---|---|
| `katas/determinism/07-promise-equiv-solutions` | `katas/concurrency/03-basic-spawning` | `katas/concurrency/02-threads` |
| `puzzles/concurrent/03-parallel-pipeline-with-unique-state` | `katas/concurrency/01-spawn` | `katas/concurrency/02-threads` |
| same | `katas/concurrency/03-pipeline` | no matching kata; likely puzzle 02 |
| `koans/foundations/16-goal-expression` | `katas/type-system/01-adt` | `01-discriminated-unions` |
| `koans/type-system/05`, `06`, `07` | `katas/type-system/03-typeclasses` | `04-type-classes` |
| `koans/type-system/08` | `katas/type-system/04-phantom-types` | `09-phantom-types` |
| `koans/tooling/05` | `katas/mode-system/04-uniqueness-violation` | `03-uniqueness-deep` |
| `koans/tooling/06` | `katas/foundations/03-higher-order` | `04-higher-order` |

There is a second, visible contradiction: the root table labels bridge 02 “Channel-based
concurrent pipelines” (`README.md:57-60`), whereas bridge 02 is a sequential sales
pipeline based on `foldl`, `map`, and a higher-order grouping key
(`bridge/02-pipeline-extend/README.md:3-66`). Correct either the root description or the
exercise identity. This is exactly the sort of error that makes a learner distrust the
rest of a curriculum map.

Also update `katas/README.md:9-11`: it presents Foundations as the only track and says
“More tracks will follow,” while the root exposes eight tracks. The root and category
indexes need a single source of truth or a CI link/count check.

## 5. Voice and consistency

The voice is mostly consistent: direct, technical, and respectful of learner agency.
“Build and run it first,” “What to observe,” “Checkpoint,” and “What you are practising”
form a useful, recurring instructional rhythm. The koans are necessarily terse, but the
better ones still explain *why* the compiler error protects a semantic invariant; see
`koans/mode-system/04-uniqueness-violation/README.md:23-25`.

The consistency problem is structural rather than tonal:

- Puzzles consistently have `Primary skills`, `Why Mercury`, and prerequisites; bridges
  vary widely in framing and closing reflection.
- Some tasks use executable checkpoints; others just say “test it” without a test case.
- Names drift between “After,” “Prerequisites,” and unqualified prose. Use one standard
  prerequisite block, with real relative Markdown links.

## 6. Notable outliers

**Better than average**

- `puzzles/advanced/07-mercury-in-mercury/README.md`: best overall design. It makes a
  very hard problem startable, uses real intermediate tests, and ends with questions
  that distinguish a working toy interpreter from understanding Mercury.
- `bridge/05-mode-reversal/README.md`: strong Mercury framing, sensible staged work,
  and excellent design questions (`:103-115`) about direction-specific determinism and
  programmer-validated promises.
- `bridge/11-error-handling/README.md`: makes learners choose among mechanisms rather
  than treating errors as one generic topic.
- `koans/parsing/06-phrase-det/README.md:24-41`: unusually clear about determinism
  propagating through a DCG call chain and the required call-site consequence.

**Worse than average**

- `katas/README.md`: stale and materially incomplete as the main kata index.
- `bridge/10-parallel-pipeline/README.md`: underspecified fan-in termination and an
  over-large supervisor task make the requested implementation ambiguous.
- `puzzles/concurrent/02-pipeline/README.md`: excellent explanation, but its full stage
  implementation removes most of the puzzle.
- The READMEs with stale prerequisites are individually readable but fail their basic
  navigational contract.

## 7. Fix before public release

1. Repair every stale prerequisite immediately, turn all curriculum paths into relative
   links, and add automated validation that every README path resolves. This is the
   release blocker.
2. Reconcile the root bridge table with bridge 02, and replace the stale `katas/README.md`
   index. Generate counts/index rows if possible rather than maintaining duplicate prose.
3. Adopt a README template by exercise format. At minimum: purpose/Why Mercury,
   prerequisites, starting point, task, acceptance criteria, and reflection. Koans can
   remain compact, but should retain concept → observation → task.
4. Add a mechanism-specific “Why Mercury” section to bridges 01–03 and 07–10. Do not use
   generic claims such as “Mercury is declarative”; identify the exact checked property
   the task exposes.
5. Fix bridge 10's worker completion protocol and split supervision into a separately
   scoped exercise. State ordering, failure, restart, and completion guarantees.
6. Reclassify complete implementation blocks in puzzles as optional hints. Preserve
   explicit representations, examples, and acceptance tests; remove the direct path from
   prompt to copyable solution.
7. Audit technically absolute language (“the correct tool,” “more elegant”) and replace it
   with trade-offs learners can test. The curriculum is strongest when it teaches a
   design decision, not a slogan.
