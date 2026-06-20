# Cinnabar idiomatic-Mercury review

## Assessment: 8/10

The revised material generally teaches the right defaults: determinism and failure contracts are explicit; `!IO` effects are contained; DCGs express grammar state; and types distinguish absence, validation, and IO failure.

Particularly strong examples are the calculator’s `semidet` full-consumption lexer, bridge 11’s `io.res(list(string))` propagation, `stats_pipeline.m` retaining a `det` entry point, and the plugin existential example.

## Corrections needed

1. `pragma memo` is not a semantic cycle-prevention invariant for a nondeterministic graph relation.
2. The meta-interpreter’s missing occurs check and non-global freshness must be explicit teaching limits.
3. CSV needs an explicit empty-record/final-newline contract.

Keep semantic preconditions beside the predicate that relies on them.
