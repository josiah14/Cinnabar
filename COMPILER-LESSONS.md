# Mercury compiler lessons learned

Bugs encountered while building this curriculum's examples, grouped by category.
Each entry is: what went wrong, what Mercury actually said, and what fixed it.

---

## 1. Build system and toolchain

### `mkinit: not found` when calling `mmc` directly

**Symptom:** `mmc --make` fails immediately with `sh: mkinit: not found`.

**Cause:** `mmc` shells out to several companion tools (`mkinit`, `mld`, etc.) that
must be on PATH. Calling `/nix/store/.../bin/mmc` directly without adding the
mercury `bin/` directory to PATH means the companion tools are not found.

**Fix:** `export PATH=/nix/store/.../mercury-22.01.8/bin:$PATH` before calling `mmc`,
not just a direct path to the binary.

---

### `R_X86_64_32 relocation` linker error with `asm_fast` grade

**Symptom:**
```
ld: Mercury/os/start.o: relocation R_X86_64_32 against `.text' can not be used
when making a PIE object; recompile with -fPIE
```

**Cause:** The `asm_fast` grade emits x86 assembly using absolute addresses. Modern
Linux defaults to position-independent executables (PIE), which require relative
addressing. Outside a Mercury-aware build environment, the system linker uses PIE
mode by default.

**Fix:** Use the Mercury build that has its own linker configuration (the `nix develop`
shell sets this up). In this project: `c9qll4rka99zid2hzlxkkvpcrnnvrf5j-mercury-22.01.8`
works outside `nix develop`; `x85sr9yfr9r7p4pxjrm69fh4b8zxxndl-mercury-22.01.8`
(the debug-grade build) does not.

---

### `pragma memo` silently ignored in parallel grade

**Symptom:** Code using `pragma memo` compiles with a warning but memo has no effect.

**Cause:** Tabling (`pragma memo`) is incompatible with the parallel grade
(`asm_fast.par.gc.stseg`). The compiler does not error — it silently drops the pragma.

**Fix:** Either use the sequential grade for tabling, or accept that memo is a no-op
and demonstrate the concept differently.

---

## 2. Module imports — cryptic error messages

### `undefined symbol '[|]'/2` — missing `import_module list`

**Symptom:** Error on a line that uses `[s(X), i(Y)]` (a format argument list) or any
list literal.

**Cause:** List syntax (`[|]`, `[]`) lives in the `list` module. Without
`import_module list`, these symbols are undefined. The error message names the
constructor, not the module.

**Fix:** Add `:- import_module list.` The same applies to `io.format` calls — the
format argument list `[s(X), i(N)]` requires `list`.

---

### `undefined type 'char'/0` — missing `import_module char`

**Cause:** The `char` type is not automatically available. Import it explicitly.

**Caution:** an automated "remove unused imports" pass can wrongly flag `char` as unused
when only char *literals* (`'a'`) appear in clause bodies but the `char` *type* shows up
solely in `:- pred`/`:- func` declarations (e.g. `list(char)` arguments). Removing it
then breaks compilation. This regressed `csv_reader.m` once — always recompile after an
import cull.

---

### `undefined type 'bool'/0` — missing `import_module bool`

**Cause:** Same pattern. `bool`, `char`, `float`, `int`, `string` all require explicit
imports despite being primitive-feeling types.

---

### `undefined symbol 'float.log'/1` — math functions are in `math`, not `float`

**Cause:** Logarithms, trig, etc. live in `import_module math`, not `float`. `float`
only has arithmetic, conversion, and basic comparison.

---

### `undefined symbol 'i'/1` in `io.format` — missing `import_module string`

**Symptom:** `io.format("...", [i(N)], !IO)` fails with "undefined symbol `i'/1`,
that symbol is defined in module `string`."

**Cause:** The format specifier constructors (`i/1`, `s/1`, `f/1`, `c/1`) are
constructors of the `poly_type` type, which lives in the `string` module. Even if
the rest of the code uses no string functions, any `io.format` call with a format
argument list requires `import_module string`.

This appears particularly when a module uses no string operations and relies solely
on `io.format` — the dependency on `string` is not obvious.

**Fix:** Add `:- import_module string.` to the implementation section.

**Extra trap:** A file can compile successfully in a directory with a pre-built
`Mercury/` subdirectory (because the cached `.int` files satisfy the dependency
transitively) but fail from scratch in a clean directory. Always compile from a
fresh directory when verifying a file is self-contained.

---

### `use_module` in interface section — names not re-exported to callers

**Symptom:** Module A has `import_module B` in its interface section. Module C
imports A. When C uses names from B, the compiler reports them as undefined even
though A imported B.

**Cause:** `import_module B` in an interface section exposes B's names to the
implementation section but also re-exports them to any module that imports A. This
can cause callers to accidentally depend on B transitively. `use_module B` in the
interface section makes B's types usable in A's type and mode signatures without
re-exporting any of B's names to A's callers.

**Fix:** In interface sections, prefer `use_module` over `import_module`. In
implementation sections, use `import_module` freely.

```mercury
:- interface.
:- use_module list.           % list.list(T) usable in signatures; list not re-exported
:- type my_type(T) == list.list(T).

:- implementation.
:- import_module list.        % member, length, etc. all available here
```

The rule: `use_module` in interface = opaque dependency. `import_module` in
interface = transparent (re-exported) dependency.

---

## 3. Determinism system

### `cc_multi` propagates up the entire call chain

**Symptom:** Declaring a predicate `det` fails because it calls `thread.spawn`, which
is `cc_multi`. Fixing the declaration to `cc_multi` then breaks `main` (which is
declared `det`).

**Rule:** Any predicate that calls a `cc_multi` predicate must itself be declared
`cc_multi`. This propagates all the way to `main` if needed. Mercury allows `main` to
be declared `cc_multi`.

**Fix:** Change the declaration chain: calling pred → `cc_multi`; `main` → `cc_multi`.

---

### Semidet predicate with `io::di, io::uo` is a compile error

**Symptom:** Declaring `pred(int::in, io::di, io::uo) is semidet` and having the
predicate fail in some cases.

**Error:** "invalid determinism for a predicate with I/O state."

**Cause:** If a `semidet` predicate fails, the `io` token is never consumed — the
I/O state disappears. Any predicate that threads I/O state must be at least `det`.

**Fix:** Change to `det` and use if-then-else to handle the non-printing case
explicitly (e.g., `true` as the else branch).

---

### Multi-clause predicates with overlapping guards → `nondet`, not `det`

**Symptom:** Two clauses that are not mutually exclusive (both can match the same
input) are declared `det` but Mercury infers `nondet`.

**Example:**
```mercury
:- pred categorize(int::in, string::out) is det.  % WRONG
categorize(N, Cat) :- N >= 0, Cat = "non-negative".
categorize(N, Cat) :- N =< 0, Cat = "non-positive".
```
For `N = 0`, both clauses match → `nondet`.

**Fix:** Use a single if-then-else chain. Mercury cannot statically verify that
arithmetic guards are mutually exclusive.

---

### DCG multi-clause rules always infer `multi` or `nondet`

**Cause:** Multi-clause DCG rules behave like multi-clause predicates: if more than
one clause can match a given input, the determinism is `nondet` or `multi`. Mercury
does not infer `det` for multi-clause DCG rules even if the patterns look exclusive.

**Fix:** Rewrite multi-clause DCG rules as single-clause rules using if-then-else
inside the body.

---

### `cc_multi` (via thread.spawn) inferred as `multi`, not `cc_multi`

**Symptom:** Declaring a predicate `cc_multi` that calls `thread.spawn`. Mercury
infers `multi` (not `cc_multi`) and reports a determinism mismatch.

**Cause:** `thread.spawn` is `cc_multi`. A predicate calling it is inferred as `multi`
(the "requires all solutions" version), not `cc_multi`. The fix is to declare the
calling predicate as `cc_multi`.

