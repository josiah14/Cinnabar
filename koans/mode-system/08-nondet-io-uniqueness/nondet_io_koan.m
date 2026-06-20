:- module nondet_io_koan.
:- interface.
:- import_module io.
:- pred main(io::di, io::uo) is det.

:- implementation.
:- import_module int.
:- import_module list.
:- import_module solutions.
:- import_module string.

% any_even/2 is nondet: it generates each even element from the list.
:- pred any_even(list(int)::in, int::out) is nondet.
any_even(List, X) :-
    list.member(X, List),
    X mod 2 = 0.

% BUG: any_even/2 is nondet. Using it as the condition of an if-then-else
% where !IO is threaded through the branches is rejected by the uniqueness
% checker: the unique IO token cannot be consumed once per solution of a
% nondet goal — unique values have exactly one owner.
:- pred report_even(list(int)::in, io::di, io::uo) is det.
report_even(List, !IO) :-
    ( any_even(List, X) ->
        io.format("first even: %d\n", [i(X)], !IO)
    ;
        io.write_string("no even numbers\n", !IO)
    ).

main(!IO) :-
    report_even([1, 3, 4, 7, 8], !IO).
