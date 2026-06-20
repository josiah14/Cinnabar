# Bridge: mode reversal

**After:** `katas/mode-system/02-multi-mode`

**Why Mercury:** in most languages, a string-to-int parser and an int-to-string
formatter are separate functions. Mercury's mode system lets you write the logical
relationship once and declare two directions — the compiler verifies that each clause
body implements the same relation, and rejects modes that would require information
the direction can't provide.

`convert.m` is a working program with a single predicate:

```mercury
:- pred str_to_int(string::in, int::out) is semidet.
```

Build and run it first:

```
mmc --make --grade asm_fast.par.gc.stseg convert
./convert
```

The predicate converts strings to integers in one direction. The tasks add the
reverse direction, explain why `pragma promise_equivalent_clauses` is the right
tool, and demonstrate what goes wrong when the promise is not valid.

---

## Extension tasks

### 1. Add the reverse mode

Add a second mode to `str_to_int`:

```
str_to_int(out, in) is det
```

When given an integer, this mode produces its decimal string representation. There
is no failure case — every integer has a valid decimal string.

Steps:
1. Replace the single mode declaration with two mode declarations.
2. Write a second clause body using mode-specific syntax: `str_to_int(S::out, N::in)`.
3. Add `pragma promise_equivalent_clauses(str_to_int/2)`.
4. In `main`, call the reverse mode and print the result.

The pragma asserts that both clause bodies compute the same logical relation — that
`(S, N)` is a valid pair in both directions. Verify this is true before adding it.

### 2. The third mode trap

Attempt to add a third mode:

```
str_to_int(out, out) is nondet
```

This mode would generate `(string, int)` pairs nondeterministically. Think through
what `promise_equivalent_clauses` would be asserting if you added it — the pragma
requires *every* clause to compute the same relation, and the compiler takes your
word for it.

The mode itself is legal and will compile. The harder questions are: can you write a
generator clause that produces exactly the same `(S, N)` pairs as the forward and
reverse modes? (Look carefully at what `string.to_int` accepts versus what
`string.int_to_string` produces.) And what enumeration order keeps the generator
productive over an unbounded domain?

Keep the third mode out of `str_to_int` — generation is a different job from
conversion. Write a separate predicate with a different name, and document precisely
what `promise_equivalent_clauses` would and would not be able to promise about it.

### 3. Build a `version_array` using both modes

Write a predicate that takes a `list(string)`, parses each as an integer using the
forward mode, and stores the results in a `version_array(int)` (defaulting to `0`
for strings that do not parse):

```mercury
:- pred strings_to_array(list(string)::in, version_array(int)::out) is det.
```

Then write a second predicate that uses the reverse mode to recover the string
representation of each element:

```mercury
:- pred array_to_strings(version_array(int)::in, list(string)::out) is det.
```

`version_array` is the right choice here because:
- You need to read individual elements by index after building the array.
- `array` would require unique modes (`di`/`uo`) threaded through every write,
  making the list fold awkward.
- `version_array` is persistent: reading one element does not consume the array.

---

## What you are practising

- Multi-mode predicates with mode-specific clause bodies
- `pragma promise_equivalent_clauses` and what the pragma actually asserts
- Identifying when the promise is not valid (and the correct response: separate predicate)
- `version_array` as the functional alternative to `array` when shared reads are needed

---

## Design questions

1. For `str_to_int`, the forward mode is `semidet` (a string might not be a valid integer)
   and the reverse mode is `det` (every integer has exactly one decimal string). What
   determines which direction is semidet and which is det? Can you construct a relation
   where *both* directions are semidet?

2. `pragma promise_equivalent_clauses` is validated by the programmer, not the compiler.
   What would happen at runtime if you applied it to two clause bodies that computed
   *different* logical relations — same types, same modes, wrong semantics?

3. Why is `version_array` the right choice for Task 3 rather than `array`? Write the
   type signature you would need if you used `array` instead and explain what changes.
