# Skill: issue-approve

**Trigger:** Davide scrive `/approva`
**Agente:** Claude Code
**Versione:** 3.0.0

> Riferimento flusso: vedi `WORKFLOW.md` — Fase 5a

---

## Obiettivo

Mergiare la PR, chiudere la issue, notificare Davide. Gestire eventuali azioni infra necessarie.

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

Se servono env vars, migrazioni DB, config VPS → elenca le azioni da eseguire e comunicale a Davide:

```
⚙️ Azioni infra richieste per questa issue:
- [ ] <azione 1> (es. aggiungere env var XYZ al VPS)
- [ ] <azione 2> (es. eseguire migrazione DB)

Queste vanno eseguite manualmente sul VPS.
```

Se non servono azioni infra → skip questo step.

### Step 6 — Weekly tracking

Aggiungi riga a `memory/weekly/current.md`:
```
| YYYY-MM-DD | PR | <repo> | #N | <titolo> | ✅ merged |
```

---

## Note

- Mai eseguire senza `/approva` esplicito di Davide
- Se la issue ha avuto reject precedenti, le label `needs-fix` vengono rimosse
