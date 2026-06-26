#!/usr/bin/env bats

CINNABAR="$(cd "$(dirname "${BATS_TEST_FILENAME:-$0}")" && pwd)"
GRADE="asm_fast.par.gc.stseg"

# ---------------------------------------------------------------------
# 01-hello-world KATA
# ---------------------------------------------------------------------
KATA="$CINNABAR/katas/foundations/00-reactivation/01-hello-world"

setup() {
    rm -rf "$KATA/Mercury"
}
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

# Validates my worked solutions for this kata (not in the upstream repo).
@test "01-hello-world: runtests passes (start_bang + start_explicit)" {
    cd "$KATA"
    run ./runtests.bats
    [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------
# 21-io-uniqueness KOAN
# ---------------------------------------------------------------------
KOAN="$CINNABAR/koans/foundations/21-io-uniqueness"

@test "21-io-uniqueness: koan compiles and produces correct output" {
   cd "$KOAN"
   run ./runtests.bats
   [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------
# 23-io-func-result KOAN
# ---------------------------------------------------------------------
KOAN="$CINNABAR/koans/foundations/23-io-func-result"

@test "23-io-func-result: koan compiles and produces correct output" {
   cd "$KOAN"
   run ./runtests.bats
   [ "$status" -eq 0 ]
}

