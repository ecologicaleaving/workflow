# Checkpoint Format Specification

## Overview

Checkpoints are structured comments posted on GitHub issues to track agent progress.
Each checkpoint contains both a **human-readable** section and a **machine-readable** JSON block.

## Format

```markdown
## ✅ Checkpoint N — <Title>

**Stato:** completato|in-progress|bloccato

**Cosa è stato fatto:**
- item 1
- item 2

**Risultati test:**
<test output or summary>

**Prossimo step pianificato:**
<description of next planned step>

**Auto-gate: verifico autonomamente prima di procedere. In caso di blocco notifico Davide.**

<!-- CHECKPOINT_DATA
{"checkpoint":N,"status":"completed|in-progress|blocked","items_completed":2,"next_step":"description"}
-->
```

## Fields

### Human-Readable Section

| Field | Required | Description |
|-------|----------|-------------|
| Checkpoint N | Yes | Sequential checkpoint number |
| Title | Yes | Brief description of what this checkpoint covers |
| Stato | Yes | One of: `completato`, `in-progress`, `bloccato` |
| Cosa è stato fatto | Yes | Bullet list of completed items |
| Risultati test | Yes | Test output, dry-run results, or "N/A" |
| Prossimo step pianificato | Yes | What comes next |
| Auto-gate line | Yes | Standard line documenting auto-gate result |

### Machine-Readable Block (`CHECKPOINT_DATA`)

The JSON block is embedded in an HTML comment so it's invisible when rendered but parseable by scripts.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `checkpoint` | number | Yes | Sequential checkpoint number (1-based) |
| `status` | string | Yes | One of: `completed`, `in-progress`, `blocked` |
| `items_completed` | number | Yes | Count of completed items in this checkpoint |
| `next_step` | string | Yes | Description of the next planned step |

## Parsing

Use `scripts/parse-checkpoint.sh` to extract checkpoint data from issue comments:

```bash
# All checkpoints as JSON array
./scripts/parse-checkpoint.sh 27 ecologicaleaving/workflow

# Last checkpoint only
./scripts/parse-checkpoint.sh --last 27 ecologicaleaving/workflow

# Status summary only
./scripts/parse-checkpoint.sh --status 27 ecologicaleaving/workflow
```

## Rules

1. Checkpoint numbers are sequential per issue (1, 2, 3, ...)
2. Each checkpoint MUST contain the `<!-- CHECKPOINT_DATA ... -->` block
3. The JSON block MUST be valid JSON on a single line
4. Agents proceed autonomously if gate passes; stop and notify Davide if blocked
5. Only one checkpoint per comment
