:- module config_parser.
:- interface.
:- import_module io.
:- import_module maybe.
:- import_module string.
:- pred main(io::di, io::uo) is det.
:- type config.
:- func parse_config(string) = config.
:- func get(config, string, string) = maybe(string).

:- implementation.
:- import_module int.
:- import_module list.
:- import_module map.
:- import_module pair.

%---------------------------------------------------------------------------%
% Abstract type

:- type config ---> config(map(string, map(string, string))).

%---------------------------------------------------------------------------%
% Parser

parse_config(Input) = config(SectionMap) :-
    Lines = string.split_at_char('\n', Input),
    parse_lines(Lines, "", map.init, SectionMap).

:- pred parse_lines(list(string)::in, string::in,
                    map(string, map(string, string))::in,
                    map(string, map(string, string))::out) is det.
parse_lines([], _, M, M).
parse_lines([Line | Lines], Section0, M0, M) :-
    Stripped = string.strip(Line),
    ( Stripped = "" ->
        parse_lines(Lines, Section0, M0, M)
    ; string.prefix(Stripped, "#") ->
        parse_lines(Lines, Section0, M0, M)
    ; is_section_header(Stripped, Section1) ->
        parse_lines(Lines, Section1, M0, M)
    ; is_key_value(Stripped, Key, Value) ->
        ( map.search(M0, Section0, SM0) ->
            map.set(Key, Value, SM0, SM1)
        ;
            map.from_assoc_list([Key - Value], SM1)
        ),
        map.set(Section0, SM1, M0, M1),
        parse_lines(Lines, Section0, M1, M)
    ;
        % Lenient policy (deliberate): a line that is none of the above — not
        % blank, comment, section header, or key=value — is skipped. This keeps
        % the parser robust to stray input, but it also means a malformed setting
        % such as "port 8080" (missing '=') is dropped silently. To surface such
        % lines instead, thread a list(string) of skipped lines through this fold
        % and return it alongside the config so the caller can report them.
        parse_lines(Lines, Section0, M0, M)
    ).

:- pred is_section_header(string::in, string::out) is semidet.
is_section_header(Line, Section) :-
    string.first_char(Line, '[', Rest),
    string.suffix(Rest, "]"),
    string.length(Rest, Len),
    string.left(Rest, Len - 1, Section),
    Section \= "".

:- pred is_key_value(string::in, string::out, string::out) is semidet.
is_key_value(Line, Key, Value) :-
    string.sub_string_search(Line, "=", Pos),
    string.left(Line, Pos, RawKey),
    string.right(Line, string.length(Line) - Pos - 1, RawValue),
    Key = string.strip(RawKey),
    Value = string.strip(RawValue),
    Key \= "".

%---------------------------------------------------------------------------%
% Accessor

get(config(M), Section, Key) = Result :-
    ( map.search(M, Section, SM), map.search(SM, Key, V) ->
        Result = yes(V)
    ;
        Result = no
    ).

%---------------------------------------------------------------------------%

main(!IO) :-
    Sample =
        "[database]\n" ++
        "host = localhost\n" ++
        "port = 5432\n" ++
        "\n" ++
        "[server]\n" ++
        "host = 0.0.0.0\n" ++
        "port = 8080\n" ++
        "# this is a comment\n" ++
        "debug = true\n",
    Config = parse_config(Sample),
    Queries = [
        {"database", "host"},
        {"database", "port"},
        {"server", "debug"},
        {"server", "missing_key"}
    ],
    list.foldl(
        (pred({Sec, Key}::in, !.IO::di, !:IO::uo) is det :-
            io.format("[%s] %s = %s\n",
                [s(Sec), s(Key), s(string.string(get(Config, Sec, Key)))], !IO)),
        Queries, !IO).
