:- module fixed.
:- interface.
:- import_module io.
:- pred main(io::di, io::uo) is det.

:- implementation.
:- import_module int.
:- import_module list.
:- import_module solutions.
:- import_module string.

:- pred any_even(list(int)::in, int::out) is nondet.
any_even(List, X) :-
    list.member(X, List),
    X mod 2 = 0.

% solutions/2 collects all results before IO begins. The pattern [X | _]
% makes the condition semidet — safe to thread unique !IO through.
:- pred report_even(list(int)::in, io::di, io::uo) is det.
report_even(List, !IO) :-
    ( solutions(any_even(List), [X | _]) ->
        io.format("first even: %d\n", [i(X)], !IO)
    ;
        io.write_string("no even numbers\n", !IO)
    ).

main(!IO) :-
    report_even([1, 3, 4, 7, 8], !IO).
