---
name: 8020-workflow
description: "80/20 Solutions team workflow rules. Use when handling GitHub issues, PRs, deploy, branches, commits, Kanban, or any development/infrastructure task."
---

# 80/20 Solutions — Workflow

## ⚙️ STEP 0 — Verifica aggiornamento workflow (OBBLIGATORIO)

Prima di procedere con qualsiasi operazione GitHub:

```bash
REMOTE_SHA=$(gh api "repos/ecologicaleaving/workflow/commits?path=WORKFLOW.md&per_page=1" --jq '.[0].sha' 2>/dev/null)
LOCAL_SHA=$(cat <SKILL_DIR>/.version 2>/dev/null || echo "none")

if [ "$REMOTE_SHA" != "$LOCAL_SHA" ]; then
  echo "⚠️ Workflow aggiornato online — notifica Davide prima di procedere"
fi
```

---

## 📖 Riferimento principale

Il flusso completo, ruoli, comandi, modelli agente e Kanban sono in **`WORKFLOW.md`** nella root del repo.

Leggi `WORKFLOW.md` per il quadro generale. Leggi la skill specifica solo per la fase che stai eseguendo.

---

## 🗺️ INDICE OPERAZIONI — Leggi solo il file che ti serve

| Operazione | Dove |
|-----------|------|
| Flusso completo, ruoli, comandi, Kanban | `WORKFLOW.md` (root) |
| Creare una issue | skill `create-issue` |
| Validare + pianificare una issue | skill `issue-validate` |
| Implementazione con checkpoint | skill `issue-implement` |
| Apertura PR + notifica | skill `issue-pr-ready` |
| /approva → merge + chiusura | skill `issue-approve` |
| /reject → rework | skill `issue-reject` |
| Reject complesso (≥2) | skill `issue-research-rework` |
| Branch e commit | `COMMIT_CONVENTIONS.md` |
| Security pre-push | skill `security-audit` |

---

## 🚨 REGOLA CARDINALE

**Nessun fix/patch senza autorizzazione esplicita di Davide.**

```
⚠️ Problema trovato: <descrizione>
📌 Causa: <cosa sta succedendo>
🔧 Proposta fix: <cosa farei>
❓ Autorizzo a procedere?
```

Nessuna eccezione. Anche se la fix sembra banale, Davide decide.

---

## 👥 Modello ruoli attuale

- **Davide** — Product Owner: comanda, testa, approva/reject
- **Agente** (Claude Code) — fa tutto il resto in autonomia

Claudio e Ciccio non sono più ruoli attivi. L'agente gestisce issue, kanban, implementazione, PR e merge.
