:- module shared_state_koan.
:- interface.
:- import_module io.
:- pred main(io::di, io::uo) is det.
:- implementation.

% Two parallel tasks, both handed the SAME unique IO state (IO0).
%
% Normally you write `!IO`, and Mercury threads the IO state through the
% conjuncts one after another — so `( ... !IO & ... !IO )` compiles, but the
% data dependency makes it run sequentially. To genuinely ask both branches to
% share one IO state we have to name it: IO0 is passed to BOTH writes below.
%
% io.state is unique — only one goal may consume it. The uniqueness checker
% rejects the sharing statically, before anything runs.
main(IO0, IO) :-
    (
        io.write_string("task A\n", IO0, IO)
    &
        io.write_string("task B\n", IO0, _IOb)
    ).
