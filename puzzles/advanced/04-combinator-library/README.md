# Puzzle: parser combinator library

**Primary skills:** higher-order predicates with inst annotations, determinism
reasoning, composition

**Why Mercury:** building a combinator library forces you to put determinism in the
types, not just in your head. Each combinator's determinism is a function of its
argument combinators' determinisms — and Mercury verifies this.

## Prerequisites

- `katas/foundations/04-higher-order`
- `katas/determinism/01-six-categories`
- `katas/mode-system/04-higher-order-insts`

---

## The problem

Build a small parser combinator library over `list(char)`. A parser is a predicate
that consumes a prefix of the input and produces a result:

```mercury
:- type parser(T) == pred(T, list(char), list(char)).
```

A `det` parser always produces exactly one result and never fails.
A `semidet` parser produces at most one result (fails on parse error).
A `nondet` parser may produce multiple results (for ambiguous grammars).

---

## Base combinators

Implement these with their exact declared determinisms:

```mercury
% Always succeeds, produces V, consumes nothing.
:- pred pure(T, T, list(char), list(char)).
:- mode pure(in, out, in, out) is det.

% Always fails.
:- pred empty(T, list(char), list(char)).
:- mode empty(out, in, out) is failure.

% Consumes the next character if it exists; fails on empty input.
:- pred item(char, list(char), list(char)).
:- mode item(out, in, out) is semidet.

% Consumes the next character if Pred succeeds on it.
:- pred satisfy(pred(char::in) is semidet, char, list(char), list(char)).
:- mode satisfy(in(pred(in) is semidet), out, in, out) is semidet.
```

## Derived combinators

```mercury
% Run P then Q on the remaining input; produce a pair.
:- mode seq_det(
    in(parser_det),
    in(parser_det),
    out, in, out) is det.

:- mode seq_semidet(
    in(parser_semidet),
    in(parser_semidet),
    out, in, out) is semidet.

% Try P; if it fails, try Q.
:- mode choice_det(
    in(parser_det),
    in(parser_det),
    out, in, out) is det.

:- mode choice_semidet(
    in(parser_semidet),
    in(parser_semidet),
    out, in, out) is semidet.

% Apply P zero or more times; always succeeds (returns empty list on zero).
:- mode many(in(parser_semidet), out, in, out) is det.
```

> **Termination caveat.** `many` is `det` but does *not* always terminate. The
> `parser_semidet` inst guarantees P has at most one solution (cardinality) — it says
> nothing about whether P *consumes* input (progress). If you pass `many` a parser
> that can succeed without advancing (e.g. `pure`), it loops forever. The invariant
> you must uphold: a parser given to `many` consumes at least one token on success.

## Define inst aliases

```mercury
:- inst parser_det     == (pred(out, in, out) is det).
:- inst parser_semidet == (pred(out, in, out) is semidet).
```

---

## What to build with the library

Using only your combinators:

1. A `digit` parser (semidet): consumes one ASCII digit character
2. A `number` parser (det): consumes as many digits as possible, converts to int
   — succeeds with 0 if no digits are present
3. A `literal(string)` parser (semidet): consumes an exact string

Test `number` on: `"123abc"`, `"abc"`, `"0"`.

---

## Design question

Mercury does not allow a single combinator that is polymorphic over determinism:
`seq` cannot simultaneously be `det` when given `det` parsers and `semidet` when
given `semidet` parsers. You must write separate versions. Why? What would need to
be true of Mercury's type system for determinism-polymorphic combinators to work?
