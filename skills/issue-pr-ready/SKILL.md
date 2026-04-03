---
name: issue-pr-ready
description: >
  Post-implementation: pre-PR checklist, open PR, move Kanban card,
  add labels, notify Davide.
  Use when: all acceptance criteria are implemented and the branch is ready for review.
---

# Issue PR-Ready — Post-Implementation Flow

> Riferimento flusso: vedi `WORKFLOW.md` — Fase 4

Use when all acceptance criteria for an issue are complete
and the branch is ready for pull request and review.

## Prerequisites

- All acceptance criteria verified (code complete)
- Branch is up to date with target branch
- `config.json` is available in the workflow repo root
- `gh` CLI authenticated and available
- `scripts/generate-pr-body.sh` available in the workflow repo

## Procedure

### Step 1 — Pre-PR Checklist

Before opening the PR, verify ALL of the following:

- [ ] **All AC items implemented** — every acceptance criterion from the issue is done
- [ ] **Lint / test pass** — run project linter and tests, fix any failures
- [ ] **PROJECT.md updated** — if the project has a PROJECT.md, update it with changes
- [ ] **No unrelated changes** — diff only contains changes for this issue
- [ ] **Commits are clean** — atomic commits with `feat:` / `fix:` / `chore:` prefixes
- [ ] **Branch naming** — follows pattern from `config.json` → `workflow.branchPattern`

If any item fails, fix it before proceeding.

### Step 2 — Push Branch and Open PR

```bash
# Read config values
REPO=$(jq -r '.github.repos["<project>"]' config.json)
DEFAULT_BRANCH=$(jq -r '.workflow.defaultBranch' config.json)
BRANCH=$(git branch --show-current)

# Push branch
git push origin "$BRANCH"

# Generate PR body using the template script
PR_BODY=$(./scripts/generate-pr-body.sh "$ISSUE_NUMBER")

# Open PR
gh pr create \
  --repo "$REPO" \
  --base "$DEFAULT_BRANCH" \
  --head "$BRANCH" \
  --title "feat: #${ISSUE_NUMBER} — <issue title>" \
  --body "$PR_BODY"
```

### Step 3 — Move Kanban Card → Test

Move the issue card to the "Test" column on the project board:

```bash
# Read Kanban config
PROJECT_ID=$(jq -r '.github.kanban.projectId' config.json)
STATUS_FIELD_ID=$(jq -r '.github.kanban.statusFieldId' config.json)
TEST_COLUMN_ID=$(jq -r '.github.kanban.columns.Test.id' config.json)

# Use the kanban-move script or direct gh API
./scripts/kanban-move.sh "$ISSUE_NUMBER" "Test"
```

### Step 4 — Add Label `review-ready`

```bash
gh issue edit "$ISSUE_NUMBER" --repo "$REPO" --add-label "review-ready"
```

### Step 5 — Notify Davide

Send a structured notification to Davide with test instructions:

```
📋 Issue #<N> — <Title> pronta per test

**Branch:** <branch-name>
**PR:** <pr-url>
**Repo:** <repo>

**Cosa testare:**
1. <test instruction 1>
2. <test instruction 2>

**Come testare:**
- `git checkout <branch>`
- <run instructions>

**AC verificati dall'agente:**
- ✅ AC1 — <description>
- ✅ AC2 — <description>
...

Quando hai testato, usa:
- `/approva` se tutto ok
- `/reject <motivo>` se serve rework
```

## Note

- CI deploya automaticamente su test dopo il push del branch
- Bot Telegram notifica Davide con link + AC
- Dopo `/approva` di Davide → skill `issue-approve`
- Dopo `/reject` di Davide → skill `issue-reject`
- Valori config (project ID, field ID, column ID): vedi `config.json`
