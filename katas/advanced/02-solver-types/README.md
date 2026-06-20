# 02 — Solver types

**After:** `katas/advanced/01-ffi-depth` — `foreign_proc` is required for Tasks 2 and 3;
`katas/advanced/07-ffi-pragma-attrs` — purity attributes used in FFI stubs

Solver types are Mercury's hook for constraint logic programming (CLP). The
language machinery — the `solver type` declaration, the `any` inst, the
trailing grade — is all specified and enforced by the compiler. A working
constraint engine to sit behind it is a separate matter.

---

## What the language provides

### The `solver type` declaration

A solver type separates the *declaration* (interface section) from the
*definition* (implementation section):

```mercury
% Interface section — public name only:
:- solver type token_var.

% Implementation section — representation and inst mapping:
:- solver type token_var
    where
        representation is int,
        ground is ground,
        any is any.
```

The `representation is int` tells the compiler how to store the value at
runtime. `ground is ground` and `any is any` map Mercury's inst names to
the type's instantiatedness states.

### The `any` inst

Normal Mercury variables have two states: `free` (unbound) or `ground` (fully
instantiated). Solver types add a third:

```
free    — unbound
any     — constrained but not yet determined (in the constraint store)
ground  — fully instantiated
```

Predicates that produce or consume solver variables must annotate arguments
with `(any)`:

```mercury
:- pred make_var(token_var::out(any)) is det.
:- pred constrain(token_var::in(any), int::in, int::in) is det.
:- pred label(token_var::in(any), int::out) is det.
```

Plain `::in` is shorthand for `::in(ground)`. The mode checker enforces
`any` vs `ground` **statically** — passing an `any` variable where `ground`
is expected is a compile-time mode error, not a runtime failure.

### The `.tr` trailing grade

Solver types that need correct backtracking into the constraint store require
the trailing grade (`asm_fast.gc.tr`). When a branch fails, the runtime walks
a trail of constraint-store modifications and reverses them. Without trailing,
solver type variables cannot roll back on backtracking.

The trailing grade is available in the Mercury install used by this project
(`asm_fast.gc.tr` is in `lib/mercury/ints/`), but the cinnabar dev shell
defaults to the parallel grade (`asm_fast.par.gc.stseg`). CLP experiments
require compiling with `--grade asm_fast.gc.tr`.

---

## What is missing: the constraint engine

Mercury's stdlib provides only the type-system hook and trailing machinery.
There is no bundled CLP(FD) engine and no maintained third-party CLP library
for Mercury 22. The predicates that would do domain propagation, arc
consistency, and labeling do not exist yet.

A constraint engine would provide:

```mercury
:- pred domain(token_var::in(any), int::in, int::in) is det.
:- pred (#=)(token_var::in(any), token_var::in(any)) is det.
:- pred (#\=)(token_var::in(any), token_var::in(any)) is semidet.
:- pred labeling(list(token_var)::in(list_skel(any)), list(int)::out) is nondet.
```

With those predicates, SEND+MORE=MONEY would look like:

```mercury
solve(S, E, N, D, M, O, R, Y) :-
    domain([S, E, N, D, M, O, R, Y], 0, 9),
    S #\= 0, M #\= 0,
    1000*S + 100*E + 10*N + D + 1000*M + 100*O + 10*R + E
        #= 10000*M + 1000*O + 100*N + 10*E + Y,
    labeling([S, E, N, D, M, O, R, Y]).
```

See `CLP-PLAN.md` for the plan to build a Rust-backed CLP(FD) engine via FFI.

---

## Tasks

**Task 1 — Mode annotation exercise:**

The koan at `koans/advanced/07-solver-any-inst` shows the mode error that
fires when you call a predicate with plain `::in` using an `any`-inst
variable. Work through that koan before continuing here.

**Task 2 — Declare your own solver type:**

Declare a `pixel_var` solver type with `representation is int`. Write:
- `make_pixel_var(pixel_var::out(any)) is det` via a `foreign_proc` that
  sets the representation to 0
- `read_pixel(pixel_var::in(any), int::out) is det` via a `foreign_proc`
  that reads the representation value

Compile and run. Observe that the mode checker enforces `any` throughout.

**Task 3 — Purity and if-then-else:**

Add this to `main`:

```mercury
make_pixel_var(P),
( read_pixel(P, V), V > 127 ->
    io.write_string("bright\n", !IO)
;
    io.write_string("dark\n", !IO)
)
```

Compile. Read the purity error Mercury produces. Wrap the if-then-else in
`promise_pure(...)` to fix it. Understand why: testing an `any` variable in
a condition has purity implications that Mercury requires you to acknowledge.

**Task 4 (reading):**

Read `CLP-PLAN.md`. Understand what the Rust FFI engine would need to
provide and why the trailing grade is necessary for correct backtracking.

---

## External references

- `library/solver_builtin.m` in Mercury source — the hook definitions
- Mercury reference manual §9.6 — solver types and the `any` inst
- SWI-Prolog CLP(FD) documentation — conceptually equivalent, widely available
