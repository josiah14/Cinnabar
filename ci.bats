#!/usr/bin/env bats

CINNABAR="$(cd "$(dirname "${BATS_TEST_FILENAME:-$0}")" && pwd)"
GRADE="asm_fast.gc.stseg"

# ---------------------------------------------------------------------
# 01-hello-world KATA
# ---------------------------------------------------------------------
KATA_HELLO_WORLD="$CINNABAR/katas/foundations/00-reactivation/01-hello-world"

setup() {
    rm -rf "$KATA_HELLO_WORLD/Mercury"
    rm -rf "$KATA_FIBONACCI/Mercury"
}

@test "01-hello-world: start.m compiles" {
    cd "$KATA_HELLO_WORLD"
    run mmc --make --grade "$GRADE" start
    [ "$status" -eq 0 ]
}

@test "01-hello-world: start.m declares io::di / io::uo / !IO skeleton" {
    grep -qE 'io::di' "$KATA_HELLO_WORLD/start.m"
    grep -qE 'io::uo' "$KATA_HELLO_WORLD/start.m"
    grep -qF '!IO' "$KATA_HELLO_WORLD/start.m"
}

# Validates my worked solutions for this kata (not in the upstream repo).
@test "01-hello-world: runtests passes (start_bang + start_explicit)" {
    cd "$KATA_HELLO_WORLD"
    run ./runtests.bats
    [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------
# 02-fibonacci KATA
# ---------------------------------------------------------------------
KATA_FIBONACCI="$CINNABAR/katas/foundations/00-reactivation/02-fibonacci"

@test "02-fibonacci: start.m compiles and check fails for non-zero fib input values" {
    cd "$KATA_FIBONACCI"
    run mmc --make --grade "$GRADE" start
    [ "$status" -eq 0 ]
    run ./start
    [ "$output" = "PASS: fib(0) = 0
FAIL: fib(1) = 1
FAIL: fib(2) = 1
FAIL: fib(5) = 5
FAIL: fib(10) = 55" ]
}

@test "02-fibonacci: runtests passes (fibonacci.m)" {
    cd "$KATA_FIBONACCI"
    run ./runtests.bats
    [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------
# 21-io-uniqueness KOAN
# ---------------------------------------------------------------------
KOAN_21="$CINNABAR/koans/foundations/21-io-uniqueness"

@test "21-io-uniqueness: koan compiles and produces correct output" {
   cd "$KOAN_21"
   run ./runtests.bats
   [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------
# 23-io-func-result KOAN
# ---------------------------------------------------------------------
KOAN_23="$CINNABAR/koans/foundations/23-io-func-result"

@test "23-io-func-result: koan compiles and produces correct output" {
   cd "$KOAN_23"
   run ./runtests.bats
   [ "$status" -eq 0 ]
}

