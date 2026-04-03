# Skill: issue-approve

**Trigger:** Davide scrive `/approva`  
**Agente:** Claudio  
**Versione:** 2.0.0

> Riferimento flusso: vedi `WORKFLOW.md` — Fase 5a

---

## Obiettivo

Mergiare la PR, chiudere la issue, notificare. Ciccio coinvolto solo se servono azioni infra.

---

## Procedura

### Step 1 — Merge PR

```bash
gh pr merge <PR_N> --repo ecologicaleaving/<repo> --merge --delete-branch
```

La CI deploya automaticamente in produzione.

### Step 2 — Aggiorna label e chiudi issue

```bash
gh issue edit <N> --repo ecologicaleaving/<repo> \
  --remove-label "review-ready,deployed-test,needs-fix" \
  --add-label "deployed-prod"
gh issue close <N> --repo ecologicaleaving/<repo>
```

### Step 3 — Sposta card → Done

```bash
./scripts/kanban-move.sh <N> <repo> Done
```

### Step 4 — Conferma a Davide

```
✅ [Issue #N] Live in produzione
📌 PR mergiata, issue chiusa, card → Done
```

### Step 5 — Azioni infra (solo se necessario)

Se servono env vars, migrazioni DB, config VPS → prepara messaggio per Ciccio e proponilo a Davide prima di inviare.

Se non servono azioni infra → nessun coinvolgimento di Ciccio.

### Step 6 — Weekly tracking

Aggiungi riga a `memory/weekly/current.md`:
```
| YYYY-MM-DD | PR | <repo> | #N | <titolo> | ✅ merged |
```

---

## Note

- Mai eseguire senza `/approva` esplicito di Davide
- Se la issue ha avuto reject precedenti, le label `needs-fix` vengono rimosse
