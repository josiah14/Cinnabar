# Puzzle: four-operation calculator with precedence

**Primary skills:** DCGs, operator precedence via grammar structure, `maybe` for parse errors, recursion

**Why Mercury:** a recursive descent parser written as DCG rules is extremely close to
the formal grammar. Operator precedence falls out of rule structure, not explicit precedence tables.

## Prerequisites

- `katas/parsing/01-dcg-basics` — DCG rules, terminals, `phrase/2`
- `katas/parsing/02-dcg-goals` — `{Goal}` escaping, passing values through DCG rules
- `koans/parsing/01-dcg-goals` — `{Goal}` vs `(Goal)` — the exact error this puzzle avoids

---

## The problem

Parse and evaluate arithmetic expressions from a string.

Input: `"3 + 4 * (2 - 1)"` → evaluate to `7`

Operators: `+`, `-`, `*`, `/`. Standard precedence (`*` and `/` bind tighter than `+` and `-`).
Parentheses override precedence. Division by zero → `no`.

---

## Grammar for precedence

Encode precedence in the grammar structure — lower-precedence operators at higher levels:

```
expr   → term (('+' | '-') term)*     -- lowest precedence
term   → factor (('*' | '/') factor)*
factor → '(' expr ')' | number | '-' factor
```

In DCG form, use an accumulator for left-associativity:

```mercury
:- pred expr(int, list(token), list(token)).
:- mode expr(out, in, out) is semidet.

expr(V) --> term(T), expr_rest(T, V).

expr_rest(Acc, V) --> [plus],  term(T), expr_rest(Acc + T, V).
expr_rest(Acc, V) --> [minus], term(T), expr_rest(Acc - T, V).
expr_rest(Acc, Acc) --> [].

term(V) --> factor(F), term_rest(F, V).

term_rest(Acc, V) --> [star],  factor(F), { F \= 0 }, term_rest(Acc * F, V).
term_rest(Acc, V) --> [slash], factor(F), { F \= 0 }, term_rest(Acc // F, V).
term_rest(Acc, Acc) --> [].

factor(V) --> [lparen], expr(V), [rparen].
factor(V) --> [int_tok(V)].
factor(V) --> [minus], factor(F), { V = -F }.
```

---

## Tokenizer

Write a simple tokenizer: `string → list(token)` where
`token ---> int_tok(int) ; plus ; minus ; star ; slash ; lparen ; rparen`.

Tokenize by scanning characters with a DCG over `list(char)`. Make it **strict**:
if the scan stops before the end of the input (an unrecognised character), the
tokenizer should *fail*, not return the tokens it managed to collect. Otherwise input
like `"1 @ 2"` tokenizes to just `[int_tok(1)]`, the `@ 2` is silently dropped, and the
expression parser happily returns `yes(1)` for invalid input. The fix is to require the
remaining character list to be empty (`Rest = []`), which makes `tokenize` semidet — see
the pipeline below, where it sits inside the if-then-else condition.

---

## Full pipeline

```mercury
:- func calculate(string) = maybe(int).
calculate(Input) = Result :-
    ( tokenize(Input, Tokens), expr(V, Tokens, []) ->
        Result = yes(V)
    ;
        Result = no
    ).
```

---

## What to observe

- Verify `"3 + 4 * 2"` = 11 (not 14 — multiplication binds tighter)
- Verify `"(3 + 4) * 2"` = 14
- Verify `"10 / 0"` = `no` (division by zero)
- Verify `"1 + "` = `no` (parse error)
- Verify `"1 @ 2"` = `no` (invalid character — the strict tokenizer rejects input it
  cannot fully consume, instead of silently parsing the `1` prefix as `yes(1)`)
