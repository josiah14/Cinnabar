:- module fibonacci.


:- interface.

:- import_module io.

:- pred main(io::di, io::uo) is det.


:- implementation.

:- import_module bool.
:- import_module require.
:- import_module int.
:- import_module list.
:- import_module string.

% fib: the classic recursive definition.
% It is det — every non-negative integer has exactly one Fibonacci value.
:- pred fib(int::in, int::out) is det.
fib(N, O) :- (
    (N = 0 ; N = 1) -> O = N
  ; N > 1 -> fib(N-2, O0), fib(N-1, O1), O = O0 + O1
  ; error("fib cannot take negative numbers")
).

% Note that func is syntactic sugar for a deterministic pred that takes
% one input and produces one output, so the above could be written, thus:
:- func fib0(int) = int.
fib0(N) = (
    (N = 0 ; N = 1) -> N
    ; N > 1 -> fib0(N-2) + fib0(N-1)
    ; func_error("fib cannot take negative numbers")
).

% The below approach violates the deterministic requirement of the
% predicate. Mercury cannot valitade that this is not multideterminant
% because it cannot pattern match N > 1 or N < 0.
%
% :- pred fib0(int::in, int::out) is det.
% fib0(0, 0).   % stub: add base cases for 0 and 1; recurse for N > 1
% fib0(1, 1).
% fib0(N, O) :- (
%     N > 1 -> (
%         fib(N-2, O0),
%         fib(N-1, O1),
%         O = O0 + O1
%     )
%   ; error("fib cannot take negative numbers")
% ).

:- pred check(string::in, bool::in, io::di, io::uo) is det.
check(Name, yes, !IO) :- io.format("PASS: %s\n", [s(Name)], !IO).
check(Name, no,  !IO) :- io.format("FAIL: %s\n", [s(Name)], !IO).

main(!IO) :-
    check("fib(0) = 0",  ( fib(0, 0) -> yes ; no ), !IO),
    check("fib(1) = 1",  ( fib(1, 1) -> yes ; no ), !IO),
    check("fib(2) = 1",  ( fib(2, 1) -> yes ; no ), !IO),
    check("fib(5) = 5",  ( fib(5, 5) -> yes ; no ), !IO),
    check("fib(10) = 55", ( fib(10, 55) -> yes ; no ), !IO),
    check("fib0(0) = 0",  ( fib0(0) = 0 -> yes ; no ), !IO),
    check("fib0(1) = 1",  ( fib0(1) = 1 -> yes ; no ), !IO),
    check("fib0(2) = 1",  ( fib0(2) = 1 -> yes ; no ), !IO),
    check("fib0(5) = 5",  ( fib0(5) = 5 -> yes ; no ), !IO),
    check("fib0(10) = 55", ( fib0(10) = 55 -> yes ; no ), !IO).
