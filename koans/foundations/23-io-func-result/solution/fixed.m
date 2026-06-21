:- module fixed.
:- interface.
:- import_module io.
:- pred main(io::di, io::uo) is det.

:- implementation.

main(!IO) :-
    io.write_string("Hello!\n", !IO),
    !:IO = hello(!.IO).

% Name the IO states explicitly: the function takes one io (di) and returns the
% next (uo). `!IO` is forbidden only in the result position; explicit threading
% through a function compiles. (Idiomatically, IO-effecting code is usually a
% predicate — see the solution notes.)
:- func hello(io::di) = (io::uo) is det.
hello(IO0) = IO :-
    io.write_string("Hi!\n", IO0, IO).
