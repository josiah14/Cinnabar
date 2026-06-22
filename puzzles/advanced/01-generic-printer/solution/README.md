# Generic printer solution notes

## `deconstruct` vs typeclass

The RTTI approach works for any type without modification. But it has costs:

- **No compile-time checking:** if you add a type to your system and it has a weird
  `deconstruct` representation, you only find out at runtime.
- **No customization:** you cannot make an `int` print as `"42"` instead of `"42"` —
  the functor IS the representation.
- **Performance:** RTTI calls are slower than direct pattern matching.

The typeclass approach (`printable` from `katas/type-system/04-type-classes`) requires
an instance per type but gives you full control over formatting and compile-time safety.

Use RTTI for debugging tools and generic infrastructure. Use typeclasses for
user-facing display.

## The `canonicalize` flag

`deconstruct(V, canonicalize, ...)` normalizes the representation — for example,
it represents `[1,2,3]` as `'[|]'(1, '[|]'(2, '[|]'(3, '[]')))` consistently.
The alternative `include_details_cc` gives more information for debugging but is
`cc_multi` rather than `det`.

## Type-name erasure: why `yes(yes(42))` prints as `yes/1`, not `maybe`

`deconstruct` hands back the *constructor's* functor name and arity — and nothing
about the *type* that constructor belongs to. Deconstructing `yes(yes(42))` yields
`Functor = "yes"`, `Arity = 1`; the fact that this value has type `maybe(maybe(int))`
is gone. In functor/arity notation the printer is working from `yes/1`, never from
`maybe`.

This is why the printer can be type-agnostic in the first place — but it has a real
consequence: two constructors from *different* types that happen to share a name and
arity deconstruct identically and print identically. The printed tree shows you the
constructor skeleton, not the static type. If you need the type name, that is what
`type_of`/`type_name` are for (`katas/advanced/03-rtti`); `deconstruct` alone will not
recover it. `canonicalize` is the flag that opts into this normalized, type-name-erased
view — `include_details_cc` carries more, at the cost of `cc_multi`.
