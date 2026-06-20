# Cinnabar final overall assessment

## Overall rating: 8/10

Cinnabar is now a credible, unusually deep post-tutorial Mercury curriculum. Recent work resolved navigation drift, stale reference contracts, parser prefix acceptance, fan-in shutdown documentation, and widespread compiler-level defects. The repository compiles cleanly under Mercury 22.01.8; CI mechanics are excluded here.

## What works

- The kata → koan → bridge → puzzle progression is coherent.
- Current indexes make the curriculum discoverable.
- Mercury-specific concepts drive the design: modes, insts, determinism, uniqueness, DCGs, grades, concurrency, FFI, and typeclasses.
- Templates and revised solution notes improve contributor consistency.

## Remaining release work

1. Fix memoized search’s divergence on the supplied cyclic graph and CSV’s phantom final row.
2. Fence or repair the meta-interpreter’s freshness/occurs-check limitations, and remove bridge 10’s stale solution-note contradiction.
3. Next, add a working CLP project and a multi-module capstone.

The remaining backlog is small and concrete. Preserve the current discipline: compile and run reference examples, state failure and termination contracts, and make advanced simplifications explicit.
