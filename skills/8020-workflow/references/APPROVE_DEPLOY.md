# APPROVE_DEPLOY.md — Procedura /approva

> ⚠️ Questo file è un riferimento rapido. La procedura completa è nella skill `issue-approve`.

## Trigger
Davide scrive: `/approva`

## Procedura

1. **Merge PR su master**
```bash
gh pr merge <PR_N> --repo ecologicaleaving/<REPO> --merge --delete-branch
```

2. **Aggiorna label e chiudi issue**
```bash
gh issue edit <N> --repo ecologicaleaving/<REPO> \
  --remove-label "review-ready,deployed-test,needs-fix" \
  --add-label "deployed-prod"
gh issue close <N> --repo ecologicaleaving/<REPO>
```

3. **Sposta card → Done**
```bash
./scripts/kanban-move.sh <N> <REPO> Done
```

4. **Notifica Davide** con conferma

5. **Se servono azioni infra** (env vars, DB, config) → prepara messaggio per Ciccio, proponi a Davide
