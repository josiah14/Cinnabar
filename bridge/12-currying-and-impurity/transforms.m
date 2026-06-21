:- module transforms.
:- interface.
:- import_module io.
:- pred main(io::di, io::uo) is det.

:- implementation.
:- import_module float, list, string.

% Three general numeric transforms. Each takes its CONFIGURATION first and the
% value last — that argument order is what makes them curry-friendly (see the
% bridge tasks). None of them is specialised to a particular factor or range.

:- func scale(float, float) = float.
scale(Factor, X) = X * Factor.

:- func shift(float, float) = float.
shift(By, X) = X + By.

:- func clamp(float, float, float) = float.
clamp(Lo, Hi, X) =
    ( if X < Lo then Lo
    else if X > Hi then Hi
    else X
    ).

:- func sample = list(float).
sample = [0.2, 0.7, 1.5, -0.3, 0.9].

main(!IO) :-
    % A fixed two-step pipeline, written WITHOUT partial application: each step
    % wraps a general transform in a lambda that supplies the fixed config.
    Scaled  = list.map((func(X) = scale(2.0, X)), sample),
    Clamped = list.map((func(X) = clamp(0.0, 1.0, X)), Scaled),
    io.write_string("scaled by 2, clamped to [0,1]:\n", !IO),
    list.foldl(print_float, Clamped, !IO).

:- pred print_float(float::in, io::di, io::uo) is det.
print_float(X, !IO) :-
    io.format("  %.2f\n", [f(X)], !IO).
