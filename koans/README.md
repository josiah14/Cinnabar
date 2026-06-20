# Koans

Each koan is a small Mercury program with one specific flaw. The flaw is real — the
compiler catches it. Your task: read the error, understand why it occurs, and fix it.

The `solution/` subdirectory contains the corrected code and an explanation. Resist
looking until you have read the error and formed a hypothesis.

## Structure of each koan

```
01-koan-name/
  README.md        ← what to look for and what the compiler says
  koan.m           ← broken code
  solution/
    README.md      ← explanation of the fix
    fixed.m        ← corrected code
```

## Tracks

| Track | Koans |
|-------|-------|
| `foundations/` | 01-maybe, 02-string, 03-higher-order, 04-modules, 05-exceptions, 06-file-io, 07-built-in-types, 08-res-constructors, 09-array-unique, 10-foldl-accumulator, 11-state-var-direction, 12-map-io-capture, 13-missing-module-imports, 14-use-module-interface (text), 15-int-operators, 16-goal-expression, 17-error-message-ambiguity (text), 18-foldl-func, 19-char-digit |
| `type-system/` | 01-adt, 02-typeclass, 03-abstract, 04-parametric, 05-missing-instance, 06-missing-constraint, 07-superclass-instance, 08-phantom-mismatch, 09-instance-method-body, 10-phantom-constructor |
| `mode-system/` | 01-inst, 02-inference, 03-higher-order-inst, 04-uniqueness-violation, 05-mode-errors (set), 06-negation-bindings, 07-function-semidet, 08-nondet-io-uniqueness |
| `determinism/` | 01-det-mismatch, 02-nondet-in-det, 03-committed-choice, 04-determinism-errors (set), 05-promise-equivalent-solutions, 06-cc-nondet-solutions, 07-nondet-condition-multi, 08-det-semidet-else |
| `parsing/` | 01-dcg-goals, 02-dcg-mixed, 03-dcg-mode, 04-dcg-nondet, 05-phrase-string, 06-phrase-det, 07-stateful-branch |
| `tooling/` | 01-grade (text), 02-module-name, 03-pure-predicate-optimization (text), 04-require-complete-switch, 05-memo-io, 06-tail-rec-pragma, 07-test-det, 08-property-generator, 09-prop-operators |
| `concurrency/` | 01-parallel, 02-shared-state, 03-spawn-det, 05-spawn-propagate, 06-channel-sentinel, 07-stm-context, 08-promise-equiv-io |
| `advanced/` | 01-ffi, 02-existential-escape, 03-impure-foreign-proc, 04-univ-det, 05-export-arity, 06-foreign-enum, 08-ffi-mutex (text) |
