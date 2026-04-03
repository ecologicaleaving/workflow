# WORKFLOW.md — 80/20 Solutions Development Workflow

**Versione:** 3.0.0 | **Aggiornato:** 2026-04-03

> Fonte di verità unica per il flusso di sviluppo del team.
> I valori strutturati (ID Kanban, repo, label) stanno in `config.json`.
> Le procedure dettagliate stanno nelle skill — qui c'è il "cosa e chi", le skill hanno il "come".

---

## 👥 Ruoli

| Chi | Ruolo | Cosa fa | Cosa NON fa |
|-----|-------|---------|-------------|
| **Davide** | Product Owner | Decide, testa, approva/reject | Non implementa, non deploya |
| **Claudio** (PC) | Supervisore | Crea issue, lancia agenti, supervisiona, mergia PR | Non scrive codice MAI, non gestisce infra |
| **Ciccio** (VPS) | Infra & Deploy | Gestisce VPS, DB, domini, azioni infra su richiesta | Non modifica il workflow, non lancia agenti |
| **Agente** (Sonnet) | Sviluppatore | Research, piano, implementazione, test | Non mergia, non deploya, non decide |

> ⚠️ **Regola cardinale:** Nessun fix/patch senza autorizzazione esplicita di Davide.
> ⚠️ **Repo workflow:** Solo Claudio modifica `ecologicaleaving/workflow`. Ciccio segnala → Davide decide → Claudio implementa.

---

## 🤖 Modello Agente

**Un solo agente Sonnet** (`anthropic/claude-sonnet-4-6`) per l'intero ciclo: research → piano → implementazione.

L'agente mantiene il contesto dall'esplorazione al codice — zero passaggi di informazione tra agenti diversi, zero context reload.

---

## 📋 Comandi Davide

| Comando | Effetto |
|---------|---------|
| `/create-issue` | Claudio raccoglie info e crea issue → Backlog |
| `/issue-validate #N` | Claudio completa la issue con AC, research, piano → Todo |
| `/vai` | Claudio avvia implementazione agente |
| `/approva` | Claudio mergia PR su main → CI deploya automaticamente |
| `/reject <feedback>` | Claudio registra feedback, rilancia agente in rework |

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
    FASE 3 — Implementazione (checkpoint) → InProgress
         ↓
    FASE 4 — PR + Deploy test automatico → Test
         ↓
    Davide testa
    ├── /approva → Claudio mergia → CI deploya prod → Done
    └── /reject  → Rework → loop da Fase 3
