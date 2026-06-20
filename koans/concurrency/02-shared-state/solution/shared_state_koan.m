:- module shared_state_koan.
:- interface.
:- import_module io.
:- pred main(io::di, io::uo) is det.
:- implementation.
:- import_module int.
:- import_module list.
:- import_module string.

:- func sum_to(int) = int.
sum_to(N) = ( N =< 0 -> 0 ; N + sum_to(N - 1) ).

% The parallel conjunction touches only pure values: A and B share no unique
% state, so & is safe here. The unique IO state is threaded sequentially after
% both computations finish — it is never handed to more than one branch.
main(!IO) :-
    ( A = sum_to(100) & B = sum_to(200) ),
    io.format("task A: %d\n", [i(A)], !IO),
    io.format("task B: %d\n", [i(B)], !IO).
