:- module io_uniqueness_koan.
:- interface.
:- import_module io.
:- pred main(io::di, io::uo) is det.

:- implementation.

% BROKEN: the same IO state variable, IO0, is handed to all three calls, and
% all three try to produce IO. Once the first io.write_string consumes IO0
% (its mode is `di`, destructive input), IO0 is dead — the mode system forbids
% referencing it again. Compile this and read the unique-mode error.
main(IO0, IO) :-
    io.write_string("Hello, world!\n", IO0, IO),
    io.write_string("Hello, Mercury!\n", IO0, IO),
    io.write_string("The world of Mercury says hello!\n", IO0, IO).
