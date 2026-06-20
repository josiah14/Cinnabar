# Type System

Mercury's type system is strong, static, and expressive. This track goes beyond the basics
into the features that make Mercury types genuinely powerful: recursive discriminated unions,
user-defined parametric types, abstract types, type classes, and existential types.

| Kata | Topic |
|---|---|
| `01-discriminated-unions/` | Recursive ADTs, total pattern matching, `semidet` constructors |
| `02-parametric-polymorphism/` | User-defined `tree(T)`, polymorphic predicates |
| `03-abstract-types/` | Opaque types, representation independence, encapsulation enforcement |
| `04-type-classes/` | Typeclass declaration, instance syntax, constraint propagation |
| `05-existential-types/` | Heterogeneous containers, OOP-style dispatch without OOP |
| `06-typeclass-depth/` | Superclass constraints (`<=`), multi-parameter typeclasses, functional dependencies |
| `07-typeclass-design/` | Typeclass vs. higher-order: when each is appropriate |
| `08-instance-coherence/` | Global coherence rule, orphan instances, newtype wrappers |
| `09-phantom-types/` | Phantom type parameters, unit-safe arithmetic, compile-time state machines |
| `10-gadts/` | GADT approximation strategies in Mercury (no native GADTs) |

Work in order — each kata builds vocabulary used by the next.
