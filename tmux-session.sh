#!/usr/bin/env bash
# tmux-session.sh — Start or attach to the cinnabar tmux session.
#
# Layout (4 panes):
#
#   ┌──────────────────────────────┬──────────────────────────────┐
#   │  0: Big Pickle (orchestrator)│  1: Daily coding + mmc      │
#   │     OpenCode/agent prompt    │     (inside nix develop)    │
#   ├──────────────────────────────┼──────────────────────────────┤
#   │  2: Opus / architecture      │  3: Heavy lifts             │
#   │     (escalation target)      │     Aider + Ring / batch    │
#   └──────────────────────────────┴──────────────────────────────┘
#
# Usage:
#   ./tmux-session.sh              # create or attach
#   ./tmux-session.sh kill         # kill the session

set -euo pipefail

CINNABAR="$(cd "$(dirname "$0")" && pwd)"
SESSION="cinnabar"

kill_session() {
  if tmux has-session -t "$SESSION" 2>/dev/null; then
    tmux kill-session -t "$SESSION"
    echo "Killed session '$SESSION'."
  else
    echo "Session '$SESSION' does not exist."
  fi
  exit 0
}

if [[ "${1:-}" == "kill" ]]; then
  kill_session
fi

if tmux has-session -t "$SESSION" 2>/dev/null; then
  echo "Attaching to existing session '$SESSION'..."
  tmux attach-session -t "$SESSION"
  exit 0
fi

# Get the current HEAD rev for nix develop
HEAD=$(git -C "$CINNABAR" rev-parse HEAD 2>/dev/null || echo "unknown")
NIX_CMD="nix develop 'git+file://$CINNABAR?rev=$HEAD'"

# Create session with one window and 4 panes
tmux new-session -d -s "$SESSION" -c "$CINNABAR" -n "cinnabar"

# Pane 0: Big Pickle orchestrator
tmux send-keys -t "$SESSION:0.0" "echo '=== Big Pickle / orchestrator ==='" Enter
tmux send-keys -t "$SESSION:0.0" "echo 'Agent prompt — work on TODO.md items'" Enter

# Split horizontally: pane 0 left, pane 1 right
tmux split-window -h -t "$SESSION:0" -c "$CINNABAR"
tmux send-keys -t "$SESSION:0.1" "echo '=== Daily coding (nix develop) ==='" Enter
tmux send-keys -t "$SESSION:0.1" "$NIX_CMD" Enter

# Split vertically into bottom: pane 2 under pane 0, pane 3 under pane 1
tmux split-window -v -t "$SESSION:0.0" -c "$CINNABAR"
tmux send-keys -t "$SESSION:0.2" "echo '=== Opus / architecture (escalation) ==='" Enter

tmux split-window -v -t "$SESSION:0.1" -c "$CINNABAR"
tmux send-keys -t "$SESSION:0.3" "echo '=== Heavy lifts (Aider + Ring / batch jobs) ==='" Enter

# Set even-layout for balanced tiling
tmux select-layout -t "$SESSION:0" tiled 2>/dev/null || true

# Select pane 0 as active
tmux select-pane -t "$SESSION:0.0"

# Set window title
tmux rename-window -t "$SESSION:0" "cinnabar"

echo "Created session '$SESSION'. Attaching..."
tmux attach-session -t "$SESSION"
