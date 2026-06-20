# Solution notes

## Constructing an existential plugin: the `'new'` syntax

The puzzle is about existential types, and the reference solution uses them. The one
thing you have to get right is *construction*. The bare constructor does **not** work:

```mercury
:- type plugin ---> some [T] plugin(T) => formatter(T).

mk_upper = plugin(upper).  % compile error
```

```
type error in unification of argument and constant `upper'.
argument has type `(some [T] T)',
constant `upper' has type `plugins.upper'.
```

Inside an existentially quantified constructor the argument slot has type
`(some [T] T)`, which will not unify with a concrete `upper`. Mercury needs to be
told you are *introducing* the existential binding for `T`, not applying an ordinary
functor. That is what the `'new <ctor>'` syntax does:

```mercury
mk_upper = 'new plugin'(upper).            % T inferred as upper
mk_repeat(N) = 'new plugin'(repeat(N)).
mk_prefix(P) = 'new plugin'(prefix(P)).
```

This is the same rule the `koans/advanced/02-existential-escape` koan drills:
construction requires `'new'`; deconstruction (pattern-matching `plugin(X)` to bring
`T` back into scope) does not. The `=> formatter(T)` constraint does not change any of
this — a typeclass-constrained existential constructs exactly the same way. (Verified
against `mmc` 22.01.8: the solution compiles and runs.)

## The `apply` name collision

The puzzle's typeclass has a method named `apply`. Mercury reserves the *unqualified*
name `apply` for higher-order application, so once you deconstruct `plugin(X)` and try
to call the method:

```mercury
Output = apply(X, Input).   % mode error: X is ground, not a closure
```

Mercury reads this as "apply the closure `X` to `Input`" and reports a mode error
(`variable X has instantiatedness ground, expecting higher-order func inst`). Two
fixes: module-qualify the call (`plugins.apply(X, Input)`, used in the solution), or
name the method something other than `apply` (e.g. `format_with`) and drop the
qualifier. This is worth knowing — it is an easy ten minutes of confusion otherwise.

## Calling methods on a boxed plugin

`run_pipeline` deconstructs `plugin(X)` in the clause head. That deconstruction is
what makes the methods callable: it brings the hidden `T` *and* its `formatter(T)`
dictionary back into scope, so `plugin_name(X)` and `plugins.apply(X, _)` resolve.

```mercury
run_pipeline([plugin(X) | Rest], Input, !IO) :-
    Output = plugins.apply(X, Input),
    ...
```

A `list(plugin)` is therefore a genuinely heterogeneous collection: `upper`,
`repeat`, and `prefix` values sit in the same list, each carrying the dictionary that
lets the core system dispatch to the right instance methods.

## The closure alternative (a design choice, not a necessity)

Existentials are not the only way to get the open-world property. You can store the
behaviour as a first-class function instead of a dictionary:

```mercury
:- type plugin
    --->    plugin(pname :: string, papply :: func(string) = string).

mk_upper      = plugin("upper", string.to_upper).
mk_repeat(N)  = plugin("repeat(" ++ string.int_to_string(N) ++ ")",
                       func(S) = repeat_str(N, S)).
mk_prefix(P)  = plugin("prefix", func(S) = P ++ S).
```

Each closure captures its own data (`N`, `P`) — the role the existential's hidden `T`
plays — and you call it with `(P ^ papply)(Input)`. No `'new'` ceremony, no
dictionary, no `apply` collision.

The trade-off is what you can extend later. The existential carries a *typeclass*, so
you can add a method (say `priority/1`) to `formatter` and every existing plugin
gains it for free. The closure record carries exactly one function; growing the
"interface" means changing the record type and every constructor. Existentials are
the open-world choice for the *interface*; closures are simpler when the interface is
fixed at one operation.

## Answering the design questions

**Q1: Why must you go through a deconstructing predicate to call `apply`?**
Once a value is boxed as `some [T] plugin(T)`, `T` is hidden from the outside — the
caller does not know whether it holds an `upper` or a `repeat`. You cannot name a
method on an unknown type. Deconstructing `plugin(X)` (in a clause head or with `=`)
is what re-introduces `T` and its `formatter(T)` constraint into a local scope, and
only there are `plugin_name`/`apply` callable on `X`.

**Q2: Can you compose two plugins into a new formatter?**
Yes — straightforwardly. Define a composite type holding two boxed plugins and make
it a `formatter` instance that deconstructs both and chains them:

```mercury
:- type compose_plugin ---> compose_plugin(plugin, plugin).
:- instance formatter(compose_plugin) where [
    (plugin_name(compose_plugin(plugin(A), plugin(B))) =
        plugin_name(A) ++ " | " ++ plugin_name(B)),
    (apply(compose_plugin(plugin(A), plugin(B)), S) =
        plugins.apply(B, plugins.apply(A, S)))
].

mk_compose(P1, P2) = 'new plugin'(compose_plugin(P1, P2)).
```

`mk_compose(mk_prefix(">> "), mk_upper)` then behaves as a single plugin named
`"prefix | upper"`. The composite is itself existentially boxed, so it drops into the
same `list(plugin)` as any other plugin. (Compile-verified.)

**Q3: Runtime cost vs Rust `Box<dyn Trait>`.**
Both store a pointer pair. Mercury's existential packs `(value, class_dictionary)`;
Rust's `Box<dyn Trait>` stores `(data_pointer, vtable_pointer)`. Same order of cost —
one extra indirection per method call. The closure alternative trades the dictionary
for one closure allocation per plugin and a direct call.
