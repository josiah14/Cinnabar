# Solution notes

## Task 1: parameterized filter

```mercury
:- pred run_filter(pred(item)::in(pred(in) is semidet),
                   list(item)::in, list(item)::out) is det.
run_filter(Criterion, Items, Filtered) :-
    list.filter(Criterion, Items, Filtered).
```

The inst on `Criterion` is what allows `list.filter` to call it. The argument's
*type* is `pred(item)` and its *mode* is `in(pred(in) is semidet)` — already bound
(`in`), taking one input, succeeding at most once. The higher-order inst must live in
the mode position: writing it inside the type as `pred(item::in) is semidet` is an
error ("higher order inst information ... not allowed in a predicate's argument").
And a bare `pred(item)` typed `in` is treated as `ground`; calling a `ground`
higher-order value is itself a mode error.

Usage:
```mercury
run_filter((pred(I::in) is semidet :- I^qty > 15), sample_items, HighStock),
run_filter((pred(I::in) is semidet :- I^price > 1.0), sample_items, Expensive),
```

## Task 2: parameterized transform

```mercury
:- pred run_pipeline(
    pred(item),
    (func(item) = float),
    list(item),
    float).
:- mode run_pipeline(
    in(pred(in) is semidet),
    in(func(in) = out is det),
    in, out) is det.
run_pipeline(Filter, Transform, Items, Total) :-
    list.filter(Filter, Items, Filtered),
    Revenues = list.map(Transform, Filtered),
    list.foldl(
        (pred(X::in, Acc::in, Sum::out) is det :- Sum = X + Acc),
        Revenues, 0.0, Total).
```

The mode declaration separates type from inst: the type signature names the
higher-order parameters, and the mode declaration gives their insts using
`in(pred(in) is semidet)` and `in(func(in) = out is det)`.

## Task 3: pipeline record

The Mercury inst system does not allow inst-annotated types in record field
declarations. The practical approach: store predicates as `pred(item)` (type only)
and pass mode information separately, or simply avoid the record form and pass
filter and transform as two separate arguments.

If you want a record-like structure, use a wrapper predicate:
```mercury
:- type pipeline_spec ---> pipeline_spec(
    filter_name    :: string,   % for documentation/debugging
    transform_name :: string
).
```
And keep actual predicates as top-level named predicates, selecting by spec at runtime.

This is a real limitation of Mercury versus Haskell's records: Mercury records cannot
carry inst information in field types. The canonical Mercury solution is higher-order
arguments, not records, for runtime-varying behaviour.

## Task 4: two pipelines via list.map

With separate higher-order arguments rather than a record:

```mercury
:- type pipeline_fn ---> pipeline_fn(
    filter    :: pred(item),
    transform :: func(item) = float
).
```

Since Mercury cannot directly store insted predicates in records, accept this as a
limitation and pass both arguments directly:

```mercury
:- pred run_all(list(item)::in, io::di, io::uo) is det.
run_all(Items, !IO) :-
    Pipelines = [
        (pred(item::in) is semidet :- Item^qty > 15)   - revenue,
        (pred(item::in) is semidet :- Item^price > 1.0) - (func(I) = float(I^qty))
    ],
    list.foldl(
        (pred((F - T)::in, !.IO::di, !:IO::uo) is det :-
            run_pipeline(F, T, Items, Total),
            io.format("total: %.2f\n", [f(Total)], !IO)),
        Pipelines, !IO).
```

The `F - T` pair stores the filter and transform together. Mercury infers the inst
from the pair element types at the point of use.
