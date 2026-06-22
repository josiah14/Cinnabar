# Foundations

This track builds the mechanical fluency you need before Mercury programs start feeling natural rather than fought-over. It covers the language's structural layer — modules, types, higher-order predicates, state threading with `!`, and standard library containers — before the mode and determinism tracks make the type-level reasoning explicit. By the end, reading a Mercury mode error should feel like reading a type error: informative rather than opaque.

Work them in order. The later katas assume the earlier ones.

## Track order

| Directory | Topic |
|---|---|
| `00-reactivation/` | Predict/verify pass — isolates one Mercury concept per exercise |
| `01-modules/` | Module system: interface/implementation split, `import_module` vs `use_module`, interface files |
| `02-maybe/` | `maybe(T)` — optional values, `map_maybe`, local `bind_maybe` |
| `03-string/` | String module: `string.length`, `string.count_codepoints`, word-wrap |
| `04-higher-order/` | Higher-order predicates, `list.map`/`filter`/`foldl2`, storing preds in variables |
| `05-map/` | `map(K, V)` — insert, lookup, update, sorted output |
| `06-set/` | `set(T)` — set operations and the flag-set pattern |
| `07-exceptions/` | `io.res`, `exception.catch_any`, file I/O error handling |
| `08-built-in-types/` | Integer, float, char, string corners — `//`, `rem` vs `mod`, poly-type tagging |
| `09-mode-inference/` | Goal reordering, multi-mode predicates, reading mode errors |
| `10-record-update/` | `^` field access, `:=` functional update, chained updates, copy-on-modify pattern |
| `11-stdlib-collections/` | `bag`, `bimap`, `array` vs `version_array` — less-visited stdlib collections |

## Build

The dev shell provided by the project `flake.nix` sets `asm_fast.par.gc.stseg` as the default grade. A bare `mmc --make <module>` will use that grade. If you see a "standard library not found" error, confirm you entered the shell with `nix develop` before building.

---

**Adding a kata?** See [`docs/TEMPLATES.md`](../../docs/TEMPLATES.md) for the canonical section order (the *Kata* template).