---

### `promise_equivalent_solutions` gives `semidet`, not `det`, when inner goal can fail

**Symptom:** Declaring a predicate `det` with `promise_equivalent_solutions` wrapping
the body. Mercury infers `semidet`.

**Error:**
```
error: determinism declaration not satisfied.
Declared `det', inferred `semidet'.
The reasons for the difference are the following.
Call to `list.member'(out, in) can fail.
Negated goal can succeed.
```

**Cause:** `promise_equivalent_solutions [Vars] (G)` removes the *multi-solution*
property but not the *can-fail* property:

| inner goal | result |
|------------|--------|
| `cc_multi` | `det`  |
| `cc_nondet` | `semidet` |

If the wrapped goal can fail (e.g., `list.member` on an empty list), the result is
`semidet`. The pragma does not promote a can-fail goal to `det`.

**Fix:** Either change the declaration to `is semidet`, or ensure the wrapped goal
always produces at least one solution (making it `cc_multi`).

---

### `list.member` is `nondet`, not `cc_nondet`

**Cause:** `list.member` is genuinely nondeterministic — it generates all members.
It is not `cc_nondet`. Using it to demonstrate a `cc_multi`/`cc_nondet` error
produces a plain "inferred nondet" error instead of the cc-specific error.

To demonstrate a `cc_multi` propagation error, use `thread.spawn` (which is genuinely
`cc_multi`).

---

### `cc_nondet` passed to `solutions/2` — inst mismatch

**Error:**
```
in call to predicate `solutions.solutions'/2:
  mode error: arguments `V_7, All' have the following insts:
    /* unique */ (pred(out) is cc_nondet),
    free
  which does not match any of the modes for predicate `solutions.solutions'/2.
  The first argument `V_7' has inst `/* unique */ (pred(out) is cc_nondet)',
  which does not match any of those modes.
```

**Cause:** `solutions/2` is declared:
```mercury
:- pred solutions(pred(T)::in(pred(out) is nondet), list(T)::out) is det.
```
The inst annotation `pred(out) is nondet` is exact. `cc_nondet` does not satisfy it —
committed-choice predicates and collecting-all-solutions predicates are semantically
incompatible. A `cc_nondet` predicate has committed to the first solution; asking it to
enumerate all solutions for `solutions/2` is a contradiction.

**Fix:** Use the underlying `nondet` predicate directly with `solutions/2`. If only
the first solution is needed, call the `cc_nondet` predicate from a `cc_multi` or `det`
context (such as `main`) without `solutions/2`.

**Also note:** `solutions/2` is in `import_module solutions`, not `import_module list`.
Calling it without that import gives "undefined predicate `solutions'/2".

---

### `parallel conjunct may fail` — `&` requires `det` sub-goals

**Error:** "parallel conjunct may fail. The current implementation supports only
single-solution non-failing parallel conjunctions."

**Cause:** `&` (parallel conjunction) requires both sub-goals to be `det`. A `semidet`
sub-goal may fail — there's no recovery path in the parallel context.

**Fix:** Make both sub-goals `det`. Move conditional logic outside the `&`.

---

### `require_complete_switch` gives two errors, not one

**Symptom:** Using `require_complete_switch [Var] (...)` on an incomplete switch
produces two distinct errors:

```
error: determinism declaration not satisfied.
Declared `det', inferred `semidet'.
The switch on Direction does not cover `east'/0 or `west'/0.

Error: the switch on `Direction' is required to be complete,
but it does not cover `east'/0 or `west'/0.
```

The first is Mercury's standard incomplete-switch determinism error. The second is
the pragma's own error, fired from the pragma site. Both name the missing constructors.

**Without the pragma:** only the first error fires, and it points at the `det`
declaration rather than the switch itself. The pragma makes the second error appear,
which is more actionable (points directly at the switch).

**Fix:** Add the missing constructor arms. The pragma error names them explicitly.

---

### If-then-else does not commit nondeterminism it exports to the then-branch

**Symptom:** A nondet generator used inside an if-then-else condition — written as if
`->` will commit to the first solution — is inferred `nondet`/`multi` instead of
`semidet`/`det`:

```mercury
:- pred first_with(property::in, int::out) is semidet.
first_with(P, N) :-
    ( gen(1, 50, N0), has_property(N0, P) ->   % gen is nondet
        N = N0
    ; fail ).
```

```
determinism declaration not satisfied.
  Declared `semidet', inferred `nondet'.
  Call to `gen'(in, in, out) can succeed more than once.
```

Note the reason points at the `gen` call, not at the `->`.

**Cause:** Mercury's if-then-else commits the condition's nondeterminism **only for
variables local to the condition** — existentially quantified, i.e. bound inside it
and not used afterwards. Here `N0` is bound in the condition and *exported* to the
then-branch (`N = N0`), so every solution of `gen` produces a solution of the whole
predicate; the multiplicity is not pruned. The commit applies to *existence*, not to a
value you carry out of the condition.

**Confirming test:** discard the binding and the same if-then-else becomes
deterministic:

```mercury
( gen(1, 50, _) -> X = 1 ; X = 0 )   % inferred det — commits on existence
```

