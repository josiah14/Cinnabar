:- module plugins.
:- interface.
:- import_module io.
:- pred main(io::di, io::uo) is det.

:- implementation.
:- import_module int.
:- import_module list.
:- import_module string.

%---------------------------------------------------------------------------%
% The formatter typeclass: every plugin can name itself and transform a string.

:- typeclass formatter(T) where [
    func plugin_name(T) = string,
    func apply(T, string) = string
].

%---------------------------------------------------------------------------%
% The existential wrapper. Any formatter instance fits in one `plugin` box; the
% value carries its own typeclass dictionary, so the core system can call the
% methods on it without knowing the concrete type. This is the open-world part:
% a new plugin type plus its instance slots in without touching anything here.

:- type plugin
    --->    some [T] plugin(T) => formatter(T).

%---------------------------------------------------------------------------%
% Three concrete plugin types, each with its own formatter instance.
% `repeat` and `prefix` carry data — plugins are values, not just type tags.

:- type upper ---> upper.
:- instance formatter(upper) where [
    plugin_name(_) = "upper",
    apply(_, S) = string.to_upper(S)
].

:- type repeat ---> repeat(int).
:- instance formatter(repeat) where [
    plugin_name(repeat(N)) = "repeat(" ++ string.int_to_string(N) ++ ")",
    apply(repeat(N), S) = repeat_str(N, S)
].

:- type prefix ---> prefix(string).
:- instance formatter(prefix) where [
    plugin_name(prefix(P)) = "prefix(\"" ++ P ++ "\")",
    apply(prefix(P), S) = P ++ S
].

:- func repeat_str(int, string) = string.
repeat_str(N, S) = ( N =< 0 -> "" ; S ++ repeat_str(N - 1, S) ).

%---------------------------------------------------------------------------%
% Constructors. Building an existentially quantified value requires the
% `'new <ctor>'` syntax: bare `plugin(upper)` is a type error, because the
% argument slot has the existential type `(some [T] T)`, which will not unify
% with a concrete `upper`. `'new plugin'(...)` tells the compiler to introduce
% the fresh existential binding for T, inferred from the argument's type.
% (Deconstruction needs no `'new'` — see run_pipeline below.)

:- func mk_upper = plugin.
mk_upper = 'new plugin'(upper).

:- func mk_repeat(int) = plugin.
mk_repeat(N) = 'new plugin'(repeat(N)).

:- func mk_prefix(string) = plugin.
mk_prefix(P) = 'new plugin'(prefix(P)).

%---------------------------------------------------------------------------%
% Core system: thread the string through each plugin. Deconstructing
% `plugin(X)` in the clause head brings T — and its `formatter(T)` dictionary —
% back into scope, so the methods are callable on X.
%
% `apply` is module-qualified (`plugins.apply`) on purpose: Mercury reserves the
% unqualified name `apply` for higher-order application, so `apply(X, S)` with X
% a ground value reads as "call closure X on S" and fails to mode-check. Naming
% the method something other than `apply` would avoid the qualifier entirely.

:- pred run_pipeline(list(plugin)::in, string::in, io::di, io::uo) is det.
run_pipeline([], Final, !IO) :-
    io.format("  => final: \"%s\"\n", [s(Final)], !IO).
run_pipeline([plugin(X) | Rest], Input, !IO) :-
    Output = plugins.apply(X, Input),
    io.format("  [%s] \"%s\" => \"%s\"\n",
        [s(plugin_name(X)), s(Input), s(Output)], !IO),
    run_pipeline(Rest, Output, !IO).

%---------------------------------------------------------------------------%

main(!IO) :-
    io.write_string("=== formatter plugin pipeline ===\n", !IO),
    Pipeline = [
        mk_prefix(">> "),
        mk_upper,
        mk_repeat(2),
        mk_prefix("**")
    ],
    run_pipeline(Pipeline, "hello", !IO),

    io.nl(!IO),
    io.write_string("=== single-plugin runs ===\n", !IO),
    Plugins = [mk_upper, mk_repeat(3), mk_prefix("x: ")],
    list.foldl(
        (pred(P::in, !.IO::di, !:IO::uo) is det :-
            P = plugin(X),
            io.format("  %s(\"test\") = \"%s\"\n",
                [s(plugin_name(X)), s(plugins.apply(X, "test"))], !IO)),
        Plugins, !IO).
