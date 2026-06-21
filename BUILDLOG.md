# Cinnabar Build Log

A chronological record of substantive changes to the Cinnabar Mercury
curriculum — what changed, why, and the reasoning behind design decisions.

**Format:** appended chronologically (oldest at top, newest at bottom).
Each entry includes a timestamp.

**On provenance and method.** The *creation* of this framework — the koans,
katas, bridges, and puzzles themselves — is mostly vibe-coded: LLM output
generated from a curriculum plan. That is the building of the initial learning
framework, and it is not the part that demonstrates engagement. The
human-in-the-loop work is the *review*: Josiah working the exercises as a
learner and reviewer, and the changes that hands-on use drives. The entries
below chronicle that review — the moments where actually working a koan, kata,
bridge, or puzzle surfaced a gap, a wrong fix, or an exercise that had outgrown
its format. Read content creation as the draft; read these entries as the
evidence it was genuinely exercised, not left to run unattended.

---

## Session 1 — 2026-06-21 00:42 UTC

### Kata 01 redesigned: L(X)THW progression

**What changed.** `katas/foundations/00-reactivation/01-hello-world/start.m`
is now deliberately broken — it reuses the same `IO0` variable across three
`io.write_string` calls. The README walks through four steps:

1. **Compile the broken version** → get a `unique-mode error: variable `IO0`
   is still live`. The error itself is the teaching moment.
2. **Understand `di`/`uo`** from the error's vocabulary: `clobber` (what `di`
   does), `still live` (what the compiler checks), `unique-mode error` (the
   enforcement mechanism).
3. **Thread correctly** with explicit distinct variables — pure functional
   threading, no sugar.
4. **Introduce `!IO`** as syntactic sugar, with a caveat that it only works
   for linear chains; branching patterns need the desugared form.

**Why the further redesign.** The previous two-task design (explicit → sugar)
was already better than the original reading-only kata, but it didn't use the
compiler as the teacher. The L(X)THW approach is stronger:
- The learner encounters the *concrete error* before the *abstract concept*.
  The compiler says "clobber," and `di` is defined as "the annotation that
  means clobber." The term has an anchor in compiler output.
- Breaking the sugar-first habit. Many learners reach for `!IO` by default
  and then hit branching patterns where it doesn't work. The kata now
  explicitly flags this limit and directs learners back to the desugared
  form when needed.
- `unique-mode error` is a recurring Mercury error class. Meeting it first
  in a trivial three-line program means later encounters (in complex state
  threading) reference a known experience rather than a novel diagnostic.

### Other Big Pickle items (this session)

- **`.gitignore` .err negation rules.** Added `!**/*_koan.err` and
  `!**/solution/*.err` so `ci.sh` can find koan diagnostic snapshots on
  fresh clones. Pending user approval before merging.
- **Bridge CI compilation.** Added a `ci.sh` step that extracts ` ```mercury `
  fenced code blocks from bridge solution READMEs, writes them to temporary
  files, and compiles with `mmc` using `-M` module-name heuristics. All 11
  bridges verified clean.
- **Puzzle acceptance criteria.** Added or enhanced acceptance tables in all
  17 puzzle READMEs — 8 with no criteria at all (full tables), 4 with
  partial inline descriptions (formalized), 5 already adequate (left
  as-is). Covers normal cases, edge cases, and failure contracts.

---

## Session 2 — 2026-06-21 (later)

### Kata 01: stretch tasks on `!IO` limits

**What changed.** Added Tasks 4 and 5 (stretch) to the README, plus two new
skeleton files `lambda_head.m` and `func_result.m` — both deliberately broken
so the learner hits a compiler error first.

**Task 4 — Lambda heads.** `!IO` in a lambda head is rejected because there
is no syntax to annotate the modes of the two implied parameters. The
exercise ships a `lambda_head.m` with `pred(!IO) :- ...` in a lambda;
compiling yields:

```
Error: the clause head part of a lambda expression should have one of the
following forms: `pred(<args>) is <determinism>' ...
```

The fix requires explicit `(pred(IO0::di, IO::uo) is det :- ...)` with
manual IO threading inside the body.

**Task 5 — Function results.** `!IO` as a function result is rejected because
`!IO` expands to two variables but a function returns exactly one value. The
exercise ships a `func_result.m` with `hello(!IO) = !IO`; compiling yields:

```
Error: !IO cannot be a function result.
  You probably meant !:IO.
```

The fix uses explicit arguments: `hello(!.IO, !:IO) = !:IO`.

