# Start here

Three paths into Cinnabar, depending on where you're coming from.

---

## Path A: "I just finished the Mercury tutorial"

You can read Mercury. You know about `in`/`out` modes, determinism categories,
DCGs, and maybe some higher-order. You want to *think* in Mercury.

1. Work through the tracks in order. Each track starts easy and builds.
   ```
   Foundations → Type system → Mode system → Determinism → Parsing
   ```
   Then: `Tooling → Concurrency → Advanced`.

2. Within each track, do the katas first, then the koans. Katas drill one
   muscle at a time. Koans teach you to read compiler errors as diagnostics
   rather than noise.

3. Add bridges when you want a change of pace. Bridges give you working code
   and ask you to extend it — less blank-page friction than a puzzle.
   - After Foundations: bridges `01`, `02`, `03`, `11`
   - After Mode system + Determinism: bridges `04`, `05`, `06`
   - After Parsing + Advanced: bridges `07`, `08`, `09`, `10`, `12`

4. Tackle puzzles when a track has you curious about what Mercury can really do.
   They draw on multiple tracks and force synthesis.

5. When Mercury gives you a cryptic error, check `COMPILER-LESSONS.md` before
   digging through documentation. It records the actual mistakes and compiler
   messages encountered while building this curriculum.

**Start at:** `katas/foundations/00-reactivation/01-hello-world`

---

## Path B: "I know Prolog"

You understand unification, backtracking, and the logic programming model.
Mercury will feel familiar but stricter — the mode and type systems are the
main adjustment.

1. Skip Foundations, or skim it fast. The Prolog-to-Mercury shift is about
   adding structure, not learning new programming concepts.

2. Start with the **Mode system** and **Determinism** tracks. These are the
   biggest delta from Prolog. In Prolog, any predicate can fail, succeed,
   or succeed many times at runtime. In Mercury, you declare which up front,
   and the compiler checks you.

3. Then do **Type system** — Mercury's discriminated unions and typeclasses
   work differently from Prolog's unstructured terms.

4. Add **Parsing** (DCGs are familiar territory, but Mercury's mode-checked
   DCGs reveal new discipline), then **Tooling**, **Concurrency**, **Advanced**.

**Start at:** `katas/mode-system/01-insts-and-modes`

---

## Path C: "I know Haskell / ML / Rust but not logic programming"

You're comfortable with strong static typing, algebraic data types, and
pattern matching. The new territory is the logic programming engine —
unification, backtracking, multiple solution modes, and the relational
model.

1. Start with Foundations to learn the logic programming basics: unification,
   generate-and-test, state threading with `!`, and the relational style.

2. The **Mode system** and **Determinism** tracks will feel like natural
   extensions of what you already value — Mercury makes you declare and
   verify properties that Haskell and Rust enforce at the type level, but
   goes further by tracking instantiation state and solution count.

3. **Prolog-knowledgeable friends will be useful here.** The mental model
   shift is real: instead of "compute a result," you describe a relation
   and let the engine find solutions. The puzzles (especially Sudoku and
   N-queens) are designed to make this click.

4. Otherwise follow the main track order.

**Start at:** `katas/foundations/00-reactivation/01-hello-world`

---

## General notes

- **Bridges** are the most underrated format in the curriculum. When a
  concept is not clicking, do the relevant bridge — working code you extend
  teaches faster than blank-page exercises.
- **`COMPILER-LESSONS.md`** is not decorative. Bookmark it.
- **Run `nix develop`** from the project root to get a shell with the
  Mercury toolchain. Then `mmc --make <module>` to compile any exercise.
- The full curriculum assumes Mercury 22.01.8.
