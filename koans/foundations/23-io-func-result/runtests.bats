#!/usr/bin/env bats

KOAN="$(cd "$(dirname "${BATS_TEST_FILENAME:-$0}")" && pwd)"
GRADE="asm_fast.par.gc.stseg"

setup() {
    rm -rf "$KOAN/func_result_koan" "$KOAN/func_result_koan.mh" "$KOAN/Mercury"
}
@test "23-io_func_result_koan: func_result_koan.m compiles and produces correct output" {
    cd "$KOAN"
    run mmc --make --grade "$GRADE" func_result_koan
    [ "$status" -eq 0 ]
    run ./func_result_koan
    [ "$output" = "Hello!
Hi!" ]
}

