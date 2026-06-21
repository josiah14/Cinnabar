:- module cfg.

% An OPAQUE configuration value. Clients see the type name and the accessor
% functions, never the representation: they cannot pattern-match or construct a
% `config` except through `make/3`. This is Mercury's information hiding — the
% constructor lives only in the implementation section, so the record shape can
% change without touching any client.

:- interface.

:- import_module bool.

    % The representation is deliberately hidden: this is an abstract type
    % declaration (no `--->` in the interface).
:- type config.

    % make(Host, Port, Verbose) = Config.
    % Total over already-typed inputs. Semantic validation (required keys,
    % port range) is the validator's job, not the constructor's — make/3 only
    % promises that the result is a well-formed value of the abstract type.
:- func make(string, int, bool) = config.

:- func host(config) = string.
:- func port(config) = int.
:- func verbose(config) = bool.

:- implementation.

:- type config
    --->    config(
                cfg_host    :: string,
                cfg_port    :: int,
                cfg_verbose :: bool
            ).

make(Host, Port, Verbose) = config(Host, Port, Verbose).

host(C)    = C ^ cfg_host.
port(C)    = C ^ cfg_port.
verbose(C) = C ^ cfg_verbose.
