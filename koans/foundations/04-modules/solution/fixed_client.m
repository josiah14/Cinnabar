:- module fixed_client.
:- interface.
:- import_module io.
:- pred main(io::di, io::uo) is det.

:- implementation.
:- import_module fixed_utils.
:- import_module list.
:- import_module string.   % FIX: explicitly import what we use

main(!IO) :-
    fixed_utils.format_greeting("world", G),
    io.write_string(G ++ "\n", !IO),
    Len = string.length(G),
    io.format("Length: %d\n", [i(Len)], !IO).
