# Correctness — Codex

## Overall: 6.5/10

The meta-interpreter freshness fix is soundly structured: the counter is
threaded through one derivation and the new capture regression documents why
depth alone is insufficient. The CI implementation, however, still does not
enforce one of its stated guarantees.

1. **[P1] Diagnostic snapshots cannot fail CI.** In `ci.sh:51-74`, a mismatch
   sets `all_found=false` but only prints `PASS (broke, diagnostic differs)`;
   it still increments `pass` and never increments `fail` or appends to
   `failures`. The Nix run reported this for multiple koans (including
   `advanced/01-ffi`, `concurrency/01-parallel`, and `foundations/01-maybe`).
   This violates the documented rule that snapshot diagnostics must match.
   Treat a mismatch as a failure, or explicitly remove snapshot matching from
   the CI contract.

2. **[P1] `.gitignore` now exposes transient solution error logs.** The broad
   exception at `.gitignore:15`, `!**/solution/*.err`, overrides `*.err` for
   every solution directory. The worktree consequently contains a large set of
   untracked compiler logs such as `solution/fixed.err` and puzzle `*.err`
   files. `compile_fail` only reads `$dir/${module}.err` for intentionally
   failing koans, so the broad solution exception is neither required nor
   validated. Narrow the exception to committed diagnostic fixtures, and make
   any required fixture naming explicit.

3. **[P2] The new config documentation's `.mh` assertion is incorrect.** See
   `CODEX-01-readme-quality.md`; this matters beyond prose because it teaches
   learners an incorrect model of the compiler's build products.
