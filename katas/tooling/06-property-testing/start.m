:- module start.
:- interface.
:- import_module io.
:- pred main(io::di, io::uo) is det.

:- implementation.
:- import_module int.
:- import_module list.
:- import_module maybe.
:- import_module solutions.
:- import_module string.

% ---- runner (provided — read but do not modify) ----------------------

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

% ---- generators (TODO: implement these) ------------------------------

% Generate integers from -10 to 10.
% Use int.nondet_int_in_range/3 (Mercury 22's bounded integer generator).
:- pred gen_small_int(int::out) is nondet.
gen_small_int(_) :- fail.  % TODO

% Generate natural numbers from 0 to 20.
:- pred gen_nat(int::out) is nondet.
gen_nat(_) :- fail.  % TODO

% Generate integers from -3 to 3. Used inside gen_small_list.
:- pred gen_tiny_int(int::out) is nondet.
gen_tiny_int(_) :- fail.  % TODO

% Helper: generate a list of exactly Len integers using gen_tiny_int.
:- pred gen_list_aux(int::in, list(int)::out) is nondet.
gen_list_aux(_, []) :- fail.  % TODO: two clauses — base case and recursive case

% Generate all lists of length 0-3 with elements from gen_tiny_int.
:- pred gen_small_list(list(int)::out) is nondet.
gen_small_list(_) :- fail.  % TODO

% ---- properties (TODO: implement these) ------------------------------

% Holds when int.abs(N) >= 0. Should always pass.
:- pred prop_abs_nonneg(int::in) is semidet.
prop_abs_nonneg(_) :- fail.  % TODO

% Holds when N * 2 = N + N. Should always pass.
:- pred prop_double_add(int::in) is semidet.
prop_double_add(_) :- fail.  % TODO

% Holds when N > 0. Should fail for N =< 0.
:- pred prop_positive(int::in) is semidet.
prop_positive(_) :- fail.  % TODO

% Holds when list.length(list.reverse(Xs)) = list.length(Xs). Should always pass.
:- pred prop_reverse_length(list(int)::in) is semidet.
prop_reverse_length(_) :- fail.  % TODO

% Holds when no element appears more than once in the list.
% Fails (finds counterexample) when the list contains a duplicate.
:- pred prop_no_duplicates(list(int)::in) is semidet.
prop_no_duplicates(_) :- fail.  % TODO

% ---- main (TODO: wire generators to properties) ----------------------

main(!IO) :-
    % Call check_property five times:
    %   prop_abs_nonneg    against gen_small_int
    %   prop_double_add    against gen_small_int
    %   prop_positive      against gen_small_int
    %   prop_reverse_length against gen_small_list
    %   prop_no_duplicates  against gen_small_list
    io.write_string("TODO: call check_property\n", !IO).
