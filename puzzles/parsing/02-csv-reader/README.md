# Puzzle: CSV reader with quoted fields

**Primary skills:** DCGs, `string`, `io.res`, `list`, lookahead

**Why Mercury:** CSV with quoted fields requires proper lookahead — a field ends at an
unquoted comma or newline. DCGs express this naturally.

## Prerequisites

- `katas/parsing/01-dcg-basics` — DCG rules, list-of-char input representation
- `katas/parsing/02-dcg-goals` — lookahead patterns, conditional rule selection

---

## The problem

Parse a CSV string into `list(list(string))` — a list of rows, each row a list of field values.

Rules:
- Fields are separated by commas
- Rows are separated by newlines
- A field may be quoted with double-quotes: `"hello, world"` is one field
- Inside a quoted field, `""` (two consecutive quotes) represents a literal `"`
- Whitespace inside quotes is preserved; outside quotes, leading/trailing whitespace is trimmed

---

## Malformed input

Make the parser **strict**. The DCG stops at the first row it cannot parse (e.g. a field
with an unterminated quote) and returns the rows collected so far, leaving the rest of
the input unconsumed. If the top level ignores that remainder, a parse error silently
becomes end-of-file and you get truncated data with no warning. Have `parse` return
`maybe(csv)` and require the remaining character list to be empty — `no` when anything is
left unconsumed. The failure then shows up in the type, not as missing rows.

---

## Sample input

```
name,age,city
Alice,30,"New York"
Bob,25,"San Francisco, CA"
Carol,35,"Say ""hello"""
```

Expected output:
```
[["name", "age", "city"],
 ["Alice", "30", "New York"],
 ["Bob", "25", "San Francisco, CA"],
 ["Carol", "35", "Say \"hello\""]]
```

---

## Key DCG rules

```mercury
:- pred csv(list(list(string)), list(char), list(char)).
:- mode csv(out, in, out) is semidet.

csv([Row | Rows]) --> row(Row), ['\n'], csv(Rows).
csv([Row]) --> row(Row).
csv([]) --> [].

:- pred row(list(string), list(char), list(char)).
:- mode row(out, in, out) is semidet.

row([Field | Fields]) --> field(Field), [','], row(Fields).
row([Field]) --> field(Field).

:- pred field(string, list(char), list(char)).
:- mode field(out, in, out) is semidet.

field(S) --> ['"'], quoted_chars(Cs), ['"'], { string.from_char_list(Cs, S) }.
field(S) --> unquoted_chars(Cs), { string.from_char_list(Cs, S) }.
```

`quoted_chars`: consume chars until unescaped `"`. Handle `""` as an escaped `"`.
`unquoted_chars`: consume chars until `,` or `\n`.

---

## Extensions

- Handle `\r\n` line endings (Windows CSV)
- Support configurable separator (tab for TSV)
- Write a CSV writer (the inverse)
- Parse a CSV file from disk, report row/column counts
