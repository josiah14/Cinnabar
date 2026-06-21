# Cinnabar — Agent Guide

This file governs how AI agents interact with the cinnabar project.

---

## 1. Dev shell (Nix)

Development environment is a Nix flake. In FaradAI, `/nix/store` is read-only —
agents may use prebuilt store paths but may not build new ones.

### Enter the shell

Do **not** run `nix develop .` from a dirty checkout — Nix snapshots the
worktree into a new store path which needs a store write (fails in FaradAI).

Instead, enter through the current committed revision:

```bash
nix develop 'git+file:///home/josiah/Development/personal/education/self/polyparadigm-project/cinnabar?rev=1a90a5e62aca85dfcb7af05c26ec45466031a73f'
```

For a single command:

```bash
nix develop 'git+file:///home/josiah/Development/personal/education/self/polyparadigm-project/cinnabar?rev=1a90a5e62aca85dfcb7af05c26ec45466031a73f' --command mmc --version
```

When HEAD moves, replace `rev=` with `git rev-parse HEAD` output. This works
only if FaradAI has prebuilt that revision's flake closure.

---

## 2. Quorum review workflow

The project uses a **quorum-of-models** review pipeline. The lifecycle:

```
Review ─→ Synthesize ─→ Prioritize ─→ Assign ─→ Fix & verify
  ↑                                                    │
  └────────────────────────────────────────────────────┘
        (next cycle: re-review after fixes)
```

### 2.1 Review phase

Run N independent review passes, each covering 6 dimensions:

| # | Dimension | Focus |
|---|-----------|-------|
| 1 | README quality | Clarity, navigation, accuracy of descriptions |
| 2 | Coverage breadth + depth | What's missing vs. what's shallow |
| 3 | Correctness | Compilation, runtime, contract bugs |
| 4 | Code quality | Idiom, hygiene, dead code, imports |
| 5 | Idiomatic Mercury | Mode/determinism/type patterns, Prolog-isms |
| 6 | Overall | Synthesis + scoring |

Each reviewer produces 6 markdown files: `01-readme-quality.md` through `06-overall.md`.

### 2.2 Synthesis phase

A single aggregator model reads all review passes and produces:

1. **`REVIEWS-SYNTHESIS/SYNTHESIS.md`** — adjudicates conflicts, derives consensus,
   notes which reviewer missed what. Calibration note about each model's bias.

2. **`TODO.md`** — prioritized action items with model-fit tags.

### 2.3 TODO.md conventions

Each item is tagged with:

| Tag | Meaning |
|-----|---------|
| `[Opus]` | Needs correct Mercury determinism/mode/type reasoning. Wrong fix risk. |
| `[Sonnet]` | Mechanical/editorial, clear acceptance criteria. Cheaper path. |
| `[User]` | Interactive infra (SSH/keys). Agent cannot do this. |
| `[any]` | Any model can pick this up. |

Effort tags:

| Tag | Meaning |
|-----|---------|
| `{max}` | Open-ended research; must compile-fail/compile-pass for exact reason |
| `{xhigh}` | Non-local correctness reasoning (e.g. concurrency) |
| `{high}` | Concrete refactor with clear acceptance criteria |

**Hard rule:** any code change must be verified inside `nix develop` with `mmc`.
"Looks plausible" is not done.

### 2.4 Assignment phase

Assign `[Opus]` items to Opus 4.8, `[Sonnet]` items to DeepSeek V4 Flash Free
(or Sonnet 4.6 if available), `[User]` items to the human.

---

## 3. Model roles & capabilities

| Model | Role | SWE-bench | Cost | When to use |
|-------|------|-----------|------|-------------|
| **Big Pickle** (me) | Orchestrator, reviews, daily coding | ~72% | $0 | Default orchestrator, non-expert reviews, simple fixes |
| **DeepSeek V4 Flash Free** | Daily coding agent | 79.0% (52.6% Pro) | $0 | Most code work — beats Big Pickle on correctness |
| **Nemotron 3 Ultra Free** | Long-context specialist | 71% | $0 | Files >50K tokens where Big Pickle context degrades; 1M ctx |
| **Sonnet 4.6** | Mechanical/editorial | 79.6% | $3/$15 | `[Sonnet]`-tagged TODO items when quality matters |
| **Opus 4.8** | Architecture + hard Pro | 88.6% (69.2% Pro) | $5/$25 | `[Opus]` items, architectural decisions, SWE-bench Pro |
| **Ring 2.6-1T** | Heavy lifts (via Aider) | 74.0% | ~$0.08/$0.63 | Cheap bulk refactoring, large-file edits |
| **Laguna M.1** | Parallel review (OpenRouter free) | 74.6% | $0 | Best OpenRouter free model for quorum reviews |

