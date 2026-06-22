#!/usr/bin/env bash
# CI gate for cinnabar.
#
# Rules:
#   - *_koan.m files in koans/ (not in solution/) must FAIL to compile.
#   - solution/*.m files in koans/ must PASS compilation.
#   - katas/*/start.m files must PASS compilation.
#   - bridge starter *.m files (not in solution/) must PASS compilation.
#   - puzzles/*/solution/*.m files must PASS compilation.
#
# Text-only koans (no *_koan.m file) are skipped automatically.

set -uo pipefail

CINNABAR="$(cd "$(dirname "$0")" && pwd)"
GRADE="asm_fast.par.gc.stseg"

if ! command -v mmc > /dev/null 2>&1; then
    echo "mmc not found on PATH. Run inside a nix dev shell: nix develop --command ./ci.sh"
    exit 1
fi

pass=0
fail=0
failures=()

# Silence mmc output unless verbose mode is set.
MMC_OUT=/dev/null
if [[ "${VERBOSE:-}" == "1" ]]; then
    MMC_OUT=/dev/stdout
fi

compile_fail() {
    local dir="$1"
    local module="$2"
    local label="$3"
    local out
    out=$(
        cd "$dir"
        rm -rf Mercury/
        mmc --make --grade "$GRADE" "$module" 2>&1
    )
    local code=$?
    [[ "${VERBOSE:-}" == "1" ]] && echo "$out"
    if [[ $code -eq 0 ]]; then
        echo "  FAIL (koan compiled — it should not): $label"
        ((fail++))
        failures+=("koan compiled when it should fail: $label")
        return
    fi
    # If a .err snapshot exists, verify the expected diagnostic phrases still fire.
    # File:line prefixes are stripped so source edits don't cause false mismatches.
    local err_file="$dir/${module}.err"
    if [[ -f "$err_file" ]]; then
        local strip='s/^[^: ]*:[0-9]*: *//'
        local expected actual all_found=true
        expected=$(sed "$strip" "$err_file" | grep -v '^\s*$' | sort -u)
        actual=$(echo "$out" | sed "$strip" | sort -u)
        while IFS= read -r line; do
            [[ -z "$line" ]] && continue
            if ! echo "$actual" | grep -qF "$line"; then
                all_found=false
                break
            fi
        done <<< "$expected"
        if $all_found; then
            echo "  PASS (broke as expected, diagnostic confirmed): $label"
            ((pass++))
        else
            echo "  FAIL (broke, diagnostic differs — update ${err_file#"$CINNABAR/"}): $label"
            ((fail++))
            failures+=("diagnostic mismatch: $label")
        fi
    else
        echo "  PASS (broke as expected): $label"
        ((pass++))
    fi
}

compile_pass() {
    local dir="$1"
    local module="$2"
    local label="$3"
    (
        cd "$dir"
        rm -rf Mercury/
        mmc --make --grade "$GRADE" "$module" > "$MMC_OUT" 2>&1
    )
    local code=$?
    if [[ $code -eq 0 ]]; then
        echo "  PASS: $label"
        ((pass++))
    else
        echo "  FAIL: $label"
        ((fail++))
        failures+=("failed to compile: $label")
    fi
}

module_of() {
    # Strip path and .m extension to get the module name.
    basename "$1" .m
}

# ---------------------------------------------------------------------------
# 0. Index integrity — README entry count must match on-disk directory count
# ---------------------------------------------------------------------------
echo "=== Index integrity checks ==="

check_index() {
    local label="$1"
    local dir="$2"
    local readme="$3"
    local on_disk in_readme

    on_disk=$(find "$dir" -mindepth 1 -maxdepth 1 -type d -name '[0-9][0-9]-*' 2>/dev/null | wc -l)
    # Count table rows (lines starting with |) whose first cell matches `NN-`.
    in_readme=$(grep -c '^\s*|.*`[0-9][0-9]-' "$readme" 2>/dev/null || echo 0)

    if [[ "$on_disk" -eq "$in_readme" ]]; then
        echo "  OK ($on_disk entries): $label"
        ((pass++))
    else
        echo "  DRIFT: $label — ${on_disk} dirs on disk, ${in_readme} entries in README"
        ((fail++))
        failures+=("index drift: $label (${on_disk} on disk, ${in_readme} in README)")
    fi
}

