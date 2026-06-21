#!/usr/bin/env bash
# quorum-review.sh — Orchestrate a multi-model review cycle for cinnabar.
#
# Usage:
#   ./quorum-review.sh <target> [reviewers...]
#
# Target: a file, directory, or "all" for the full project.
# Reviewers: space-separated model tags (default: laguna big-pickle deepseek)
#
# Stages:
#   1. Generate review prompts for each model × 6 dimensions
#   2. (Manual) Run each model with its prompts, place output in {MODEL}-REVIEWS/
#   3. Synthesize: collect all reviews and produce REVIEWS-SYNTHESIS/SYNTHESIS.md
#   4. Prioritize: generate updated TODO.md with model-fit tags
#
# Example:
#   ./quorum-review.sh puzzles/parsing/01-calculator laguna deepseek big-pickle
#   ./quorum-review.sh bridge/10 laguna opus          # escalate to Opus
#   ./quorum-review.sh all                            # all 3 defaults

set -euo pipefail

CINNABAR="$(cd "$(dirname "$0")" && pwd)"

show_help() {
  echo "Usage: ./quorum-review.sh <target> [reviewers...] [--collect|--synth|--gen-todo]"
  echo ""
  echo "Commands (default: generate prompts + status):"
  echo "  <target>       File, directory, or 'all'"
  echo "  --synth        Generate synthesis prompt from collected reviews"
  echo "  --collect      Show review collection status"
  echo "  --gen-todo     Print TODO.md format instructions"
  echo ""
  echo "Examples:"
  echo "  ./quorum-review.sh all"
  echo "  ./quorum-review.sh puzzles/parsing/01-calculator laguna deepseek opus"
  echo "  ./quorum-review.sh bridge/10 --synth"
  echo ""
  echo "Model tags: big-pickle, deepseek, laguna, opus, sonnet, ring, nemotron"
  echo "Default: laguna deepseek big-pickle (3 free models)"
}

# Main
case "${1:-}" in
  --help|-h) show_help; exit 0 ;;
esac

TARGET="${1:-all}"
shift 2>/dev/null || true

# Default reviewer quorum: 3 free models with different biases
REVIEWERS=("${@:-laguna deepseek big-pickle}")

DIMENSIONS=(
  "01-readme-quality"
  "02-coverage"
  "03-correctness"
  "04-code-quality"
  "05-idiomatic-mercury"
  "06-overall"
)

# Model display names
declare -A MODEL_NAMES
MODEL_NAMES[big-pickle]="Big Pickle"
MODEL_NAMES[deepseek]="DeepSeek V4 Flash Free"
MODEL_NAMES[laguna]="Laguna M.1"
MODEL_NAMES[opus]="Opus 4.8"
MODEL_NAMES[sonnet]="Sonnet 4.6"
MODEL_NAMES[ring]="Ring 2.6-1T"
MODEL_NAMES[nemotron]="Nemotron 3 Ultra Free"

