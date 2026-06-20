> **HISTORICAL — superseded 2026-06-19.**
> This review pre-dates the three-reviewer synthesis in `REVIEWS-SYNTHESIS/SYNTHESIS.md`.
> Its "~7 of ~41 compile" headline is no longer accurate — the curriculum was substantially
> rebuilt and all koans/solutions/bridges/puzzles verified against `mmc` after this was
> written. See `REVIEWS-SYNTHESIS/SYNTHESIS.md` for current status and `ci.sh` for the
> authoritative gate.

---

# Cinnabar — Compiler-Verified Review

*Reviewed 2026-06-16 against Mercury 22.01.8 (`mmc --grade asm_fast.par.gc.debug.stseg --errorcheck-only`)*

## Headline

Roughly 7 of ~41 shipped Mercury programs compile. The curriculum's *design* is strong; its *code* was, with few exceptions, never run through `mmc`.

| Group | Compiles | Total |
|---|---|---|
| Puzzle solutions | 2 | 14 |
| Bridge `start.m` files | 0 | 3 |
| Koan solutions (answer keys) | ~5 | ~24 |

**Programs that pass:** `puzzles/data-structures/01-anagram-finder`, `puzzles/data-structures/04-frequency-histogram`, `koans/type-system/02-typeclass/solution/fixed.m`, `koans/mode-system/04-uniqueness-violation/solution/` (new), `koans/parsing/01-dcg-goals/solution/fixed.m`, `koans/tooling/02-module-name/solution/` (new), `koans/foundations/04-modules/solution/` (compiles once filenames are matched).

---

## Five Systematic Root Causes

All of the following recur across dozens of files, which is the tell that nothing was compiled:

### 1. Missing basic imports

Solutions use list literals, arithmetic, `io.format` directives, and type operators without importing `list`/`int`/`string`/`char`. For example:

- `koans/foundations/01-maybe/solution/fixed.m` — imports `maybe`+`string` but not `int` (`X * 2` → `undefined '*'/2`) or `list` (`[i(N)]` → `undefined '[|]'/2`)
- `koans/determinism/01-det-mismatch/solution/fixed.m` — imports nothing in its implementation section

Hits: most koan solutions and several puzzle solutions.

### 2. Invented stdlib API

Verified against installed `.int` files in the Nix store:

| Used in code | Reality | Files affected |
|---|---|---|
| `maybe.map/2` | Does not exist | `expr_eval.m`, `bridge/01`, `koans/foundations/01`, several others |
| `maybe.bind/2` | Does not exist | Same files; no monadic bind in Mercury stdlib |
| `int.between/3` | Does not exist | `sudoku.m`, `nqueens.m`, `crypto.m`, det koans |
| `string.strip/2` (predicate) | It's a function | `csv_reader.m:40` |
| `list.nth_member/3` | Does not exist | `sudoku.m:42` |

Real functions: `map_maybe/2` (not `.map`); `int.nondet_int_in_range/3` (not `.between`).

### 3. Prolog-isms that are not Mercury

- **`=:=`** (`crypto.m:23`, det koan, determinism README) — Mercury arithmetic equality is `=`; `=:=` doesn't exist.
- **`phrase/2`** — does not exist as a stdlib predicate. DCG rules desugar at compile time; you call them directly: `tokens(Toks, Input, [])`. Taught as canonical in `katas/parsing/01-dcg-basics` and cascades into `02-dcg-mixed`, `puzzles/parsing/01-calculator`, `02-csv-reader`, my `koans/parsing/03-dcg-mode`.
- **`import_module dcg`** — no such module in Mercury 22.01.8. Three `.m` files import it.

### 4. Missing `pair` and `solutions` imports

- `-`/2 used as pair constructor without `import_module pair` — `graph.m`, `config_parser.m`
- `solutions/2` used without `import_module solutions` — `sudoku.m`, `nqueens.m`, `crypto.m`, `graph.m`, `memoized_search.m`, det koans

### 5. Interface/implementation re-declaration

