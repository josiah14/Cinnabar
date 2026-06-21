# Puzzle: plugin architecture

**Primary skills:** existential types, typeclass-constrained existential types,
heterogeneous collections, open-world extension

**Why Mercury:** existential types let you store values of unknown types in a
uniform container, as long as each value carries its typeclass dictionary. You
get the same "add a new implementation without changing the caller" property as
runtime OOP dispatch, but the types are checked at construction time, not at
runtime.

## Prerequisites

- `katas/type-system/04-type-classes`
- `bridge/09-typeclass-refactor`
- `puzzles/advanced/05-generic-parser` (typeclass fluency)

---

## The problem

Build a small plugin system. A **plugin** is any type that implements a
typeclass. Plugins are stored in a heterogeneous list. The core system iterates
the list and calls the typeclass method on each one, without knowing the
concrete types.

---

## The typeclass

```mercury
:- typeclass formatter(T) where [
    func plugin_name(T) = string,
    func apply(T, string) = string
].
```

`plugin_name` returns a display name. `apply` transforms an input string.

> **Heads-up:** Mercury reserves the *unqualified* name `apply` for higher-order
> application. After you deconstruct a boxed plugin, calling `apply(X, S)` will be
> read as "call closure `X` on `S`" and fail to mode-check. Module-qualify the call
> (`yourmodule.apply(X, S)`) or name the method something else (e.g. `format_with`).

---

## The existential wrapper

```mercury
:- type plugin ---> some [T] plugin(T) => formatter(T).
```

This lets you store any `formatter(T)` instance in the same `plugin` box.
Construct with `'new plugin'(Value)` — the `'new'` syntax is required for
existentially quantified constructors; bare `plugin(Value)` is a type error, because
the argument slot has the existential type `(some [T] T)`, which will not unify with a
concrete value. Mercury infers `T` from `Value` and checks that `formatter(T)` has an
instance. Deconstruct in a clause head or with `=` (no `'new'` needed) — Mercury
brings the constraint `formatter(T)` back into scope for the existential body.

---

## Three concrete plugins

Implement these three formatter types, each with their own `formatter` instance:

1. `upper` — converts the input to uppercase
2. `repeat(int)` — repeats the input string N times, concatenated
3. `prefix(string)` — prepends a fixed string to the input

The `repeat` and `prefix` plugins carry data — the int and the prefix string.
This demonstrates that plugins are values, not just type tags.

---

## The pipeline

```mercury
:- pred run_pipeline(list(plugin)::in, string::in, io::di, io::uo) is det.
```

For each plugin in the list, print the plugin name, the input, and the result
of `apply`. Use the output of the previous plugin as the input to the next
(a fold).

---

## Main

Build a pipeline of at least four plugins (use at least two different types).
Feed it a test string and print the transformation chain.

---

---

## Acceptance criteria

With the pipeline `[prefix(">> "), upper, repeat(2), prefix("**")]` and input `"hello"`:

| Step | Plugin | Input | Output |
|---|---|---|---|
| 1 | `prefix(">> ")` | `"hello"` | `">> hello"` |
| 2 | `upper` | `">> hello"` | `">> HELLO"` |
| 3 | `repeat(2)` | `">> HELLO"` | `">> HELLO>> HELLO"` |
| 4 | `prefix("**")` | `">> HELLO>> HELLO"` | `"**>> HELLO>> HELLO"` |
| **Final** | — | — | `"**>> HELLO>> HELLO"` |

Single-plugin verification:

| Plugin | Input | Expected output |
|---|---|---|
| `upper` | `"test"` | `"TEST"` |
| `repeat(3)` | `"test"` | `"testtesttest"` |
| `prefix("x: ")` | `"test"` | `"x: test"` |
| `repeat(0)` | `"anything"` | `""` (empty) |
| `repeat(-5)` | `"anything"` | `""` (empty) |
| `prefix("")` | `"x"` | `"x"` (unchanged) |

Edge cases:

| Pipeline | Input | Final output |
|---|---|---|
| `[]` (empty) | `"hello"` | `"hello"` |
| `[upper]` | `"abc"` | `"ABC"` |
| `[repeat(1)]` | `"x"` | `"x"` |

## Design questions

1. The existential type `some [T] plugin(T) => formatter(T)` hides T from the
   outside. Why does this prevent the caller from calling `apply` directly
   without going through a predicate that deconstructs the box?

2. Can you define a `compose(plugin, plugin)` constructor that stores two plugins
   and applies them in sequence, making it itself a valid `formatter`? What would
   the instance declaration look like? What breaks if you try?

3. Mercury's existential types are "packed" — each `plugin` value carries a
   typeclass dictionary. What is the runtime cost compared to storing a concrete
   type? Compare to Rust's `Box<dyn Trait>` model.
