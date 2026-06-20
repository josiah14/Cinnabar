# Cinnabar final overall assessment

## Overall rating: 7/10

Cinnabar is an unusually ambitious and thoughtful post-tutorial Mercury curriculum. It
does not stop at syntax, algorithms, or a shallow “make the compiler happy” loop. Its
best material teaches the defining parts of Mercury—modes, determinism, insts,
higher-order contracts, DCGs, purity, and concurrency—as design tools. A learner who
works through the intended path and reflects on the supplied questions should emerge
meaningfully more fluent, not merely with a pile of completed exercises.

It is not yet release-ready as a community reference. Navigation/index drift obscures the
path; several solution explanations and reference patterns need correction; and the
published CI workflow is disabled. These are fixable editorial/engineering issues, but
they matter acutely in a small-language community where learners will rely on this
repository as practical authority.

## 1. Learning path

The intended arc is coherent and stronger than a collection of unrelated challenges:

1. **Katas** establish local habits: a mode, determinism category, collection idiom, or
   DCG property at a time.
2. **Koans** turn compiler messages into explanations of a single violated contract.
3. **Bridges** remove blank-page friction by asking learners to alter a working program.
4. **Puzzles** combine the pieces into design decisions: search/pruning, parsing, type
   abstraction, pipelines, and interpretation.

That progression has real pedagogical force. For example, a learner encounters
`maybe` as a focused kata, then repairs a `map_maybe` function/predicate mismatch in a
koan, extends a config reader in bridge 01, and uses `maybe` in evaluators and parsers.
The same recurrence exists for determinism, DCGs, higher-order code, and channels. This
is how fluency forms.

The caveat is discoverability. The per-track indexes omit many later exercises: the type
index stops at 05 despite ten katas; parsing stops at 03 despite nine; bridges list only
01–03 and 11; and the puzzle index omits much of Advanced. The coherent path exists in
the tree but is not reliably visible to a learner following local READMEs. Fix the map
before judging whether learners will experience the intended arc.

## 2. Educational philosophy

The curriculum has a coherent philosophy:

- the compiler is a source of feedback, not merely a gatekeeper;
- repeated constrained practice builds usable instincts;
- types, modes, and determinism should shape program design early;
- working code is an aid for stepping into larger problems, not an answer to memorize;
- learners should explain a choice, not only produce a green build.

The root's “You bring raw material; the heat does the work” metaphor matches the best
designs. `katas/determinism/01-six-categories`, the mode/inst sequence, determinism
ratchet bridge, parser hardening bridge, and meta-interpreter checkpoints all make the
learner supply the reasoning.

Application is uneven. A puzzle README that includes complete implementations of all
pipeline stages turns heat into transcription. A bridge that asks for a supervisor but
supplies only “would restart here” is a design sketch, not a completed learning loop.
The philosophy should yield a consistent standard: specify an invariant and acceptance
criterion, leave the design work to the learner, then use the solution to explain the
trade-offs.

## 3. Difficulty curve

The main curve is appropriate:

- Foundations gives practical Mercury mechanics and standard-library vocabulary.
- Type, mode, and determinism tracks deepen the compile-time model before demanding
  larger designs.
- Parsing makes modes/determinism operational through grammar and state threading.
- Tooling, concurrency, and advanced topics add production-facing concerns.
- Advanced puzzles culminate naturally in generic parsing, plugins, search, and a
  Mercury-in-Mercury interpreter.

There are three avoidable spikes:

1. `00-reactivation/06-pure-randomness` introduces mutable state, impurity, FFI, and
   initialization before the main Foundations sequence. It is suitable as optional
   experienced-programmer recall, not as ordinary early-track progression.
2. Bridge 10 jumps from a three-stage pipeline to fan-out/fan-in termination, bounded
   buffers, backpressure, exception transport, supervision, restart, and lost-work
   semantics. It should be two exercises.
3. Solver types introduce a compelling advanced feature but stop at the language hook
   because no CLP engine is available. Mark it explicitly as a reading/architecture
   branch, or add a small working finite-domain constraint-store project.

## 4. Format coherence

The four formats are distinct in principle and usually in practice:

| Format | Best use in Cinnabar | Boundary to protect |
|---|---|---|
| Katas | Deliberate repetition of a local, named mechanism. | Do not turn them into reading-only references. |
| Koans | One compiler-detectable flaw and one targeted repair. | Ensure one primary diagnostic; incidental type/import errors defeat the format. |
| Bridges | Extend a running program while making a few connected choices. | Keep the extension bounded and its protocol specified. |
| Puzzles | Design a solution from multiple concepts with meaningful choices. | Do not include the complete required implementation in the prompt. |

The main format changes to make:

- The current concurrent pipeline puzzle belongs closer to a bridge unless its full stage
  code is moved behind optional hints.
- Bridge 10's supervisor/restart section is a puzzle-sized systems exercise; split it
  from bounded backpressure/fan-in.
- The solver-types kata is partly a reference/reading exercise. Either add a working
  implementation task or label that format honestly.

