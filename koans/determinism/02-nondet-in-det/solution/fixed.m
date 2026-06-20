:- module fixed.
:- interface.
:- import_module io.
:- pred main(io::di, io::uo) is det.

:- implementation.
:- import_module int.
:- import_module list.
:- import_module solutions.

:- pred find_factor(int::in, int::out) is nondet.
find_factor(N, F) :-
    int.nondet_int_in_range(2, N - 1, F),
    N mod F = 0.

% solutions/2 runs the nondet find_factor in its own multi-solution context and
% gathers every factor into a list — a value the det caller can hold.
:- pred all_factors(int::in, list(int)::out) is det.
all_factors(N, Factors) :-
    solutions(find_factor(N), Factors).

main(!IO) :-
    all_factors(12, Fs),
    io.write_line(Fs, !IO).
