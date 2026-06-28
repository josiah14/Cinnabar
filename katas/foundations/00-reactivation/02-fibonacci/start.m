:- module start.
:- interface.
:- import_module io.
:- pred main(io::di, io::uo) is det.

:- implementation.
:- import_module bool.
:- import_module int.
:- import_module list.
:- import_module string.

% fib: the classic recursive definition.
% It is det — every non-negative integer has exactly one Fibonacci value.
:- func fib(int) = int.
fib(_) = 0.   % stub: add base cases for 0 and 1; recurse for N > 1

:- pred check(string::in, bool::in, io::di, io::uo) is det.
check(Name, yes, !IO) :- io.format("PASS: %s\n", [s(Name)], !IO).
check(Name, no,  !IO) :- io.format("FAIL: %s\n", [s(Name)], !IO).

main(!IO) :-
    check("fib(0) = 0",  ( fib(0)  = 0  -> yes ; no ), !IO),
    check("fib(1) = 1",  ( fib(1)  = 1  -> yes ; no ), !IO),
    check("fib(2) = 1",  ( fib(2)  = 1  -> yes ; no ), !IO),
    check("fib(5) = 5",  ( fib(5)  = 5  -> yes ; no ), !IO),
    check("fib(10) = 55", ( fib(10) = 55 -> yes ; no ), !IO).
