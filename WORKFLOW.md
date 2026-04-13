# WORKFLOW.md — 80/20 Solutions Development Workflow

**Versione:** 4.0.0 | **Aggiornato:** 2026-04-13

> Fonte di verità unica per il flusso di sviluppo del team.
> I valori strutturati (ID Kanban, repo, label) stanno in `config.json`.
> Le procedure dettagliate stanno nelle skill — qui c'è il "cosa e chi", le skill hanno il "come".

---

## 👥 Ruoli

| Chi | Ruolo | Cosa fa | Cosa NON fa |
|-----|-------|---------|-------------|
| **Davide** | Product Owner | Decide, testa, approva/reject, dà i comandi | Non implementa, non deploya |
| **Agente** (Claude Code) | Sviluppatore autonomo | Tutto il resto: issue, research, piano, implementazione, kanban, PR, merge | Non decide senza autorizzazione di Davide |

> ⚠️ **Regola cardinale:** Nessun fix/patch senza autorizzazione esplicita di Davide.
> ⚠️ **Repo workflow:** Solo l'agente modifica `ecologicaleaving/workflow` su indicazione di Davide.

---

## 🤖 Modello Agente

**Un solo agente** (`claude-sonnet-4-6` via Claude Code) gestisce l'intero ciclo:
research → piano → implementazione → PR → merge.

L'agente mantiene il contesto dall'esplorazione al codice — zero passaggi tra agenti diversi.

---

## 📋 Comandi Davide

| Comando | Effetto |
|---------|---------|
| `/create-issue` | Agente raccoglie info e crea issue → Backlog |
| `/issue-validate #N` | Agente completa la issue con AC, research, piano → Todo |
| `/vai` | Agente avvia implementazione |
| `/approva` | Agente mergia PR su main → CI deploya automaticamente |
| `/reject <feedback>` | Agente registra feedback e rilancia rework |

---

## 🔄 Flusso Completo

```
Davide descrive problema/feature
         ↓
    FASE 1 — Creazione issue → Backlog
         ↓
    FASE 2 — Validazione + Piano → Todo
         ↓
    /vai (Davide)
         ↓
    FASE 3 — Implementazione (auto-gate) → InProgress
         ↓
    FASE 4 — PR + Deploy test automatico → Test
         ↓
    Davide testa
    ├── /approva → Agente mergia → CI deploya prod → Done
    └── /reject  → Rework → loop da Fase 3
```

---

## FASE 1 — Creazione Issue

**Chi:** Agente
**Skill:** `create-issue`
**Kanban:** → Backlog

Raccolta rapida: repo, tipo (bug/feature/improvement), obiettivo in una riga.
Issue leggera — i dettagli arrivano nella Fase 2.

---

## FASE 2 — Validazione + Piano

**Chi:** Agente (interattivo con Davide)
**Skill:** `issue-validate`
**Kanban:** Backlog → Todo

1. **Domande a Davide** — AC, edge case, dipendenze, note tecniche (una alla volta)
2. **Verifica deploy** — CI pipeline, secrets, sottodomini (una volta per repo)
3. **Esplora + pianifica** — research e piano in un colpo solo
4. **Auto-validazione** — check formale: AC coperti, scope ok, niente red flag
5. **Notifica Davide** — piano pronto, aspetta `/vai`

> ⚠️ L'agente NON avvia mai l'implementazione senza `/vai` esplicito di Davide.

---

## FASE 3 — Implementazione

**Chi:** Agente
**Skill:** `issue-implement`
**Kanban:** Todo → InProgress (dopo `/vai`)

### Auto-gate

L'agente procede in autonomia e si auto-blocca solo su anomalie o al gate finale.

| Momento | Cosa succede |
|---------|-------------|
| Dopo `/vai` | Agente implementa in autonomia |
| Anomalia | Agente si blocca e notifica Davide |
| **Gate finale** | Agente verifica: AC ok, test ok, build ok, security audit ok |
| Gate superato | Agente procede a push + PR automaticamente |
| Gate fallito | Agente fixa e ripete il gate |

### Notifica a Davide (dopo push + PR)

```
✅ [Issue #N] Implementazione completata, PR aperta
📌 <summary cosa è stato fatto>
🔗 <link PR>
⏭️ Testa su test-<repo>.8020solutions.org
```

Anomalia non risolvibile → blocca, notifica Davide, aspetta istruzioni.
Più di 5 iterazioni senza convergere → blocco automatico.

### Security Audit (obbligatorio pre-push)

**Skill:** `security-audit`
L'agente esegue `scripts/security-audit.sh` + check manuali prima del push.

