# Solution

Use a 3-way if-then-else, moving `pop/3` into a condition position:

```mercury
drain(S, !IO) :-
    ( is_empty(S) ->
        io.write_string("done\n", !IO)
    ; pop(S, Top, Rest) ->
        io.write_string(Top ++ "\n", !IO),
        drain(Rest, !IO)
    ;
        true  % unreachable
    ).
```

**Why this works:**

In Mercury, a `semidet` call in *condition* position is permitted — the if-then-else
is designed to handle a condition that may fail. The determinism of the overall
expression is determined by whether all branches are covered, not by whether the
condition can fail.

With three branches each ending in a `det` goal (`io.write_string`, the recursive
`drain`, and `true`), the if-then-else is `det`. The third branch is dead — `empty`
is handled by `is_empty`, and `node(Top, Rest)` is handled by `pop` — but Mercury
requires it to confirm that every path leads to exactly one solution.

**The rule:**

> When a `semidet` call must appear in a `det` predicate, move it into a condition
> position and add a dead else branch with `true` and a comment explaining the
> invariant that makes it unreachable.

This is a recurring pattern when working with abstract types whose operations are
`semidet` for logical soundness even though the constructor set guarantees they
succeed in context.
