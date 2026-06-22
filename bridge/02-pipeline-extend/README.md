# Bridge: extend the sales pipeline

**After:** `katas/foundations/04-higher-order`

**Why Mercury:** passing a function to `map` or `foldl` is routine everywhere. What
Mercury adds is that a higher-order argument carries an *inst* — the modes and
determinism of the closure — and the compiler checks that the closure you pass
matches what the consumer declared. The `print_category` predicate you hand to
`foldl` must prove it has exactly the mode and determinism `foldl`'s argument inst
demands; a mismatch is a compile error, not a runtime surprise.

`pipeline.m` is the working pipeline from kata 04. It defines `item`, filters by stock
level, maps to revenue, and folds to a total. It compiles and runs.

```
mmc --make pipeline
./pipeline
```

Read it. Understand the `foldl2` call before extending anything.

---

## Extension tasks

### 1. Add a `category` field

Add `category :: string` to `item`. Update `sample_items` to give each item a category
(`"fruit"` or `"dried"`). The existing pipeline should still compile after this change.

### 2. Group by category

Write:
```mercury
:- pred group_by_category(list(item)::in,
                          map(string, list(item))::out) is det.
```

Use `map.search` and `map.set` inside a `foldl`. The result maps each category name
to the list of items in that category.

Print each category's items and their total revenue.

### 3. Sort the output

When printing grouped results, sort the category names so output is deterministic:

```mercury
map.keys(GroupMap, CategoryKeys),
list.sort(CategoryKeys, SortedKeys),
list.foldl(print_category(GroupMap), SortedKeys, !IO).
```

Write `print_category` as a separate predicate with the right inst annotation on its
higher-order argument to `foldl`.

### 4. Parameterize the grouping key (optional)

Write a generic grouping predicate:
```mercury
:- pred group_by(func(T) = K, list(T), map(K, list(T))).
:- mode group_by(in(func(in) = out is det), in, out) is det.
```

Use it to group by category, then try grouping by `high_stock` status (a `bool`).

---

## What you are practising

- Adding fields to existing types and propagating the change
- `map` as an accumulator in `foldl`
- Designing the right inst annotation for a higher-order argument
- Generalizing a specific grouping function into a parametric one
