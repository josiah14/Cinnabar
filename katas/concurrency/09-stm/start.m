:- module stm_kata.
:- interface.
:- import_module io.
:- pred main(io::di, io::uo) is det.

:- implementation.
:- import_module int.
:- import_module list.
:- import_module string.
:- import_module stm_builtin.
:- import_module unit.

% ---- account operations (TODO: implement these) ----------------------

% Add Amount to Account's balance.
:- pred deposit(int::in, stm_var(int)::in, stm::di, stm::uo) is det.
deposit(_Amount, _Account, !STM) :- true.  % TODO

% Subtract Amount from Account's balance.
:- pred withdraw(int::in, stm_var(int)::in, stm::di, stm::uo) is det.
withdraw(_Amount, _Account, !STM) :- true.  % TODO

% Move Amount from From to To atomically.
:- pred transfer(int::in, stm_var(int)::in, stm_var(int)::in,
    stm::di, stm::uo) is det.
transfer(_Amount, _From, _To, !STM) :- true.  % TODO: call withdraw then deposit

% ---- main (TODO: fill in the atomic_transaction calls) ---------------

main(!IO) :-
    new_stm_var(1000, Savings, !IO),
    new_stm_var(0, Checking, !IO),
    % TODO: transfer 500 from Savings to Checking
    % TODO: deposit 200 into Savings
    % TODO: read and print both balances
    io.write_string("TODO\n", !IO),
    _ = Savings,  % suppress unused warnings while incomplete
    _ = Checking.