**Fix:** To return the first match, do not rely on the if-then-else to commit a value.
Use a semidet recursive scan (each step's condition then has at most one solution), or
`solutions(generate_and_filter, [First | _])` to collect all matches and take the head.

**Where discovered:** `puzzles/advanced/03-bidirectional-search/solution/`

---

### `det` does not imply termination — cardinality is not progress

**Symptom:** A predicate declared `det` (and accepted as such) loops forever at runtime.
Classic case: a `many`-style combinator over a parser that can succeed without consuming
input.

```mercury
:- mode many(in(parser_semidet), out, in, out) is det.
many(P, Results, Input, Rest) :-
    ( call(P, V, Input, Mid) ->
        many(P, Vs, Mid, Rest), Results = [V | Vs]   % recurses on Mid
    ;
        Results = [], Rest = Input ).
```

`many(pure(V), ...)` type-checks and never returns.

**Cause:** Determinism describes the *number of solutions* a goal has (here: exactly one),
not whether it *terminates*. The `parser_semidet` inst guarantees at most one solution
(cardinality) but says nothing about whether a successful `P` shortens the input
(progress). If `P` succeeds with `Mid = Input`, `many` recurses on identical input and
diverges — still perfectly `det`. No inst can express "must consume": cardinality is
statically checkable, progress is not.

**Fix:** Make the invariant a documented precondition ("a parser passed to `many` consumes
≥1 token on success"), or enforce it by requiring the residual to shrink before recursing
(`call(P, V, Input, Mid), list.length(Mid) < list.length(Input)` in the condition). For an
abstract stream with no generic length, enforcement needs a class method reporting
remaining size.

**Where discovered:** `puzzles/advanced/04-combinator-library/`,
`puzzles/advanced/05-generic-parser/` (verified: unguarded version runs until killed;
length-guarded version is `det` and terminates).

---

## 4. Mode system

### Scope error: binding a variable inside `\+`

**Symptom:** Using a variable as the output of a predicate called inside `\+`, then
using that variable outside the negation.

**Error:**
```
scope error: attempt to bind a non-local variable inside a negation.
Variable `T' has instantiatedness `free',
expected instantiatedness was `ground'.
```

**Cause:** `\+` creates an opaque scope. Bindings produced inside `\+` do not
propagate to the outer clause — `T` enters the negation `free` and exits `free`,
regardless of what happens inside. A variable declared as `out` in the clause head
must be `ground` at the end of the clause, so the mode checker catches this.

**Common pattern:** Trying to use negation to "select" a value by negating a bad
check: `\+ (list.member(T, Xs), bad(T))`. This does not bind `T` — it only checks
whether there is any T in Xs satisfying `bad(T)`.

**Fix:** Separate generation from testing. Use `list.member(T, Xs)` to bind `T`,
then test the property separately: `T \= bad_value` or `\+ bad(T)` with T already
ground. `list.find_first_match` is the idiomatic way to find the first element
satisfying a property with `semidet` result.

---

### `nondet` predicate in if-then-else condition from `det` context → `multi`

**Symptom:** Calling a `nondet` predicate in the condition of `( P -> T ; E )` inside
a `det` predicate. The outer predicate is inferred `multi`.

**Error:**
```
error: determinism declaration not satisfied.
Declared `det', inferred `multi'.
Call to `find_important'(in, out) can succeed more than once.
```

**Cause:** An if-then-else condition is a committed-choice context, but only for
`semidet` or `cc_nondet` goals. A `nondet` condition can succeed multiple times —
Mercury treats each solution as a branch, making the if-then-else `multi` (one
result per solution of the condition). The outer `det` declaration then fails.

**Fix:** Ensure the condition predicate is `semidet` or `cc_nondet`. For list
search, use `list.find_first_match` (semidet) rather than `list.member` +
filter (nondet). Alternatively, wrap with `promise_equivalent_solutions` if all
solutions are logically equivalent.

---

### Mercury reorders conjuncts — "free variable" bugs can be silently fixed

**Symptom:** Writing code with a variable used before it's bound (intending a mode
error for a koan), but the code compiles cleanly because Mercury reordered the goals.

**Rule:** Mercury's mode analysis reorders conjuncts to satisfy modes. If goal B
produces a variable that goal A needs, Mercury will run B before A automatically.
This is a feature, not a bug — but it means naive "use before bind" examples don't
produce errors.

**To trigger a genuine free variable error:** the variable must be bound in only one
branch of an if-then-else (not bound in all branches), or must never be bound at all
within the reachable goals.

---

### Unique (`di`) values consumed by `in` mode — no error

**Symptom:** Passing an `array_di` value to `array.set` (consuming it), then passing
the same variable to a predicate taking `array(T)::in`. Expected a uniqueness error;
code compiles cleanly.

**Rule:** Once a unique value is consumed via `di`, its memory remains valid for
read-only access. Mercury does not prevent reading a "spent" unique value via `in`
mode — it only prevents creating aliases (two simultaneous `di` references).

**The actual uniqueness error** (aliasing) occurs when you pass the same `di` value
to two separate destructive operations in the same clause.

---

### `!X` shorthand is not allowed in lambda argument lists

**Symptom:** Writing `(pred(X::in, !Acc) is det :- ...)` in a `list.foldl` call.

**Error:**
```
Error: !Acc cannot be a lambda argument.
  Perhaps you meant !.Acc or !:Acc.
Error: in head of lambda expression: some but not all arguments have modes.
```

**Cause:** `!X` expands to two arguments — the old and new values of a state
variable — but this expansion only works in *call* positions. Lambda heads require
each argument to be declared separately with its own mode annotation. There is no
mechanism for the compiler to expand `!Acc` in a lambda head because it does not
know which position is in and which is out without seeing all the mode annotations.

**Fix:** Use the `N0`/`N` naming convention explicitly:
```mercury
(pred(X::in, Acc0::in, Acc::out) is det :- Acc = Acc0 + X)
```

---

### `!:N` is free until assigned — using it as input is a mode error

**Symptom:** Writing `!:N = !:N * 2` intending to double the value of N.

**Error:**
```
warning: variable `STATE_VARIABLE_N_0' occurs only once in this scope.
mode error: variable `STATE_VARIABLE_N' has instantiatedness `free',
  expected instantiatedness was `ground'.
```

**Cause:** In a clause using `!N`, two internal variables are created: the old
value (`STATE_VARIABLE_N_0`, which is `!.N`, mode `in`) and the new value
(`STATE_VARIABLE_N`, which is `!:N`, mode `out`). The output variable starts free.
Using `!:N` on the right-hand side of an expression reads a free variable, which
the mode checker rejects.

The warning about `STATE_VARIABLE_N_0` is a companion signal: if the old value
(`!.N`) is never read, you are probably reading `!:N` where you meant `!.N`.

**Fix:** `!:N = !.N * 2` — read `!.N` (ground), write result to `!:N` (free → ground).

---

### Cannot use `!:IO` inside a lambda passed to a pure combinator

**Symptom:** Passing a lambda that calls an IO predicate to `list.map`.

**Error:**
```
Error: cannot use !:IO here due to the surrounding lambda expression;
  you may only refer to !.IO.
Here is the surrounding context that makes state variable IO readonly.
```

**Cause:** `list.map` has no IO threading — its lambda signature is
`pred(T::in, U::out) is det`. When the lambda body uses `!IO`, Mercury tries to
wire up the write-side (`!:IO`), but the surrounding `list.map` call has no
mechanism to consume and produce the unique IO token. The lambda context makes
`!:IO` (the write side) unavailable; only `!.IO` (a read-only view) is reachable.

**Fix:** Replace `list.map` with `list.foldl`, which accepts an extra state pair:
```mercury
list.foldl(
    (pred(S::in, !.IO::di, !:IO::uo) is det :- io.write_string(S, !IO)),
    Strs, !IO)
```

---

### `uo` (unique output) must be produced in every branch

**Error:** "mode mismatch in if-then-else. The variable `A' is ground in some branches
but not others."

**Cause:** A predicate declaring `array(T)::array_uo` as output must initialize
the array in every execution path. Skipping initialization in one branch leaves
the variable `free`, violating the `uo` mode.

**Fix:** Initialize in every branch — even a fallback `array.init(0, default, A)`.

---

### Existential construction needs the `'new <ctor>'` syntax — bare constructor is a type error

**Symptom:** Constructing a value of an existential type with the ordinary
constructor:

```mercury
:- type plugin ---> some [T] plugin(T) => formatter(T).

mk_upper = plugin(upper).  % ERROR
```

produces:

```
type error in unification of argument and constant `upper'.
argument has type `(some [T] T)',
constant `upper' has type `plugins.upper'.
```

**Cause:** Inside an existentially quantified constructor the argument slot has type
`(some [T] T)`. The bare `plugin(upper)` is read as applying an ordinary functor, and
Mercury will not unify a concrete `upper` with the existential argument type. This is
*not* a sign that existential construction is impossible — only that the ordinary
syntax does not express it.

**Fix:** Use the `'new <ctor>'` syntax, which tells the compiler to introduce a fresh
existential binding for `T` (inferred from the argument):

```mercury
mk_upper     = 'new plugin'(upper).
mk_repeat(N) = 'new plugin'(repeat(N)).
```

This works **even with the `=> formatter(T)` typeclass constraint** — a
typeclass-constrained existential constructs exactly like an unconstrained one.
(Verified: `puzzles/advanced/06-plugin-architecture/solution/plugins.m` compiles and
runs with `'new plugin'(...)`.) Deconstruction (`plugin(X)` in a clause head) needs no
`'new'` and brings `T` plus its constraint back into scope. This is the same rule
drilled in `koans/advanced/02-existential-escape`.

**Alternative design (not a workaround):** storing behaviour as a first-class closure
record (`plugin(pname::string, papply::func(string)=string)`) also gives open-world
extension, without the `'new'` ceremony or a typeclass dictionary. The trade-off:
adding a *method* to the interface later is free with the existential's typeclass but
forces a record-type change with closures. Pick by whether the interface is fixed.

**Where discovered:** `puzzles/advanced/06-plugin-architecture/solution/plugins.m`

---

### Typeclass method named `apply` collides with builtin higher-order application

**Symptom:** A typeclass with a method `func apply(T, string) = string`, called on a
ground value (e.g. after deconstructing an existential box):

```mercury
run(plugin(X), In, Out) :- Out = apply(X, In).
```

```
mode error: variable `X' has instantiatedness `ground',
expecting higher-order func inst of arity 1.
```

**Cause:** Mercury treats the *unqualified* name `apply` as builtin higher-order
application, so `apply(X, In)` is parsed as "call closure `X` on `In`". `X` is a ground
value, not a closure, so the mode check fails. The typeclass method is shadowed.

**Fix:** Module-qualify the call (`mymodule.apply(X, In)`), or — cleaner — name the
method something other than `apply` (e.g. `format_with`, `transform`) and drop the
qualifier. Any unqualified call to a method named `apply` hits this.

**Where discovered:** `puzzles/advanced/06-plugin-architecture/solution/plugins.m`

---

### A nondet generating mode can join a multimoded predicate, and `promise_equivalent_clauses` is not checked

**Symptom:** Uncertainty about whether a predicate with `(in,out) is semidet` and
`(out,in) is det` modes can also carry an `(out,out) is nondet` "generate everything"
mode under one `promise_equivalent_clauses`. It can — this compiles:

```mercury
:- mode str_to_int(in, out)  is semidet.
:- mode str_to_int(out, in)  is det.
:- mode str_to_int(out, out) is nondet.   % generate all (S, N) pairs
:- pragma promise_equivalent_clauses(str_to_int/2).
str_to_int(S::out, N::out) :- gen_int(N), S = string.int_to_string(N).
```

**What is actually true:**
- Modes of different determinism happily coexist on one predicate; a nondet mode is fine.
- An *infinite* relation is no obstacle — a nondet mode enumerates lazily, one solution
  per backtrack. The real risk is enumeration **order**: a non-productive generator
  (e.g. `gen_int(N) :- gen_int(M), N = M + 1`) type-checks but diverges at runtime before
  yielding anything. Make the generator yield before it recurses.
- `promise_equivalent_clauses` is a **promise the compiler does not verify**. It asserts
  every clause computes the same relation; getting that wrong is silent. Here it is subtly
  wrong even for two modes: `string.to_int` is lenient (accepts `"042"`, `"+42"`) while
  `string.int_to_string` only ever produces canonical strings (see §7), so the forward
  clause's relation is strictly larger than the reverse clause's.

**Guidance:** keep generation in a separate predicate; reserve
`promise_equivalent_clauses` for clauses whose relation you can actually prove identical.

**Where discovered:** `bridge/05-mode-reversal/` (verified: three-mode version compiles and
the `(out,out)` mode produces correct pairs with a productive generator).

---

## 5. Type system

### "Unsatisfiable typeclass constraint" — two different causes, same message

Mercury reports "unsatisfiable typeclass constraint: `show(color)'" for two
distinct problems. Recognizing which one you have determines the fix.

**Cause 1: no instance for a concrete type.**
You call a typeclass method on `color` but never declared `instance show(color)`.

```
instance_koan.m: unsatisfiable typeclass constraint:
    `instance_koan.show(instance_koan.color)'.
```

Fix: write the missing instance.

**Cause 2: missing constraint on a type variable.**
A polymorphic predicate calls `show(X, Str)` where `X :: T`, but the predicate
signature does not declare `<= show(T)`.

```
constraint_koan.m: unsatisfiable typeclass constraint: `constraint_koan.show(T)'.
```

Fix: add `<= show(T)` to the `:- pred` declaration. This propagates the requirement
to callers, which must then supply `T` with a `show` instance.

The disambiguator: if the error names a concrete type (`color`, `shape`), write
an instance. If it names a type variable (`T`), add a constraint to the signature.

---

### Subclass instance requires superclass instance to exist first

**Symptom:** Declaring `instance describable(shape)` when `describable <= printable`
but no `instance printable(shape)` exists.

**Error:**
```
In instance declaration for `describable/1':
the following superclass constraint is not satisfied:
  `superclass_koan.printable(superclass_koan.shape)'.
```

**Cause:** Mercury checks superclass constraints at the declaration site of the
subclass instance, not at use sites. Any code that has `describable(shape)` also
implicitly has `printable(shape)` — so the superclass instance must exist concretely.

**Fix:** Declare `instance printable(shape)` before `instance describable(shape)`.

---

### Comma inside `where [...]` is an item separator, not a conjunction

**Symptom:** Writing a multi-goal method body inside an instance `where [...]` block.

**Error:**
```
In instance declaration for `printable/1':
  the type class has no predicate method named `write_string'/3.
```

**Cause:** Inside `where [...]`, commas separate *method clauses*, not goals.
The compiler reads:
```mercury
:- instance printable(shape) where [
    do_print(S, !IO) :- describe(S, Str),       % item 1
    io.write_string(Str ++ "\n", !IO)            % item 2 — NOT a conjunction goal
].
```
The second line is parsed as a new method definition, and `io.write_string` is not
a method of `printable` — hence the error.

**Fix:** Delegate multi-goal bodies to a module-level predicate:
```mercury
:- instance printable(shape) where [
    do_print(S, !IO) :- print_shape(S, !IO)   % single-goal body — safe
].

:- pred print_shape(shape::in, io::di, io::uo) is det.
print_shape(S, !IO) :-
    describe(S, Str),
    io.write_string(Str ++ "\n", !IO).
```
Single-goal method bodies (no comma) are always safe inside `where [...]`.

---

### `=` is a goal in Mercury, not an expression

**Symptom:** Writing `bool_val(VA = VB)` in a function body — intending to produce
`bool_val(yes)` if `VA` equals `VB`.

**Error:** "the language construct `='/2 should be used as a goal, not as an
expression."

**Cause:** In Mercury, `=` is unification (a goal/predicate), not an equality test
that returns a bool. It cannot appear inside a functor application as an expression.

**Fix:**
```mercury
( VA = VB -> Result = bool_val(yes) ; Result = bool_val(no) )
```

---

### Phantom type tags need a dummy constructor

**Symptom:** `:- type metres.` compiles but then gives "abstract declaration has no
corresponding definition."

**Cause:** In Mercury, `:- type metres.` declares an *abstract* type (no definition
visible in this module). It does not create an empty type. To create a concrete type
with no data, you must give it at least one constructor.

**Fix:**
```mercury
:- type metres ---> metres_unit.
```
The constructor is never called — it exists only to satisfy Mercury's requirement.

---

### Multi-clause function with pattern matching inside a clause body → `semidet`

**Symptom:** A function clause that pattern-matches on the result of another call
in the body is inferred `semidet`, not `det`.

**Example:**
```mercury
eval(add_e(A, B)) = int_val(NA + NB) :-
    eval(A) = int_val(NA),   % can fail if eval(A) returns bool_val(...)
    eval(B) = int_val(NB).
```
The unification `eval(A) = int_val(NA)` can fail → clause is `semidet`.

**Fix:** Use if-then-else with a fallback:
```mercury
eval(add_e(A, B)) = Result :-
    ( eval(A) = int_val(NA), eval(B) = int_val(NB) ->
        Result = int_val(NA + NB)
    ;
        Result = int_val(0)   % ill-typed expression fallback
    ).
```

---

## 5b. Tabling and tail recursion pragmas

### `pragma memo` cannot be applied to predicates with unique-mode arguments

**Symptom:** Applying `pragma memo` to a predicate that threads `io::di, io::uo`.

**Error:**
```
Error: `:- pragma memo' declaration not allowed for procedure with unique modes.
```

**Cause:** Mercury's tabling system memoizes by storing ground inputs in a hash
table and returning cached outputs. The IO state (`io::di`) is unique, not ground —
it cannot be compared for equality, stored in a table, or replayed. The error fires
at the declaration site, not at any call site.

**Fix:** Remove `pragma memo` from any predicate that threads unique-mode arguments.
For loop detection on pure recursive predicates (no IO), `pragma loop_check` is
available — it also requires non-unique inputs.

---

### `pragma require_tail_recursion` defaults to `[warn]` — use `[error]` to enforce

**Symptom:** Adding `pragma require_tail_recursion(pred/arity, [])` to a
non-tail-recursive predicate. The compiler produces a warning but still compiles.

**Cause:** The default option is `[warn]`, not `[error]`. A warning does not
block compilation.

**Fix:** Use `[error]` to turn the pragma into a hard compile-time failure:
```mercury
:- pragma require_tail_recursion(sum_list/2, [error]).
```
The error message "self-recursive call is not tail recursive" names the line
of the non-tail call. The fix is to introduce an accumulator so the recursive
call is the last goal in every clause.

---

## 6. Purity system

### `foreign_proc` without `promise_pure` is impure — error fires at the declaration

**Symptom:** A `foreign_proc` clause without a `promise_pure` attribute. Mercury
errors at the predicate declaration, not at the call site.

**Error:**
```
purity error: predicate is impure.
It must be declared `impure' or promised pure.

Error: foreign clause for predicate `c_square'/2 has purity impure
but that predicate has been declared pure.
```

**Cause:** All `foreign_proc` clauses are **impure by default** — Mercury cannot
inspect foreign code and assumes the worst. The `:- pred` declaration is implicitly
`pure` (the default). The mismatch between an impure clause and a pure declaration
is caught when the clause is processed.

**Fix options:**
1. Add `promise_pure` to the attribute list — valid when the C code is a true
   mathematical function of its inputs (no global reads, no IO, no mutation).
2. Declare the Mercury predicate `:- impure` and propagate impurity to callers.
3. Thread `!IO` through the call to make side effects explicit in Mercury's type
   system — the standard approach for foreign code with IO effects.

**`promise_pure` is a promise, not a check.** If the C code is not actually pure,
the compiler will not warn. Incorrect `promise_pure` enables the optimizer to
reorder or eliminate calls, producing incorrect behavior silently.

---

## 6b. Concurrency system

### `thread.spawn` callback must be `cc_multi`, not `det`

**Symptom:** Passing a `det` predicate to `thread.spawn`.

**Error:**
```
mode error: variable `V_6' has instantiatedness `(pred(di, uo) is det)',
  expected instantiatedness was `(pred(di, uo) is cc_multi)'.
```

**Cause:** `thread.spawn` has mode `(pred(di, uo) is cc_multi, di, uo) is cc_multi`.
The callback must be `cc_multi`. A `det` predicate has a stricter contract
(exactly one outcome, no committed choice), which doesn't satisfy the spawn mode.

**Note:** Mercury may warn that a trivially-`det` body declared `cc_multi` "could
be tighter." The warning is correct about the body, but the `cc_multi` declaration
is required to satisfy `thread.spawn`'s mode. This is one of the rare cases where
you intentionally declare weaker than inferred.

---

### `cc_multi` propagates upward from `thread.spawn`

**Symptom:** Predicate calling `thread.spawn` is declared `det`.

**Error:**
```
error: determinism declaration not satisfied.
  Declared `det', inferred `multi'.
  Call to `thread.spawn'(...) can succeed more than once.

Error: call to predicate `thread.spawn'/3 with determinism `cc_multi'
  occurs in a context which requires all solutions.
```

**Cause:** `thread.spawn` is `cc_multi`. Any predicate that calls it must be
at least `cc_multi`. The property propagates upward through the entire call chain
to `main`. Anywhere `thread.spawn` is introduced, trace the callers and update
each declaration.

---

### Alternative to propagating `cc_multi`: `promise_equivalent_solutions [!:IO]`

**Context:** `thread.spawn` is `cc_multi`. If `main` is `det` and you do not want to
change its declaration, there is an alternative to propagating `cc_multi` upward.

**Fix:** Wrap each `thread.spawn` call in
`promise_equivalent_solutions [!:IO]`:

```mercury
promise_equivalent_solutions [!:IO]
    thread.spawn(worker(Chan), !IO),
```

This tells Mercury: "all solutions of this goal produce observationally equivalent
`!:IO` states." Because the IO state after spawning is the same regardless of which
`cc_multi` resolution is chosen, the assertion is correct.

**When to use each approach:**

| Approach | Use when |
|---|---|
| Declare `main` `cc_multi` | All spawns in `main`; idiomatic Mercury style |
| `promise_equivalent_solutions [!:IO]` | `main` must stay `det`; spawns are scattered through multiple predicates |

Both are semantically equivalent for `thread.spawn`. The `cc_multi` propagation
approach is simpler when spawning in multiple places.

---

### `channel(T)` has no built-in sentinel — encode it in the element type

**Symptom:** Sending `no` or `yes(X)` values to a `channel(int)`.

**Error:**
```
type error: argument has type `maybe.maybe(T)', expected type was `int'.
```

**Cause:** Mercury channels are monomorphic — `channel(int)` carries only `int`.
There is no out-of-band "closed" signal. To signal end-of-stream, the sentinel
must be part of the element type: use `channel(maybe(int))`, send `yes(X)` for
data and `no` as the terminal signal. The type system makes the communication
protocol explicit.

---

### `( ... !IO & ... !IO )` compiles — `!IO` auto-threads, so it is not really parallel

**Symptom:** A koan meant to show that two parallel branches cannot share unique IO
state stopped failing — this compiles in Mercury 22:

```mercury
main(!IO) :-
    ( io.write_string("A\n", !IO) & io.write_string("B\n", !IO) ).
```

**Cause:** `!IO` is shorthand that the parser *threads* — it rewrites the conjunction so
the first branch's output state becomes the second branch's input state. The result is a
dependent parallel conjunction with a data dependency on the IO state, which serializes the
branches. Nothing is shared, so nothing is rejected (and no real parallelism is gained).

To actually share one unique state between both branches you must name it explicitly, and
*then* the uniqueness checker rejects it:

```mercury
main(IO0, IO) :-
    ( io.write_string("A\n", IO0, IO) & io.write_string("B\n", IO0, _) ).
```

```
unique-mode error: the called procedure would clobber its argument,
but variable `IO0' is still live.
```

**Lesson:** uniqueness still forbids sharing a unique value across parallel branches — but
`!IO` quietly threads instead of sharing, so demonstrating the violation requires writing
the state by hand. The fix for real code is to run *pure* goals in parallel and keep the
unique IO on one sequential thread.

**Where discovered:** `koans/concurrency/02-shared-state/` (verified via the AGENTS.md dev
shell: explicit-share koan fails, pure-parallel solution compiles and runs).

---

## 6c. Parsing and DCG

### `phrase/2` does not exist in Mercury — call DCG predicates directly

**Symptom:** Using `phrase(Rule, Input)` style from Prolog.

**Error:** `undefined predicate 'phrase'/2` or `undefined predicate 'phrase'/3`.

**Cause:** Mercury does not provide a `phrase` meta-predicate. DCG rules defined
with `-->` desugar to regular predicates with two extra `list(T)` arguments. Call
them directly: `rule(Args..., Input, Rest)`. There is no DCG utility module that
exports `phrase` in Mercury 22.01.8.

---

### Multi-clause DCG rules infer `nondet`, not `semidet`

**Symptom:** Declaring a multi-clause DCG rule `semidet` or `det`.

**Error:**
```
error: determinism declaration not satisfied.
  Declared `semidet', inferred `nondet'.
  Disjunction has multiple clauses with solutions.
```

**Cause:** Multiple clauses are logical alternatives — any of them can succeed
on a given input. Mercury cannot statically prove mutual exclusivity, so it
infers `nondet`. To get `semidet`, collapse the alternatives into a single clause
using if-then-else. The if-then-else commits to the first matching branch.

---

### Stateful DCG disjunction — variable not bound in all branches

**Error:**
```
In clause for `item(in, out, in, out)':
  mode mismatch in disjunction.
  The variable `A' is ground in some branches but not others.
    In this branch, `A' is ground.
    In this branch, `A' is free.
```

**Cause:** A DCG rule that threads extra state (e.g., `stats(A, D)`) as arguments
contains a disjunction where one branch updates one state component but forgets to
bind another. Every output variable must be bound in every branch of a disjunction —
including unchanged state that is just being passed through. A branch that silently
drops a state variable leaves that variable free.

**Fix:** Explicitly equate unchanged state variables: `{ A = A0 }`. Also switch the
disjunction to if-then-else — a `;` disjunction infers `nondet` because Mercury cannot
prove branches are mutually exclusive. If-then-else commits to the first matching branch
and allows `semidet` inference.

**Rule:** In any stateful DCG rule, treat every state variable like `!IO` — every
branch must account for every state variable, either updating it or equating in with out.

---

### DCG rules take `list(char)`, not `string` — convert before calling

**Symptom:** Passing a string literal directly to a DCG rule.

**Error:**
```
type error: variable `Input' has type `string',
  expected type was `list.list(character)'.
```

**Cause:** DCG rules desugar to predicates on `list(T)`. A `string` is not a
`list(char)` — they are distinct types. Convert with `string.to_char_list/2`
before calling any DCG rule.

---

### DCG rule determinism propagates to every caller

**Symptom:** Calling a `semidet` DCG rule from a `det` predicate.

**Error:**
```
error: determinism declaration not satisfied.
  Declared `det', inferred `semidet'.
  Call to `digit_char'(out, in, out) can fail.
```

**Cause:** A DCG rule inherits the determinism of its body. If a rule can fail
(e.g., `[C], { char.is_digit(C) }` fails on non-digit input), it is `semidet`.
Calling it from a `det` predicate propagates the `semidet` constraint upward.
Either declare the caller `semidet` and handle failure at the use site, or wrap
the result in `maybe(T)` and return `no` on failure.

---

## 6d. FFI and RTTI

### `pragma foreign_export` arity must match the predicate's declared arity

**Symptom:** `pragma foreign_export("C", pred(in, out), "name")` when the predicate
has three arguments.

**Error:**
```
Error: `:- pragma foreign_export' declaration for predicate `pred'/2
    without corresponding `:- pred' declaration.
    `pred' does exist with arity 3.
```

**Cause:** Mercury derives the predicate identity from the name and the number of
modes in the export pragma. If the count is wrong, it looks for (and fails to find)
a predicate with that arity. The error message helpfully names the correct arity.

**Fix:** List all argument modes in the export pragma:
```mercury
:- pragma foreign_export("C", scale(in, in, out), "mercury_scale").
```

---

### `pragma foreign_enum` mapping must cover every constructor

**Symptom:** `pragma foreign_enum` for a type with N constructors that only lists
N-1 mappings.

**Error:**
```
In `:- pragma foreign_enum' declaration for type `color'/0:
    error: the following constructor does not have a foreign value:
        `yellow'.
```

**Cause:** Every constructor needs a C value. A partial mapping would produce
undefined behavior when the missing constructor is passed across the FFI boundary.
The check is at declaration time — the same static completeness guarantee as
`require_complete_switch`.

**Fix:** Add the missing mapping entry. The C constant must also be available in
the C compilation environment (via `pragma foreign_decl` or an `#include`d header).

---

### Omitting `will_not_call_mercury` causes per-call mutex acquisition

**Symptom:** FFI code that calls simple C functions in a hot loop runs much slower
than expected, or threads contend on an invisible lock.

**Cause:** A `foreign_proc` without `will_not_call_mercury` tells the Mercury
runtime that the C code might call back into Mercury. To make that safe, the runtime
acquires the Mercury engine mutex on every call. For functions that never call back
(most C library functions), this overhead is pure waste.

**Fix:** Add `will_not_call_mercury` to the pragma attribute list:

```mercury
:- pragma foreign_proc("C",
    c_abs(N::in, Abs::out),
    [will_not_call_mercury, promise_pure, thread_safe],
    "Abs = (N < 0) ? -N : N;").
```

`will_not_call_mercury` is not just a performance hint — it also disables the
reentrancy guard. The three pragmas typically go together for simple C utility
functions: `will_not_call_mercury, promise_pure, thread_safe`.

---

### `univ_to_type` is `semidet` — wrap it when the caller must be `det`

**Symptom:** Calling `univ_to_type(U, N)` from a predicate declared `det`.

**Error:**
```
error: determinism declaration not satisfied. Declared `det', inferred `semidet'.
Call to `univ.univ_to_type'(in, out) can fail.
```

**Cause:** `univ_to_type` can fail at runtime if the dynamic type stored in the
`univ` doesn't match the requested output type. Failing is part of its contract,
and Mercury propagates the can-fail property to any `det`-declared wrapper.

**Fix:** Either change the wrapper to `semidet` and handle failure at the call site
with if-then-else, or use `det_univ_to_type` (throws an exception on mismatch
instead of failing).

---

## 7. Standard library surprises

### `io.error_message` has both function and predicate forms — inline use causes type ambiguity

**Symptom:** Calling `io.error_message(E)` inline inside `io.format` or inside a
branch of a disjunction gives a type error or "ambiguous overloading" error.

**Cause:** `io.error_message` is defined in two forms:
- Function: `io.error_message(io.error) = string`
- Predicate: `io.error_message(io.error, string)`

When called inline in a position where Mercury must resolve which form is being
used, the type checker sometimes cannot disambiguate. This is especially likely
inside the `error(E)` branch of an `io.result` match, where the surrounding
context has already committed the type of `E`.

**Fix (option 1):** Extract `io.error_message` to a local variable first:

```mercury
Res = error(E),
io.error_message(E, Msg),
io.format("Error: %s\n", [s(Msg)], !IO)
```

**Fix (option 2):** Use the function form with an explicit type annotation at
the call site to resolve the ambiguity.

**Fix (option 3):** Throw the `io.error` as an exception, catch it in an outer
scope where the type context is cleaner, then call `io.error_message` there.

---

### `/` and `//` for `int` — both work in Mercury 22, but not always

**Symptom (older Mercury or missing import):**
```
error: undefined symbol `/'/2.
That symbol is defined in module `float', which does not have an
`:- import_module' declaration.
```

**Cause and Mercury 22 status:** In Mercury 22.01.8, both `/` and `//` are defined
on `int` (with `import_module int`) and both perform truncating integer division:
`7 / 2 = 3`, `7 // 2 = 3`. The "undefined symbol" error appears only when
`import_module int` is missing and the compiler resolves `/` to the `float` module
instead.

In older Mercury versions (or with no int import), `/` on `int` was ambiguous or
resolved to float:
- `//` — integer division (truncates toward zero), defined on `int`
- `/` — float division, defined on `float` (older behavior)

If you see "That symbol is defined in module `float'" after writing `N / 2` for an
`int` variable, add `import_module int`. Use `//` by preference if you want clarity
across Mercury versions.

**Fix:** Add `import_module int` and/or use `//` for explicit integer division:

```mercury
average(A, B) = (A + B) // 2.
```

Related: `rem` and `mod` behave differently on negative numbers.
- `rem`: truncated remainder (`-7 rem 3 = -1`)
- `mod`: floored modulus (`-7 mod 3 = 2`)

---

### `=\=` does not exist — use `\=` for structural inequality

**Symptom:**
```
error: undefined symbol `=\='/2.
```

**Cause:** Mercury does not have Prolog's arithmetic inequality operator `=\=`.
Mercury's structural inequality operator is `\=` (succeeds when two terms cannot
unify). For ground integers, `A \= B` is equivalent to `not (A = B)`, which is
correct arithmetic inequality.

There is no `=:=` either — use `=` for arithmetic equality of ground integers
(since unification on ground terms compares values).

**Fix:** Replace `=\=` with `\=`:

```mercury
( Denominator \= 0 -> X = Numerator // Denominator ; X = 0 )
```

---

### `io.res` uses `ok`/`error` constructors, not `yes`/`no`

**Symptom:** Pattern-matching on the result of `io.open_input` with `yes(Stream)`.

**Error:**
```
error: undefined symbol `yes'/1.
That symbol is defined in modules `bool' and `maybe', none of which
have `:- import_module' declarations.
```

**Cause:** `io.res(T)` is defined as `ok(T) ; error(io.error)` — it is not a
`maybe`. Students familiar with `maybe(T) ---> yes(T) ; no` often assume `io.res`
follows the same naming. The constructor `yes` belongs to a different type entirely.

Mercury's error message helpfully names the modules where `yes` *is* defined
(`bool`, `maybe`), which makes the cross-type confusion diagnosable.

**Fix:** Replace `yes(Stream)` with `ok(Stream)` and `no` with `error(_)`.

---

### `array.set` consumes its input array — updates must chain

**Symptom:** Calling `array.set` with the same original `Arr0` twice, intending
to make two independent updates.

**Error:**
```
unique-mode error: the called procedure would clobber its argument,
  but variable `Arr0' is still live.
warning: variable `Arr1' occurs only once in this scope.
```

**Cause:** `array.set` has mode `(in, in, array_di, array_uo) is det` — the input
array (`array_di`) is destructively consumed and replaced by the output (`array_uo`).
The original handle is invalidated. Using it again is a uniqueness violation.

The warning about the unused `Arr1` is a companion signal: if the output of one set
call is never used, you almost certainly used the original array again by mistake.

Updates must chain linearly through the outputs:
```
Arr0 →[set 0]→ Arr1 →[set 1]→ Arr2 →[set 2]→ Result
```

**Contrast with `version_array`:** `version_array` is persistent — reads use `in`
mode, the original is never consumed, and multiple live references are allowed.
Use `version_array` when you need to branch or retain old versions.

---

### `char.digit_to_int` does not exist — use `char.decimal_digit_to_int`

The predicate for converting a digit character to an int is
`char.decimal_digit_to_int/2`, not `char.digit_to_int/2`.

---

### `list.foldl` takes `pred(L, A, A)`, not `func(L, A) = A`

**Cause:** `list.foldl` is declared with a predicate argument, not a function
argument. Passing a function lambda fails with a type or mode error.

**Fix:** Use a predicate lambda:
```mercury
list.foldl(pred(X::in, Acc::in, Next::out) is det :- Next = Acc + X,
           List, 0, Sum)
```

---

### If-then-else variable scope: condition bindings reach the then-branch, not the else

**Symptom:** A variable bound in an if-then-else condition behaves differently depending
on where it is used:

```mercury
( char.decimal_digit_to_int(C, Digit) ->
    Result = Digit      % OK — Digit is in scope, holds the parsed value
;
    Result = Digit      % WRONG — this Digit is a fresh, unbound variable
).
```

**Cause:** Variables bound in the condition of `( Cond -> Then ; Else )` are in scope in
**Then** — the condition succeeded, so the bindings exist, and using them there is normal
(`( find(K, V) -> use(V) ; ... )`). They are **not** in scope in **Else**: the else-branch
runs precisely when the condition failed, so there is nothing to bind. Reusing the name in
the else-branch does not reach the condition — it introduces a new, unbound variable. That
surfaces not as a clean "undefined variable" message but as a `variable ... occurs only
once` warning plus a downstream mode error (e.g. `Result is ground in some branches but
not others`).

**Fix:** Reference condition-bound variables only in the then-branch. If a value must be
available in the else-branch or after the if-then-else, bind it before the condition, or
give the else-branch its own independent binding.

**Verified:** `char.decimal_digit_to_int(C, Digit)` in a condition with `Digit` used in the
then-branch compiles and runs (`'7'` → 7); the previous version of this entry, which
claimed the *then*-branch use itself fails, was wrong. See also §3, "If-then-else does not
commit nondeterminism it exports to the then-branch," which relies on this then-branch
visibility.

---

### `string.to_int` is lenient; `string.int_to_string` is canonical — they are not inverses

**Symptom:** Assuming `to_int` and `int_to_string` define one clean bijection between
strings and integers (e.g. when promising two modes of a converter compute the same
relation). They do not.

**Behaviour (verified in Mercury 22.01.8):**

```
to_int("42")  = 42      to_int("042") = 42      to_int("+42") = 42
to_int("00")  = 0       to_int("-0")  = 0
to_int(" 42") = FAIL    to_int("42 ") = FAIL    (surrounding whitespace rejected)
int_to_string(42) = "42"   (always canonical: no leading zeros, no '+')
```

**Cause:** `to_int` accepts several textual forms for the same integer (leading zeros, a
leading `+`, `-0`), so it is many-to-one. `int_to_string` emits exactly one canonical
string per integer. The relation `{(S,N) | to_int(S)=N}` therefore strictly *contains*
`{(S,N) | int_to_string(N)=S}` — the two directions are not inverse relations.

**Implication:** any `promise_equivalent_clauses` over a `str_to_int`-style predicate is
promising about the *canonical* relation, and the `to_int` direction quietly overshoots it.
Do not rely on round-tripping arbitrary input strings unchanged; only canonical strings
survive `to_int` then `int_to_string`. (Whitespace must be stripped before `to_int`.)

**Where discovered:** `bridge/05-mode-reversal/`.

---

### `list.filter_map` has a function form (takes a `func`) and a predicate form (takes a `pred`)

**Symptom:** Calling `filter_map` with the `= list` function syntax but passing a `pred`
lambda:

```mercury
Pairs = list.filter_map(
    (pred(S::in, K - V::out) is semidet :- ...),
    Parts),
```

gives a confusing type error — the result variable is "inferred" to be a `pred(...)`:

```
variable `Pairs' has overloaded actual/expected types {
  (expected) `list.list(pair(string, string))',
  (inferred) `pred(list(pair(...)), list(string))' ... }
```

**Cause:** `list.filter_map` comes in two shapes. The **function** form is
`filter_map(func(X) = Y is semidet, list(X)) = list(Y)` — it takes a partial *function*.
The **predicate** form is `filter_map(pred(X, Y) is semidet, list(X), list(Y))` — a
3-argument predicate taking a *pred*. Writing `Pairs = filter_map(PredLambda, Parts)`
mixes them: the function-call syntax expects a `func` lambda, so the `pred` lambda fails
to match and the call is misread as a partial application.

**Fix:** match the lambda kind to the call form. With a `pred` lambda, use the predicate
form as a goal: `list.filter_map(PredOrLambda, In, Out)` (often cleanest with a named
helper predicate). With a `func` lambda, the `= list` form works.

**Where discovered:** `bridge/11-error-handling/` (`parse_line`).

---

## 7b. Testing convention

### Test predicate with direct unification gives "unification can fail" error

**Symptom:** A test predicate declared `det` whose body ends with `Got = Expected`.

**Error:**
```
error: determinism declaration not satisfied. Declared `det', inferred `semidet'.
Unification of `Got' and `6' can fail.
```

**Cause:** Direct unification (`=`) is `semidet` — it succeeds when both sides
match and fails otherwise. A `det` predicate cannot contain a goal that can fail.

**Fix:** Wrap unification in an if-then-else with `error/1` in the else branch:
```mercury
:- import_module require.

test_sum :-
    sum_list([1, 2, 3], Got),
    ( Got = 6 ->
        true
    ;
        error("test_sum failed: expected 6, got " ++ string.int_to_string(Got))
    ).
```

Mercury treats exception-throwing as `det` (one outcome: an exception).
The if-then-else as a whole is `det` because both branches are `det`.

`error/1` is in `import_module require`. Without this import, the predicate
is undefined and a separate "undefined predicate `error'/1`" error fires.

---

## 6e. Software transactional memory

### `read_stm_var` with `!IO` — type error: `io.state` vs `stm_builtin.stm`

**Symptom:**
```
in argument 3 of call to predicate `stm_builtin.read_stm_var'/4:
  type error: variable `STATE_VARIABLE_IO_N' has type `io.state',
  expected type was `stm_builtin.stm'.
```

**Cause:** `read_stm_var` (and `write_stm_var`, `retry`) require a `stm::di, stm::uo`
state variable pair — the transaction context. Passing `!IO` (`io.state`) is a type
error. There is no implicit coercion between the two state types.

The error often cascades: the `stm` output of `read_stm_var` then gets fed to the
next call that expected `io.state`, generating a second error.

**Fix:** Wrap the call inside `atomic_transaction`:

```mercury
atomic_transaction(
    (pred(Val::out, S0::di, S::uo) is det :-
        read_stm_var(Var, Val, S0, S)
    ), Result, !IO).
```

`atomic_transaction` is the gate from IO context into transaction context. The
lambda receives `S0::di, S::uo` — those are the `stm` state variables.

---

### `unit` type requires `import_module unit`

**Symptom:**
```
error: undefined symbol `unit'/0.
```

**Cause:** The `unit` type (used as a "void" return from transactions that don't
produce a value) is in `import_module unit`, not in any default imports.

**Fix:** Add `import_module unit.` and use `unit::out` + `_` to discard:
```mercury
atomic_transaction(
    (pred(unit::out, S0::di, S::uo) is det :-
        write_stm_var(Var, NewVal, S0, S)
    ), _, !IO).
```

---

## 7c. Property-based testing

### `int.between/3` does not exist in Mercury 22 — use `int.nondet_int_in_range/3`

**Symptom:**
```
error: undefined predicate `int.between'/3.
```

**Cause:** The common name `between(Low, High, X)` for bounded integer generation does
not exist in Mercury 22's `int` module. The predicate is named
`int.nondet_int_in_range(Low, High, X)`. The name makes the determinism explicit.

**Fix:**
```mercury
gen_small_int(N) :- int.nondet_int_in_range(-10, 10, N).
```

`int.nondet_int_in_range(Low, High, X)` is `(in, in, out) is nondet`. It backtracks
from `Low` to `High` inclusive.

---

### Generator declared `det` — mode mismatch when passed to `solutions/2`

**Symptom:**
```
in argument 2 of call to predicate `check_property/5':
mode error: variable `V_7' has instantiatedness
  `/* unique */ (pred(out) is det)',
  expected instantiatedness was `(pred(out) is nondet)'.
```

**Cause:** `solutions/2` requires `pred(out) is nondet`. A generator declared `det`
produces exactly one value and cannot backtrack. Passing it where `nondet` is expected
is a mode mismatch.

**Fix:** Declare the generator `nondet` and give it a body that backtracks:
```mercury
:- pred gen_small_int(int::out) is nondet.   % was: det
gen_small_int(N) :- int.nondet_int_in_range(-10, 10, N).
```

A `det` generator also silently limits test coverage: the property is only checked
against one value. The compiler catches the mode error, but without it, tests would
appear to pass while most inputs go untested.

---

### `list.length` type ambiguity in property expressions

**Symptom:**
```
error: ambiguous overloading causes type ambiguity.
Possible type assignments include:
  V_3: `int' or `pred(int)'
```

**Cause:** Writing `list.length(list.reverse(Xs)) = list.length(Xs)` in a property
body. The `= ` unification is polymorphic, and Mercury cannot always resolve the
return type of `list.length` in this position — `int` and `pred(int)` both match.

**Fix:** Use the predicate form of `list.length` to make the type unambiguous:
```mercury
prop_reverse_length(Xs) :-
    list.length(Xs, Len),
    list.length(list.reverse(Xs), Len).
```

Or add an explicit type annotation: `list.length(Xs) : int`.

---

## 8. Mercury 22.01.8 parallel grade (`&`) backend bugs

These are confirmed compiler bugs in Mercury 22.01.8, not user errors. The
workarounds are required for code using `&` in the `asm_fast.par.gc.stseg` grade.

### Bug 1: if-then-else after `&` output crashes the backend

**Symptom:**
```
ll_backend.var_locn.actually_place_var/6: Unexpected: placing nondummy var N
which has no state
```

**Trigger:** Using a variable produced by `&` in an if-then-else condition in the
same clause body.

**Workaround:** Extract the `&` call into a named predicate. Never use `&`-produced
variables in if-then-else conditions in the same clause. Replace bool-valued checks
with a `check_eq(Name, Got, Expected, !IO)` pattern.

---

### Bug 2: ordering of predicates containing `&` matters

**Symptom:**
```
clobber_lval_in_var_state_map/6: Unexpected: empty state
```

**Trigger:** Multiple predicates that internally contain `&` called in a clause,
in an order different from their definition order.

**Workaround:** Call predicates containing `&` in *definition order* — the predicate
defined first in the source file must be called first in `main`.

---

### Bug 3: function calls in `&` conjuncts crash the backend

**Symptom:** The backend crashes during code generation.

**Trigger:** Using `= expr` (function call syntax) inside a `&` conjunct:
```mercury
( A = heavy_compute(500) & B = heavy_compute(600) )  % CRASHES
```

**Workaround:** Use predicate form (`out` argument) instead of function form:
```mercury
:- pred heavy_compute(int::in, int::out) is det.
( heavy_compute(500, A) & heavy_compute(600, B) )    % OK
```
Functions in `&` conjuncts reliably crash the 22.01.8 backend. Use predicates
exclusively in parallel conjunctions.

---

### Uniqueness mismatch: nondet condition with IO branches

**Symptom:**
```
error: uniqueness mismatch
  In if-then-else: condition is nondet, but branches bind unique variables
```

**Trigger:** Using an if-then-else where the condition is `nondet` and one or more
branches thread through a unique state (e.g., `io`):
```mercury
( solve(Puzzle, Solution) ->
    io.write_line(Solution, !IO)    % IO in branch — FAILS
;
    io.write_string("No solution\n", !IO)
)
```

Mercury's uniqueness checker rejects this because a nondet condition might succeed
multiple times; each success would consume the unique `!IO` state, violating the
single-use invariant.

**Fix:** Use `solutions/2` to collect results outside IO, then pattern-match:
```mercury
( solutions(solve(Puzzle), [Solution | _]) ->
    io.write_line(Solution, !IO)
;
    io.write_string("No solution\n", !IO)
)
```

The `solutions/2` call is det/semidet (it builds a list), so the condition is no
longer nondet, and the uniqueness checker is satisfied. This is the idiomatic Mercury
pattern for "find first solution, do something with it in IO."

---

### `det` declaration unsatisfied when else-branch calls `semidet` predicate

**Symptom:**
```
error: determinism declaration not satisfied.
  Declared `det', inferred `semidet'.
  Call to `stack.pop'(in, out, out) can fail.
```

**Trigger:** An if-then-else where the else branch calls a `semidet` predicate, even
though logically (given the condition) it cannot fail:
```mercury
drain_stack(S, !IO) :-
    ( stack.is_empty(S) ->
        io.write_string("(empty)\n", !IO)
    ;
        stack.pop(S, Top, Rest),    % semidet — compiler infers semidet here
        ...
    ).
```

The compiler considers `stack.pop` independently of the fact that `is_empty` failing
implies the stack is non-empty. It sees a `semidet` call in a `det` context.

**Fix:** Use a 3-way if-then-else, moving the semidet call into a condition:
```mercury
drain_stack(S, !IO) :-
    ( stack.is_empty(S) ->
        io.write_string("(empty)\n", !IO)
    ; stack.pop(S, Top, Rest) ->
        io.format("%d\n", [i(Top)], !IO),
        drain_stack(Rest, !IO)
    ;
        true  % unreachable — is_empty and pop cover all constructors
    ).
```

The third branch is dead but required so Mercury can infer `det`. Add a comment
naming why it is unreachable so readers don't try to remove it.
