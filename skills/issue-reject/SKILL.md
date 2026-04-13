# Skill: issue-reject

**Trigger:** Davide scrive `/reject <feedback>`
**Agente:** Claude Code
**Versione:** 3.0.0

> Riferimento flusso: vedi `WORKFLOW.md` — Fase 5b

---

## Obiettivo

Gestire il rework dopo un reject: registrare feedback e risultati test sulla issue, ripartire con l'implementazione.

---

## Procedura

### Step 1 — Raccolta feedback

Se Davide non ha specificato risultati test nel reject, chiedi:
```
Hai risultati dei test da allegare al reject? (log, screenshot, descrizione errore)
```

### Step 2 — Aggiorna issue su GitHub

Aggiungi un commento con la sezione rework:

```bash
gh issue comment <N> --repo ecologicaleaving/<repo> --body "
## ❌ Rework $(date +%Y-%m-%d) — Reject #$(N_REWORK)

**Feedback di Davide:**
<feedback>

**Risultati test:**
<risultati test se forniti>

**Cosa deve essere corretto:**
- <action item 1>
- <action item 2>

---
*Reject ricevuto il $(date +%Y-%m-%d %H:%M) — Rework in corso*
"
```

### Step 3 — Aggiorna label

```bash
gh issue edit <N> --repo ecologicaleaving/<repo> \
  --remove-label "review-ready,deployed-test" \
  --add-label "needs-fix"
```

### Step 4 — Sposta card → Review

```bash
./scripts/kanban-move.sh <N> <repo> Review
```

### Step 5 — Avvia rework

Riprendi dal branch esistente (`feature/issue-N-slug`).
Leggi l'ultimo commento sulla issue per il feedback completo.
Analizza il problema, implementa il fix.
Segui il flusso `issue-implement` (auto-gate, poi `issue-pr-ready`).

### Step 6 — Sposta card → InProgress

```bash
./scripts/kanban-move.sh <N> <repo> InProgress
```

### Step 7 — Conferma a Davide

```
🔄 [Issue #N] Rework avviato
📌 Feedback registrato sulla issue
🤖 In lavorazione — ti aggiorno al gate
```

---

## Nota

Il loop reject → rework → test continua fino a `/approva` di Davide.
Ogni reject viene numerato progressivamente nella issue (Rework 1, Rework 2, ecc.)
Dopo 2+ reject usa la skill `issue-research-rework` per un'analisi più approfondita.
