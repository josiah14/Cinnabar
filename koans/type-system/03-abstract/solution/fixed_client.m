:- module fixed_client.
:- interface.
:- import_module io.
:- pred main(io::di, io::uo) is det.

:- implementation.
:- import_module int.
:- import_module list.
:- import_module stack.
:- import_module string.

:- pred drain_stack(stack(int)::in, io::di, io::uo) is det.
drain_stack(S, !IO) :-
    ( stack.is_empty(S) ->
        io.write_string("(empty)\n", !IO)
    ; stack.pop(S, Top, Rest) ->
        io.format("%d\n", [i(Top)], !IO),
        drain_stack(Rest, !IO)
    ;
        true  % unreachable: is_empty/1 and pop/3 together cover all cases
    ).

main(!IO) :-
    S = stack.push(3, stack.push(2, stack.push(1, stack.empty))),
    drain_stack(S, !IO).
