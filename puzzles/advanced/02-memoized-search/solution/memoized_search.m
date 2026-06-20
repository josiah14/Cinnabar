:- module memoized_search.
:- interface.
:- import_module io.
:- pred main(io::di, io::uo) is det.

:- implementation.
:- import_module int.
:- import_module list.
:- import_module map.
:- import_module pair.
:- import_module solutions.
:- import_module string.

:- type node == string.
:- type graph == map(node, list(pair(node, int))).

%---------------------------------------------------------------------------%
% Path finder with memo to break cycles

:- pred path(graph::in, node::in, node::in,
             int::out, list(node)::out) is nondet.
:- pragma memo(path/5).

path(_, Start, Start, 0, [Start]).
path(Graph, Start, Goal, Cost, [Start | Rest]) :-
    Start \= Goal,
    map.search(Graph, Start, Neighbors),
    list.member(Next - EdgeCost, Neighbors),
    path(Graph, Next, Goal, RestCost, Rest),
    Cost = EdgeCost + RestCost.

%---------------------------------------------------------------------------%
% Find shortest among all paths

:- pred shortest_path(graph::in, node::in, node::in,
                      int::out, list(node)::out) is semidet.
shortest_path(Graph, Start, Goal, MinCost, BestPath) :-
    solutions(
        (pred(Cost - P :: out) is nondet :- path(Graph, Start, Goal, Cost, P)),
        AllPaths),
    AllPaths = [First | Rest],
    list.foldl(
        (pred(Cost - P::in, MC0 - MP0::in, MC - MP::out) is det :-
            ( Cost < MC0 -> MC = Cost, MP = P ; MC = MC0, MP = MP0 )),
        Rest, First, MinCost - BestPath).

%---------------------------------------------------------------------------%

:- func example_graph = graph.
example_graph = map.from_assoc_list([
    "a" - ["b" - 1, "c" - 4],
    "b" - ["c" - 2, "d" - 5],
    "c" - ["d" - 1],
    "d" - ["a" - 3]    % cycle: d → a
]).

main(!IO) :-
    G = example_graph,
    Queries = [{"a", "d"}, {"a", "c"}, {"d", "c"}, {"a", "a"}],
    list.foldl(
        (pred({Start, Goal}::in, !.IO::di, !:IO::uo) is det :-
            ( shortest_path(G, Start, Goal, Cost, Path) ->
                io.format("%s → %s: cost %d via %s\n",
                    [s(Start), s(Goal), i(Cost),
                     s(string.join_list(" → ", Path))], !IO)
            ;
                io.format("%s → %s: unreachable\n",
                    [s(Start), s(Goal)], !IO)
            )),
        Queries, !IO).
