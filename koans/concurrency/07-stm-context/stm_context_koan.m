:- module stm_context_koan.
:- interface.
:- import_module io.
:- pred main(io::di, io::uo) is det.

:- implementation.
:- import_module stm_builtin.

main(!IO) :-
    new_stm_var(42, Var, !IO),
    % BUG: read_stm_var expects stm::di, stm::uo — not io::di, io::uo.
    % There is no !STM in scope here; the transaction context is missing.
    read_stm_var(Var, Val, !IO),
    io.write_line(Val, !IO).
