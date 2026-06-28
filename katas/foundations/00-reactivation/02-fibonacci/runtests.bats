#!/usr/bin/env bats

GRADE="asm_fast.gc.stseg"

setup() {
    cd "$(dirname "${BATS_TEST_FILENAME}")"
    rm -rf Mercury/
}

@test "fibonacci.m: compiles and the check predicate passes for all checked values" {
    run mmc --make --grade "$GRADE" fibonacci
    [ "$status" -eq 0 ]
    run ./fibonacci
    [ "$output" = "PASS: fib(0) = 0
PASS: fib(1) = 1
PASS: fib(2) = 1
PASS: fib(5) = 5
PASS: fib(10) = 55
PASS: fib0(0) = 0
PASS: fib0(1) = 1
PASS: fib0(2) = 1
PASS: fib0(5) = 5
PASS: fib0(10) = 55" ]
}

