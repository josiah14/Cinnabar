# Cinnabar README and conceptual-quality review

## Rating: 8/10

The learner-facing map is now materially stronger: counts agree with the on-disk inventory, bridge 02 is described accurately, and track indexes expose the full curriculum. `docs/TEMPLATES.md` supplies a useful common contract. CI is excluded from this review.

## Remaining issues

1. `bridge/10-parallel-pipeline/README.md:25-31` correctly says the writer must change for fan-in, but `solution/README.md:39-40` still says the task claims otherwise. Remove the historical sentence and lead with the sentinel-counting invariant.
2. `README.md:23` says Tooling, Concurrency, and Advanced can be taken in any order. Recommend subpaths instead; FFI, solver types, and advanced parsing have meaningful prerequisites.
3. Put a visible limitation box in the meta-interpreter puzzle: it uses depth-based rather than globally fresh renaming and has no occurs check.

The documentation is now strong enough that its main remaining risk is overstating advanced examples, not navigation drift.