prompt_for_dimension() {
  local dim="$1" target_desc="$2"
  case "$dim" in
    01-readme-quality)
      echo "## README quality review for: $target_desc"
      echo ""
      echo "Evaluate the README(s) for clarity, navigation, accuracy of descriptions,"
      echo "and whether they set appropriate expectations. Score 1-10."
      echo ""
      echo "Check:"
      echo "- Does the README accurately describe what's in the directory?"
      echo "- Are prerequisites and learning objectives clear?"
      echo "- Is navigation correct (links, indices)?"
      echo "- Does it set appropriate expectations?"
      ;;
    02-coverage)
      echo "## Coverage review for: $target_desc"
      echo ""
      echo "Evaluate breadth and depth of coverage relative to what the topic needs."
      echo "Score breadth 1-10 and depth 1-10."
      echo ""
      echo "Check:"
      echo "- What's missing that should be here?"
      echo "- What's present but too shallow?"
      echo "- Are there important concepts left unexplored?"
      ;;
    03-correctness)
      echo "## Correctness review for: $target_desc"
      echo ""
      echo "Evaluate compilation, runtime behavior, and contract correctness."
      echo "Score 1-10."
      echo ""
      echo "Check:"
      echo "- Does the code compile with mmc (Mercury 22.01.8)?"
      echo "- Are there contract bugs (wrong return, swallowed errors)?"
      echo "- Do koans fail for the EXACT intended reason (not a secondary issue)?"
      echo "- Are there latent bugs that wouldn't be caught by compilation alone?"
      ;;
    04-code-quality)
      echo "## Code quality review for: $target_desc"
      echo ""
      echo "Evaluate code hygiene, imports, dead code, commenting, structure."
      echo "Score 1-10."
      echo ""
      echo "Check:"
      echo "- Are there unused imports or dead code?"
      echo "- Are comments accurate and non-stale?"
      echo "- Is the code structured clearly?"
      echo "- Are there systematic issues (e.g., invented stdlib API)?"
      ;;
    05-idiomatic-mercury)
      echo "## Idiomatic Mercury review for: $target_desc"
      echo ""
      echo "Evaluate how well the code uses Mercury-specific patterns."
      echo "Score 1-10."
      echo ""
      echo "Check:"
      echo "- Are mode/determinism annotations appropriate?"
      echo "- Are there Prolog-isms that should be Mercury-idiomatic?"
      echo "- Is the function/predicate balance appropriate?"
      echo "- Does it use committed choice, DCGs, insts appropriately?"
      ;;
    06-overall)
      echo "## Overall assessment for: $target_desc"
      echo ""
      echo "Synthesize the above into a final score, key strengths, key gaps,"
      echo "and the single most impactful change."
      echo "Score 1-10."
      echo ""
      echo "Provide:"
      echo "- Summary of findings"
      echo "- Dimension scores in a table"
      echo "- What this does better than alternatives"
      echo "- The single highest-impact action item"
      echo "- Comparison to any previous reviews if available"
      ;;
  esac
}

# Uppercase model names for directory convention (OPUS-REVIEWS/, CODEX-REVIEWS/, etc.)
to_upper() {
  echo "$1" | tr '[:lower:]' '[:upper:]'
}

make_review_dir() {
  local model="$1"
  local upper
  upper="$(to_upper "$model")"
  local dir="${CINNABAR}/${upper}-REVIEWS"
  mkdir -p "$dir"
  echo "$dir"
}

generate_prompts() {
  local target="$1" model="$2"
  local model_name="${MODEL_NAMES[$model]:-$model}"
  local upper
  upper="$(to_upper "$model")"
  local dir
  dir="$(make_review_dir "$model")"

  local target_desc
  if [[ "$target" == "all" ]]; then
    target_desc="the entire cinnabar curriculum"
  elif [[ -d "$target" ]]; then
    target_desc="$(realpath --relative-to="$CINNABAR" "$target")"
  else
    target_desc="$target"
  fi

  echo "=== Generating prompts for $model_name ($model) ==="

  for dim in "${DIMENSIONS[@]}"; do
    local prompt_file="$dir/$dim.md.prompt"
    prompt_for_dimension "$dim" "$target_desc" > "$prompt_file"
    echo "  Wrote $prompt_file"
  done

  echo ""
  echo "To run $model_name on the '$target_desc' target:"
  echo "  For each dimension, feed the .prompt file to the model with the"
  echo "  target source code, save the model's output as ${upper}-REVIEWS/<dim>.md"
  echo "  (overwriting the .prompt file)."
  echo ""
}

collect_reviews() {
  local target="$1"
  echo "=== Review collection status ==="
  for model in "${REVIEWERS[@]}"; do
    local upper
    upper="$(to_upper "$model")"
    local dir="${CINNABAR}/${upper}-REVIEWS"
    local count=0
    if [[ -d "$dir" ]]; then
      for dim in "${DIMENSIONS[@]}"; do
        local file="$dir/$dim.md"
        if [[ -f "$file" ]] && [[ ! "$file" == *.prompt ]]; then
          ((count++))
        fi
      done
    fi
    echo "  $model ($upper-REVIEWS/): $count/6 reviews submitted"
  done
}

