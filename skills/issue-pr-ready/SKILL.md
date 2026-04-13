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

- Auto-gate finale superato (issue-implement Step 5)
- Branch aggiornato rispetto al branch target
- `config.json` disponibile nella root del workflow repo
- `gh` CLI autenticato e disponibile
- `scripts/generate-pr-body.sh` disponibile nel workflow repo

## Procedure

### Step 1 — Push Branch e Apertura PR

```bash
# Leggi valori da config
REPO=$(jq -r '.github.repos["<project>"]' config.json)
DEFAULT_BRANCH=$(jq -r '.workflow.defaultBranch' config.json)
BRANCH=$(git branch --show-current)

# Push branch
git push origin "$BRANCH"

# Genera body PR dal template
PR_BODY=$(./scripts/generate-pr-body.sh "$ISSUE_NUMBER")

# Apri PR
gh pr create \
  --repo "$REPO" \
  --base "$DEFAULT_BRANCH" \
  --head "$BRANCH" \
  --title "feat: #${ISSUE_NUMBER} — <issue title>" \
  --body "$PR_BODY"
```

### Step 2 — Sposta Card Kanban → Test

```bash
./scripts/kanban-move.sh "$ISSUE_NUMBER" "$REPO" Test
```

### Step 3 — Aggiungi Label `review-ready`

```bash
gh issue edit "$ISSUE_NUMBER" --repo "$REPO" --add-label "review-ready"
```

### Step 4 — Notifica Davide

```
✅ [Issue #N] PR pronta → <link PR>
📌 <summary>

🧪 Come testare:
1. <istruzione 1>
2. <istruzione 2>

💡 Cosa aspettarsi:
<risultato atteso>

**AC verificati:**
- ✅ AC1 — <descrizione>
- ✅ AC2 — <descrizione>

→ /approva se ok | /reject <motivo> se serve rework
```

## Note

- CI deploya automaticamente su test dopo il push del branch
- Dopo `/approva` di Davide → skill `issue-approve`
- Dopo `/reject` di Davide → skill `issue-reject`
- Valori config (project ID, field ID, column ID): vedi `config.json`
