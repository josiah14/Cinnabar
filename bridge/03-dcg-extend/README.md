# Bridge: extend the tokenizer

**After:** `katas/parsing/01-dcg-basics`

**Why Mercury:** a DCG rule is sugar for a predicate that threads the input as two
hidden difference-list arguments, and Mercury type- and determinism-checks the result
like any other predicate. Adding a `caret` or `float_tok` constructor to your `token`
type forces every rule that pattern-matches tokens to stay exhaustive, and the
determinism of each rule (does it commit, can it backtrack?) is a checked property —
so "rule ordering matters, first match wins" is something the compiler's determinism
analysis makes precise rather than a convention you hope holds.

`tokenizer.m` is a working tokenizer for a simple expression language. It handles integers
and four operators (`+`, `-`, `*`, `/`). It tokenizes a string into a `list(token)`.

```
mmc --make tokenizer
./tokenizer
```

Read the DCG rules carefully. Notice how `digits` accumulates a list of digit characters,
then `one_token` converts them to an integer.

---

## Extension tasks

### 1. Add `^` for exponentiation

Add a `caret` constructor to the `token` type. Add a DCG rule to `one_token` that
matches `'^'` and produces `caret`.

Test it: `"3 ^ 4"` should tokenize to `[int_tok(3), caret, int_tok(4)]`.

### 2. Add float literals

Add a `float_tok(float)` constructor to `token`. A float literal is digits, then `.`,
then one or more digits: `"3.14"`.

Write a new DCG rule in `one_token`:
```mercury
one_token(float_tok(F)) --> digits(IntDs), ['.'], digits(FracDs), { FracDs \= [] },
    { ... convert to float ... }.
```

Hint for conversion: `string.to_float/2` is `semidet` and can parse `"3.14"` if you
reconstruct the string from the character lists.

Order matters: put the `float_tok` rule **before** the `int_tok` rule, or `"3.14"` will
tokenize as `[int_tok(3), dot_tok, int_tok(14)]` (if you add a dot token) rather than
one float.

### 3. Add `token_to_string`

Write:
```mercury
:- func token_to_string(token) = string.
```

Map each token constructor to a readable string: `int_tok(3)` → `"int(3)"`,
`plus` → `"+"`, `float_tok(3.14)` → `"float(3.14)"`, etc.

Use it to print a tokenized expression for debugging:
```mercury
Strings = list.map(token_to_string, Tokens),
Joined = string.join_list(" ", Strings),
io.format("Tokens: [%s]\n", [s(Joined)], !IO).
```

---

## What you are practising

- Extending a DCG incrementally without breaking existing rules
- Token type evolution — adding constructors and updating all pattern matches
- Rule ordering in DCGs (first match wins in `semidet` rules)
- Writing a `token_to_string` function as an exhaustive case analysis
