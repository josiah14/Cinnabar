:- module fixed.
:- interface.
:- import_module io.
:- pred main(io::di, io::uo) is det.

:- implementation.

% The lambda names its two IO parameters explicitly, with their di/uo modes,
% then threads them inside the body. `!IO` is only forbidden in the *head* of a
% lambda; everywhere else the sugar is fine, so the outer call still uses it.
main(!IO) :-
    greet((pred(IO0::di, IO::uo) is det :-
        io.write_string("Ahoy!\n", IO0, IO)
    ), !IO).

:- pred greet(pred(io, io)::in(pred(di, uo) is det), io::di, io::uo) is det.
greet(P, !IO) :-
    P(!IO).
