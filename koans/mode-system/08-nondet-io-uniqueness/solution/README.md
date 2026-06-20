# Solution

Replace the nondet condition with `solutions/2`, then pattern-match the result list:

```mercury
report_even(List, !IO) :-
    ( solutions(any_even(List), [X | _]) ->
        io.format("first even: %d\n", [i(X)], !IO)
    ;
        io.write_string("no even numbers\n", !IO)
    ).
```

`solutions(any_even(List), Bag)` is `det`: it runs `any_even` to exhaustion and
collects every result in `Bag`. The nondeterminism is fully contained — no
backtracking escapes into the IO context.

The pattern `[X | _]` applied inside the condition makes the whole condition
`semidet`: it succeeds (binding `X` to the first solution) when the bag is non-empty,
and fails when the bag is empty. A `semidet` condition is safe: the if-then-else
commits to one branch and `!IO` is threaded through exactly once.

**Why `mostly_unique` vs `unique`?**

Mercury tracks unique ownership through modes. When a goal can be backtracked over,
any variable that was consumed *before* the backtrack point is no longer guaranteed
to be the sole live reference — something earlier in the search tree might still hold
a reference. This degrades the token from `unique` to `mostly_unique`. IO operations
require `unique`, so the compiler rejects the call.

`solutions/2` is the standard Mercury idiom for "find the first solution of a nondet
predicate and then do IO with it." The general pattern:

```mercury
( solutions(nondet_goal(Args), [First | _]) ->
    ... use First in IO ...
;
    ... handle empty case ...
)
```