---

## FASE 4 — PR + Deploy Test

**Chi:** Agente + CI (deploy automatico)
**Skill:** `issue-pr-ready`
**Kanban:** InProgress → Test

1. Agente verifica checklist pre-PR (AC, test, PROJECT.md, niente file anomali)
2. Agente apre PR con summary strutturato
3. CI deploya automaticamente su `test-<repo>.8020solutions.org`
4. Agente aggiunge label `review-ready`
5. Agente notifica Davide con link e istruzioni di test

### Notifica Davide

```
✅ [Issue #N] PR pronta → <link PR>
📌 <summary>

🧪 Come testare:
<passi concreti>

💡 Cosa aspettarsi:
<risultato atteso>

→ /approva se ok | /reject <motivo> se serve rework
```

---

## FASE 5a — Approvazione

**Chi:** Agente
**Skill:** `issue-approve`
**Kanban:** Test → Done

1. Agente mergia la PR su main: `gh pr merge --merge --delete-branch`
2. CI deploya automaticamente in produzione
3. Agente chiude la issue e aggiunge label `deployed-prod`
4. Agente notifica Davide con conferma
5. **Se servono azioni infra** (env vars, migrazioni DB) → Agente elenca le azioni da eseguire manualmente e le comunica a Davide

---

## FASE 5b — Reject + Rework

**Chi:** Agente
**Skill:** `issue-reject` (per reject semplici) | `issue-research-rework` (per reject complessi ≥2)
**Kanban:** Test → Review → InProgress → Test (loop)

1. Agente registra feedback + risultati test come commento sulla issue
2. Label: rimuove `review-ready`, aggiunge `needs-fix`
3. Agente rilancia rework con feedback come contesto
4. Stesso flusso Fase 3 → Fase 4
5. Loop fino a `/approva`

---

## 📊 Kanban

| Colonna | Significato | Chi sposta |
|---------|-------------|------------|
| **Backlog** | Issue creata | Agente (create-issue) |
| **Todo** | Validata, piano pronto, aspetta /vai | Agente (issue-validate) |
| **InProgress** | Agente al lavoro | Agente (dopo /vai) |
| **Test** | PR aperta, CI ha deployato in test | Agente (issue-pr-ready) |
| **Review** | Reject, rework in corso | Agente (issue-reject) |
| **Done** | Mergiato, in produzione, chiuso | Agente (issue-approve) |

### Label

| Label | Significato |
|-------|-------------|
| `agent:claude-code` | Agente Claude Code assegnato |
| `in-progress` | Agente al lavoro |
| `review-ready` | PR pronta per test Davide |
| `deployed-test` | Live su test (aggiunta da CI) |
| `needs-fix` | Reject, rework in corso |
| `deployed-prod` | Live in produzione |

---

## 🗺️ Mappa Skill

| Skill | Quando si usa |
|-------|--------------|
| `create-issue` | Fase 1 — creazione issue leggera |
| `issue-validate` | Fase 2 — validazione completa + research + piano |
| `issue-implement` | Fase 3 — implementazione con auto-gate |
| `issue-pr-ready` | Fase 4 — checklist pre-PR, apertura PR, notifiche |
| `issue-approve` | Fase 5a — merge + chiusura dopo /approva |
| `issue-reject` | Fase 5b — rework dopo reject semplice |
| `issue-research-rework` | Fase 5b — research approfondita per reject complessi |
| `security-audit` | Pre-push — gate di sicurezza obbligatorio |
| `8020-commit-workflow` | Convenzioni commit |
| `create-prd` | Creazione PRD da brief |
| `prd-to-issues` | Breakdown PRD in issue |
| `preparazione-repo` | Setup iniziale repo per workflow 8020 |
| `pdf-to-md` | Converti PDF in Markdown prima di leggerli (obbligatoria per tutti) |

---

## 📂 Script condivisi

Usa sempre gli script in `scripts/` invece di comandi inline:

| Script | Cosa fa |
|--------|---------|
| `kanban-move.sh` | Sposta card Kanban (legge ID da config.json) |
| `generate-pr-body.sh` | Genera body PR dal template |
| `security-audit.sh` | Check automatici sicurezza pre-push |

---

## 📝 Convenzioni

- **Branch:** `feature/issue-N-slug`, `fix/issue-N-slug`
- **Commit:** Conventional Commits (`feat:`, `fix:`, `chore:`, `docs:`)
- **Niente commit su main/master**
- **PROJECT.md** aggiornato prima di ogni PR
- **Weekly tracking:** dopo ogni merge, riga in `memory/weekly/current.md`
