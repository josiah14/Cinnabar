:- module combinators.
:- interface.
:- import_module io.
:- pred main(io::di, io::uo) is det.

:- implementation.
:- import_module char.
:- import_module int.
:- import_module list.
:- import_module pair.
:- import_module string.

%---------------------------------------------------------------------------%
% Parser inst aliases

:- inst parser_det     == (pred(out, in, out) is det).
:- inst parser_semidet == (pred(out, in, out) is semidet).

%---------------------------------------------------------------------------%
% Base combinators — type and mode declarations kept separate where needed

:- pred pure(T, T, list(char), list(char)).
:- mode pure(in, out, in, out) is det.
pure(V, V, S, S).

:- pred empty(T, list(char), list(char)).
:- mode empty(out, in, out) is failure.
% A parser that never succeeds. The body must be `fail`, not an empty fact
% body: with `is failure` there is no success path, so the `out` result is
% legitimately never bound. An empty body `empty(_, _, _).` instead asserts the
% predicate succeeds, leaving that output `free` — a mode error, not `failure`.
empty(_, _, _) :- fail.

:- pred item(char, list(char), list(char)).
:- mode item(out, in, out) is semidet.
item(C, [C | Rest], Rest).

:- pred satisfy(pred(char), char, list(char), list(char)).
:- mode satisfy(in(pred(in) is semidet), out, in, out) is semidet.
satisfy(Pred, C, Input, Rest) :-
    item(C, Input, Rest),
    call(Pred, C).

%---------------------------------------------------------------------------%
% Sequence combinators

:- pred seq_det(pred(A, list(char), list(char)),
                pred(B, list(char), list(char)),
                pair(A, B), list(char), list(char)).
:- mode seq_det(in(parser_det), in(parser_det), out, in, out) is det.
seq_det(P, Q, A - B, Input, Rest) :-
    call(P, A, Input, Mid),
    call(Q, B, Mid, Rest).

:- pred seq_semidet(pred(A, list(char), list(char)),
                    pred(B, list(char), list(char)),
                    pair(A, B), list(char), list(char)).
:- mode seq_semidet(in(parser_semidet), in(parser_semidet), out, in, out) is semidet.
seq_semidet(P, Q, A - B, Input, Rest) :-
    call(P, A, Input, Mid),
    call(Q, B, Mid, Rest).

%---------------------------------------------------------------------------%
% Choice combinators

:- pred choice_det(pred(T, list(char), list(char)),
                   pred(T, list(char), list(char)),
                   T, list(char), list(char)).
:- mode choice_det(in(parser_det), in(parser_det), out, in, out) is det.
% Runs P only; Q is ignored. Unlike choice_semidet there is no fallback —
% a det parser always succeeds, so the second alternative is unreachable.
choice_det(P, _, V, Input, Rest) :-
    call(P, V, Input, Rest).

:- pred choice_semidet(pred(T, list(char), list(char)),
                       pred(T, list(char), list(char)),
                       T, list(char), list(char)).
:- mode choice_semidet(in(parser_semidet), in(parser_semidet), out, in, out) is semidet.
choice_semidet(P, Q, V, Input, Rest) :-
    ( call(P, V0, Input, Rest0) ->
        V = V0,
        Rest = Rest0
    ;
        call(Q, V, Input, Rest)
    ).

%---------------------------------------------------------------------------%
% Repetition

:- pred many(pred(T, list(char), list(char)), list(T), list(char), list(char)).
:- mode many(in(parser_semidet), out, in, out) is det.
many(P, Results, Input, Rest) :-
    ( call(P, V, Input, Mid) ->
        many(P, Vs, Mid, Rest),
        Results = [V | Vs]
    ;
        Results = [],
        Rest = Input
    ).

%---------------------------------------------------------------------------%
% Concrete parsers

% Consume one digit character.
:- pred digit(char, list(char), list(char)).
:- mode digit(out, in, out) is semidet.
digit(C, Input, Rest) :-
    satisfy(char.is_digit, C, Input, Rest).

% Consume as many digits as possible; always succeeds (zero or more).
:- pred digits(list(char), list(char), list(char)).
:- mode digits(out, in, out) is det.
digits(Cs, Input, Rest) :-
    many(satisfy(char.is_digit), Cs, Input, Rest).

% Parse a decimal integer. Succeeds with 0 if no digits are present.
:- pred number(int, list(char), list(char)).
:- mode number(out, in, out) is det.
number(N, Input, Rest) :-
    digits(Cs, Input, Rest),
    ( Cs = [] ->
        N = 0
    ;
        S = string.from_char_list(Cs),
        ( string.to_int(S, N0) ->
            N = N0
        ;
            N = 0
        )
    ).

% Match an exact string literal; fail if input does not start with Target.
:- pred literal(string, string, list(char), list(char)).
:- mode literal(in, out, in, out) is semidet.
literal(Target, Target, Input, Rest) :-
    string.to_char_list(Target, TargetChars),
    match_chars(TargetChars, Input, Rest).

:- pred match_chars(list(char), list(char), list(char)).
:- mode match_chars(in, in, out) is semidet.
match_chars([], Rest, Rest).
match_chars([C | Cs], [C | Input], Rest) :-
    match_chars(Cs, Input, Rest).

%---------------------------------------------------------------------------%

:- pred run_number(string::in, io::di, io::uo) is det.
run_number(S, !IO) :-
    number(N, string.to_char_list(S), Rest),
    io.format("\"%s\" => %d  remaining=\"%s\"\n",
        [s(S), i(N), s(string.from_char_list(Rest))], !IO).

main(!IO) :-
    io.write_string("=== number parser ===\n", !IO),
    run_number("123abc", !IO),
    run_number("abc", !IO),
    run_number("0", !IO),
    run_number("", !IO),

    io.nl(!IO),
    io.write_string("=== literal parser ===\n", !IO),
    Chars = string.to_char_list("hello world"),
    ( literal("hello", _, Chars, Rest) ->
        io.format("\"hello\" matched; remaining: \"%s\"\n",
            [s(string.from_char_list(Rest))], !IO)
    ;
        io.write_string("\"hello\" did not match\n", !IO)
    ),
    ( literal("world", _, Chars, _) ->
        io.write_string("\"world\" matched at start (unexpected)\n", !IO)
    ;
        io.write_string("\"world\" did not match at start (correct)\n", !IO)
    ),

    io.nl(!IO),
    io.write_string("=== seq_semidet: digit then digit ===\n", !IO),
    Chars2 = string.to_char_list("42x"),
    ( seq_semidet(digit, digit, A - B, Chars2, Rest2) ->
        io.format("first two digits: %c %c  remaining: \"%s\"\n",
            [c(A), c(B), s(string.from_char_list(Rest2))], !IO)
    ;
        io.write_string("no two digits\n", !IO)
    ).