**Caveats:**
- Big Pickle context degrades past ~50-70K despite 200K spec. Use Nemotron for very long files.
- DeepSeek V4 Flash Free is a limited-time offer — may be deprecated.
- Ring is generous/misses defects — treat "looks correct" as weak evidence.
- Codex is the harshest grader but produced one incorrect technical claim (`solutions/2` sort).

### Review model assignments

For quorum reviews, run at least 3 models in parallel:

| Run | Models | Rationale |
|-----|--------|-----------|
| Primary | Laguna M.1 + DeepSeek V4 Flash + Big Pickle | Three free models covering different biases |
| Escalation | Add Opus 4.8 | When consensus disagrees or hard Pro bugs |
| Deep-dive | Ring 2.6-1T | Cheap bulk pass over large codebase |

---

## 4. File layout conventions

```
Agents.md                   ← this file
TODO.md                     ← prioritized action items with model-fit tags
ci.sh                       ← authoritative CI gate (run inside nix develop)
REVIEW.md                   ← historical, superseded by REVIEWS-SYNTHESIS/
REVIEWS-SYNTHESIS/SYNTHESIS.md  ← adjudicated multi-model synthesis
{OPUS,CODEX,RING,BIG-PICKLE}-REVIEWS/
   01-readme-quality.md
   02-coverage.md
   03-correctness.md
   04-code-quality.md
   05-idiomatic-mercury.md
   06-overall.md
```

New review runs:

- `DEEPSEEK-REVIEWS/` — DeepSeek V4 Flash Free reviews
- `LAGUNA-REVIEWS/` — Laguna M.1 reviews (OpenRouter)
- `SONNET-REVIEWS/` — Sonnet 4.6 reviews
- Additional reviewers use `{MODEL}-REVIEWS/` pattern.

---

## 5. Tmux session layout

The recommended tmux session (`cinnabar`) uses 4 panes:

```
┌──────────────────────────────┬──────────────────────────────┐
│                              │                              │
│  0: Big Pickle (orchestrator)│  1: DeepSeek V4 Flash        │
│     prompt for orchestrator  │     (daily coding + mmc)     │
│                              │     within nix develop       │
│                              │                              │
├──────────────────────────────┼──────────────────────────────┤
│                              │                              │
│  2: Opus / Architecture      │  3: Heavy lifts             │
│     (escalation)             │     Aider + Ring / bulk      │
│                              │                              │
└──────────────────────────────┴──────────────────────────────┘
```

Pane 1 should be inside `nix develop` for `mmc` access. All panes share the
same working directory (`~/Development/personal/education/self/polyparadigm-project/cinnabar`).

---

## 6. CI gate

Run before any commit that touches `.m` files:

```bash
nix develop 'git+file:///home/josiah/Development/personal/education/self/polyparadigm-project/cinnabar?rev=<HEAD>' --command ./ci.sh
```

Rules:
- `*_koan.m` files (not in `solution/`) must FAIL compilation.
- `solution/*.m` files in koans must PASS compilation.
- `katas/*/start.m` files must PASS compilation.
- bridge starter `*.m` files (not in `solution/`) must PASS compilation.
- bridge `solution/*.m` files must PASS compilation.
- `puzzles/*/solution/*.m` files must PASS compilation.
- Koans with `.err` snapshots must produce matching diagnostic output.
- Bridge solution README ` ```mercury ` code blocks are extracted and syntax-checked.

---

## 7. Quick reference

```bash
# Enter dev shell
nix develop 'git+file:///home/josiah/Development/personal/education/self/polyparadigm-project/cinnabar?rev=$(git rev-parse HEAD)'

# Build + run a Mercury file
mmc --make --grade asm_fast.par.gc.stseg <module> && ./<module>

# Run CI gate
nix develop ... --command ./ci.sh

# Start tmux session
tmux new-session -s cinnabar
```
