:- module det_semidet_koan.
:- interface.
:- import_module io.
:- pred main(io::di, io::uo) is det.

:- implementation.
:- import_module string.

:- type stack(T) ---> empty ; node(T, stack(T)).

:- func push(T, stack(T)) = stack(T).
push(X, S) = node(X, S).

:- pred is_empty(stack(T)::in) is semidet.
is_empty(empty).

% pop/3 is semidet — it fails on an empty stack.
:- pred pop(stack(T)::in, T::out, stack(T)::out) is semidet.
pop(node(Top, Rest), Top, Rest).

% BUG: drain/3 is declared det. The else branch calls pop/3 which is semidet.
% Even though is_empty/1 failing implies the stack is non-empty, Mercury does
% not propagate that knowledge: pop/3 is seen as potentially failing, so the
% whole predicate is inferred semidet.
:- pred drain(stack(string)::in, io::di, io::uo) is det.
drain(S, !IO) :-
    ( is_empty(S) ->
        io.write_string("done\n", !IO)
    ;
        pop(S, Top, Rest),
        io.write_string(Top ++ "\n", !IO),
        drain(Rest, !IO)
    ).

main(!IO) :-
    S = push("c", push("b", push("a", empty))),
    drain(S, !IO).
