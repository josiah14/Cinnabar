:- module fixed.
:- interface.
:- import_module io.
:- pred main(io::di, io::uo) is det.

:- implementation.
:- import_module int.
:- import_module list.
:- import_module maybe.
:- import_module solutions.
:- import_module string.

% ---- runner ----------------------------------------------------------

:- pred check_property(string::in,
    pred(T)::in(pred(out) is nondet),
    pred(T)::in(pred(in) is semidet),
    io::di, io::uo) is det.
check_property(Name, Gen, Prop, !IO) :-
    solutions(Gen, Cases),
    find_counterexample(Prop, Cases, Result),
    (
        Result = no,
        io.format("PASS %s (%d cases)\n",
            [s(Name), i(list.length(Cases))], !IO)
    ;
        Result = yes(Counter),
        io.format("FAIL %s: counterexample = ", [s(Name)], !IO),
        io.write_line(Counter, !IO)
    ).

:- pred find_counterexample(pred(T)::in(pred(in) is semidet),
    list(T)::in, maybe(T)::out) is det.
find_counterexample(_, [], no).
find_counterexample(Prop, [X | Xs], Result) :-
    ( Prop(X) ->
        find_counterexample(Prop, Xs, Result)
    ;
        Result = yes(X)
    ).

% ---- generator (fixed) -----------------------------------------------

% FIX: declare nondet, and generate a range rather than one hard-coded value.
% A det generator produces exactly one test case — the property might pass for
% that one value while failing for many others. Generators must be nondet.
:- pred gen_small_int(int::out) is nondet.
gen_small_int(N) :- int.nondet_int_in_range(-10, 10, N).

% ---- property --------------------------------------------------------

:- pred prop_abs_nonneg(int::in) is semidet.
prop_abs_nonneg(N) :- int.abs(N) >= 0.

% ---- main -----------------------------------------------------------

main(!IO) :-
    check_property("prop_abs_nonneg", gen_small_int, prop_abs_nonneg, !IO).
