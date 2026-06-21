:- module lambda_head_koan.
:- interface.
:- import_module io.
:- pred main(io::di, io::uo) is det.

:- implementation.

% BROKEN: `!IO` is used as a parameter in a lambda head, `pred(!IO) :- ...`.
% `!IO` stands for two implied parameters, and there is no syntax to give them
% their di/uo modes in a lambda head — so the compiler rejects it. Compile this
% and read the error.
main(!IO) :-
    greet(pred(!IO) :-
        io.write_string("Ahoy!\n", !IO)
    , !IO).

:- pred greet(pred(io, io)::in(pred(di, uo) is det), io::di, io::uo) is det.
greet(P, !IO) :-
    P(!IO).
