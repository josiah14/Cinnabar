% declare the module name, must match the file name.
:- module hello.


% Begin the definition of this module's public-facing interface.
:- interface.

% the io module is required for the interface definition (and implicitly
% also the implementation code).
:- import_module io.

% io is the reference to the io module imported, above. di stands for
% "destructive input", meaning the input variable's value is not preserved
% once this predicate is called. uo stands for unique output, which just means
% the predicate returns a "unique" value, in this case a new IO state token,
% which holds/represents the entire world state - so you execute main, provide
% it with an input which in this case is the previous state of the world and
% you get back a new IO token representing this new world-state after pred
% execution. Receiving this token enables you to sequence IO operations by
% providing the returned token to them. However, since this is main, you
% receive back the new world-state token but never use it.
:- pred main(io::di, io::uo) is det.


% begin the implementation code.
:- implementation.

% the way IO works here is each write_string takes a string to output as the
% first argument, and then the following handle IO state. The second argument
% is a destructive inuput: the destructive part means that the value of the
% variable is destroyed after the call to write_string - and then a new unique IO
% token is produced.
% This purely (in logical and functional terms) sequences the IO operations in the
% order they're written. The operations are strung together by and (,)
% operators, and logic ensures that the next operation only runs if the
% previous succeeded, and this is important because in event of failure the IO
% may be corrupted. Notice all the write_string operations use the same
% variable - IO - the ! before it is syntactic sugar for 2 variables, IO0, IO1
% let's call them. The first, IO0 is consumed as the previous state of the world,
% and IO1 is produced as the new state of the world. This sequencing is how
% execution order is defined while maintaining functional and logical purity.
% Because of the di, we know that the consumed IO variable cannot be reused, it's
% destroyed in the execution of the predicate or function with the di designation.
main(!IO) :-
    io.write_string("Hello, World!\n", !IO),
    io.write_string("Hello, Mercury!!\n", !IO),
    io.write_string("IO token threaded: write_string 2\n", !IO),
    io.write_string("IO token threaded: write_string 3\n", !IO).

