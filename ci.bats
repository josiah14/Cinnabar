#!/usr/bin/env bats

CINNABAR="$(cd "$(dirname "${BATS_TEST_FILENAME:-$0}")" && pwd)"
GRADE="asm_fast.par.gc.stseg"
KATA="$CINNABAR/katas/foundations/00-reactivation/01-hello-world"

setup() {
    rm -rf "$KATA/Mercury"
}

# ---------------------------------------------------------------------
# 01-hello-world
# ---------------------------------------------------------------------
@test "01-hello-world: start.m compiles" {
    cd "$KATA"
    run mmc --make --grade "$GRADE" start
    [ "$status" -eq 0 ]
}

@test "01-hello-world: start.m (noop) produces no output" {
    cd "$KATA"
    run ./start
    [ "$output" = "" ]
}

#
# The following 2 tests validate the solutions I created to this kata, they
# don't exist in the original forked repo.
# 

@test "01-hello-world: start_bang.m compiles and produces correct output" {
    cd "$KATA"
    run mmc --make --grade "$GRADE" start_bang
    [ "$status" -eq 0 ]
    run ./start_bang
    expected="Hello, World!
Hello, Mercury!!
IO token threaded: write_string 2
IO token threaded: write_string 3"
    [ "$output" = "$expected" ]
}

@test "01-hello-world: start_explicit.m compiles and produces correct output" {
    cd "$KATA"
    run mmc --make --grade "$GRADE" start_explicit
    [ "$status" -eq 0 ]
    run ./start_explicit
    expected="Hello, World!
Hello, Mercury!!
IO token threaded: write_string 2
IO token threaded: write_string 3"
    [ "$output" = "$expected" ]
}
