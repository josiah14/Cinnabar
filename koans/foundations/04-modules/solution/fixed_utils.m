:- module fixed_utils.
:- interface.

% FIX: use_module in interface — types available in signatures, names not re-exported
:- use_module string.

:- pred format_greeting(string::in, string::out) is det.

:- implementation.
:- import_module string.

format_greeting(Name, Greeting) :-
    Greeting = "Hello, " ++ Name ++ "!".
