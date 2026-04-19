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

### Step 1b — Monitora CI deploy produzione

```bash
gh run watch --repo ecologicaleaving/<repo>
```

**Se il deploy fallisce:**
1. Leggi i log: `gh run view <run_id> --repo ecologicaleaving/<repo> --log-failed`
2. Identifica l'errore e fixa (hotfix direttamente su master o nuovo branch)
3. Push → monitora nuovamente
4. Massimo 3 iterazioni — se non si risolve notifica subito Davide con dettaglio errore

**Se il deploy ha successo** → procedi con Step 2.

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

Se servono env vars, migrazioni DB, riavvii servizi → Claudio le esegue direttamente via SSH:

```bash
# Env var
ssh root@46.225.60.101 "cd /opt/<repo> && echo 'VAR=valore' >> .env && docker compose restart <service>"

# Migrazione DB
ssh root@46.225.60.101 "cd /opt/<repo> && docker compose exec app <migration-command>"

# Riavvio
ssh root@46.225.60.101 "cd /opt/<repo> && docker compose pull && docker compose up -d"
```

Dopo ogni azione infra, conferma a Davide:
```
⚙️ Azioni infra completate:
- ✅ <azione 1>
- ✅ <azione 2>
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