check_index "katas/foundations" "$CINNABAR/katas/foundations" "$CINNABAR/katas/foundations/README.md"
check_index "katas/type-system" "$CINNABAR/katas/type-system" "$CINNABAR/katas/type-system/README.md"
check_index "katas/mode-system" "$CINNABAR/katas/mode-system" "$CINNABAR/katas/mode-system/README.md"
check_index "katas/determinism" "$CINNABAR/katas/determinism" "$CINNABAR/katas/determinism/README.md"
check_index "katas/parsing"     "$CINNABAR/katas/parsing"     "$CINNABAR/katas/parsing/README.md"
check_index "katas/tooling"     "$CINNABAR/katas/tooling"     "$CINNABAR/katas/tooling/README.md"
check_index "katas/concurrency" "$CINNABAR/katas/concurrency" "$CINNABAR/katas/concurrency/README.md"
check_index "katas/advanced"    "$CINNABAR/katas/advanced"    "$CINNABAR/katas/advanced/README.md"
check_index "bridge"            "$CINNABAR/bridge"            "$CINNABAR/bridge/README.md"

echo ""
# ---------------------------------------------------------------------------
# 1. Koans — must fail
# ---------------------------------------------------------------------------
echo "=== Koans (expect compile failure) ==="
while IFS= read -r -d '' koan_file; do
    dir="$(dirname "$koan_file")"
    module="$(module_of "$koan_file")"
    label="${koan_file#"$CINNABAR/"}"
    compile_fail "$dir" "$module" "$label"
done < <(
    find "$CINNABAR/koans" -name "*_koan.m" \
        ! -path "*/solution/*" \
        -print0 | sort -z
)

# ---------------------------------------------------------------------------
# 2. Koan solutions — must pass
# ---------------------------------------------------------------------------
echo ""
echo "=== Koan solutions (expect compile success) ==="
while IFS= read -r -d '' sol_file; do
    # Skip library modules (no main predicate — they are compiled as dependencies
    # of the main module in multi-module solutions).
    grep -q ':- pred main(' "$sol_file" 2>/dev/null || continue
    dir="$(dirname "$sol_file")"
    module="$(module_of "$sol_file")"
    label="${sol_file#"$CINNABAR/"}"
    compile_pass "$dir" "$module" "$label"
done < <(
    find "$CINNABAR/koans" -path "*/solution/*.m" \
        ! -name "*.mh" \
        -print0 | sort -z
)

# ---------------------------------------------------------------------------
# 3. Kata starters — must pass
# ---------------------------------------------------------------------------
echo ""
echo "=== Kata starters (expect compile success) ==="
while IFS= read -r -d '' start_file; do
    dir="$(dirname "$start_file")"
    module="$(module_of "$start_file")"
    label="${start_file#"$CINNABAR/"}"
    compile_pass "$dir" "$module" "$label"
done < <(
    find "$CINNABAR/katas" -name "start.m" \
        ! -path "*/solution/*" \
        -print0 | sort -z
)

# ---------------------------------------------------------------------------
# 4. Bridge starters — must pass
# ---------------------------------------------------------------------------
echo ""
echo "=== Bridge starters (expect compile success) ==="
while IFS= read -r -d '' bridge_file; do
    dir="$(dirname "$bridge_file")"
    module="$(module_of "$bridge_file")"
    label="${bridge_file#"$CINNABAR/"}"
    compile_pass "$dir" "$module" "$label"
done < <(
    find "$CINNABAR/bridge" -name "*.m" \
        ! -path "*/solution/*" \
        ! -name "*.mh" \
        -print0 | sort -z
)

# ---------------------------------------------------------------------------
# 5. Puzzle solutions — must pass
# ---------------------------------------------------------------------------
echo ""
echo "=== Puzzle solutions (expect compile success) ==="
while IFS= read -r -d '' puzzle_file; do
    # Skip library modules (no main predicate — they are compiled as
    # dependencies of the main module in multi-module solutions, e.g.
    # advanced/08-multi-module-config). Building one directly would fail at the
    # link stage for lack of a main/2.
    grep -q ':- pred main(' "$puzzle_file" 2>/dev/null || continue
    dir="$(dirname "$puzzle_file")"
    module="$(module_of "$puzzle_file")"
    label="${puzzle_file#"$CINNABAR/"}"
    compile_pass "$dir" "$module" "$label"
done < <(
    find "$CINNABAR/puzzles" -path "*/solution/*.m" \
        ! -name "*.mh" \
        -print0 | sort -z
)

# ---------------------------------------------------------------------------
# 6. Bridge solution snippets — extract and syntax-check ```mercury blocks
# ---------------------------------------------------------------------------
echo ""
echo "=== Bridge solution README code blocks (syntax check) ==="

BRIDGE_TMPDIR="$(mktemp -d "/tmp/cinnabar-bridge-XXXXXX")"
cleanup_bridge() { rm -rf "$BRIDGE_TMPDIR"; }
trap cleanup_bridge EXIT

