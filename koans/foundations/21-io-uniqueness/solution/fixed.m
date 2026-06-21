:- module fixed.
:- interface.
:- import_module io.
:- pred main(io::di, io::uo) is det.

:- implementation.

% Each call consumes one IO state and produces the next. The `!IO` sugar
% expands to exactly that chain of distinct variables (IO0, IO1, IO2, IO), so
% no token is ever referenced after it has been consumed.
main(!IO) :-
    io.write_string("Hello, world!\n", !IO),
    io.write_string("Hello, Mercury!\n", !IO),
    io.write_string("The world of Mercury says hello!\n", !IO).
