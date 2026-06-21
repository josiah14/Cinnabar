:- module lambda_head.
:- interface.
:- import_module io.
:- pred main(io::di, io::uo) is det.

:- implementation.

% !IO in a lambda head is not allowed.
% Try to compile this and see the error.
main(!IO) :-
    greet(pred(!IO) :-
        io.write_string("Ahoy!\n", !IO)
    , !IO).

:- pred greet(pred(io, io)::in(pred(di, uo) is det), io::di, io::uo) is det.
greet(P, !IO) :-
    P(!IO).
