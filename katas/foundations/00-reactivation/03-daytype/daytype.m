:- module daytype.


:- interface.

:- import_module io.

:- pred main(io::di, io::uo) is det.


:- implementation.

:- import_module bool.
:- import_module list.
:- import_module string.
:- import_module char.

:- type day ---> mon ; tue ; wed ; thu ; fri ; sat ; sun.

% is_weekday: multi-clause (or if-then-else) function over a discriminated union.
% Each constructor of `day` should map to yes or no.
:- func is_weekday(day) = bool.
is_weekday(mon) = yes.
is_weekday(tue) = yes.
is_weekday(wed) = yes.
is_weekday(thu) = yes.
is_weekday(fri) = yes.
is_weekday(sat) = no.
is_weekday(sun) = no.

:- func day_name_from_shorthand(day) = string.
day_name_from_shorthand(D) = cap_first(string(D)) ++ "day".

:- func cap_first(string) = string.
cap_first(S) =
    ( if string.first_char(S, C, Rest)
      then string.from_char_list([char.to_upper(C)]) ++ Rest
      else S
    ).

% day_name: map a day to its string name (for display).
:- func day_name(day) = string.
day_name(N) = Fullname :-
    ( N = mon, Fullname = day_name_from_shorthand(N)
    ; N = tue, Fullname = "Tuesday"
    ; N = wed, Fullname = "Wednesday"
    ; N = thu, Fullname = "Thursday"
    ; N = fri, Fullname = day_name_from_shorthand(N)
    ; N = sat, Fullname = "Saturday"
    ; N = sun, Fullname = day_name_from_shorthand(N)
    ).

:- pred check(string::in, bool::in, io::di, io::uo) is det.
check(Name, yes, !IO) :- io.format("PASS: %s\n", [s(Name)], !IO).
check(Name, no,  !IO) :- io.format("FAIL: %s\n", [s(Name)], !IO).

main(!IO) :-
    check("mon is weekday",   ( is_weekday(mon) = yes -> yes ; no ), !IO),
    check("tue is weekday",   ( is_weekday(tue) = yes -> yes ; no ), !IO),
    check("wed is weekday",   ( is_weekday(wed) = yes -> yes ; no ), !IO),
    check("thu is weekday",   ( is_weekday(thu) = yes -> yes ; no ), !IO),
    check("fri is weekday",   ( is_weekday(fri) = yes -> yes ; no ), !IO),
    check("sat not weekday",  ( is_weekday(sat) = no  -> yes ; no ), !IO),
    check("sun not weekday",  ( is_weekday(sun) = no  -> yes ; no ), !IO),
    check("mon name",         ( day_name(mon) = "Monday" -> yes ; no ), !IO),
    check("tue name",         ( day_name(tue) = "Tuesday" -> yes ; no ), !IO),
    check("wed name",         ( day_name(wed) = "Wednesday" -> yes ; no ), !IO),
    check("thu name",         ( day_name(thu) = "Thursday" -> yes ; no ), !IO),
    check("fri name",         ( day_name(fri) = "Friday" -> yes ; no ), !IO),
    check("sat name",         ( day_name(sat) = "Saturday" -> yes ; no ), !IO),
    check("sun name",         ( day_name(sun) = "Sunday" -> yes ; no ), !IO).
