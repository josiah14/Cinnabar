# 03 — Daytype

**Concept:** multi-clause disjunctive `func` body, compound if-then-else, `io.read_from_string` with `posn` threading, `command_line_arguments`

**Before you open `daytype.m`:** write down what you remember about how Mercury handles multiple clauses for the same predicate or function — specifically, whether it is like Prolog (try each clause in order, backtrack) or something different.

### Answer

I had to look this up because I'd never actually formally learned it, or else forgotten it from my studies 7 years ago. But Prolog needs to backtrack because it's dynamically typed. Dynamically types means there's nothing constraining which values could be sent to the predicate which gives the compiler no way to enumerate over the types, so it has to try each clause in order and backtrack to find a solution. However, since Mercury has static typing, the types themselves are bounded sets, and thus these multiple clauses can essentially become a switch-case statement, so no backtracking is needed; it's essentially done similarly to the way Haskell handles pattern-matching over multiple clauses.

---

## What to look for

A multi-clause `func` in Mercury is not backtracking over alternatives — it is a set of pattern-matching cases. Each clause matches a specific input pattern; at most one fires. This makes the determinism tractable: if every clause is `det`, the whole `func` is `det`, with no search involved.

The `io.read_from_string` call introduces `posn` — a position record Mercury uses to track where in a string the parser has reached. It is threaded through reads the same way `!IO` is threaded through I/O calls, though here it is explicit rather than using the `!` sugar. Notice how the `posn` goes in, and a new `posn` comes out — the same unique-threading pattern as I/O, applied to parsing state.

`io.command_line_arguments` retrieves command-line args as a `list(string)`. Watch how the program handles the case where arguments are absent or malformed.

## After reading

Could you say:
- What is the difference between multi-clause pattern matching in Mercury and backtracking in Prolog?
- Where does the `posn` go after the read? Is it used again, or discarded?

---

> **Tutorial cross-reference:** Mercury Tutorial §2–3 covers type declarations and basic pattern
> matching. This exercise partially overlaps: the multi-clause `func` pattern is the same. The
> `posn`-threading and `command_line_arguments` usage are not in the tutorial. If multi-clause
> pattern matching is rusty, see §2 before continuing.
