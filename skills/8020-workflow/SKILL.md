---
name: 8020-workflow
description: "80/20 Solutions team workflow rules for Ciccio. Use when handling GitHub issues, creating/merging PRs, deploying apps, managing branches, writing commit messages, coordinating with Claude Code, triggering CI/CD builds, managing APK releases, processing /reject or /approve commands, moving Kanban board cards, or doing any development or infrastructure task. Ensures Ciccio follows the correct process for the hybrid VPS+PC team system."
---

# 80/20 Solutions — Workflow (Ciccio)

## Ruoli nel team
- **Davide**: Product owner, testa APK, approva deploy in produzione
- **Ciccio (VPS)**: Orchestrazione, deploy, infra, monitoring, issue management (label `ciccio`)
- **Claude Code (PC)**: Development senior, commit, push (label `claude-code`)
- **Codex (PC)**: Development alternativo, commit, push (label `codex`)

## 📋 Board Kanban — 7 colonne
**GitHub Project**: https://github.com/users/ecologicaleaving/projects/2

| Colonna | Chi sposta | Quando |
|---------|-----------|--------|
| `Backlog` | Ciccio | Issue creata, nessun agente assegnato |
| `Todo` | Ciccio/Davide | Label agente assegnata, pronta per lavorazione |
| `In Progress` | Ciccio/Agente | Agente ha preso in carico |
| `Test` | Ciccio | PR aperta + APK/build disponibile — Davide testa |
| `Review` | Ciccio | Dopo /reject — agente sta rilavorando |
| `Deploy` | Ciccio | Dopo /approve — deploy prod in corso |
| `Done` | Ciccio | Issue chiusa, in produzione |

## Flusso standard

```
Issue creata → Todo
  → agente inizia → In Progress
  → PR aperta + build → Test → notifica Davide

Davide testa:
  /approve → Deploy → Done (merge → prod)
  /reject  → Review (agente rilav ora) → Test
```

## Quando Ciccio riceve /reject
1. Aggiungi commento GitHub con feedback completo
2. Sposta card: `Test` → `Review` (non toccare le label)
3. Lavora il fix → quando pronto → sposta card: `Review` → `Test`
4. Notifica Davide con nuovo APK/link

## Quando Ciccio riceve /approve
1. Mergia PR su master
2. Sposta card: `Test` → `Deploy`
3. Deploya in produzione
4. Sposta card: `Deploy` → `Done`, chiudi issue
5. Notifica Davide con link prod

## Quando Ciccio fa deploy test (dopo PR aperta)
1. Build/APK disponibile (CI verde)
2. Sposta card: `In Progress` → `Test`
3. Notifica Davide con link APK/URL test

## Regole fondamentali
- **Mai committare su master/main** — sempre feature branch + PR
- **PROJECT.md** va aggiornato ad ogni issue completata (version bump + DONE)
- **APK test**: `https://apps.8020solutions.org/downloads/test/`
- **ciccio-notify**: `/usr/local/bin/ciccio-notify` per notifiche da CI
- **Deploy key**: `/root/.ssh/github-actions-deploy`

## Labels sistema
Le issue usano **sole due label**:
1. **Label progetto** — nome del progetto (es. `beachref`, `finn`)
2. **Label agente** — chi lavora l'issue (`ciccio`, `claude-code`, `codex`)

| Label | Significato |
|-------|-------------|
| `ciccio` | Ciccio (VPS) — routing obbligatorio |
| `claude-code` | Claude Code (PC) — routing obbligatorio |
| `codex` | Codex (PC) — routing obbligatorio |

**Regole:**
- Le label di stato (`in-progress`, `review-ready`, `deployed-test`, `needs-fix`) NON si usano — lo stato è indicato dalla colonna Kanban
- Label agente NON viene mai rimossa durante la lavorazione
- VPS skippa sempre issue con `claude-code` o `codex`

## Riferimenti completi
- `references/WORKFLOW_CICCIO.md` — procedure complete Ciccio
- `references/WORKFLOW_CLAUDE_CODE.md` — workflow Claude Code (coordinamento)
- `references/BRANCH_STRATEGY.md` — git branching
- `references/COMMIT_CONVENTIONS.md` — formato commit
