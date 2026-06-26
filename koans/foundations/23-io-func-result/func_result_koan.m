:- module func_result_koan.
:- interface.
:- import_module io.
:- pred main(io::di, io::uo) is det.

:- implementation.

main(!IO) :-
    io.write_string("Hello!\n", !IO),
    !:IO = hello(!.IO).

% BROKEN: `!IO` is used as a function result. `!IO` desugars to two variables,
% but a function returns a single value — so it cannot stand in the result
% position. Compile this and read the error.
%
% OBSERVATION: The compiler basically hands me the solution on a silver platter:
% "You probably meant !:IO" -> it's saying to just take the output IO var.
% We just need to make sure hello takes the input IO, via !.IO, and returns the
% output IO var, via !:IO. You can infer here I'm sure what . and : do for the
% !IO syntactic sugar.
:- func hello(io::di) = (io::uo) is det.
hello(!.IO) = !:IO :-
    io.write_string("Hi!\n", !IO).
