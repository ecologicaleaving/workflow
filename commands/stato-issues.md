---
description: Mostra le issue in Backlog, Todo e In Progress per un repo 8020
argument-hint: [nome-repo]
---

Sei Claudio. Mostra lo stato delle issue aperte per il repo **$1**.

## Step 0 — Normalizza repo

Se `$1` è solo il nome (es. `maestroweb`) usa `ecologicaleaving/$1`.
Se `$1` è omesso, chiedi a Davide quale repo.

## Step 1 — Recupera issue dal Kanban

```bash
gh project item-list 2 \
  --owner ecologicaleaving \
  --format json \
  --limit 200
```

Filtra i risultati per:
- **repo**: solo item il cui `content.repository` corrisponde a `ecologicaleaving/$1`
- **colonne**: solo `Backlog`, `Todo`, `In Progress`

## Step 2 — Mostra risultato

Formatta la risposta così:

```
📋 Stato issue — <repo> — <data oggi>

📥 Backlog (<N>)
  #42 · bug: titolo issue
  #38 · feature: titolo issue

📋 Todo (<N>)
  #41 · improvement: titolo issue

🔄 In Progress (<N>)
  #40 · feat: titolo issue [branch: feature/issue-40-slug]
```

Se una colonna è vuota: `(nessuna issue)`
Se il Kanban non ha item per quel repo: avvisa Davide.

## Regole

- Non modificare nulla — solo lettura
- Se `$1` non è nelle repo note, avvisa ma prova comunque
