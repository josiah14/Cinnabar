:- module start.
:- interface.
:- import_module io.
:- pred main(io::di, io::uo) is det.

:- implementation.
:- import_module bool.
:- import_module int.
:- import_module list.
:- import_module string.

% ---- Exercise 1: read lines from a stream into a list ----------------------

% Read every line from an open stream into a list, in file order, with the
% trailing newline stripped. An IO error must travel out as error(_), never a
% truncated ok.
% Hint: io.read_line_as_string gives ok(Line) / eof / error(Err). Recurse on
% the stream; string.rstrip removes the trailing newline.
:- pred read_lines(io.text_input_stream::in, io.res(list(string))::out,
    io::di, io::uo) is det.
read_lines(_Stream, ok([]), !IO).   % stub: always returns an empty list

% ---- Exercise 2: open a named file, read it, close it ----------------------

% Open FileName, read all its lines with read_lines, then close the stream. If
% the open fails (missing file, permission denied, ...) return error(Err) — do
% not swallow it into an empty ok.
% Hint: io.open_input gives ok(Stream) / error(Err); pair it with io.close_input.
:- pred load_lines(string::in, io.res(list(string))::out,
    io::di, io::uo) is det.
load_lines(_FileName, ok([]), !IO).   % stub: ignores the file entirely

% ---- Exercise 3: pure post-processing --------------------------------------

% Count the non-blank lines. This is a *pure* function — no IO. The design
% lesson: read into a list once, then operate on it with ordinary pure code.
% Hint: list.filter out the "" lines, then list.length.
:- func count_nonblank(list(string)) = int.
count_nonblank(_Lines) = 0.   % stub

:- pred check(string::in, bool::in, io::di, io::uo) is det.
check(Name, yes, !IO) :- io.format("PASS: %s\n", [s(Name)], !IO).
check(Name, no,  !IO) :- io.format("FAIL: %s\n", [s(Name)], !IO).

main(!IO) :-
    % Set up a known fixture file, then exercise the read predicates on it.
    FixtureName = "io_kata_fixture.txt",
    io.open_output(FixtureName, OutRes, !IO),
    (
        OutRes = ok(OutStream),
        io.write_string(OutStream, "alpha\n\ngamma\n", !IO),
        io.close_output(OutStream, !IO),

        load_lines(FixtureName, LoadRes, !IO),
        (
            LoadRes = ok(Lines),
            check("load_lines: 3 lines",
                ( list.length(Lines) = 3 -> yes ; no ), !IO),
            check("load_lines: order [alpha, \"\", gamma]",
                ( Lines = ["alpha", "", "gamma"] -> yes ; no ), !IO),
            check("count_nonblank = 2",
                ( count_nonblank(Lines) = 2 -> yes ; no ), !IO)
        ;
            LoadRes = error(E1),
            check("load_lines: fixture readable", no, !IO),
            io.format("  (error: %s)\n", [s(io.error_message(E1))], !IO)
        ),

        % The error path: a file that does not exist must come back as error(_).
        load_lines("io_kata_missing_98765.txt", MissRes, !IO),
        check("load_lines: missing file -> error",
            ( MissRes = error(_) -> yes ; no ), !IO),

        io.remove_file(FixtureName, _RmRes, !IO)
    ;
        OutRes = error(E2),
        io.format("FAIL: could not create fixture: %s\n",
            [s(io.error_message(E2))], !IO)
    ).
