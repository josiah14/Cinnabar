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

% ---- account operations ----------------------------------------------

:- pred deposit(int::in, stm_var(int)::in, stm::di, stm::uo) is det.
deposit(Amount, Account, !STM) :-
    read_stm_var(Account, Balance, !STM),
    write_stm_var(Account, Balance + Amount, !STM).

:- pred withdraw(int::in, stm_var(int)::in, stm::di, stm::uo) is det.
withdraw(Amount, Account, !STM) :-
    read_stm_var(Account, Balance, !STM),
    write_stm_var(Account, Balance - Amount, !STM).

:- pred transfer(int::in, stm_var(int)::in, stm_var(int)::in,
    stm::di, stm::uo) is det.
transfer(Amount, From, To, !STM) :-
    withdraw(Amount, From, !STM),
    deposit(Amount, To, !STM).

% ---- advanced: conditional transfer with retry and or_else -----------

:- pred transfer_if_enough(int::in, stm_var(int)::in, stm_var(int)::in,
    stm::di, stm::uo) is det.
transfer_if_enough(Amount, From, To, !STM) :-
    read_stm_var(From, Balance, !STM),
    ( Balance >= Amount ->
        withdraw(Amount, From, !STM),
        deposit(Amount, To, !STM)
    ;
        retry(!.STM)
    ).

:- type transfer_result ---> transferred ; insufficient_funds.

:- pred safe_transfer(int::in, stm_var(int)::in, stm_var(int)::in,
    transfer_result::out, stm::di, stm::uo) is det.
safe_transfer(Amount, From, To, Result, !STM) :-
    or_else(
        (pred(transferred::out, S0::di, S::uo) is det :-
            transfer_if_enough(Amount, From, To, S0, S)),
        (pred(insufficient_funds::out, S0::di, S::uo) is det :-
            S = S0),
        Result, !STM).

% ---- main ------------------------------------------------------------

main(!IO) :-
    new_stm_var(1000, Savings, !IO),
    new_stm_var(0, Checking, !IO),

    % Transfer 500 from savings to checking
    atomic_transaction(
        (pred(unit::out, S0::di, S::uo) is det :-
            transfer(500, Savings, Checking, S0, S)
        ), _, !IO),

    % Deposit 200 into savings
    atomic_transaction(
        (pred(unit::out, S0::di, S::uo) is det :-
            deposit(200, Savings, S0, S)
        ), _, !IO),

    % Read final balances
    atomic_transaction(
        (pred(Sav::out, S0::di, S::uo) is det :-
            read_stm_var(Savings, Sav, S0, S)
        ), SaveBal, !IO),
    atomic_transaction(
        (pred(Chk::out, S0::di, S::uo) is det :-
            read_stm_var(Checking, Chk, S0, S)
        ), CheckBal, !IO),

    io.format("savings:  %d\n", [i(SaveBal)], !IO),
    io.format("checking: %d\n", [i(CheckBal)], !IO),

    % Try to transfer 600 from checking (balance is 500) — should block/fallback
    atomic_transaction(
        (pred(Result::out, S0::di, S::uo) is det :-
            safe_transfer(600, Checking, Savings, Result, S0, S)
        ), Outcome, !IO),
    (
        Outcome = transferred,
        io.write_string("transferred 600 from checking\n", !IO)
    ;
        Outcome = insufficient_funds,
        io.write_string("insufficient funds for 600 transfer\n", !IO)
    ),

    % Try to transfer 200 from checking (balance is still 500) — should succeed
    atomic_transaction(
        (pred(Result2::out, S0::di, S::uo) is det :-
            safe_transfer(200, Checking, Savings, Result2, S0, S)
        ), Outcome2, !IO),
    (
        Outcome2 = transferred,
        io.write_string("transferred 200 from checking to savings\n", !IO)
    ;
        Outcome2 = insufficient_funds,
        io.write_string("insufficient funds for 200 transfer\n", !IO)
    ).
