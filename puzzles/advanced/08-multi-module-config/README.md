# Puzzle: multi-module config library

**Primary skills:** module boundaries, abstract (opaque) types, `import_module`
vs `use_module`, multi-module builds, error accumulation

**Why Mercury:** an abstract type declared in a module's interface (`:- type
config.` with no `--->`) is genuinely opaque — clients cannot pattern-match or
construct it, only call the exported operations. The compiler enforces the
boundary across module files, so "validation is the only way to build a
config" becomes a checked property, not a convention.

## Prerequisites

- `katas/foundations/01-modules` — splitting a program across modules
- `katas/type-system/03-abstract-types` — hiding a type's representation
- `katas/advanced/06-abstract-module` — opaque types, `use_module` vs
  `import_module`, swapping implementations behind an interface
- `koans/foundations/04-modules` — multi-module imports and the build

This puzzle is the integrative capstone for those: instead of one abstract type
in one module, you design a **four-module system** and the build that ties it
together. It is the gap between "can read Mercury" and "can lay out a Mercury
package."

---

## The problem

Build a small configuration library that reads `key = value` text, validates
it, and prints it back — split across four cooperating modules plus a `main`.
The point is not the parsing; it is the **module boundaries** and the opaque
`config` type that only the validator can construct.

Input is a list of lines (`list(string)`). A line is either blank, a comment
(first non-blank character `#`), or `key = value`. Required keys are `host` and
`port`; `verbose` is optional (default false); any other key is an error.
`port` must be an integer in `1..65535`.

---

## Module architecture

Design these four library modules and one top module. The arrows are the
allowed dependency edges — keep them acyclic and minimal.

```
config_demo (main)
   ├── parser      lines -> key/value pairs (or a syntax error)
   ├── validator ──┐  key/value pairs -> opaque config (or a list of errors)
   └── printer   ──┤  opaque config -> canonical text
                   └── cfg   the opaque `config` type + accessors
```

**`cfg`** — the opaque core. Its interface declares `:- type config.`
(no constructors visible), a smart constructor `make/3`, and read-only
accessors. The representation (a record, a map, whatever) lives only in the
implementation section.

**`parser`** — pure syntax. Turns `list(string)` into key/value pairs, ignoring
blanks and `#` comments, reporting the line number of the first malformed line.
It knows nothing about which keys are valid.

**`validator`** — pure semantics. Takes the key/value pairs, checks required
keys / port range / unknown keys, and on success calls `cfg.make` to mint the
opaque value. It should collect **all** errors, not just the first.

**`printer`** — takes a `config` and renders it back to canonical text using
**only** `cfg`'s accessors. It must not be able to see the representation; if it
could pattern-match the record, the boundary would be leaking.

**`config_demo`** — `main/2`. Wires `parser -> validator -> printer` over a few
sample inputs and prints the results.

---

## Key predicates to write

- `cfg.make(string, int, bool) = config` and `cfg.host/1`, `cfg.port/1`,
  `cfg.verbose/1`
- `parser.parse(list(string), parse_result)` where
  `parse_result ---> ok(assoc_list(string, string)) ; bad_line(int, string)`
- `validator.validate(assoc_list(string, string), validation)` where
  `validation ---> valid(cfg.config) ; invalid(list(string))`
- `printer.render(cfg.config) = string`

---

## Building it

All `.m` files live in `solution/`. Build the top module; `--make` works out
the dependency graph and compiles the rest bottom-up:

```
mmc --make --grade asm_fast.par.gc.stseg config_demo
```

There is no separate "interface file" to hand-write. In Mercury the interface
you author *is* the `:- interface.` section of each `.m` file. `mmc` derives
the on-disk interface files from it — `.int3`, `.int2`, `.int` (used by other
modules at compile time). A `.mh`/`.mih` C header is generated only if a module
uses `pragma foreign_export`; this library has none, so you will see no `.mh`.

---

## What to observe

- **The opaque boundary is checked.** Try adding `Config = cfg.config(H, P, V)`
  (pattern-matching the record) inside `printer` — it is a type error, because
  the constructor is not exported. Only `cfg`'s own implementation sees it.
- **`use_module` vs `import_module`.** Importing `cfg` with `use_module` forces
  every reference to be qualified (`cfg.make`, `cfg.config`), so the dependency
  is visible at each use site. `import_module` would let you drop the qualifier
  but pollutes the namespace. The validator and printer use `use_module cfg`
  deliberately.
- **Dependency direction.** `cfg` imports none of the others; `parser` imports
  none of them either. The graph is a DAG, which is what lets `--make` compile
  bottom-up and what would let you reuse `cfg` in a different program.

---

## Extensions

- Give `cfg` a second representation (e.g. an `assoc_list` instead of a record)
  and confirm that **only `cfg.m` changes** — `validator` and `printer` compile
  untouched. That is the opaque type paying off.
- Promote the library modules into **sub-modules** of `cfg`
  (`cfg.parser`, `cfg.validator`, `cfg.printer`) using `:- include_module`.
  Observe how the qualified names and the build change.
- Add a `merge/2` that overlays one config on another (later keys win), and
  decide whether it belongs in `cfg` (needs the representation) or in a client
  (can it be written with only the accessors?).

---

## Design questions

1. The validator is the only module that calls `cfg.make`. What prevents a
   client from constructing a `config` that skips validation — is it a
   convention, or does the compiler enforce it? What exactly would a client
   have to import to break the rule, and why can't it?

2. `parser` returns key/value *strings*; `validator` turns them into typed,
   range-checked values. Why split syntax from semantics into two modules
   instead of validating during parsing? What does each module gain by not
   knowing about the other's concern?

3. `printer` depends on `cfg` but not on its representation. If `cfg` switched
   from a record to a `map(string, string)`, which modules would need
   recompilation, and which would need source changes? (They are not the same
   set.)

---

## Expected output

```
=== sample A (valid) ===
parsed and validated OK:
host = localhost
port = 8080
verbose = true

=== sample B (semantic errors) ===
parsed OK, but validation failed:
  - port out of range (1-65535): 99999
  - unknown key: debug

=== sample C (syntax error) ===
parse error on line 2: this line has no equals
```
