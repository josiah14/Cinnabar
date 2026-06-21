:- module config_demo.

% The top module. Wires the four library modules into one pipeline:
%
%   raw lines --parser--> key/value pairs --validator--> opaque cfg.config
%                                                  \----> list of errors
%   cfg.config --printer--> canonical text
%
% Build it as a multi-module program (all .m files in this directory):
%
%   mmc --make --grade asm_fast.par.gc.stseg config_demo
%
% `--make` reads each module's interface, computes the dependency graph
% (config_demo -> parser, validator, printer; validator, printer -> cfg) and
% compiles bottom-up. Only this module has a `main/2`; the others are
% libraries, compiled because they are imported.

:- interface.

:- import_module io.

:- pred main(io::di, io::uo) is det.

:- implementation.

:- import_module list, string.
:- import_module parser, validator, printer.
:- use_module cfg.

main(!IO) :-
    run("sample A (valid)", sample_a, !IO),
    io.nl(!IO),
    run("sample B (semantic errors)", sample_b, !IO),
    io.nl(!IO),
    run("sample C (syntax error)", sample_c, !IO).

:- pred run(string::in, list(string)::in, io::di, io::uo) is det.
run(Label, Lines, !IO) :-
    io.format("=== %s ===\n", [s(Label)], !IO),
    parser.parse(Lines, PResult),
    (
        PResult = parser.bad_line(LineNo, Content),
        io.format("parse error on line %d: %s\n", [i(LineNo), s(Content)], !IO)
    ;
        PResult = parser.ok(Pairs),
        validator.validate(Pairs, VResult),
        (
            VResult = validator.valid(Config),
            io.write_string("parsed and validated OK:\n", !IO),
            io.write_string(printer.render(Config), !IO)
        ;
            VResult = validator.invalid(Errors),
            io.write_string("parsed OK, but validation failed:\n", !IO),
            list.foldl(
                ( pred(E::in, !.IO::di, !:IO::uo) is det :-
                    io.format("  - %s\n", [s(E)], !IO) ),
                Errors, !IO)
        )
    ).

:- func sample_a = list(string).
sample_a = [
    "# web server config",
    "host = localhost",
    "port = 8080",
    "verbose = true"
].

:- func sample_b = list(string).
sample_b = [
    "host = example.com",
    "port = 99999",
    "debug = yes"
].

:- func sample_c = list(string).
sample_c = [
    "host = localhost",
    "this line has no equals",
    "port = 80"
].