synthesize() {
  local target="$1"
  local syn_dir="${CINNABAR}/REVIEWS-SYNTHESIS"
  mkdir -p "$syn_dir"

  echo "=== Generating synthesis prompt ==="
  local syn_file="$syn_dir/SYNTHESIS.md.prompt"
  {
    echo "# Synthesis of multi-model review for: $target"
    echo ""
    echo "You are the aggregator. Read all reviewer passes below and produce:"
    echo ""
    echo "1. A scorecard table (dimension × reviewer)"
    echo "2. Consensus findings (all agree) — fix first"
    echo "3. Majority findings (2 of N agree) — fix, medium-high confidence"
    echo "4. Contested items — adjudicate with reasoning"
    echo "5. Single-reviewer findings worth keeping"
    echo "6. A prioritized action backlog as TODO.md entries with model-fit tags"
    echo ""
    echo "For each contested claim, resolve by deriving the answer from first"
    echo "principles and the actual Mercury source, not by counting votes."
    echo ""
    echo "--- Review passes ---"
    echo ""

    for model in "${REVIEWERS[@]}"; do
      local upper
      upper="$(to_upper "$model")"
      local dir="${CINNABAR}/${upper}-REVIEWS"
      local model_name="${MODEL_NAMES[$model]:-$model}"
      if [[ -d "$dir" ]]; then
        for dim in "${DIMENSIONS[@]}"; do
          local file="$dir/$dim.md"
          if [[ -f "$file" ]] && [[ ! "$file" == *.prompt ]]; then
            echo "## ${model_name} — ${dim}"
            echo ""
            cat "$file"
            echo ""
          fi
        done
      fi
    done
  } > "$syn_file"

  echo "  Wrote $syn_file"
  echo "  Feed this to the aggregator model (recommended: Opus 4.8)."
  echo "  Save output as REVIEWS-SYNTHESIS/SYNTHESIS.md"
  echo "  Then run: ./quorum-review.sh --gen-todo"
}

generate_todo() {
  echo "=== TODO generation instructions ==="
  echo ""
  echo "From REVIEWS-SYNTHESIS/SYNTHESIS.md, extract action items as TODO.md entries:"
  echo ""
  echo "Format each item as:"
  echo ""
  echo "- [ ] \`[model-tag]\` \`{effort-tag}\` **Short description** — details."
  echo ""
  echo "Model tags: [Opus], [Sonnet], [User], [any]"
  echo "Effort tags: {max}, {xhigh}, {high}"
  echo ""
  echo "Group by priority:"
  echo "  ## P0 — release blockers (trust + navigation)"
  echo "  ## P1 — correctness of reference material"
  echo "  ## P2 — polish"
  echo "  ## P3 — scope expansion (post-release)"
  echo ""
  echo "Mark completed items with [x]. Include a 'Done (this session)' section."
}

# Main
case "${1:-}" in
  --synth)
    synthesize "$TARGET"
    ;;
  --collect)
    collect_reviews "$TARGET"
    ;;
  --gen-todo)
    generate_todo
    ;;
  *)
    echo "=== Quorum Review: $TARGET ==="
    echo "Reviewers: ${REVIEWERS[*]}"
    echo ""

    for model in "${REVIEWERS[@]}"; do
      generate_prompts "$TARGET" "$model"
    done

    echo ""
    echo "---"
    echo "Prompts generated. Next steps:"
    echo "  1. Run each model with its prompts (feed target source + prompt to model)"
    echo "  2. Save model output as {MODEL_UPPER}-REVIEWS/<dim>.md"
    echo "  3. Check status:  ./quorum-review.sh --collect"
    echo "  4. Synthesize:    ./quorum-review.sh --synth"
    echo "  5. Feed synthesis prompt to aggregator model (recommended: Opus 4.8)"
    echo "  6. Update TODO.md from synthesis output"
    ;;
esac
