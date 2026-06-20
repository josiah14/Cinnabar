:- module csv_reader.
:- interface.
:- import_module io.
:- pred main(io::di, io::uo) is det.

:- implementation.
:- import_module char.
:- import_module list.
:- import_module maybe.
:- import_module string.

%---------------------------------------------------------------------------%
% Types

:- type row == list(string).
:- type csv == list(row).

%---------------------------------------------------------------------------%
% DCG parser — multiple clauses → nondet; rewritten with if-then-else throughout

:- pred parse_csv(csv, list(char), list(char)).
:- mode parse_csv(out, in, out) is det.
parse_csv(Rows) -->
    ( row(Row) ->
        ( newline ->
            parse_csv(Rest), { Rows = [Row | Rest] }
        ;
            { Rows = [Row] }
        )
    ;
        { Rows = [] }
    ).

:- pred newline(list(char), list(char)).
:- mode newline(in, out) is semidet.
newline -->
    ( ['\r'] ->
        ['\n']
    ;
        ['\n']
    ).

:- pred row(row, list(char), list(char)).
:- mode row(out, in, out) is semidet.
row(Fields) -->
    field(F),
    ( [','] ->
        row(Fs), { Fields = [F | Fs] }
    ;
        { Fields = [F] }
    ).

:- pred field(string, list(char), list(char)).
:- mode field(out, in, out) is semidet.
field(S) -->
    ( ['"'] ->
        quoted_chars(Cs), ['"'],
        { S = string.from_char_list(Cs) }
    ;
        unquoted_chars(Cs),
        % strip is a design choice: trims leading/trailing whitespace from
        % unquoted fields. RFC 4180 does not require this; omit if you need
        % whitespace-preserving CSV.
        { S = string.strip(string.from_char_list(Cs)) }
    ).

:- pred quoted_chars(list(char), list(char), list(char)).
:- mode quoted_chars(out, in, out) is det.
quoted_chars(Cs) -->
    ( ['"'], ['"'] ->
        quoted_chars(Rest), { Cs = ['"' | Rest] }
    ; [C], { C \= '"' } ->
        quoted_chars(Rest), { Cs = [C | Rest] }
    ;
        { Cs = [] }
    ).

:- pred unquoted_chars(list(char), list(char), list(char)).
:- mode unquoted_chars(out, in, out) is det.
unquoted_chars(Cs) -->
    ( [C], { C \= (','), C \= ('\n'), C \= ('\r') } ->
        unquoted_chars(Rest), { Cs = [C | Rest] }
    ;
        { Cs = [] }
    ).

%---------------------------------------------------------------------------%
% Top-level — strict. parse_csv stops at the first row it cannot parse and
% returns the rows so far, leaving the unparsed remainder in Rest. Requiring
% Rest = [] turns a malformed row into `no` instead of silently truncating the
% file at that point (treating a parse failure as end-of-input).

:- func parse(string) = maybe(csv).
parse(Input) = Result :-
    Chars = string.to_char_list(Input),
    parse_csv(Rows, Chars, Rest),
    ( Rest = [] ->
        Result = yes(Rows)
    ;
        Result = no
    ).

:- pred show(string::in, io::di, io::uo) is det.
show(Input, !IO) :-
    Result = parse(Input),
    (
        Result = yes(Rows),
        io.write_string("ok:\n", !IO),
        list.foldl(
            (pred(Row::in, !.IO::di, !:IO::uo) is det :-
                io.write_string("  ", !IO), io.write_line(Row, !IO)),
            Rows, !IO)
    ;
        Result = no,
        io.write_string("parse error (malformed input)\n", !IO)
    ).

main(!IO) :-
    Good = "name,age,city\nAlice,30,\"New York\"\nBob,25,\"San Francisco, CA\"\n",
    Bad  = "name,age\nAlice,\"unterminated",
    show(Good, !IO),
    io.nl(!IO),
    show(Bad, !IO).
