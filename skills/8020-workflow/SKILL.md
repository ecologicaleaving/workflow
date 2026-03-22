---
name: 8020-workflow
description: "80/20 Solutions team workflow rules for Ciccio and Claudio. Use when handling GitHub issues, creating/merging PRs, deploying apps, managing branches, writing commit messages, coordinating with Claude Code, triggering CI/CD builds, managing APK releases, processing /reject or /approve commands, moving Kanban board cards, or doing any development or infrastructure task. Ensures agents follow the correct process for the hybrid VPS+PC team system."
---

# 80/20 Solutions — Workflow

## ⚙️ STEP 0 — Verifica aggiornamento workflow (OBBLIGATORIO)

Prima di procedere con qualsiasi operazione GitHub, verifica che il workflow locale sia allineato alla versione online:

```bash
export PATH=$PATH:/root/go/bin
REMOTE_SHA=$(gh api "repos/ecologicaleaving/workflow/commits?path=skills/8020-workflow&per_page=1" --jq '.[0].sha' 2>/dev/null)
LOCAL_SHA=$(cat <SKILL_DIR>/.version 2>/dev/null || echo "none")

if [ "$REMOTE_SHA" != "$LOCAL_SHA" ]; then
  echo "⚠️ Workflow aggiornato online — notifica Davide prima di procedere"
fi
```

Dove `<SKILL_DIR>` è la directory locale di questa skill.

- **Se aggiornato online** → notifica Davide e chiedi se sincronizzare prima di procedere
- **Se allineato** → prosegui con l'operazione richiesta

---

## 🗺️ INDICE OPERAZIONI — Leggi solo il file che ti serve

| Operazione | File da leggere |
|-----------|----------------|
| Creare una issue | `references/CREATE_ISSUE.md` |
| Avviare lavorazione (assegnare agente) | `references/ISSUE_START.md` |
| Deploy su ambiente test | `references/DEPLOY_TEST.md` |
| /reject da Davide | `references/REJECT.md` |
| /approva da Davide → prod | `references/APPROVE_DEPLOY.md` |
| Kanban: colonne e regole | `references/KANBAN.md` |
| Branch e commit | `references/BRANCH_STRATEGY.md` |
| Convenzioni commit | `references/COMMIT_CONVENTIONS.md` |

---

## 👥 Ruoli (riferimento rapido)

| Chi | Cosa fa |
|-----|---------|
| **Davide** | Product owner, approva, testa |
| **Claudio (PC)** | Assegna agente, lancia lavorazione, supervisiona dev |
| **Ciccio (VPS)** | Crea issue, Kanban, deploy, infra |
| **Claude Code / Codex** | Sviluppo, commit, push |

## 🚨 REGOLA CARDINALE — Nessuna fix/patch senza autorizzazione

**Quando un agente (Claudio o Ciccio) identifica un problema, un bug, un errore di deploy, un workflow rotto, o qualsiasi anomalia:**

1. **NON applicare fix, patch, o workaround autonomamente**
2. **Segnalare il problema a Davide** con descrizione chiara e proposta di soluzione
3. **Aspettare l'autorizzazione esplicita di Davide** prima di toccare qualsiasi cosa

Questo vale per:
- Fix di codice (bug, errori, regressioni)
- Patch infrastrutturali (CI/CD, deploy, config VPS)
- Correzioni workflow YAML
- Modifiche database / migrazioni d'emergenza
- Qualsiasi intervento non pianificato nella issue originale

**Formato segnalazione:**
```
⚠️ Problema trovato: <descrizione>
📌 Causa: <cosa sta succedendo>
🔧 Proposta fix: <cosa farei>
❓ Autorizzo a procedere?
```

**Nessuna eccezione.** Anche se la fix sembra banale, Davide decide.

---

## 🏷️ Label agente (riferimento rapido)

- `agent:claude-code` — Claude Code (PC)
- `agent:ciccio` — Ciccio (VPS)
- `agent:codex` — Codex (PC)
- **MAI assegnare label agente senza indicazione di Davide**

## 📋 Kanban colonne (riferimento rapido)

| Colonna | Quando |
|---------|--------|
| `Backlog` | Issue creata, **nessun agente assegnato** |
| `Todo` | Label agente assegnata da Claudio |
| `In Progress` | Agente in lavorazione |
| `Test` | Build/APK disponibile — Davide testa |
| `Review` | Dopo /reject |
| `Deploy` | Dopo /approva — deploy prod in corso |
| `Done` | In produzione, issue chiusa |
