:- module fixed.
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

:- pred pop(stack(T)::in, T::out, stack(T)::out) is semidet.
pop(node(Top, Rest), Top, Rest).

% 3-way if-then-else: pop/3 in a condition position where semidet is expected.
% Third branch is dead — is_empty and pop cover all constructors — but required
% for Mercury to infer det.
:- pred drain(stack(string)::in, io::di, io::uo) is det.
drain(S, !IO) :-
    ( is_empty(S) ->
        io.write_string("done\n", !IO)
    ; pop(S, Top, Rest) ->
        io.write_string(Top ++ "\n", !IO),
        drain(Rest, !IO)
    ;
        true  % unreachable
    ).

main(!IO) :-
    S = push("c", push("b", push("a", empty))),
    drain(S, !IO).
