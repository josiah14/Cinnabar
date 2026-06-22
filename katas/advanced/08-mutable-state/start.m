:- module start.
:- interface.
:- import_module io.
:- pred main(io::di, io::uo) is det.

:- implementation.
:- import_module bool.
:- import_module int.
:- import_module list.
:- import_module store.
:- import_module string.

% Mercury has no implicit mutable cell. A genuinely mutable reference lives in a
% `store(S)` — a typed heap that is threaded `di`/`uo` so the compiler can prove
% there is never more than one live version of it. You read and write through
% `generic_mutvar` handles. The store is the state; the handles are values.

% --- A private store, threaded as !S -----------------------------------------
% Sum a list by allocating one mutable accumulator and writing through it.
:- pred sum_store(list(int)::in, int::out) is det.
sum_store(Xs, Total) :-
    store.init(S0),
    store.new_mutvar(0, Acc, S0, S1),
    add_all(Xs, Acc, S1, S2),
    store.get_mutvar(Acc, Total, S2, _S3).

% S is the store-state type, declared exactly as the library declares its own
% operations; at the call site it unifies with the store store.init produced.
% The `<= store.store(S)` constraint is what makes the get/set calls type-check.
:- pred add_all(list(int), store.generic_mutvar(int, S), S, S) <= store.store(S).
:- mode add_all(in, in, di, uo) is det.
add_all(_Xs, _Acc, !S).     % should walk Xs, adding each element into Acc

% --- The io.state IS a store -------------------------------------------------
% An io_mutvar is a handle whose store is the IO state itself; the same
% new/get/set operations thread `!IO` instead of a private `!S`.
:- pred bump_twice(int::out, io::di, io::uo) is det.
bump_twice(Final, !IO) :-
    store.new_mutvar(0, Ref, !IO),
    store.get_mutvar(Ref, Final, !IO).   % should set/read so Final ends at 2

:- pred check(string::in, bool::in, io::di, io::uo) is det.
check(Name, yes, !IO) :- io.format("PASS: %s\n", [s(Name)], !IO).
check(Name, no,  !IO) :- io.format("FAIL: %s\n", [s(Name)], !IO).

main(!IO) :-
    sum_store([3, 4, 5, 6], Total),
    check("sum_store [3,4,5,6] = 18", ( Total = 18 -> yes ; no ), !IO),
    bump_twice(N, !IO),
    check("io mutvar bumped to 2", ( N = 2 -> yes ; no ), !IO).
