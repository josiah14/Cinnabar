# README quality — DeepSeek V4 Flash Free

## Overall: 7/10

The root README is well-written with a strong voice. Navigation tables are accurate now (index drift was fixed). The recent additions (puzzle acceptance criteria tables, bridge 05/11/12 READMEs) raise the bar. But the project's 4-format ambition creates structural inconsistency that templates alone can't fix.

## Strengths

- **Root README** — the ore/heat metaphor is well-chosen; the "What's not here" section is honest. The prerequisite chains and recommended order are accurate for most learners.
- **Bridge 05 (mode reversal)** — best "Why Mercury" section in the repo. The contrast between `string.to_int` leniency and `int_to_string` canonicity is a teaching insight that only someone who has actually written multi-mode code would flag. Bridge 11's decision table ("maybe vs io.res vs exceptions") is similarly strong.
- **Koans 21–23 READMEs** — clear broken-concept statements, good cross-references ("this is one of exactly two places `!IO` is rejected"). The "Going further" section in koan 21 that points forward to 22 and 23 is a nice touch.
- **Multi-module config (puzzle 08)** — the module architecture diagram, the clear `use_module` vs `import_module` explanation, and the design questions (especially Q3 about recompilation vs source changes) are all excellent.

## Weaknesses

1. **Kata READMEs lack a "Why Mercury" section.** This is the same criticism Big Pickle levels at bridges, but katas are worse: they describe the concept and the task but rarely explain why Mercury's treatment of the concept differs from other languages. Determinism katas are the biggest miss — every one should start with "In most languages determinism is a runtime property; in Mercury it is a compile-time contract." Only about 3 of ~70 katas have this framing.

2. **Reactivation sub-katas have minimal READMEs.** `00-reactivation/01-hello-world/README.md` is good (explicit threading vs `!IO` sugar, cross-ref to koan 21). But the other 6 reactivation katas at the path `00-reactivation/02-maybe/` through `07-*` have two-sentence stubs in the parent README with no individual READMEs. A learner landing on `00-reactivation/05-maps-sets/` gets a `start.m` and no explanation of what's being reactivated or why maps vs sets matters.

3. **Bridge 12 snippet CI failure acknowledged but not fixed.** The TODO says code blocks 1/3/5/7 fail because the heuristic import set omits `float`. This is a known broken gate. It adds noise to CI output and undermines confidence in the bridge-snippet verification system.

4. **Puzzle acceptance criteria tables are now present (just added) but inconsistently formatted.** Some use code fences inside list items, others use proper markdown tables. The calculator README's table is inside a collapsed `<details>` block, which hides it from the learner who glances at the README without expanding.

5. **Root README's "any order" claim for Tooling/Concurrency/Advanced persists** despite Big Pickle flagging it. The fix is trivial (replace "any order" with "Recommended: Tooling → Concurrency → Advanced; Advanced 01 (FFI) → 02 (solver) → 03–07 (any order)") and should have been applied rather than re-documented.

## Veredict

The READMEs are the curriculum's third-strongest asset (after mode/determinism depth and koan diagnostics). They communicate well with an intermediate programmer. The ceiling is structural: katas lack "why Mercury" framing, reactivation sub-katas lack individual READMEs, and the known bridge-snippet CI failures erode trust. A focused pass on kata READMEs (add "Why Mercury" paragraphs) and reactivation sub-katas (individual one-pagers) would lift this to 8/10.
