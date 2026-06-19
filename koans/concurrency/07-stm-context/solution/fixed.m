:- module stm_context_koan.
:- interface.
:- import_module io.
:- pred main(io::di, io::uo) is det.

:- implementation.
:- import_module stm_builtin.

main(!IO) :-
    new_stm_var(42, Var, !IO),
    % FIX: read_stm_var runs in transaction context (!STM).
    % Wrap in atomic_transaction to create that context.
    atomic_transaction(
        (pred(Val::out, S0::di, S::uo) is det :-
            read_stm_var(Var, Val, S0, S)
        ), Result, !IO),
    io.write_line(Result, !IO).
