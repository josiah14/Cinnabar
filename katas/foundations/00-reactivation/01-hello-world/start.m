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
% Create start_bang.m for the !IO version and start_explicit.m for the
% explicit version. Run runtests.bats to check both.
main(!IO) :-
    io.write_string("", !IO).
