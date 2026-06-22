:- module start.
:- interface.
:- import_module io.
:- pred main(io::di, io::uo) is det.

:- implementation.
:- import_module bool.
:- import_module int.
:- import_module list.
:- import_module maybe.
:- import_module solutions.
:- import_module string.

% A function f(X) = Y is exactly `:- pred f(in, out) is det` with sugar for
% nesting in expressions. The choice between func and pred only starts to bite
% when the relation is NOT a total, single-valued function. These three cases
% make the consequence concrete: the relation drives the determinism, and the
% determinism drives the shape.

% --- Case 1: total + deterministic ----------------------------------------
% A genuine function. Composes directly inside an arithmetic expression.
:- func area(int, int) = int.
area(_W, _H) = 0.       % should be W * H

% --- Case 2: partial (can be undefined) -----------------------------------
% As a predicate the partiality is just `semidet`: the goal fails, no value.
:- pred safe_div(int::in, int::in, int::out) is semidet.
safe_div(N, D, N) :- D > 0.      % should fail when D = 0, else bind Q = N // D

% The same partiality as a FUNCTION forces a maybe-typed result, because a
% function must return a value for every input. Every caller now pattern-matches.
:- func checked_div(int, int) = maybe(int).
checked_div(_N, _D) = no.        % should be yes(N // D) when D \= 0, else no

% --- Case 3: multi-valued (relational) ------------------------------------
% No function can enumerate. Only a `nondet` predicate yields many solutions;
% the caller harvests them with `solutions`.
:- pred divides(int::in, int::out) is nondet.
divides(_N, F) :- list.member(F, []).    % should enumerate divisors of N

:- pred check(string::in, bool::in, io::di, io::uo) is det.
check(Name, yes, !IO) :- io.format("PASS: %s\n", [s(Name)], !IO).
check(Name, no,  !IO) :- io.format("FAIL: %s\n", [s(Name)], !IO).

main(!IO) :-
    check("area 3x4 = 12", ( area(3, 4) = 12 -> yes ; no ), !IO),
    check("safe_div 10/2 = 5", ( safe_div(10, 2, Q), Q = 5 -> yes ; no ), !IO),
    check("safe_div 1/0 fails", ( safe_div(1, 0, _) -> no ; yes ), !IO),
    check("checked_div 10/2 = yes(5)",
          ( checked_div(10, 2) = yes(5) -> yes ; no ), !IO),
    check("checked_div 1/0 = no",
          ( checked_div(1, 0) = no -> yes ; no ), !IO),
    solutions((pred(F::out) is nondet :- divides(12, F)), Fs),
    check("divisors of 12 = [1,2,3,4,6,12]",
          ( Fs = [1, 2, 3, 4, 6, 12] -> yes ; no ), !IO).
