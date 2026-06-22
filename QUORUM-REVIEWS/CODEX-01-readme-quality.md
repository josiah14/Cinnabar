# README quality — Codex

## Overall: 7/10

The new acceptance tables materially improve the puzzle contracts, and the
multi-module puzzle has a clear architecture diagram. Two accuracy problems
need correction before this documentation is treated as authoritative.

1. **[P1] The multi-module puzzle makes a falsifiable claim that its own build
   disproves.** `puzzles/advanced/08-multi-module-config/README.md:97-101`
   says that `.mh`/`.mih` headers are generated only for `pragma foreign_export`
   and that this library will generate none. Building the supplied solution has
   generated `cfg.mh`, `parser.mh`, `printer.mh`, `validator.mh`, and
   `config_demo.mh`. Explain the actual generated artifacts, or avoid asserting
   that none will exist.

2. **[P2] The root puzzle index omits an entire topic.** `README.md:75-83`
   says there are 21 puzzles, but its topic table lists only 18: data structures
   (4), parsing (3), concurrent (3), and advanced (8). The three
   `puzzles/logic/*` exercises are absent. Add a logic row so the navigation
   supports the stated total.

The Hello World rewrite is substantially clearer as a small first exercise,
but it repeats the expected output twice and removes the command needed to run
the test. One output block and an explicit `./runtests` command would be a more
compact learner path.
