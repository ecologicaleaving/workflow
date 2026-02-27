---
name: 8020-workflow
description: "80/20 Solutions team workflow rules for Ciccio. Use when handling GitHub issues, creating/merging PRs, deploying apps, managing branches, writing commit messages, coordinating with Claude Code, triggering CI/CD builds, managing APK releases, processing /reject or /approve commands, moving Kanban board cards, or doing any development or infrastructure task. Ensures Ciccio follows the correct process for the hybrid VPS+PC team system."
---

# 80/20 Solutions — Workflow (Ciccio)

## Ruoli nel team
- **Davide**: Product owner, testa APK, approva deploy in produzione
- **Ciccio (VPS)**: Orchestrazione, deploy, infra, monitoring, issue management
- **Claude Code (PC)**: Development, commit, push (label `claude-code`)

## 📋 Board Kanban — 5 colonne
**GitHub Project**: https://github.com/users/ecologicaleaving/projects/2

| Colonna | Chi sposta | Quando |
|---------|-----------|--------|
| `📥 Backlog` | Ciccio | Issue creata, nessun agente assegnato |
| `📋 Todo` | Ciccio/Davide | Label agente assegnata / dopo /reject |
| `🔄 In Progress` | Monitor | Solo quando agente prende in carico |
| `🚀 PUSH` | Monitor/Agente | Commit fatto (label review-ready) |
| `🧪 Test` | CI GitHub Actions | APK deployato (label deployed-test) |
| `✔️ Done` | Ciccio | /approve + deploy prod |

## Flusso standard

```
Issue creata → label agent:xxx → 📋 Todo
  → agente inizia → 🔄 In Progress
  → commit/push → 🚀 PUSH (review-ready)
  → Ciccio deploya test → 🧪 Test → notifica Davide

Davide testa:
  /approve → ✔️ Done (merge → prod)
  /reject  → 🔄 In Progress (routing automatico per agente)
```

## Quando Ciccio riceve /reject
1. Aggiungi commento GitHub con feedback completo
2. Rimuovi `deployed-test`, aggiungi `needs-fix`
3. Sposta card: `🧪 Test` → `📋 Todo` (il monitor la prende al prossimo ciclo)
4. **NON** toccare la label `agent:xxx` (il monitor la usa per routing)
5. `🔄 In Progress` scatta solo quando il monitor spawna l'agente

Per dettagli routing agente, leggi `references/WORKFLOW_CICCIO.md`.

## Quando Ciccio fa deploy test
1. Pull da GitHub releases/
2. Deploy su `test-REPO.8020solutions.org`
3. Sposta card: `🚀 PUSH` → `🧪 Test`
4. Notifica Davide con link APK/URL test

## Regole fondamentali
- **Mai committare su master/main** — sempre feature branch + PR
- **PROJECT.md** va aggiornato ad ogni issue completata (version bump + DONE)
- **APK test**: `https://apps.8020solutions.org/downloads/test/`
- **ciccio-notify**: `/usr/local/bin/ciccio-notify` per notifiche da CI
- **Deploy key**: `/root/.ssh/github-actions-deploy`

## Labels sistema
| Label | Significato |
|-------|-------------|
| `claude-code` | Claude Code (PC) |
| `ciccio` | Ciccio (VPS) |
| `in-progress` | In lavorazione |
| `review-ready` | Pronto per test Davide |
| `deployed-test` | Live su test |
| `needs-fix` | Rifiutato, da rilavorare |

## Riferimenti completi
- `references/WORKFLOW_CICCIO.md` — procedure complete Ciccio
- `references/WORKFLOW_CLAUDE_CODE.md` — workflow Claude Code (coordinamento)
- `references/BRANCH_STRATEGY.md` — git branching
- `references/COMMIT_CONVENTIONS.md` — formato commit
