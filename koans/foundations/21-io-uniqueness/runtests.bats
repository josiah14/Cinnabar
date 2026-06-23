#!/usr/bin/env bats

KOAN="$(cd "$(dirname "${BATS_TEST_FILENAME:-$0}")" && pwd)"
GRADE="asm_fast.par.gc.stseg"

setup() {
    rm -rf "$KOAN/io_uniqueness_koan" "$KOAN/io_uniqueness_koan.mh" "$KOAN/Mercury"
}
@test "21-io-uniqueness: io_uniqueness_koan.m compiles" {
    cd "$KOAN"
    run mmc --make --grade "$GRADE" io_uniqueness_koan
    [ "$status" -eq 0 ]
}

