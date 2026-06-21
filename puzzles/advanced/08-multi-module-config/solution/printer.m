:- module printer.

% Renders a config back to canonical "key = value" text. It imports cfg via
% `use_module`, so it can name the `config` type but reaches its contents ONLY
% through the exported accessors — it cannot pattern-match the representation.
% That is the payoff of the opaque type: the printer is decoupled from cfg's
% internal record shape, and would not need editing if cfg switched, say, to a
% map-backed representation.

:- interface.

:- import_module string.
:- use_module cfg.

:- func render(cfg.config) = string.

:- implementation.

:- import_module bool.

render(C) =
    "host = "    ++ cfg.host(C) ++ "\n" ++
    "port = "    ++ string.int_to_string(cfg.port(C)) ++ "\n" ++
    "verbose = " ++ bool_str(cfg.verbose(C)) ++ "\n".

:- func bool_str(bool) = string.
bool_str(yes) = "true".
bool_str(no)  = "false".
