# Bridge: expression language

**After:** `katas/parsing/02-dcg-goals` and `bridge/03-dcg-extend`

**Why Mercury:** a recursive-descent grammar written as multiple DCG clauses is, to
Mercury, a *nondeterministic* predicate — and the determinism checker says so out loud
(`multi`/`nondet`). Turning it into a real single-parse recursive-descent parser means
rewriting with if-then-else so each rule is `det` or `semidet`, and the compiler
confirms you actually achieved that. Precedence and left-associativity are encoded in
the grammar's structure; determinism analysis is what tells you whether that structure
is unambiguous.

`tokenizer.m` is a working lexer for arithmetic expressions. It converts a string
like `"10 * 3 - 4"` into a list of tokens: `[int_tok(10), star, int_tok(3), minus, int_tok(4)]`.

Build and run it first:

```
mmc --make --grade asm_fast.par.gc.stseg tokenizer
./tokenizer
```

Notice the compiler warning: `tokenize` is declared `semidet` but inferred `det`.
Fix this in Task 1 when you rework the module.

The tasks build a complete interpreter for arithmetic expressions on top of the
tokenizer — one step at a time.

---

## Extension tasks

### 1. Add a recursive-descent parser

Define an expression ADT:

```mercury
:- type expr
    --->    num(int)
    ;       add(expr, expr)
    ;       sub(expr, expr)
    ;       mul(expr, expr)
    ;       div(expr, expr).
```

Write a parser over `list(token)` using DCG rules. Start with a grammar that handles
`+` and `-` only (no precedence needed yet):

```
expr --> term, expr_rest(term).
expr_rest(Left) --> [plus], term(Right), expr_rest(add(Left, Right)).
expr_rest(Left) --> [minus], term(Right), expr_rest(sub(Left, Right)).
expr_rest(Left) --> { true }.  % empty: no more operators
term --> [int_tok(N)], { num(N) }.
```

Rewrite using if-then-else throughout (multiple DCG clauses infer `multi` or
`nondet` in Mercury — see `katas/determinism/04-multi-nondet`).

The result should parse `"1 + 2 - 3"` into `sub(add(num(1), num(2)), num(3))`.

Fix the `tokenize` determinism warning at this point — change its declaration to `det`.

### 2. Add correct precedence and associativity

Extend the grammar to handle `*` and `/` with higher precedence than `+` and `-`,
and left-associativity for all operators.

The standard recursive-descent approach: two levels of rules.
- `expr` handles `+` and `-` (low precedence)
- `term` handles `*` and `/` (high precedence)
- `factor` handles atoms (integers and parenthesised expressions)

Left-associativity is achieved by the accumulator pattern in `expr_rest` and
`term_rest` — passing the left subtree as an argument and building up the tree left
to right.

Verify:
- `"3 + 4 * 2"` → `add(num(3), mul(num(4), num(2)))` (precedence: `*` binds tighter)
- `"10 - 3 - 2"` → `sub(sub(num(10), num(3)), num(2))` (left-assoc: groups left)

### 3. Add an evaluator

Write:

```mercury
:- func eval(expr) = int.
```

Handle division: `div(A, B)` when `B = 0` should either use `0` as a fallback or
change `eval` to return `maybe(int)`. Choose one approach and document why.

Compose tokenizer + parser + evaluator in `main` to form a complete calculator.
Test on: `"3 + 4 * 2"`, `"10 - 3 - 2"`, `"100 / 5 + 2"`.

### 4. Add variables and `let`

Extend the token type with `ident_tok(string)` and `let_tok`.

Extend the lexer to recognise identifier tokens (sequences of letters) and the
keyword `let`.

Extend the ADT:
```mercury
;   var(string)
;   let(string, expr, expr)   % let x = e1 in e2
```

Extend the parser to handle `let x = expr in expr`. The `let` keyword binds the
variable `x` to the value of `e1` within `e2`.

Extend the evaluator to carry an environment:
```mercury
:- func eval(map(string, int), expr) = maybe(int).
```

Test: `"let x = 3 + 4 in x * 2"` should evaluate to `14`.

### 5. Error messages with token position

Right now the parser fails silently. Extend the token type to carry a position:

```mercury
:- type tok ---> tok(token, int).  % token + character offset
```

Return `parse_result(expr) ---> ok(expr) ; error(int, string)` from the top-level
parse call, where the `int` is the character offset of the unexpected token.

---

## What you are practising

- Building a parser stage on top of an existing lexer
- Left-recursion elimination via the accumulator (left-rest) pattern
- Connecting lexer, parser, and evaluator into a complete pipeline
- Extending a grammar incrementally without breaking existing stages
