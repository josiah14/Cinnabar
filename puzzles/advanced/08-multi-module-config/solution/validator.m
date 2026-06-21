:- module validator.

% Semantic validation: turn parsed key/value pairs into an opaque `cfg.config`,
% or collect ALL the reasons it is invalid (not just the first). Required keys:
% host, port. Optional: verbose (default false). Any other key is rejected.
%
% This is the only module that mints a `cfg.config`. It reaches cfg through
% `use_module`, so every reference is qualified (`cfg.make`, `cfg.config`):
% the dependency on cfg is visible at every use site.

:- interface.

:- import_module assoc_list, list, string.
:- use_module cfg.

:- type validation
    --->    valid(cfg.config)
    ;       invalid(list(string)).   % every problem found, in a fixed order

:- pred validate(assoc_list(string, string)::in, validation::out) is det.

:- implementation.

:- import_module bool, int, maybe.

validate(Pairs, Result) :-
    check_host(Pairs, MaybeHost, HostErrs),
    check_port(Pairs, MaybePort, PortErrs),
    check_verbose(Pairs, Verbose, VerboseErrs),
    UnknownErrs = unknown_keys(Pairs),
    Errors = HostErrs ++ PortErrs ++ VerboseErrs ++ UnknownErrs,
    ( if
        Errors = [],
        MaybeHost = yes(Host),
        MaybePort = yes(Port)
    then
        Result = valid(cfg.make(Host, Port, Verbose))
    else
        Result = invalid(Errors)
    ).

:- pred check_host(assoc_list(string, string)::in,
                   maybe(string)::out, list(string)::out) is det.
check_host(Pairs, MaybeHost, Errs) :-
    ( if assoc_list.search(Pairs, "host", H) then
        MaybeHost = yes(H), Errs = []
    else
        MaybeHost = no, Errs = ["missing required key: host"]
    ).

:- pred check_port(assoc_list(string, string)::in,
                   maybe(int)::out, list(string)::out) is det.
check_port(Pairs, MaybePort, Errs) :-
    ( if assoc_list.search(Pairs, "port", PStr) then
        ( if string.to_int(PStr, P) then
            ( if P >= 1, P =< 65535 then
                MaybePort = yes(P), Errs = []
            else
                MaybePort = no,
                Errs = ["port out of range (1-65535): " ++ PStr]
            )
        else
            MaybePort = no,
            Errs = ["port is not an integer: " ++ PStr]
        )
    else
        MaybePort = no, Errs = ["missing required key: port"]
    ).

:- pred check_verbose(assoc_list(string, string)::in,
                      bool::out, list(string)::out) is det.
check_verbose(Pairs, Verbose, Errs) :-
    ( if assoc_list.search(Pairs, "verbose", VStr) then
        ( if VStr = "true" then
            Verbose = yes, Errs = []
        else if VStr = "false" then
            Verbose = no, Errs = []
        else
            Verbose = no,
            Errs = ["verbose must be true or false: " ++ VStr]
        )
    else
        Verbose = no, Errs = []
    ).

    % One "unknown key: K" error per key that is not host/port/verbose,
    % in source order.
:- func unknown_keys(assoc_list(string, string)) = list(string).
unknown_keys(Pairs) = Errs :-
    Keys = assoc_list.keys(Pairs),
    list.filter_map(
        ( pred(K::in, E::out) is semidet :-
            not known_key(K),
            E = "unknown key: " ++ K ),
        Keys, Errs).

:- pred known_key(string::in) is semidet.
known_key("host").
known_key("port").
known_key("verbose").
