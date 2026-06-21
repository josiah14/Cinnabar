# Puzzle: generic pretty-printer

**Primary skills:** `deconstruct.deconstruct/5`, `univ`, `type_of`, recursive value inspection

**Why Mercury:** RTTI lets you write code that works on any Mercury value without knowing
its type at compile time. The result is a tool genuinely useful for debugging, implemented
in under 30 lines.

## Prerequisites

- `katas/advanced/03-rtti` — `deconstruct/5`, `univ`, `type_of`, RTTI overview
- `katas/type-system/02-parametric-polymorphism` — parametric types to test the printer on

---

## The problem

Print any Mercury value as an indented tree:

```
node(
  node(
    leaf
    1
    leaf
  )
  2
  node(
    leaf
    3
    leaf
  )
)
```

Input: any Mercury value (via `univ` type erasure)
Output: indented string representation to stdout

---

## Key operations

```mercury
:- import_module deconstruct.
:- import_module univ.

% Convert any value to a type-erased univ
U = univ(MyValue).

% Decompose a univ into functor name, arity, and argument univs
deconstruct(univ_value(U), canonicalize, Functor, Arity, Args).
% Functor: string (constructor name)
% Arity: int (number of arguments)
% Args: list(univ) (type-erased arguments)
```

---

## The recursive structure

```mercury
:- pred pretty(univ::in, int::in, io::di, io::uo) is det.
pretty(U, Depth, !IO) :-
    V = univ_value(U),
    deconstruct(V, canonicalize, Functor, Arity, Args),
    Indent = string.duplicate_char(' ', Depth * 2),
    ( Arity = 0 ->
        io.format("%s%s\n", [s(Indent), s(Functor)], !IO)
    ;
        io.format("%s%s(\n", [s(Indent), s(Functor)], !IO),
        list.foldl(pretty_arg(Depth + 1), Args, !IO),
        io.format("%s)\n", [s(Indent)], !IO)
    ).
```

---

## Test it on

- A binary tree (your `tree(T)` type from `katas/type-system/02-parametric-polymorphism`)
- A list: `[1, 2, 3]` — observe the cons-cell structure
- A nested `maybe`: `yes(yes(42))`
- A plain int: `42` — note the functor is just `"42"`

---

---

## Acceptance criteria

| Input value | Expected printed output | Key property |
|---|---|---|
| `42` | `42` | atomic value, arity 0 |
| `"hello"` | `"hello"` | string as functor name |
| `[]` | `[]` | empty list, arity 0 |
| `[1]` | `[|](\n  1\n  []\n)` | singleton cons-cell |
| `[1, 2]` | `[|](\n  1\n  [|](\n    2\n    []\n  )\n)` | nested cons-cells |
| `yes(yes(42))` | `yes(\n  yes(\n    42\n  )\n)` | nested compound |
| `no` | `no` | arity 0 maybe |

## What to observe

- `[]` and `[H|T]` have functor names `"[]"` and `"[|]"` respectively
- `int` values have their numeral as the functor name, arity 0
- The printer works for *any* Mercury type without modification

## Design question

When would you reach for `deconstruct` vs writing a typeclass instance?
The answer shapes when RTTI is appropriate and when it is a design smell.
