:- module func_result.
:- interface.
:- import_module io.
:- pred main(io::di, io::uo) is det.

:- implementation.

main(!IO) :-
    io.write_string("Hello!\n", !IO).

% !IO as a function result is not allowed.
% Try to compile this and see the error.
:- func hello(io::di) = (io::uo) is det.
hello(!IO) = !IO :-
    io.write_string("Hi!\n", !IO).
