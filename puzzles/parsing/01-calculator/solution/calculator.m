:- module calculator.
:- interface.
:- import_module io.
:- pred main(io::di, io::uo) is det.

:- implementation.
:- import_module char.
:- import_module int.
:- import_module list.
:- import_module maybe.
:- import_module string.

%---------------------------------------------------------------------------%
% Tokens

:- type token ---> int_tok(int) ; plus ; minus ; star ; slash ; lparen ; rparen.

% Strict lexer: fails if any input is left untokenised. token_list stops at the
% first unrecognised character, so a non-empty remainder means the input contained
% something the lexer does not accept (e.g. "1 @ 2"). Failing here keeps such input
% from silently parsing as a prefix and returning a wrong answer.
:- pred tokenize(string::in, list(token)::out) is semidet.
tokenize(Input, Tokens) :-
    Chars = string.to_char_list(Input),
    tokens(Tokens, Chars, Rest),
    Rest = [].

:- pred tokens(list(token), list(char), list(char)).
:- mode tokens(out, in, out) is det.
tokens(Ts) --> whitespace, token_list(Ts).

% Deterministic chain: consume one token or terminate with []; no backtracking.
:- pred token_list(list(token), list(char), list(char)).
:- mode token_list(out, in, out) is det.
token_list(Ts) -->
    ( one_token(T) ->
        whitespace,
        token_list(Ts0),
        { Ts = [T | Ts0] }
    ;
        { Ts = [] }
    ).

% Maximal-munch tokenisation as a deterministic conditional chain.
:- pred one_token(token, list(char), list(char)).
:- mode one_token(out, in, out) is semidet.
one_token(T) -->
    ( ['+'] ->
        { T = plus }
    ; ['-'] ->
        { T = minus }
    ; ['*'] ->
        { T = star }
    ; ['/'] ->
        { T = slash }
    ; ['('] ->
        { T = lparen }
    ; [')'] ->
        { T = rparen }
    ; ( [D], { char.is_digit(D) } ) ->
        digits(Ds),
        { string.to_int(string.from_char_list([D | Ds]), N) },
        { T = int_tok(N) }
    ;
        { fail }
    ).

% Greedy: consume digit characters while available, succeed with [] otherwise.
:- pred digits(list(char), list(char), list(char)).
:- mode digits(out, in, out) is det.
digits(Ds) -->
    ( [D], { char.is_digit(D) } ->
        digits(Rest), { Ds = [D | Rest] }
    ;
        { Ds = [] }
    ).

% Skip any run of whitespace; always succeeds (zero or more).
:- pred whitespace(list(char), list(char)).
:- mode whitespace(in, out) is det.
whitespace -->
    ( [C], { char.is_whitespace(C) } ->
        whitespace
    ;
        { true }
    ).

%---------------------------------------------------------------------------%
% Parser (recursive descent via DCG, left-associative with accumulator)

:- pred expr(int, list(token), list(token)).
:- mode expr(out, in, out) is semidet.
expr(V) --> term(T), expr_rest(T, V).

% Left-associative +/- via a tail-recursive accumulator.
:- pred expr_rest(int, int, list(token), list(token)).
:- mode expr_rest(in, out, in, out) is semidet.
expr_rest(Acc, V) -->
    ( [plus] ->
        term(T), expr_rest(Acc + T, V)
    ; [minus] ->
        term(T), expr_rest(Acc - T, V)
    ;
        { V = Acc }
    ).

:- pred term(int, list(token), list(token)).
:- mode term(out, in, out) is semidet.
term(V) --> factor(F), term_rest(F, V).

% Left-associative */÷ via accumulator. Division guard: F \= 0 uses structural
% unification — Mercury's arithmetic has no =\=/2.
:- pred term_rest(int, int, list(token), list(token)).
:- mode term_rest(in, out, in, out) is semidet.
term_rest(Acc, V) -->
    ( [star] ->
        factor(F), term_rest(Acc * F, V)
    ; [slash] ->
        factor(F), { F \= 0 }, term_rest(Acc // F, V)
    ;
        { V = Acc }
    ).

% Parenthesised subexpressions, integer literals, and unary minus.
:- pred factor(int, list(token), list(token)).
:- mode factor(out, in, out) is semidet.
factor(V) -->
    ( [lparen] ->
        expr(V), [rparen]
    ; [int_tok(N)] ->
        { V = N }
    ; [minus] ->
        factor(F), { V = -F }
    ;
        { fail }
    ).

%---------------------------------------------------------------------------%
% Top-level

:- func calculate(string) = maybe(int).
calculate(Input) = Result :-
    ( tokenize(Input, Tokens), expr(V, Tokens, []) ->
        Result = yes(V)
    ;
        Result = no
    ).

main(!IO) :-
    Tests = [
        "3 + 4 * 2",          % 11 (not 14)
        "(3 + 4) * 2",        % 14
        "10 - 3 - 2",         % 5 (left-assoc)
        "100 / 10 / 2",       % 5 (left-assoc)
        "10 / 0",             % no
        "1 + ",               % no (parse error)
        "1 @ 2",              % no (invalid character — not yes(1))
        "-5 + 3"              % -2
    ],
    list.foldl(
        (pred(Expr::in, !.IO::di, !:IO::uo) is det :-
            ( calculate(Expr) = yes(V) ->
                io.format("%s = %d\n", [s(Expr), i(V)], !IO)
            ;
                io.format("%s = no\n", [s(Expr)], !IO)
            )),
        Tests, !IO).