`puzzles/parsing/03-config-parser/solution/config_parser.m` declares `parse_config/1` and `get/3` in both interface and implementation sections → "multiply defined."

---

## My Session's Contributions — Errors to Own

3 of 5 new koans added in the previous session don't compile:

- **`koans/concurrency/02-shared-state/solution/`** and **`katas/concurrency/03-concurrent-io/`**: `import_module semaphore` / `semaphore.new` — the module is `thread.semaphore` (a submodule).
- **`koans/parsing/03-dcg-mode/`**: both the broken file and the solution use `phrase/2` + `import_module dcg`, so the koan fails for the wrong reasons. Lesson (mode annotation) is sound; implementation isn't.
- **`koans/advanced/02-existential-escape/solution/`**: missing `import_module list` (`[s(Label)]` format list).

Clean: `koans/mode-system/04-uniqueness-violation/`, `koans/tooling/02-module-name/`.

---

## Specific File Inventory

### Koan solutions — FAIL (should compile but don't)

| File | Primary error |
|---|---|
| `koans/foundations/01-maybe/solution/fixed.m` | `maybe.map` doesn't exist; missing `int`, `list` |
| `koans/foundations/02-string/solution/fixed.m` | Missing imports |
| `koans/foundations/03-higher-order/solution/fixed.m` | Missing `int` (`*` undefined) |
| `koans/foundations/05-exceptions/solution/fixed.m` | Missing `list` |
| `koans/foundations/06-file-io/solution/fixed.m` | Type ambiguity, missing `list` |
| `koans/foundations/07-built-in-types/solution/fixed.m` | Missing imports |
| `koans/type-system/01-adt/solution/fixed.m` | `f` format spec undefined |
| `koans/type-system/03-abstract/solution/fixed_client.m` | Missing `list`, `int` |
| `koans/type-system/04-parametric/solution/fixed.m` | Type error; `>` undefined |
| `koans/mode-system/01-inst/solution/fixed.m` | `version_array.set` type error |
| `koans/mode-system/02-inference/solution/fixed.m` | `>` undefined; `++` undefined |
| `koans/mode-system/03-higher-order-inst/solution/fixed.m` | Missing `int`, `list` |
| `koans/determinism/01-det-mismatch/solution/fixed.m` | Missing `int`, `list` |
| `koans/determinism/02-nondet-in-det/solution/fixed.m` | `int.between`; `=:=`; `solutions` missing |
| `koans/determinism/03-committed-choice/solution/fixed.m` | `>` undefined; missing `list` |
| `koans/parsing/02-dcg-mixed/solution/fixed.m` | `phrase/2` |
| `koans/parsing/03-dcg-mode/solution/dcg_mode_koan.m` | `import_module dcg`; `phrase/2` |
| `koans/concurrency/02-shared-state/solution/shared_state_koan.m` | `import_module semaphore` wrong |
| `koans/advanced/02-existential-escape/solution/existential_koan.m` | Missing `list` |

### Puzzle solutions — FAIL

| File | Primary error |
|---|---|
| `puzzles/logic/01-sudoku/solution/sudoku.m` | `int.between`; missing `solutions` |
| `puzzles/logic/02-n-queens/solution/nqueens.m` | `int.between`; missing `solutions` |
| `puzzles/logic/03-crypto-arithmetic/solution/crypto.m` | `int.between`; `=:=`; missing `solutions` |
| `puzzles/data-structures/02-expression-evaluator/solution/expr_eval.m` | `maybe.map`; `maybe.bind`; missing imports |
| `puzzles/data-structures/03-graph-reachability/solution/graph.m` | `-`/2 (pair) undefined; missing `solutions` |
| `puzzles/parsing/01-calculator/solution/calculator.m` | `import_module dcg`; `phrase/2` |
| `puzzles/parsing/02-csv-reader/solution/csv_reader.m` | `phrase/2` |
| `puzzles/parsing/03-config-parser/solution/config_parser.m` | Multiply-defined funcs; `-` undefined |
| `puzzles/advanced/01-generic-printer/solution/generic_printer.m` | `yes/1` undefined (missing `maybe`) |
| `puzzles/advanced/02-memoized-search/solution/memoized_search.m` | Missing `solutions` |
| `puzzles/concurrent/01-parallel-sort/solution/parallel_sort.m` | `i` format spec undefined |
| `puzzles/concurrent/02-pipeline/solution/pipeline.m` | Missing `list`, `int` |

