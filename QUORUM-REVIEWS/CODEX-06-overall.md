# Overall — Codex

## Score: 7/10

This is a meaningful curriculum improvement: puzzle acceptance criteria, a
multi-module capstone, a currying/impurity bridge, and the meta-interpreter
freshness correction all address real teaching and correctness needs.

Do not merge the CI-policy changes as authoritative yet. The gate currently
labels diagnostic snapshot mismatches as PASS, despite claiming to verify
them, and the new broad `.err` exception pollutes a normal worktree with
generated solution logs. Those two issues undermine the central claim that
the exercises are mechanically verified.

Recommended order:

1. Make snapshot mismatches fail CI and either regenerate or deliberately
   retire stale snapshots.
2. Restrict `.err` tracking to intentional fixtures.
3. Correct the config puzzle's `.mh` statement and restore the missing logic
   row in the root puzzle index.
4. Add duplicate-key semantics and executable acceptance criteria to the two
   new learning units.

Verification performed: ran the prescribed Nix dev-shell CI command (using a
temporary Nix cache because the default cache was unwritable); it compiled the
checked entries and surfaced several snapshot mismatches that the script
misclassified as PASS.
