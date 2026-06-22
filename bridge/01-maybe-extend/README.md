# Bridge: extend the config reader

**After:** `katas/foundations/02-maybe`

**Why Mercury:** in most languages an absent value is `null` — indistinguishable
from a present one until it crashes at the point of use. Mercury's `maybe(T)` is a
discriminated union (`no ; yes(T)`), and the determinism checker forces every use to
deconstruct both `yes(X)` and `no` before it can reach the value inside. "Missing"
and "invalid" become distinct, compiler-tracked states rather than a single `null`
you hope to remember to check.

`config_reader.m` is a working config reader. It:
- Defines a `config` record with `host :: maybe(string)` and `port :: maybe(int)`
- Reads from a hardcoded association list
- Derives a connection string using a locally-defined `bind_maybe`
- Prints the result

Build and run it first. Make sure you understand every predicate.

```
mmc --make config_reader
./config_reader
```

---

## Extension tasks

### 1. Add a `timeout` field with a default

Add `timeout :: maybe(int)` to `config`. When absent, use a default of `30`.

Write:
```mercury
:- func timeout_or_default(config) = int.
```

If `Config^timeout = yes(T)`, return `T`. If `no`, return `30`.

Then add the timeout to the printed connection string: `"host:port (timeout=30s)"`.

### 2. Add port validation

The port must be between 1 and 65535. If the raw port string parses to an integer
outside that range, treat it the same as a missing port (return `no`).

Modify `lookup_config` so an out-of-range port produces `no` rather than `yes(N)`.

Hint:
```mercury
( string.to_int(S, N), N >= 1, N =< 65535 -> yes(N) ; no )
```

### 3. Add a second format

Write a second formatting function:
```mercury
:- func url_string(config) = maybe(string).
```

It should produce `"http://host:port"` if both are present, `no` otherwise.

Test it with configs where host is present but port is absent, and vice versa.

---

## What you are practising

- `maybe` as a propagating failure type
- The difference between "missing" and "invalid"
- Writing multiple functions that share the same `maybe`-threading structure
