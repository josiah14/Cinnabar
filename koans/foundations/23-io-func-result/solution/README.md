# Solution notes

`!IO` cannot be a function result because it stands for two variables (`!.IO`
and `!:IO`) and a function returns one value.

`fixed.m` keeps `hello` a function but names the IO states explicitly — it takes
one io (`di`) and returns the next (`uo`):

```mercury
:- func hello(io::di) = (io::uo) is det.
hello(IO0) = IO :- io.write_string("Hi!\n", IO0, IO).
```

and is called by binding the result to the next state: `!:IO = hello(!.IO)`.

This compiles and runs, but it is unusual style. IO-effecting code is almost
always written as a **predicate**, where the two-ended threading is natural and
`!IO` works directly:

```mercury
:- pred hello(io::di, io::uo) is det.
hello(!IO) :- io.write_string("Hi!\n", !IO).
```

Both are correct. The predicate form is the one you would actually write; the
function form is shown because it is the most direct repair of the koan — the
same `:- func` declaration, with the IO states named instead of `!IO`.
