# README quality — Laguna M.1

## Overall: 7.5/10

The READMEs are the strongest point of the public face and the root document is
genuinely well-written — the ore/heat metaphor, the "Who this is for" section,
and the navigation table all communicate ambition accurately. But the recent
fix pass has left a tell: several READMEs feel retrofitted rather than designed.

## What works

The root README is the best in class. The per-track READMEs are consistently
formatted and each has an arc sentence that connects the track to the learner's
progression. The new koan READMEs (21–23) follow the TEMPLATES.md structure
closely and are the most consistent in the repo — broken concept, prerequisites,
compiler invocation, error output, what to observe, and a clear task. Puzzle
READMEs now have acceptance-criteria tables thanks to the Big Pickle fix pass,
which is a meaningful improvement over the earlier "approach-only" state.

The `docs/TEMPLATES.md` itself is a well-considered document. Its existence is a
strong signal, but the templates are not consistently applied. A spot check of
bridge READMEs shows that bridges 01–03, 07–09 still lack "Why Mercury"
sections. Bridge 03 (DCG extend) says "What you are practising" with generic
bullet points — "Extending a DCG incrementally," "Token type evolution" —
rather than naming a checked property Mercury enforces. Compare bridge 05:
"One logical relation with two checked directions." The gap is not that the
content is bad (it isn't), but that the pedagogical framing varies by an order
of magnitude.

## Residual issues

1. **Bridge "Why Mercury" is inconsistent.** Bridges 01–03, 07–09 still lack
   mechanism-specific framing. Bridge 12's README also skips it — the
   "Why Mercury" slot is filled by the prerequisites line. Every bridge should
   name the checked language property it demonstrates.

2. **Root "any order" claim is misleading.** "Tooling, Concurrency, and Advanced
   can be taken in any order" ignores that solver types need FFI, concurrency
   needs determinism, and the advanced track has internal ordering constraints.
   A sub-path recommendation would fix this.

3. **Error-message quoting.** Koan READMEs quote compiler output, which is good,
   but some quotes are paraphrased rather than exact. Koan 22 says `lambda_head_koan.m:013: Error: the clause head part of a lambda expression should have one of the following forms: pred(<args>) is <determinism>'` — this is close but not a verbatim
   transcript, and small wording differences between Mercury versions could
   produce a false mismatch for learners comparing against the README.

4. **TEMPLATES.md is not linked from any README.** It lives under `docs/` and
   is referenced nowhere in the exercise READMEs. A brief "see TEMPLATES.md for
   the canonical section order" in each track or format README would make it
   more than a document.
