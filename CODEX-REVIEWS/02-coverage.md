# Cinnabar coverage review: Mercury breadth and depth

## Ratings

- **Breadth: 8/10**
- **Depth: 8/10**

Coverage is unusually strong for a post-tutorial Mercury curriculum: modes/insts, all determinism categories, higher-order contracts, DCGs, tabling, concurrency, FFI, RTTI, and existentials recur across formats. The mode/determinism and parsing sequences are the project’s clearest strengths.

## Remaining gaps

1. Solver-types material lacks a working CLP or constraint-store project.
2. There is no multi-module capstone covering interfaces, opaque types, build dependencies, and tests.
3. Mutable/impure/semipure design has no sustained exercise comparing it with `!IO`, uniqueness, and STM.
4. Partial application/currying deserves focused practice alongside the strong higher-order-inst material.

The planned finite-domain project and a multi-module capstone are the highest-value next additions.