```

---

## FASE 1 — Creazione Issue

**Chi:** Claudio
**Skill:** `create-issue`
**Kanban:** → Backlog

Raccolta rapida: repo, tipo (bug/feature/improvement), obiettivo in una riga.
Issue leggera — i dettagli arrivano nella Fase 2.

---

## FASE 2 — Validazione + Piano

**Chi:** Claudio (interattivo con Davide) → Sonnet (research + piano)
**Skill:** `issue-validate`
**Kanban:** Backlog → Todo

1. **Domande a Davide** — AC, edge case, dipendenze, note tecniche (una alla volta)
2. **Verifica deploy** — CI pipeline, secrets, sottodomini (una volta per repo, non ripetere se già verificato)
3. **Sonnet esplora + pianifica** — un solo agente fa research e piano in un colpo
4. **Valutazione Claudio** — check formale: AC coperti, scope ok, niente red flag
5. **Notifica Davide** — piano pronto, aspetta `/vai`

> ⚠️ Claudio NON avvia mai l'implementazione senza `/vai` esplicito.
> Dopo `/vai`, lo **stesso agente** prosegue con l'implementazione (nessun respawn).

---

## FASE 3 — Implementazione

**Chi:** Claudio (supervisione) + stesso Sonnet della Fase 2 (esecuzione)
**Skill:** `issue-implement`
**Kanban:** Todo → InProgress (dopo `/vai`)

### Checkpoint

L'agente procede in autonomia e si ferma al **gate finale** (pronto per push).
Se incontra anomalie, si auto-blocca e notifica Claudio.

| Momento | Cosa succede |
|---------|-------------|
| Dopo `/vai` | Agente implementa in autonomia (no checkpoint intermedi) |
| Anomalia | Agente si blocca, notifica Claudio → Claudio notifica Davide |
| **Gate finale** | Agente posta checkpoint: AC verificati, test passati, build ok, security audit ok |
| Claudio valida | `✅ procedi` (push) oppure `🔴 bloccato` (fix) |

### Notifica a Davide (al gate finale)

```
✅ [Issue #N] Implementazione completata
📌 <summary cosa è stato fatto>
⏭️ Apro la PR dopo verifica finale
```

Anomalia → blocca agente, notifica Davide, aspetta istruzioni.
Più di 5 iterazioni senza convergere → blocco automatico.

### Security Audit (obbligatorio pre-push)

**Skill:** `security-audit`
L'agente esegue `scripts/security-audit.sh` + check manuali prima del push.

---

## FASE 4 — PR + Deploy Test

**Chi:** Claudio (PR) + CI (deploy automatico)
**Skill:** `issue-pr-ready`
**Kanban:** InProgress → Test

1. Claudio verifica checklist pre-PR (AC, test, PROJECT.md, niente file anomali)
2. Claudio apre PR con summary strutturato
3. CI deploya automaticamente su `test-<repo>.8020solutions.org`
4. Bot Telegram notifica Davide con link + AC da verificare
5. Claudio aggiunge label `review-ready`

### Notifica Davide (con istruzioni di test)

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

**Chi:** Claudio
**Skill:** `issue-approve`
**Kanban:** Test → Done

1. Claudio mergia la PR su main: `gh pr merge --merge --delete-branch`
2. CI deploya automaticamente in produzione
3. Claudio chiude la issue e aggiunge label `deployed-prod`
4. Claudio notifica Davide con conferma
5. **Se servono azioni infra** (env vars, migrazioni DB) → Claudio prepara messaggio per Ciccio, lo propone a Davide prima di inviare

> Se non servono azioni infra → nessun coinvolgimento di Ciccio.

---

## FASE 5b — Reject + Rework

**Chi:** Claudio
**Skill:** `issue-reject` (per reject semplici) | `issue-research-rework` (per reject complessi ≥2)
**Kanban:** Test → Review → InProgress → Test (loop)

1. Claudio registra feedback + risultati test come commento sulla issue
2. Label: rimuove `review-ready`, aggiunge `needs-fix`
3. Rilancia agente con feedback come contesto
4. Stesso flusso Fase 3 → Fase 4
5. Loop fino a `/approva`

---

## 📊 Kanban

| Colonna | Significato | Chi sposta |
|---------|-------------|------------|
| **Backlog** | Issue creata | Claudio (create-issue) |
| **Todo** | Validata, piano pronto, aspetta /vai | Claudio (issue-validate) |
| **InProgress** | Agente al lavoro | Claudio (dopo /vai) |
| **Test** | PR aperta, CI ha deployato in test | Claudio (issue-pr-ready) |
| **Review** | Reject, agente in rework | Claudio (issue-reject) |
| **Done** | Mergiato, in produzione, chiuso | Claudio (issue-approve) |

> La colonna **Deploy** nel project board non è più usata — Claudio mergia direttamente dopo `/approva`.
> ID colonne e campo: vedi `config.json`.

### Label

| Label | Significato |
|-------|-------------|
| `agent:claude-code` | Agente Claude Code assegnato |
| `in-progress` | Agente al lavoro |
| `review-ready` | PR pronta per test Davide |
| `deployed-test` | Live su test (aggiunta da CI/bot) |
| `needs-fix` | Reject, rework in corso |
| `deployed-prod` | Live in produzione |

---

## 🗺️ Mappa Skill

| Skill | Quando si usa |
|-------|--------------|
| `create-issue` | Fase 1 — creazione issue leggera |
| `issue-validate` | Fase 2 — validazione completa + research + piano |
| `issue-implement` | Fase 3 — supervisione implementazione con checkpoint |
| `issue-pr-ready` | Fase 4 — checklist pre-PR, apertura PR, notifiche |
| `issue-approve` | Fase 5a — merge + chiusura dopo /approva |
| `issue-reject` | Fase 5b — rework dopo reject semplice |
| `issue-research-rework` | Fase 5b — research approfondita per reject complessi |
| `security-audit` | Pre-push — gate di sicurezza obbligatorio |
| `8020-commit-workflow` | Convenzioni commit per l'agente |
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
- **Commit:** Conventional Commits (`feat:`, `fix:`, `chore:`, `docs:`) — dettagli in `COMMIT_CONVENTIONS.md`
- **Niente commit su main/master**
- **PROJECT.md** aggiornato prima di ogni PR
- **Weekly tracking:** dopo ogni merge, riga in `memory/weekly/current.md`
