:- module start.
:- interface.
:- import_module io.
:- pred main(io::di, io::uo) is det.

:- implementation.

% TODO: make main print these four lines, in order:
%
%   Hello, World!
%   Hello, Mercury!!
%   IO token threaded: write_string 2
%   IO token threaded: write_string 3
%
% Thread the IO state through each io.write_string call. There are two
% idiomatic ways — explicit (IO0, IO1, IO2, ...) or the !IO sugar. Try both.
% This starter prints only the first line.
main(!IO) :-
    io.write_string("Hello, World!\n", !IO).
