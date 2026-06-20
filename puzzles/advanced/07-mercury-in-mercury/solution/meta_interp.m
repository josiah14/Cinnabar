:- module meta_interp.
:- interface.
:- import_module io.
:- pred main(io::di, io::uo) is det.

:- implementation.
:- import_module int.
:- import_module list.
:- import_module pair.
:- import_module solutions.
:- import_module string.

%---------------------------------------------------------------------------%
% Term representation for the interpreted language

:- type term_t
    --->    atom(string)                    % atom("tom")
    ;       int_lit(int)                    % int_lit(42)
    ;       compound(string, list(term_t))  % compound("parent", [atom("tom"), atom("bob")])
    ;       logic_var(string).              % logic_var("X")

:- type env_t    == list(pair(string, term_t)).
:- type clause_t ---> rule(term_t, list(term_t)).  % head :- [body goals]
:- type prog_t   ---> prog(list(clause_t)).

%---------------------------------------------------------------------------%
% Variable renaming: append "_N" suffix to all variable names.
% Prevents capture when the same clause is used at multiple depths.

:- pred rename(term_t::in, string::in, term_t::out) is det.
rename(atom(S), _, atom(S)).
rename(int_lit(I), _, int_lit(I)).
rename(logic_var(X), Sfx, logic_var(X ++ "_" ++ Sfx)).
rename(compound(F, Args), Sfx, compound(F, RArgs)) :-
    list.map((pred(Arg::in, R::out) is det :- rename(Arg, Sfx, R)), Args, RArgs).

:- pred rename_clause(clause_t::in, string::in, clause_t::out) is det.
rename_clause(rule(Head, Body), Sfx, rule(RHead, RBody)) :-
    rename(Head, Sfx, RHead),
    list.map((pred(Arg::in, R::out) is det :- rename(Arg, Sfx, R)), Body, RBody).

%---------------------------------------------------------------------------%
% Environment lookup and dereferencing.

:- pred lookup_v(string::in, env_t::in, term_t::out) is semidet.
lookup_v(X, [Key - Val | Rest], T) :-
    ( X = Key -> T = Val ; lookup_v(X, Rest, T) ).

% Follow variable chains; stop at non-variable or unbound variable.
:- pred deref(term_t::in, env_t::in, term_t::out) is det.
deref(logic_var(X), Env, Out) :-
    ( lookup_v(X, Env, T) -> deref(T, Env, Out) ; Out = logic_var(X) ).
deref(atom(S), _, atom(S)).
deref(int_lit(I), _, int_lit(I)).
deref(compound(F, Args), _, compound(F, Args)).

%---------------------------------------------------------------------------%
% Unification.
% Uses a single if-then-else body to keep unify_d semidet — multiple clauses
% with overlapping variable patterns would be inferred nondet.

:- pred unify(term_t::in, term_t::in, env_t::in, env_t::out) is semidet.
unify(T1, T2, Env0, Env) :-
    deref(T1, Env0, D1),
    deref(T2, Env0, D2),
    unify_d(D1, D2, Env0, Env).

:- pred unify_d(term_t::in, term_t::in, env_t::in, env_t::out) is semidet.
unify_d(D1, D2, Env0, Env) :-
    ( D1 = logic_var(X) ->
        Env = [X - D2 | Env0]
    ; D2 = logic_var(X) ->
        Env = [X - D1 | Env0]
    ; D1 = atom(S), D2 = atom(S) ->
        Env = Env0
    ; D1 = int_lit(I), D2 = int_lit(I) ->
        Env = Env0
    ; D1 = compound(Fn, As1), D2 = compound(Fn, As2) ->
        unify_list(As1, As2, Env0, Env)
    ;
        fail
    ).

:- pred unify_list(list(term_t)::in, list(term_t)::in,
                   env_t::in, env_t::out) is semidet.
unify_list([], [], Env, Env).
unify_list([H1 | T1], [H2 | T2], Env0, Env) :-
    unify(H1, H2, Env0, Env1),
    unify_list(T1, T2, Env1, Env).

%---------------------------------------------------------------------------%
% Solver: SLD resolution.
%
% Depth is incremented at each resolve step and used as the rename suffix.
% Not globally unique (same depth can be reached via different paths) but
% correct for the demo programs that don't share variable names across rules.

:- pred solve(prog_t::in, list(term_t)::in, int::in,
              env_t::in, env_t::out) is nondet.
solve(_, [], _, Env, Env).
solve(Prog, [Goal | Rest], Depth, Env0, Env) :-
    resolve(Prog, Goal, Depth, Env0, Env1),
    solve(Prog, Rest, Depth + 1, Env1, Env).

:- pred resolve(prog_t::in, term_t::in, int::in,
                env_t::in, env_t::out) is nondet.
resolve(prog(Clauses), Goal0, Depth, Env0, Env) :-
    deref(Goal0, Env0, Goal),
    list.member(Raw, Clauses),
    rename_clause(Raw, string.int_to_string(Depth), rule(Head, Body)),
    unify(Goal, Head, Env0, Env1),
    solve(prog(Clauses), Body, Depth + 1, Env1, Env).

