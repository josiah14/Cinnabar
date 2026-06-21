# Solution notes

Five modules in this directory:

| Module | Role | Depends on |
|---|---|---|
| `cfg` | opaque `config` type + `make`/accessors | — |
| `parser` | lines → key/value pairs | — |
| `validator` | pairs → `config` or errors | `cfg` |
| `printer` | `config` → text | `cfg` |
| `config_demo` | `main/2`, wires the pipeline | `parser`, `validator`, `printer`, `cfg` |

The dependency graph is a DAG with `cfg` at the bottom. `mmc --make config_demo`
walks it and compiles bottom-up.

## The opaque type is the whole point

`cfg`'s interface declares the type with no constructors:

```mercury
:- type config.                       % interface — abstract
...
:- type config ---> config(...).      % implementation — the real shape
```

Because the `config/3` constructor lives only in the implementation section, no
other module can write `config(H, P, V)` or pattern-match it. `validator` and
`printer` see exactly three operations: `make/3`, and the `host/port/verbose`
accessors. This is enforced by the compiler, not by convention — deconstructing
the record outside `cfg` is a type error ("the constructor is not visible").

That is what lets the **Extensions** swap work: change `cfg.m`'s representation
to a `map` and re-implement the four functions, and `validator`/`printer`
compile untouched, because they never named the representation.

## `make` is total; the validator is where the rules live

`cfg.make/3` takes already-typed inputs (`string, int, bool`) and is total — it
cannot express "invalid". All the *semantic* rules (required keys, port range,
unknown keys) live in `validator`, which is the only module that calls `make`.
So "you cannot build a config without going through validation" is true in
practice: the typed, range-checked inputs only ever come from `validate`.

This is a deliberate split. `make` could instead return `maybe(config)` and do
the checking itself, but then validation logic would leak into `cfg` and the
core type would depend on `assoc_list`, error strings, and key names it has no
business knowing. Keeping `make` total keeps `cfg` tiny and reusable.

## `use_module` vs `import_module`

`validator` and `printer` pull in `cfg` with `use_module cfg`, so every use is
qualified (`cfg.make`, `cfg.config`). Two reasons:

- The dependency on `cfg` is visible at each call site, not just in the import
  list.
- No risk of a name clash — `cfg.host` can't collide with a local `host`.

`config_demo` uses `import_module parser, validator, printer` (unqualified
allowed) because it leans on their constructors (`ok`, `bad_line`, `valid`,
`invalid`) heavily and the qualification would be noise. It still keeps the
demonstrative `use_module cfg` for the one type it passes through. The contrast
is the lesson: `use_module` for a dependency you want to keep at arm's length,
`import_module` for one you work with closely.

## Collecting all errors, in a fixed order

`validate` runs four independent checks (`host`, `port`, `verbose`, unknown
keys), each returning a `list(string)` of problems, and concatenates them:

```mercury
Errors = HostErrs ++ PortErrs ++ VerboseErrs ++ UnknownErrs,
( if Errors = [], MaybeHost = yes(Host), MaybePort = yes(Port)
  then Result = valid(cfg.make(Host, Port, Verbose))
  else Result = invalid(Errors) ).
```

The `MaybeHost = yes(_)` / `MaybePort = yes(_)` tests in the `then` condition
are not redundant defensiveness — they are how the typed `Host`/`Port` values
reach `make`. `Errors = []` already implies both are present (a missing key is
itself an error), but the compiler can't know that, so the `maybe` deconstruct
makes the data flow explicit. Errors come out in check order, so the output is
deterministic and testable.

## Parsing: split on the first `=`, ignore structure-only lines

`parser.parse` strips each line and skips it if it is empty or starts with `#`.
Otherwise it splits on the **first** `=` (`sub_string_search` + `between`), so a
value may itself contain `=`. A non-blank, non-comment line with no `=` is a
`bad_line` carrying its 1-based number. The parser deliberately knows nothing
about which keys are legal — that separation is design question 2.

## Build and CI notes

- Only `config_demo` has a `main/2`. The other four are libraries; building one
  directly (`mmc --make cfg`) fails at link with "undefined reference to
  `main/2`". `ci.sh`'s puzzle pass skips solution modules with no `main/`, so
  the library modules are verified as dependencies of `config_demo` rather than
  as standalone executables (the same rule the koan-solution pass already uses).
- There is no hand-written `.mh`. `mmc` generates `.int3/.int2/.int` (Mercury
  interface files consumed by other modules) from each `:- interface.` section;
  `.mh`/`.mih` C headers appear only with `pragma foreign_export`, which this
  library does not use.
