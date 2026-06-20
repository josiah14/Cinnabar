:- module start.
:- interface.
:- import_module io.
:- pred main(io::di, io::uo) is det.

:- implementation.
:- import_module bool.
:- import_module int.
:- import_module list.
:- import_module string.

% ---------------------------------------------------------------
% FFI pragma attributes — understanding the combination
% ---------------------------------------------------------------
%
% Three attributes apply to nearly all simple C utility functions:
%
%   will_not_call_mercury
%     The C code never calls back into Mercury. The runtime skips the
%     reentrancy lock. OMITTING IT: per-call engine mutex acquisition.
%
%   promise_pure
%     Declare the proc as pure (usable in pure Mercury contexts).
%     OMITTING IT: compile error — foreign proc is impure.
%
%   thread_safe
%     The C code does not rely on Mercury's global engine state.
%     OMITTING IT: per-call thread lock acquisition.
%
% The canonical combination for simple pure C utility functions:
%   [will_not_call_mercury, promise_pure, thread_safe]
%
% ---------------------------------------------------------------

% Task 1: c_abs — fill in the correct pragma attribute list.
%
% The C body is correct: Abs = (N < 0) ? -N : N.
% Add will_not_call_mercury, promise_pure, and thread_safe.
% Without promise_pure, the compiler rejects the declaration.

:- pred c_abs(int::in, int::out) is det.
:- pragma foreign_proc("C",
    c_abs(N::in, Abs::out),
    [promise_pure],  % TODO: add will_not_call_mercury and thread_safe
    "Abs = (N < 0) ? -N : N;").

% Task 2: c_clamp — clamp N to the range [Lo, Hi].
%
% Complete the foreign_proc declaration with the correct attributes
% and fill in the C body.
% Expected: c_clamp(15, 0, 10, Clamped) gives Clamped = 10.

:- pred c_clamp(int::in, int::in, int::in, int::out) is det.
:- pragma foreign_proc("C",
    c_clamp(N::in, Lo::in, Hi::in, Clamped::out),
    [promise_pure],  % TODO: add will_not_call_mercury and thread_safe
    "/* TODO: Clamped = N < Lo ? Lo : N > Hi ? Hi : N; */
     Clamped = 0;").

% Task 3 (reading exercise — no code change):
%
% c_with_mercury_callback invokes a Mercury predicate from C via a
% function pointer. Explain in a comment below WHY will_not_call_mercury
% must NOT be used here, even though the C code itself is simple.

% ANSWER:
% will_not_call_mercury must NOT be used when the C code calls back into Mercury.
% TODO: replace this stub comment with your own explanation.

% ---------------------------------------------------------------

:- pred check(string::in, bool::in, io::di, io::uo) is det.
check(Name, yes, !IO) :- io.format("PASS: %s\n", [s(Name)], !IO).
check(Name, no,  !IO) :- io.format("FAIL: %s\n", [s(Name)], !IO).

main(!IO) :-
    c_abs(-7, A1),
    check("abs(-7) = 7",   ( A1 = 7 -> yes ; no ), !IO),
    c_abs(3, A2),
    check("abs(3) = 3",    ( A2 = 3 -> yes ; no ), !IO),
    c_clamp(15, 0, 10, C1),
    check("clamp(15,0,10) = 10", ( C1 = 10 -> yes ; no ), !IO),
    c_clamp(-1, 0, 10, C2),
    check("clamp(-1,0,10) = 0",  ( C2 = 0  -> yes ; no ), !IO),
    c_clamp(5, 0, 10, C3),
    check("clamp(5,0,10) = 5",   ( C3 = 5  -> yes ; no ), !IO).
