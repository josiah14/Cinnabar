# README format templates

Canonical section order for each exercise type. Not every section is required
in every exercise — use judgment — but when a section exists, it goes in this order.

---

## Koan

```markdown
# Koan: <broken concept in plain English>

**Broken concept:** one sentence naming the flaw

## Prerequisites

- `katas/track/NN-name` — one-phrase description
- (list the minimal set; omit what is truly obvious)

---

```
mmc --make --grade asm_fast.par.gc.stseg <module_name>
```

Error: "key diagnostic phrase" (exact or paraphrased)

---

## What to observe

One to three paragraphs. Explain WHY the error fires — the invariant Mercury is
enforcing — not just which line is wrong. Name the specific check (determinism,
mode, uniqueness, type). Quote the relevant part of the error message.

---

## Your task

One paragraph or bullet list. Tell the reader exactly what kind of fix to apply
and what to look for in the compiler output after fixing. Do not give the solution.
```

The `.err` file next to the koan contains the exact compiler output, used by ci.sh
to verify the expected diagnostic still fires.

---

## Kata

```markdown
# NN — <topic name>

**After:** `katas/track/NN-name` — prereq description (omit if truly none)

One paragraph: what the kata is about and why it matters.

---

## <Core concept heading>

Reference-style explanation of the Mercury concept: syntax, semantics, the
key invariant to understand. Include a minimal code snippet.

---

## Tasks

**Task 1 — <name>:** description

**Task 2 — <name>:** description

(...)

---

## Expected output   ← include when the kata has a single deterministic output

```
output here
```
```

---

## Bridge

```markdown
# Bridge NN — <title>

**After:** `katas/track/NN-name`, ...

One sentence on what this bridge connects and what the student will extend.

---

## Starting point

Description of what the provided file already does. Refer to key predicates by name.

---

## Tasks

**Task 1:** description

**Task 2:** description

(...)
```

Solution notes live in `solution/README.md`, which explains the key decisions and
any non-obvious Mercury mechanics used in the solution.

---

## Puzzle

```markdown
# Puzzle: <topic>

**Primary skills:** comma-separated list of Mercury concepts

**Why Mercury:** one sentence on what Mercury's model makes easy or interesting here.

## Prerequisites

- `katas/track/NN-name` — description
- (...)

---

## The problem

Concise problem statement. Input type, output type, constraints. Include a
`## Representation` subsection when the data model is non-obvious.

---

## Approach  ← optional, include when there is one canonical approach worth naming

Two to four sentences naming the algorithmic approach and why it fits.

---

## Key predicates to write

Bullet list of `pred_name(arg_types)` — just enough to give structure without
spoiling the solution.

---

## What to observe

One to three bullets. Point to Mercury-specific mechanics worth noticing after
solving (mode, determinism, uniqueness, etc.).

---

## Extensions  ← optional

- Extension idea 1
- Extension idea 2

---

## Design questions  ← optional; include 2–3 for deeper puzzles

1. Question probing a Mercury-specific tradeoff.
2. Question probing algorithmic or representational choice.

---

## Expected output

```
output here
```
```

---

## Notes

- `FIX:` comments are banned in solution files. Use durable invariant comments
  instead: name the constraint being upheld, not the change that was made.
- Keep koan `.err` files current: if source changes shift line numbers, update the
  `.err` file so ci.sh diagnostic verification stays accurate.
- Expected output blocks belong in the **puzzle** README (learner-facing), not
  only in the solution README.
