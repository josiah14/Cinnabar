:- module sudoku.
:- interface.
:- import_module io.
:- pred main(io::di, io::uo) is det.

:- implementation.
:- import_module int.
:- import_module list.
:- import_module solutions.

:- type grid == list(list(int)).

:- func drop_n(int, list(T)) = list(T).
drop_n(N, List) =
    ( N =< 0 -> List ; List = [_ | Rest] -> drop_n(N - 1, Rest) ; [] ).

:- func example_puzzle = grid.
example_puzzle = [
    [5, 3, 0, 0, 7, 0, 0, 0, 0],
    [6, 0, 0, 1, 9, 5, 0, 0, 0],
    [0, 9, 8, 0, 0, 0, 0, 6, 0],
    [8, 0, 0, 0, 6, 0, 0, 0, 3],
    [4, 0, 0, 8, 0, 3, 0, 0, 1],
    [7, 0, 0, 0, 2, 0, 0, 0, 6],
    [0, 6, 0, 0, 0, 0, 2, 8, 0],
    [0, 0, 0, 4, 1, 9, 0, 0, 5],
    [0, 0, 0, 0, 8, 0, 0, 7, 9]
].

:- pred solve(grid::in, grid::out) is nondet.
solve(Grid, Solution) :-
    fill_cells(Grid, Solution).

:- pred fill_cells(grid::in, grid::out) is nondet.
fill_cells(Grid, Solved) :-
    ( first_empty(Grid, R, C) ->
        int.nondet_int_in_range(1, 9, D),
        set_cell(Grid, R, C, D, Grid1),
        valid_so_far(Grid1, R, C),
        fill_cells(Grid1, Solved)
    ;
        Solved = Grid
    ).

% Recursive descent so first_empty is semidet: nth_member would be nondet.
:- pred first_empty(grid::in, int::out, int::out) is semidet.
first_empty(Grid, R, C) :-
    first_empty_row(Grid, 1, R, C).

:- pred first_empty_row(grid::in, int::in, int::out, int::out) is semidet.
first_empty_row([Row | Rows], RowNum, R, C) :-
    ( first_zero(Row, 1, C0) ->
        R = RowNum, C = C0
    ;
        first_empty_row(Rows, RowNum + 1, R, C)
    ).

:- pred first_zero(list(int)::in, int::in, int::out) is semidet.
first_zero([V | Rest], N, C) :-
    ( V = 0 ->
        C = N
    ;
        first_zero(Rest, N + 1, C)
    ).

% Returns unchanged grid on out-of-bounds (dead branch in practice — the solver
% only calls this with valid (R, C) coordinates within a 9×9 grid).
:- pred set_cell(grid::in, int::in, int::in, int::in, grid::out) is det.
set_cell(Grid, R, C, D, Result) :-
    ( Grid = [] ->
        Result = []
    ; Grid = [Row | Rows], R = 1 ->
        set_nth(Row, C, D, NewRow),
        Result = [NewRow | Rows]
    ; Grid = [Row | Rows] ->
        set_cell(Rows, R - 1, C, D, NewRows),
        Result = [Row | NewRows]
    ;
        Result = []
    ).

% Returns [] on out-of-bounds; safe because set_cell only calls this with a
% valid column index C within a 9-element row.
:- pred set_nth(list(int)::in, int::in, int::in, list(int)::out) is det.
set_nth(List, N, V, Result) :-
    ( List = [_ | T], N = 1 ->
        Result = [V | T]
    ; List = [H | T] ->
        set_nth(T, N - 1, V, T2),
        Result = [H | T2]
    ;
        Result = []
    ).

:- pred valid_so_far(grid::in, int::in, int::in) is semidet.
valid_so_far(Grid, R, C) :-
    get_row(Grid, R, Row), no_dups(Row),
    get_col(Grid, C, Col), no_dups(Col),
    get_box(Grid, R, C, Box), no_dups(Box).

:- pred no_dups(list(int)::in) is semidet.
no_dups(Vs) :-
    list.filter((pred(V::in) is semidet :- V \= 0), Vs, Nz),
    list.sort(Nz, S),
    list.remove_dups(S, D),
    list.length(Nz, LenNz),
    list.length(D, LenD),
    LenNz = LenD.

% Returns [] on out-of-bounds; safe because valid_so_far only calls this with
% row indices produced by first_empty, which are always within 1–9.
:- pred get_row(grid::in, int::in, list(int)::out) is det.
get_row(Grid, N, Row) :-
    ( Grid = [R | _], N = 1 ->
        Row = R
    ; Grid = [_ | Rs] ->
        get_row(Rs, N - 1, Row)
    ;
        Row = []
    ).

:- pred get_col(grid::in, int::in, list(int)::out) is det.
get_col(Grid, C, Col) :-
    list.map(get_nth(C), Grid, Col).

% Returns 0 for out-of-bounds — safe because the solver only calls this on
% valid (row, col) pairs within a 9×9 grid.
:- pred get_nth(int::in, list(int)::in, int::out) is det.
get_nth(N, List, V) :-
    ( List = [H | _], N = 1 ->
        V = H
    ; List = [_ | T] ->
        get_nth(N - 1, T, V)
    ;
        V = 0
    ).

:- pred get_box(grid::in, int::in, int::in, list(int)::out) is det.
get_box(Grid, R, C, Vals) :-
    BoxR = ((R - 1) // 3) * 3 + 1,
    BoxC = ((C - 1) // 3) * 3 + 1,
    BoxRows = list.take_upto(3, drop_n(BoxR - 1, Grid)),
    list.foldl(
        (pred(Row::in, Acc0::in, Acc::out) is det :-
            Slice = list.take_upto(3, drop_n(BoxC - 1, Row)),
            Acc = Acc0 ++ Slice),
        BoxRows, [], Vals).

main(!IO) :-
    Puzzle = example_puzzle,
    ( solutions(solve(Puzzle), [Solution | _]) ->
        io.write_line(Solution, !IO)
    ;
        io.write_string("No solution\n", !IO)
    ).