# Common imports for bridge snippet compilation
BRIDGE_STD_IMPORTS="io, int, string, list, maybe, char, bool, exception, require, float"
BRIDGE_CONCUR_IMPORTS="$BRIDGE_STD_IMPORTS, channel, thread, thread.semaphore, univ, unit"

while IFS= read -r -d '' readme; do
    bridge_name="$(basename "$(dirname "$(dirname "$readme")")")"
    block_num=0

    # Write each ```mercury block to a temp file via awk
    safe_bname="${bridge_name//-/_}"
    awk -v tmpdir="$BRIDGE_TMPDIR" -v bname="$safe_bname" '
    BEGIN { in_block = 0; block = ""; count = 0; }
    /^```mercury/ { in_block = 1; block = ""; next; }
    /^```$/ && in_block {
        in_block = 0;
        count++;
        fname = tmpdir "/raw_" bname "_" count ".txt";
        printf "%s", block > fname;
        close(fname);
        block = "";
        next;
    }
    in_block { block = block $0 "\n"; }
    ' "$readme"

    for raw_file in "$BRIDGE_TMPDIR/raw_${safe_bname}"_*.txt; do
        [[ -f "$raw_file" ]] || continue
        ((block_num++))
        content="$(cat "$raw_file")"
        rm -f "$raw_file"
        line_count="$(echo "$content" | wc -l)"

        # Skip trivial blocks (< 3 lines or no predicate/func/type/import declaration)
        if [[ "$line_count" -lt 3 ]]; then continue; fi
        if ! echo "$content" | grep -qE '^\s*:- (pred|func|type|import_module)'; then continue; fi

        # Determine imports. Strip the `:- import_module` prefix, any trailing
        # `% comment`, and — crucially — the statement-terminating `.` (keeping
        # internal submodule dots like `thread.semaphore`). Without the final-dot
        # strip, `:- import_module map.` yields `map.` and the wrapper emits
        # `import_module …, map..`, a double-dot that breaks parsing.
        block_imports="$(echo "$content" | grep '^\s*:- import_module' | sed 's/.*:- import_module *//;s/%.*//;s/\.[[:space:]]*$//;s/[[:space:]]*$//' | tr '\n' ',' | sed 's/,$//')"
        if [[ -n "$block_imports" ]]; then
            combined_imports="io, int, string, list, maybe, $block_imports"
            content="$(echo "$content" | grep -v '^\s*:- import_module')"
        elif echo "$content" | grep -qE '\b(channel|thread\.|semaphore)\b'; then
            combined_imports="$BRIDGE_CONCUR_IMPORTS"
        else
            combined_imports="$BRIDGE_STD_IMPORTS"
        fi

        module_name="br_${bridge_name}_${block_num}"
        module_name="${module_name//-/_}"
        tmpfile="$BRIDGE_TMPDIR/${module_name}.m"

        cat > "$tmpfile" <<- MODEOF
:- module $module_name.
:- interface.
:- implementation.

:- import_module $combined_imports.

$content
MODEOF

        label="${readme#"$CINNABAR/"} block $block_num"
        (
            cd "$BRIDGE_TMPDIR"
            rm -rf Mercury/
            # These blocks are *fragments* of each bridge's program: they freely
            # reference types/predicates defined in the bridge's starter .m
            # (`config`, `expr`, `user`, …), so they cannot be fully type-checked
            # in isolation. `--make-short-interface` parses the block and checks
            # declaration well-formedness (syntax, mode/pred decls) without
            # resolving external types — the actual "syntax-check" this section
            # claims. (Note: `--make --errorcheck-only` is rejected by mmc as a
            # conflicting combination, so neither `--make` nor a full semantic
            # pass is usable here.)
            mmc --make-short-interface --grade "$GRADE" "$module_name" > "$MMC_OUT" 2>&1
        )
        code=$?
        if [[ $code -eq 0 ]]; then
            echo "  PASS: $label"
            ((pass++))
        else
            echo "  FAIL: $label"
            ((fail++))
            failures+=("bridge snippet does not compile: $label")
        fi
    done
done < <(
    find "$CINNABAR/bridge" -path "*/solution/README.md" -print0 | sort -z
)

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
echo "=== Results ==="
echo "  Passed: $pass"
echo "  Failed: $fail"
if [[ ${#failures[@]} -gt 0 ]]; then
    echo ""
    echo "Failures:"
    for f in "${failures[@]}"; do
        echo "  - $f"
    done
    echo ""
    exit 1
fi
echo ""
echo "All checks passed."
