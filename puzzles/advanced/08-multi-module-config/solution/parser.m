:- module parser.

% Turns raw configuration text into key/value pairs. One "key = value" per
% line; blank lines and lines whose first non-blank character is '#' are
% ignored. A non-blank, non-comment line with no '=' is a syntax error,
% reported with its 1-based line number. No semantics are checked here — that
% is the validator's concern. This module only knows about lines and '='.

:- interface.

:- import_module assoc_list, list, string.

:- type parse_result
    --->    ok(assoc_list(string, string))
    ;       bad_line(int, string).

:- pred parse(list(string)::in, parse_result::out) is det.

:- implementation.

:- import_module int, pair.

parse(Lines, Result) :-
    parse_acc(Lines, 1, [], RevResult),
    ( RevResult = ok(Rev) ->
        Result = ok(list.reverse(Rev))
    ;
        RevResult = Result
    ).

    % Accumulate key/value pairs in source order; stop at the first bad line.
:- pred parse_acc(list(string)::in, int::in,
                  assoc_list(string, string)::in, parse_result::out) is det.
parse_acc([], _, Acc, ok(Acc)).
parse_acc([Line | Rest], LineNo, Acc, Result) :-
    Stripped = string.strip(Line),
    ( if ( Stripped = "" ; string.prefix(Stripped, "#") ) then
        parse_acc(Rest, LineNo + 1, Acc, Result)
    else if split_kv(Line, Key, Val) then
        parse_acc(Rest, LineNo + 1, [Key - Val | Acc], Result)
    else
        Result = bad_line(LineNo, Stripped)
    ).

    % Split on the FIRST '='; trim surrounding whitespace from each side.
:- pred split_kv(string::in, string::out, string::out) is semidet.
split_kv(Line, Key, Val) :-
    string.sub_string_search(Line, "=", Index),
    Key = string.strip(string.between(Line, 0, Index)),
    Val = string.strip(string.between(Line, Index + 1, string.length(Line))).