## 5. Structural issues and missing connective tissue

The tracks are not conceptually misplaced—Mode System, Determinism, Parsing, and
Concurrency are particularly well organized—but their connective tissue needs work:

- The root says Tooling, Concurrency, and Advanced can be done “in any order.” Recommend
  subpaths instead: Tooling before grade-sensitive tabling/concurrency work; FFI before
  the solver-types FFI task; and prerequisite links for each advanced puzzle.
- Foundations is large but justified; it provides the idioms later tracks repeatedly
  depend on. Advanced is broad rather than bloated, but solver types are much thinner in
  working practice than FFI and RTTI.
- Determinism and parsing receive substantial repeated practice. This is appropriate for
  Mercury, but their repeated `promise_equivalent_*` lessons need an explicit sequence so
  they read as reinforcement, not duplication.
- Track indexes, prerequisite links, and the root bridge table are stale. The root calls
  bridge 02 “Channel-based concurrent pipelines,” while bridge 02 is a sequential
  higher-order grouping exercise. This damages the learner's mental map at exactly the
  point the curriculum needs to provide orientation.

## 6. Comparison with exercise repositories in other languages

Compared with a typical Exercism track, Cinnabar is stronger in **concept sequencing and
language specificity**. Exercism commonly gives isolated practice problems and tests;
Cinnabar repeatedly asks why a relation is `semidet`, why a state value is unique, or why
a DCG rule changes a caller's determinism. It teaches a programming model, not just
syntax and algorithms.

Compared with language-koans projects, Cinnabar is stronger in **scale and transfer**.
Koans are followed by bridges and puzzles where the lesson must be used in a design. The
mode/determinism/compiler-error focus is particularly suited to Mercury.

It is weaker than mature versions of both formats in **operational consistency**:

- index/navigation material is incomplete;
- some answer keys teach inaccurate or overly broad claims;
- a few reference solutions accept malformed input silently;
- the visible CI workflow is not running.

Mature community curricula earn trust through a predictable artifact contract: every
exercise is findable, every broken example fails for the promised reason, every solution
builds and behaves as documented, and the public CI badge means it.

## 7. Release readiness

If released tomorrow, Mercury users would likely respond positively to the ambition and
the rare depth of mode, determinism, concurrency, FFI, and tooling material. Experienced
users would also find the curriculum's compiler lessons and explicit trade-off questions
valuable.

They would quickly flag trust problems:

- The GitHub workflow has `if: false` in `.github/workflows/ci.yml:13`, so `ci.sh` is not
  actually enforced publicly. The local script is a good start: it compiles expected-good
  artifacts and expects koans to fail. It should also assert the intended error category
  for koans and execute relevant behavioural tests.
- `REVIEW.md` still claims that only roughly 7 of 41 programs compile, directly
  contradicting the current verified-build claim. Archive, delete, or prominently mark
  it historical with a link to the current CI result.
- Broken prerequisites/indexes and technical mistakes in solution notes make it unsafe to
  treat the repository as an authoritative Mercury learning resource yet.

### Highest-priority fixes before release

1. **Make verification public and authoritative.** Enable GitHub CI, run the gate from a
   clean checkout, add expected-diagnostic checks for koans and behavioural/protocol tests
   for reference solutions, and retire/update stale `REVIEW.md` claims.
2. **Repair the learner map.** Regenerate or comprehensively maintain all indexes,
   prerequisite links, counts, and root descriptions; add a link/path validation check.
3. **Correct reference teaching artifacts.** Fix `solutions/2` documentation, existential
   construction and committed-choice explanations, bridge 10's fan-in protocol, bridge
   11's error propagation, and the calculator/CSV full-input contracts. These are small
   changes with disproportionate credibility impact.

## 8. Genuine strengths to preserve

Several qualities are genuinely impressive and should not be diluted during cleanup:

- **Mercury specificity.** The curriculum treats modes, insts, uniqueness, determinism,
  committed choice, grades, and `!IO` as first-class topics. That is the difficult,
  valuable material post-tutorial learners actually need.
- **The mode/determinism sequence.** The progression from basic categories through
  higher-order insts, multi-mode relations, committed choice, and parallel execution is
  unusually rich and pedagogically coherent.
- **Bridges as a middle format.** A working program with scoped extensions is exactly the
  right antidote to the jump from toy exercises to blank-page puzzles. Keep this format;
  tighten its task boundaries.
- **Compiler literacy.** `COMPILER-LESSONS.md`, error-oriented koans, grade/tooling
  material, and explicit compiler reasoning prepare learners to work independently in a
  language whose diagnostics and build grades are part of daily practice.
- **Ambitious endpoints.** The parser-combinator library, generic parser, typeclass
  refactor, concurrent pipelines, and meta-interpreter give learners something more
  consequential than an endless sequence of collection exercises.

The project is close to being a standout Mercury resource. Preserve its depth and its
respect for the learner's reasoning; fix the verification, navigation, and technical
contract details that currently prevent that depth from being fully trustworthy.
