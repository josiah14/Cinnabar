# Kata: software transactional memory

**After:** `katas/concurrency/02-threads`, `katas/concurrency/05-deadlock`

STM gives you composable, lock-free shared state. Instead of managing mutexes,
you describe a transaction: a block of reads and writes that the runtime either
commits atomically or retries from scratch on conflict.

Mercury's STM lives in `import_module stm_builtin`. The state variable is `stm`
(analogous to `io` but for transactional context), threaded through predicates
inside a transaction.

---

## The two contexts

Your program has two contexts and each has its own state variable:

| Context | State variable | Operations |
|---|---|---|
| IO context | `io::di, io::uo` | `new_stm_var`, `atomic_transaction`, ordinary IO |
| Transaction context | `stm::di, stm::uo` | `read_stm_var`, `write_stm_var`, `retry` |

Never mix them. Calling `read_stm_var` with `!IO` is a type error. Calling
`io.write_string` with `!STM` is also a type error. The type system enforces the
boundary.

---

## The core API

```mercury
% Create a transactional variable (in IO context)
new_stm_var(InitialValue, Var, !IO)

% Run a transaction atomically (in IO context)
atomic_transaction(Pred, Result, !IO)
    % Pred :: pred(T, stm, stm) — runs in transaction context
    % Result :: T — value produced by the transaction

% Read a transactional variable (in transaction context)
read_stm_var(Var, Value, !STM)

% Write a transactional variable (in transaction context)
write_stm_var(Var, NewValue, !STM)

% Retry the transaction; blocks until a read variable changes
retry(!.STM)    % erroneous — never returns on this path

% Try Left; if it retries, try Right instead (in transaction context)
or_else(Left, Right, Result, !STM)
```

---

## Bank accounts scenario

This kata models two bank accounts: `savings` and `checking`. You will implement
three transactional operations, then compose them in `main`.

---

## Steps

### 1. Write `deposit/4`

```mercury
:- pred deposit(int::in, stm_var(int)::in, stm::di, stm::uo) is det.
```

Read the current balance, add `Amount`, write it back.

### 2. Write `withdraw/4`

```mercury
:- pred withdraw(int::in, stm_var(int)::in, stm::di, stm::uo) is det.
```

Read the current balance, subtract `Amount`, write it back. No balance check —
the balance may go negative. That is correct for this step; step 3 adds safety.

### 3. Write `transfer/5`

```mercury
:- pred transfer(int::in, stm_var(int)::in, stm_var(int)::in,
    stm::di, stm::uo) is det.
```

Call `withdraw(Amount, From, !STM)` then `deposit(Amount, To, !STM)`.

The key insight: `withdraw` and `deposit` each have `stm::di, stm::uo` arguments.
Chaining them threads the stm log through both operations. `atomic_transaction` then
wraps the whole chain, committing or retrying the entire sequence as a unit.

### 4. Wire everything in `main`

Use `atomic_transaction` to run each operation. The pattern for a `void` operation
(no return value) is:

```mercury
atomic_transaction(
    (pred(unit::out, S0::di, S::uo) is det :-
        deposit(200, Savings, S0, S)
    ), _, !IO).
```

The `unit` type and `_` discard the result. The `S0/S` names thread the `stm` log
through the body.

Initial balances: `savings = 1000`, `checking = 0`.

Perform:
1. Transfer 500 from savings to checking
2. Deposit 200 into savings

Read both balances with two separate `atomic_transaction` calls and print them.

Expected output:
```
savings:  700
checking: 500
```

### 5. (Advanced) Conditional transfer with `retry` and `or_else`

Write a predicate that transfers only if the source balance is sufficient,
and `retry`s otherwise (blocking in a concurrent program until another thread
deposits enough):

```mercury
:- pred transfer_if_enough(int::in, stm_var(int)::in, stm_var(int)::in,
    stm::di, stm::uo) is det.
transfer_if_enough(Amount, From, To, !STM) :-
    read_stm_var(From, Balance, !STM),
    ( Balance >= Amount ->
        withdraw(Amount, From, !STM),
        deposit(Amount, To, !STM)
    ;
        retry(!.STM)
    ).
```

Because `retry` is `erroneous`, Mercury knows the else branch never returns.
No binding of `!:STM` is required after `retry(!.STM)`.

To call this without blocking forever in the single-threaded kata, use `or_else`
to provide a fallback:

```mercury
:- type transfer_result ---> transferred ; insufficient_funds.

atomic_transaction(
    (pred(Result::out, S0::di, S::uo) is det :-
        or_else(
            (pred(transferred::out, S1::di, S2::uo) is det :-
                transfer_if_enough(400, Savings, Checking, S1, S2)),
            (pred(insufficient_funds::out, S1::di, S2::uo) is det :-
                S2 = S1),
            Result, S0, S)
    ), Outcome, !IO).
```

`or_else(Left, Right, Result, !STM)` — if `Left` calls `retry`, `Right` is invoked
with the original STM log. This gives you non-blocking conditional transactions in
single-threaded contexts, and correct blocking behavior in concurrent contexts.
