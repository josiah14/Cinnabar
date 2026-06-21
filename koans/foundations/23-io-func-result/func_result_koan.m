:- module func_result_koan.
:- interface.
:- import_module io.
:- pred main(io::di, io::uo) is det.

:- implementation.

main(!IO) :-
    io.write_string("Hello!\n", !IO).

% BROKEN: `!IO` is used as a function result. `!IO` desugars to two variables,
% but a function returns a single value — so it cannot stand in the result
% position. Compile this and read the error.
:- func hello(io::di) = (io::uo) is det.
hello(!IO) = !IO :-
    io.write_string("Hi!\n", !IO).
