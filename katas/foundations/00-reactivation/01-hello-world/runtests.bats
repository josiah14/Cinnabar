#!/usr/bin/env bats

GRADE="asm_fast.gc.stseg"

setup() {
    cd "$(dirname "${BATS_TEST_FILENAME}")"
    rm -rf Mercury/
}

@test "start_bang.m: compiles and produces correct output" {
    run mmc --make --grade "$GRADE" start_bang
    [ "$status" -eq 0 ]
    run ./start_bang
    [ "$output" = "Hello, World!
Hello, Mercury!!
IO token threaded: write_string 2
IO token threaded: write_string 3" ]
}

@test "start_bang.m: uses !IO notation" {
    run grep -qE '^[^%]*!IO' start_bang.m
    [ "$status" -eq 0 ]
}

@test "start_explicit.m: compiles and produces correct output" {
    run mmc --make --grade "$GRADE" start_explicit
    [ "$status" -eq 0 ]
    run ./start_explicit
    [ "$output" = "Hello, World!
Hello, Mercury!!
IO token threaded: write_string 2
IO token threaded: write_string 3" ]
}

@test "start_explicit.m: uses explicit IO threading" {
    run grep -qE '^[^%]*IO[0-9]' start_explicit.m
    [ "$status" -eq 0 ]
}
