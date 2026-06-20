:- module nondet_koan.
:- interface.
:- import_module io.
:- pred main(io::di, io::uo) is det.

:- implementation.
:- import_module int.
:- import_module list.

:- pred find_factor(int::in, int::out) is nondet.
find_factor(N, F) :-
    int.nondet_int_in_range(2, N - 1, F),
    N mod F = 0.

% BUG: all_factors is declared det but calls the nondet predicate find_factor
% directly. find_factor can yield many factors (or none); a det context cannot
% hold that. Wrapping a single result in a list does not help — the call itself
% is nondet inside a det body. (Types match here on purpose, so the determinism
% error is the *only* error; the fix is solutions/2 to collect all factors.)
:- pred all_factors(int::in, list(int)::out) is det.
all_factors(N, Factors) :-
    find_factor(N, F),
    Factors = [F].

main(!IO) :-
    all_factors(12, Fs),
    io.write_line(Fs, !IO).
