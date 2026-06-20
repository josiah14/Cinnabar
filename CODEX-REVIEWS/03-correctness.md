# Cinnabar correctness review

## Verification

The local compiler gate completed in the dev shell with **257 passes and 0 failures** across koans, solutions, starters, bridges, and puzzle solutions. CI mechanics are intentionally out of scope. I also ran changed reference programs.

## Findings

### High — memoized search diverges on its supplied cyclic graph

`puzzles/advanced/02-memoized-search/solution/memoized_search.m:18-30` claims `pragma memo(path/5)` breaks cycles, while the example graph contains `d -> a` at line 54. The relation has no visited-state invariant. Running its compiled executable exceeded a 10-second timeout without output.

Thread a visited set/list through `path` and reject revisits, or use a tabled fixed-point formulation and document its actual semantics. Do not teach `memo` alone as cycle detection.

### Medium — CSV creates a phantom empty row after a trailing newline

`puzzles/parsing/02-csv-reader/solution/csv_reader.m:23-32` recurses after every newline, while `row/3` accepts an empty field. Its own sample therefore prints a blank fourth row. Allow one optional final newline without calling `row/3` again, or explicitly define and test the alternate empty-record policy.

Calculator, plugin architecture, and the meta-interpreter produced their documented finite demonstrations.