### Bridge starts — FAIL

| File | Primary error |
|---|---|
| `bridge/01-maybe-extend/start.m` | `maybe.bind`; `maybe.map` |
| `bridge/02-pipeline-extend/start.m` | Type error; `float.plus` undefined |
| `bridge/03-dcg-extend/start.m` | `phrase/2` |

---

## Koan Pedagogy — Undermined by the Same Bugs

Koans promise "one specific flaw; the compiler is the teacher." But because the broken files often also lack imports, the student sees a wall of incidental errors instead of the intended lesson. And the answer keys frequently don't compile either.

**Example:** `maybe_koan.m` is supposed to teach func-vs-pred. It fails first on missing `int`/`list` and a call to nonexistent `maybe.map`. The student can't see the actual lesson through the noise.

**Worst case:** `koans/parsing/03-dcg-mode` — both the broken file and the solution fail. The intended lesson (mode annotation `in` vs `out`) is sound; neither file demonstrates it.

---

## README / Teaching Content Quality

Prose quality is genuinely good — clear, well-scoped, honest about tutorial overlap, good voice. But the instructional text ships the same errors as the code:

- `katas/parsing/01-dcg-basics/README.md` — teaches `phrase/2` as the DCG call mechanism (wrong)
- `katas/determinism/01-six-categories/README.md` — teaches `between(2, N-1, F)` and `solutions/2` without `import_module solutions`
- `EXPANSION.md` — design doc references `maybe.map`, `maybe.bind`, `between/3`, `phrase/2`

**One overcorrection to revisit:** "No universal Show" sections overstate. `string.string/1` exists and works (RTTI-based). The honest framing — "exists but uses RTTI, not a typeclass constraint" — is more interesting pedagogy.

---

## Curriculum Comprehensiveness — Strongest Dimension

Breadth is well-chosen for post-tutorial fluency: discriminated unions → parametric → abstract → typeclass → existential; full mode/inst system; all six determinism categories; DCGs; tooling; concurrency; FFI/RTTI. Good coverage.

**Genuine gaps** (if aiming for full language coverage):
- `:- mutable` and `store` (global mutable state)
- Field access/record update syntax (`^`, `:=`) as a dedicated exercise
- Typeclass depth: superclasses, functional dependencies, multi-param typeclasses
- `trace` goals for debugging
- Stdlib structures: `bag`, `bimap`, `digraph`; `array` vs `version_array` gets only a cameo

---

## Repetition / Muscle Memory — Weakest Dimension

The README says "do them more than once," and `00-reactivation/active-recall` nods at spaced repetition. But the structure doesn't engineer it:

- Each concept appears ~1–3 times total; recurrence (e.g., `map` in anagrams/histogram/graph/config) is incidental.
- **Katas have no `start.m` skeleton and no test harness.** Unlike bridges (which give `start.m`), there's no artifact that makes repetition friction-free or gives a pass/fail signal. The highest-leverage structural change: add a `start.m` skeleton + a `runtests` script per kata so the loop is "edit → compile → green."

---

## Recommended Fix Order

1. **Make compilation the gate** — CI script that compiles every `.m`; koan solutions + puzzle solutions + bridges must pass; broken koan files must fail for the documented reason.
2. **Fix the five systematic causes** (import lines + four name substitutions): `maybe.map`→`map_maybe`, `int.between`→`nondet_int_in_range`, drop `=:=`/`phrase`/`import_module dcg`, add `pair`/`solutions`.
3. **Rewrite the parsing track's DCG-invocation** to direct calls — highest-impact single content fix.
4. **Fix my four broken contributions** (semaphore module path, dcg-mode koan, existential missing import).
5. **Consider kata `start.m` skeletons** for the muscle-memory gap.
