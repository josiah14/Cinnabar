# Advanced

Topics that are genuinely niche but matter in practice: FFI, solver types, RTTI,
memoization, association-list environments, and genuine mutable state. The arc runs from crossing the C boundary (FFI pragmas and foreign types), through Mercury's reflection mechanism (RTTI/`deconstruct`), explicit memoization strategies, the data structures that underlie the meta-interpreter, the module-level tools for information hiding, and finally mutable references via the `store` module. Work through them in order before tackling the advanced puzzles — the meta-interpreter in particular draws on every preceding topic.

| Kata | Topic |
|---|---|
| `01-ffi-depth/` | All four FFI pragmas: `foreign_decl`, `foreign_type`, `foreign_proc`, `foreign_export` |
| `02-solver-types/` | Reference kata — solver type declaration, `any` inst, `.tr` grade (no working build) |
| `03-rtti/` | `deconstruct.deconstruct/5`, generic pretty-printer, when RTTI is appropriate |
| `04-pragma-memo/` | `pragma memo` for deterministic predicates; manual memoization via state-threaded map |
| `05-assoc-list-env/` | Association lists as environments: lookup, shadowing, deref chains; the idiom the meta-interpreter uses |
| `06-abstract-module/` | Abstract type declaration; information hiding; `use_module` vs `import_module`; swapping implementations without touching clients |
| `07-ffi-pragma-attrs/` | `will_not_call_mercury`, `promise_pure`, `thread_safe` — what each attribute does and the cost of omitting it |
| `08-mutable-state/` | Genuine mutable references via `store`: `store(S)` heaps, `generic_mutvar`/`io_mutvar`, `di`/`uo` threading, and why a pure accumulator usually wins |

**Not in the Mercury tutorial.**

---

**Adding a kata?** See [`docs/TEMPLATES.md`](../../docs/TEMPLATES.md) for the canonical section order (the *Kata* template).
