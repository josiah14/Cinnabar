# 01 — Hello World

**Concept:** bare module skeleton, `io.di`/`io.uo` mode annotations, `!IO` state threading

---

## Task 1 — break it first

Try to compile `start.m` as-is:

```
mmc --make start
```

It will fail. Read the error carefully:

```
start.m:010: unique-mode error: the called procedure would clobber its
start.m:010: argument, but variable `IO0' is still live.
```

Three terms to understand:

- **`clobber`** — `di` ("destructive input") means the incoming value is
  consumed and cannot be referenced again. The predicate *clobbers* it.
- **`still live`** — `IO0` appears again on line 11 and 12. The compiler
  checked every use and found more than one reference to a variable that
  should have been consumed and never seen again.
- **`unique-mode error`** — this is the class of errors that enforce
  single-threadedness. Mercury's mode system, not runtime checks, prevents
  you from using a consumed value.

The bug: `IO0` is passed to all three `io.write_string` calls as the
"current IO state" argument, but after the first call consumes it, the
compiler won't let you hand it out again.

---

## Task 2 — thread it correctly (explicitly)

Fix the program so each `io.write_string` gets its own distinct IO variable.
The chain should look like this — each call consumes one token and produces
the next:

```mercury
main(IO0, IO) :-
    io.write_string("Hello, world!\n", IO0, IO1),
    io.write_string("Hello, Mercury!\n", IO1, IO2),
    io.write_string("The world of Mercury says hello!\n", IO2, IO).
```

Make sure it compiles and prints all three lines. You just threaded IO
state the same way a pure functional language would.

---

## Task 3 — the syntactic sugar

Mercury provides `!IO` sugar so you don't have to number intermediates
by hand. Rewrite your solution:

```mercury
main(!IO) :-
    io.write_string("Hello, world!\n", !IO),
    io.write_string("Hello, Mercury!\n", !IO),
    io.write_string("The world of Mercury says hello!\n", !IO).
```

It should compile and run identically. `!IO` expands each occurrence to a
pair of distinct variables — the compiler inserts `IO0`, `IO1`, `IO2`, `IO`
for you. Nothing mutated; same threading, less typing.

`!IO` handles sequencing, if-then-else, disjunction, and parallel conjunction
correctly. The sugar is not fragile — you can reach for it confidently in
most contexts.

There are two places where `!IO` is forbidden and you must use explicit IO
variable names instead:

- **Lambda heads.** `!IO` cannot appear as a parameter in a lambda
  expression because there is no syntax to specify the modes of the two
  implied parameters. Write `(pred(IO0::di, IO::uo) is det :- ...)` and
  thread explicitly within the body.
- **Function results.** `!IO` cannot be a function result (the compiler
  says "!IO cannot be a function result") because a function returns a
  single value, not a pair of state variables.

---

## Task 4 (stretch) — Lambda heads and `!IO`

Create `lambda_head.m` with a lambda that uses `!IO` in its head:

```mercury
:- module lambda_head.
:- interface.
:- import_module io.
:- pred main(io::di, io::uo) is det.

:- implementation.

main(!IO) :-
    greet(pred(!IO) :-
        io.write_string("Ahoy!\n", !IO)
    , !IO).

:- pred greet(pred(io, io)::in(pred(di, uo) is det), io::di, io::uo) is det.
greet(P, !IO) :-
    P(!IO).
```

Compile:
```
mmc --make lambda_head
```

The compiler rejects `!IO` in the lambda head because there is no syntax to
specify the modes of the two implied parameters. Fix by threading explicitly:

```mercury
    greet((pred(IO0::di, IO::uo) is det :-
        io.write_string("Ahoy!\n", IO0, IO)
    ), !IO).
```

---

## Task 5 (stretch) — Function results and `!IO`

Create `func_result.m` with a function that uses `!IO` as its result:

```mercury
:- module func_result.
:- interface.
:- import_module io.
:- pred main(io::di, io::uo) is det.

:- implementation.

main(!IO) :-
    io.write_string("Hello!\n", !IO).

:- func hello(io::di) = (io::uo) is det.
hello(!IO) = !IO :-
    io.write_string("Hi!\n", !IO).
```

Compile:
```
mmc --make func_result
```

Among the errors you will see:

```
func_result.m:013: Error: !IO cannot be a function result.
func_result.m:013:   You probably meant !:IO.
```

`!IO` desugars to two variables, but a function returns one value. Fix:

```mercury
:- func hello(io::di) = (io::uo) is det.
hello(!.IO, !:IO) = !:IO :-
    io.write_string("Hi!\n", !.IO, !:IO).
```

---

> **Tutorial cross-reference:** This exercise drills the same concepts as
> Mercury Tutorial §1 (module skeleton, `main/2`, `io.write_string`). If
> `di`/`uo` doesn't click, re-read §1 first, then come back.
