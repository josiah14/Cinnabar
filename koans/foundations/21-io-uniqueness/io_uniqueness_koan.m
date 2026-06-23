:- module io_uniqueness_koan.
:- interface.
:- import_module io.
:- pred main(io::di, io::uo) is det.

:- implementation.

% BROKEN: the same IO state variable, IO0, is handed to all three calls, and
% all three try to produce IO. Once the first io.write_string consumes IO0
% (its mode is `di`, destructive input), IO0 is dead — the mode system forbids
% referencing it again. Compile this and read the unique-mode error.
%
% FIXED: Since the Solution used ! notation, I decided to do it the tedious way.
main(IO, IO2) :-
    io.write_string("Hello, world!\n", IO, IO0),
    io.write_string("Hello, Mercury!\n", IO0, IO1),
    io.write_string("The world of Mercury says hello!\n", IO1, IO2).