%---------------------------------------------------------------------------%
% Apply environment substitution — walk the term, replacing bound variables.

:- func apply_env(term_t, env_t) = term_t.
apply_env(atom(S), _)            = atom(S).
apply_env(int_lit(I), _)         = int_lit(I).
apply_env(compound(F, Args), E)  = compound(F, list.map((func(T) = apply_env(T, E)), Args)).
apply_env(logic_var(X), Env)     = T :-
    ( lookup_v(X, Env, T0) -> T = apply_env(T0, Env) ; T = logic_var(X) ).

%---------------------------------------------------------------------------%
% Pretty-printing terms.

:- func term_str(term_t) = string.
term_str(atom(S))           = S.
term_str(int_lit(I))        = string.int_to_string(I).
term_str(logic_var(X))      = "_" ++ X.
term_str(compound(F, Args)) = Result :-
    ( F = "[]", Args = [] ->
        Result = "[]"
    ; F = "[|]", Args = [H, T] ->
        Result = "[" ++ term_str(H) ++ list_tail_str(T)
    ;
        Result = F ++ "(" ++ string.join_list(", ", list.map(term_str, Args)) ++ ")"
    ).

:- func list_tail_str(term_t) = string.
list_tail_str(T) = Result :-
    ( T = compound("[]", []) ->
        Result = "]"
    ; T = compound("[|]", [H, TT]) ->
        Result = ", " ++ term_str(H) ++ list_tail_str(TT)
    ; T = logic_var(X) ->
        Result = "|_" ++ X ++ "]"
    ;
        Result = "|" ++ term_str(T) ++ "]"
    ).

%---------------------------------------------------------------------------%
% Demo programs

% parent(tom,bob). parent(bob,ann). parent(bob,pat).
% ancestor(X,Y) :- parent(X,Y).
% ancestor(X,Y) :- parent(X,Z), ancestor(Z,Y).

:- func ancestor_prog = prog_t.
ancestor_prog = prog([
    rule(compound("parent", [atom("tom"), atom("bob")]), []),
    rule(compound("parent", [atom("bob"), atom("ann")]), []),
    rule(compound("parent", [atom("bob"), atom("pat")]), []),
    rule(compound("ancestor", [logic_var("X"), logic_var("Y")]),
        [compound("parent", [logic_var("X"), logic_var("Y")])]),
    rule(compound("ancestor", [logic_var("X"), logic_var("Y")]),
        [compound("parent", [logic_var("X"), logic_var("Z")]),
         compound("ancestor", [logic_var("Z"), logic_var("Y")])])
]).

% app([],Y,Y).
% app([H|T],Y,[H|R]) :- app(T,Y,R).

:- func app_prog = prog_t.
app_prog = prog([
    rule(compound("app", [compound("[]", []), logic_var("Y"), logic_var("Y")]), []),
    rule(compound("app", [compound("[|]", [logic_var("H"), logic_var("T")]),
                          logic_var("Y"),
                          compound("[|]", [logic_var("H"), logic_var("R")])]),
        [compound("app", [logic_var("T"), logic_var("Y"), logic_var("R")])])
]).

:- func list_t(list(term_t)) = term_t.
list_t([])      = compound("[]", []).
list_t([H | T]) = compound("[|]", [H, list_t(T)]).

%---------------------------------------------------------------------------%

:- pred run_query(prog_t::in, term_t::in, string::in,
                  io::di, io::uo) is det.
run_query(Prog, Goal, Label, !IO) :-
    io.format("?- %s\n", [s(Label)], !IO),
    solutions(
        (pred(Env::out) is nondet :- solve(Prog, [Goal], 0, [], Env)),
        Envs),
    ( Envs = [] ->
        io.write_string("  false\n", !IO)
    ;
        list.foldl(
            (pred(Env::in, !.IO::di, !:IO::uo) is det :-
                Result = apply_env(Goal, Env),
                io.format("  %s\n", [s(term_str(Result))], !IO)),
            Envs, !IO)
    ).

main(!IO) :-
    io.write_string("=== ancestor/2 ===\n", !IO),
    run_query(ancestor_prog,
        compound("ancestor", [atom("tom"), logic_var("Who")]),
        "ancestor(tom, Who)", !IO),
    io.nl(!IO),
    run_query(ancestor_prog,
        compound("ancestor", [atom("bob"), logic_var("Who")]),
        "ancestor(bob, Who)", !IO),
    io.nl(!IO),
    run_query(ancestor_prog,
        compound("ancestor", [atom("ann"), logic_var("Who")]),
        "ancestor(ann, Who)", !IO),

    io.nl(!IO),
    io.write_string("=== append/3 ===\n", !IO),
    run_query(app_prog,
        compound("app", [list_t([int_lit(1), int_lit(2)]),
                         list_t([int_lit(3)]),
                         logic_var("Result")]),
        "app([1,2], [3], Result)", !IO),
    io.nl(!IO),
    run_query(app_prog,
        compound("app", [logic_var("A"), logic_var("B"),
                         list_t([int_lit(1), int_lit(2), int_lit(3)])]),
        "app(A, B, [1,2,3])", !IO).
