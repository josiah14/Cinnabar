# Puzzle: graph reachability with tabling

**Primary skills:** `set(T)`, recursion, `pragma memo` / `pragma loop_check` for cycle detection

**Why Mercury:** naive recursive graph traversal loops on cycles. `pragma loop_check` is
the correct Mercury tool for breaking cycles in recursive queries — more elegant than
maintaining a "visited" set manually.

## Prerequisites

- `katas/foundations/05-map` — `map(K, V)`, `set(T)`
- `katas/tooling/04-tabling` — `pragma loop_check`, `pragma memo`, tabling semantics

---

## The problem

Find all nodes reachable from a given start node in a directed graph (which may have cycles).

Input: a graph as `map(node, list(node))` (adjacency list), a start node
Output: `set(node)` of all reachable nodes (including the start)

---

## Representation

```mercury
:- type node == string.
:- type graph == map(node, list(node)).
```

---

## Approach 1: manual visited set

The straightforward approach threads a `set(node)` through the recursion:

```mercury
:- pred reachable(graph::in, node::in, set(node)::in, set(node)::out) is det.
reachable(Graph, Start, Visited0, Visited) :-
    ( set.member(Start, Visited0) ->
        Visited = Visited0
    ;
        Visited1 = set.insert(Visited0, Start),
        ( map.search(Graph, Start, Neighbors) ->
            list.foldl(reachable(Graph), Neighbors, Visited1, Visited)
        ;
            Visited = Visited1
        )
    ).
```

This is correct but verbose — you are manually implementing what `loop_check` does.

---

## Approach 2: `pragma loop_check`

A cleaner version: write `reachable` as a `nondet` predicate that generates reachable nodes,
and use `pragma loop_check` to handle cycles:

```mercury
:- pred reachable_node(graph::in, node::in, node::out) is nondet.
:- pragma loop_check(reachable_node/3).

reachable_node(_, Start, Start).
reachable_node(Graph, Start, Node) :-
    map.search(Graph, Start, Neighbors),
    list.member(Next, Neighbors),
    reachable_node(Graph, Next, Node).
```

Then:
```mercury
solutions(reachable_node(Graph, Start), ReachableList),
set.from_list(ReachableList, Reachable).
```

`pragma loop_check` detects when `reachable_node(Graph, X, _)` is called while already
being evaluated for the same arguments — cutting the cycle rather than looping.

---

## Sample graph

```mercury
example_graph = map.from_assoc_list([
    "a" - ["b", "c"],
    "b" - ["d"],
    "c" - ["b", "e"],
    "d" - ["a"],    % cycle: a → b → d → a
    "e" - []
]).
```

Reachable from "a": {"a", "b", "c", "d", "e"}

---

---

## Acceptance criteria

| Start node | Expected reachable set | Notes |
|---|---|---|
| `"a"` | `{"a", "b", "c", "d", "e"}` | All nodes reachable via the cycle |
| `"e"` | `{"e"}` | Sink node, no outgoing edges |
| any node in the cycle | all 5 nodes | Cycle eventually reaches everything |
| non-existent node | empty set or no solutions | Graceful handling |

The manual visited-set approach (approach 1) should complete without infinite looping for
any start node in the sample graph.

**Task (grade exploration):** Build the `nondet` version twice — once with
`mmc --grade asm_fast.par.gc -o graph_par graph.m` and once with
`mmc --grade asm_fast.gc -o graph graph.m`. Run each on the cyclic graph.
What happens? The compiler emits a non-fatal warning for the parallel build —
read it carefully. Why is it only a warning, not an error? When would compiling
with a `.par` grade be the right choice, despite losing tabling?

## What to observe

Without `pragma loop_check` (or a manual visited set), the program loops on the `d → a`
cycle. With it, the cycle is detected and the looping call fails immediately.

Compare: how does the performance of approach 2 compare to approach 1 for large graphs?
(Tabling has overhead; for sparse graphs, the manual set may be faster.)
