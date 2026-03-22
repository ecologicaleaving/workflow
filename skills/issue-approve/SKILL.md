# Skill: issue-approve

**Trigger:** Davide scrive `/approva #N`  
**Agente:** Claudio  
**Versione:** 1.0.0

---

## Obiettivo

Formalizzare l'approvazione di una issue dopo test positivo: aggiornare label, spostare card in Deploy, notificare Ciccio per il merge.

---

## Procedura

### Step 1 — Aggiorna label

```bash
gh issue edit <N> --repo ecologicaleaving/<repo> \
  --remove-label "review-ready,deployed-test,needs-fix" \
  --add-label "approved"
```

### Step 2 — Sposta card → Deploy

```bash
./scripts/kanban-move.sh <N> <repo> Deploy
```

### Step 3 — Notifica Ciccio

```
🔀 [<repo>] Issue #N approvata da Davide

Ciao Ciccio, puoi procedere con il merge:
- PR: <link PR>
- Repo: ecologicaleaving/<repo>

Dopo il merge, la CI deploya in produzione automaticamente (se configurata).
Se serve deploy manuale, vedi la PR per dettagli.
```

### Step 4 — Conferma a Davide

```
✅ [Issue #N] Approvata
📌 Card → Deploy, Ciccio notificato
⏭️ Ciccio procede con merge e deploy prod
```

---

## Note

- Mai eseguire senza `/approva` esplicito di Davide
- Se la issue ha avuto reject precedenti, le label `needs-fix` vengono rimosse
- Dopo il merge, Ciccio segue la skill `issue-deploy-prod`
