# Puzzle: memoized shortest path

**Primary skills:** tabling (`pragma memo`), `nondet`, `solutions/2`, arithmetic, cycle handling

**Why Mercury:** shortest-path on a cyclic graph is the canonical example where naive
recursion loops and `pragma memo` is the correct fix. Tabling caches intermediate results
and breaks cycles simultaneously.

## Prerequisites

- `katas/tooling/04-tabling` — `pragma memo`, `pragma loop_check`, tabling semantics
- `katas/determinism/01-six-categories` — `nondet`, `solutions/2`
- `puzzles/data-structures/03-graph-reachability` — simpler cycle-breaking with `pragma loop_check`

---

## The problem

Find the shortest path between two nodes in a weighted directed graph. The graph may have
cycles.

Input: `graph` (weighted adjacency list), `start :: node`, `goal :: node`
Output: `maybe(pair(int, list(node)))` — shortest path cost + the path, or `no` if unreachable

---

## Representation

```mercury
:- type node == string.
:- type graph == map(node, list(pair(node, int))).  % node → [(neighbor, cost)]
```

---

## Naive approach (loops on cycles)

```mercury
:- pred path(graph::in, node::in, node::in, int::out, list(node)::out) is nondet.
path(_, Start, Start, 0, [Start]).
path(Graph, Start, Goal, Cost, [Start | Rest]) :-
    map.search(Graph, Start, Neighbors),
    list.member(Next - EdgeCost, Neighbors),
    path(Graph, Next, Goal, RestCost, Rest),
    Cost = EdgeCost + RestCost.
```

On a cyclic graph, `path` recurses infinitely. Without `pragma memo`, this loops.

---

## Memoized approach

```mercury
:- pragma memo(path/5).
```

`pragma memo` causes the first call to `path(Graph, Start, Goal, _, _)` to proceed
normally and cache each result. If the same call is made again while already in progress
(a cycle), it returns only the cached results so far — breaking the cycle.

Then find the shortest among all solutions:

```mercury
:- pred shortest_path(graph::in, node::in, node::in,
                      int::out, list(node)::out) is semidet.
shortest_path(Graph, Start, Goal, MinCost, BestPath) :-
    solutions(path(Graph, Start, Goal), Paths),
    Paths \= [],
    list.foldl(
        (pred(Cost-Path::in, MinC0-MinP0::in, MinC-MinP::out) is det :-
            ( Cost < MinC0 -> MinC = Cost, MinP = Path ; MinC = MinC0, MinP = MinP0 )),
        Paths, 999999 - [],
        MinCost - BestPath).
```

---

## Sample graph

```mercury
example = map.from_assoc_list([
    "a" - ["b" - 1, "c" - 4],
    "b" - ["c" - 2, "d" - 5],
    "c" - ["d" - 1],
    "d" - ["a" - 3]   % cycle back to a
]).
```

Shortest path from "a" to "d": a→b→c→d (cost 4), not a→c→d (cost 5), not a→b→d (cost 6).

---

---

## Acceptance criteria

With the sample graph, `shortest_path/5` should yield:

| Start | Goal | Expected cost | Expected path | Notes |
|---|---|---|---|---|
| `"a"` | `"d"` | 4 | `["a", "b", "c", "d"]` | a→b→c→d beats a→c→d (5) and a→b→d (6) |
| `"a"` | `"c"` | 3 | `["a", "b", "c"]` | via-b (1+2) beats direct (4) |
| `"d"` | `"c"` | 6 | `["d", "a", "b", "c"]` | must go through the cycle (3+1+2) |
| `"a"` | `"a"` | 0 | `["a"]` | zero-cost trivial path |
| `"x"` | `"y"` | `no` (fails) | — | unreachable → `shortest_path` fails |

**Task (grade exploration):** Build the memoized version twice — once with
`mmc --grade asm_fast.par.gc -o memo_par memoized_search.m` and once with
`mmc --grade asm_fast.gc -o memoized_search memoized_search.m`. Run each on
the cyclic graph. The compiler warns for the parallel build — read the warning.
Does `pragma loop_check` (from the graph-reachability puzzle) have the same
grade restriction? Are there tabling pragmas that *do* work with `.par` grades?

## What to observe

- Without `pragma memo`: the program loops on the `d → a` cycle
- With `pragma memo`: paths are found and the loop is broken
- Compare: how does performance scale with graph size vs naive Dijkstra?

## Note

`pragma memo` on a `nondet` predicate with a `graph` argument requires the graph to be
fully `ground` (which it is). The memo key is the full tuple of arguments.