Also replaced the incorrect branching caveat in `cinnabar-worked` README (it
claimed `!IO` doesn't work with branching patterns) with the correct
limitation list (lambda heads + function results only).

**Design rationale.** These two limits are the complete set of places where
`!IO` is syntactically forbidden. Neither is a unique-mode limitation —
both are grammatical restrictions: `!X` cannot appear in a lambda head (no
mode-annotation syntax) nor as a function result (two values in a one-value
slot). Putting them as stretch tasks after the core three-step progression
means the learner sees the sugar first, then learns where the sugar doesn't
apply — and more importantly, *why* the desugared form is the real thing.

---

## Session 3 — 2026-06-21 08:14 UTC

### Hello-world cluster split into one kata + three koans

**The trigger (human-in-the-loop).** Josiah was working the original
`01-hello-world` kata — the break-it-first / stretch-tasks design from Sessions
1–2 — and, with that design in the working tree, realized it had outgrown the
kata *format*. A kata starter that deliberately fails to compile fights the
kata CI contract: `ci.sh` requires every `katas/*/start.m` to **compile**
(it is a muscle-memory drill), and in fact the broken `start.m` was turning the
authoritative gate red. "Compile a broken file and read the diagnostic" is the
**koan** contract — `compile_fail` plus a `.err` snapshot that CI verifies. The
exercise had become a koan in everything but filename (Josiah had even hand-made
a `start.err` snapshot, which is koan machinery). The realization was his, from
actually exercising the material rather than reading it — exactly the gap the
reactivation track is built to surface.

**What changed (Josiah's restructure).**

- **Promoted the IO-uniqueness exercise to a koan:**
  `koans/foundations/21-io-uniqueness/`. The deliberately-broken program
  (one `IO0` reused across three calls) is now `io_uniqueness_koan.m` with an
  mmc-generated `.err` snapshot; CI confirms it still fails with the documented
  `unique-mode error: ... variable 'IO0' is still live`. The clobber /
  still-live / unique-mode glossary moved with it.
- **Promoted the lambda-head demo to its own koan:**
  `koans/foundations/22-io-lambda-head/`. `!IO` as a parameter in a lambda head
  (`pred(!IO) :- ...`) is rejected — a lambda head must be
  `pred(<args>) is <determinism>`, and there is no syntax to give `!IO`'s two
  implied parameters their `di`/`uo` modes. Now `lambda_head_koan.m` with an
  mmc-generated `.err` snapshot and a compile-checked `solution/fixed.m`.
- **Promoted the function-result demo to its own koan:**
  `koans/foundations/23-io-func-result/`. `!IO` as a function result is rejected
  — `!IO` expands to two variables, a function returns one. Now
  `func_result_koan.m` with an mmc-generated `.err` snapshot and a
  compile-checked `solution/fixed.m`. This is the koan whose fix the log had
  recorded incorrectly — see the correctness note below.
- These two had been sitting in the kata as deliberately-broken `lambda_head.m`
  and `func_result.m` files that CI never compiled, so they could rot silently.
  As koans, each is now verified to fail with its exact diagnostic.
- **Rewrote `01-hello-world` as a minimal producing drill:** "make `start.m`
  print these four lines," with the two idiomatic threadings (explicit /
  `!IO`) presented in prose. The starter compiles (CI-green) and prints the
  first line; completing it is the drill.

**A judgment call worth recording.** When the kata was rebuilt, it initially
shipped `solution/explicit.m` and `solution/sugar.m`. Josiah asked whether the
solutions could be removed "without expecting too much from the student" —
catching that shipped kata solutions contradict the repo's own stated principle
("Kata solutions are also not here — by design"). They were removed: the
scaffold already demonstrates the pattern, the expected output is given, and the
adjacent koan's `solution/fixed.m` is a reference one directory away. The kata
is now consistent with every sibling.

**`runtests` made to validate.** A review pass (forwarded by Josiah) flagged
`runtests`. It existed, but 01's was the bare *compile + run* form while every
sibling reports `All tests PASSED.` / exits non-zero — and the reactivation
README promises `runtests` "tells you whether your implementation is correct."
01's now diffs actual output against the expected four lines and reports
PASS/FAIL. (Siblings grep the program's own `FAIL:` lines because they
implement a *function*; a print-exact-output kata uses output-matching instead.)

**Correctness fix — and why CI caught it.** Session 2 of this very log recorded
the func-result fix as `hello(!.IO, !:IO) = !:IO`. That is **wrong**: it passes
two arguments to a function declared `hello(io::di) = (io::uo)` (one argument),
and `mmc` rejects it. The error went unnoticed while it lived only in prose.
Promoting it to a gate-enforced koan forced a real compile, which exposed it.
Koan 23's verified fix names the IO states explicitly —
`hello(IO0) = IO :- io.write_string(..., IO0, IO)`, called as
`!:IO = hello(!.IO)` — with the idiomatic predicate form given in the solution
notes.

**Why this matters.** The kata/koan boundary is not stylistic; it is a
CI-enforced contract (katas compile, koans fail-with-a-verified-diagnostic).
Deliberate-error pedagogy belongs in koans, where the failure is checked and
cannot silently drift. The hello-world cluster now spans one producing kata and
three diagnostic koans, each sitting in the CI lane that actually verifies it.
Foundations koan count: 20 → 23.
