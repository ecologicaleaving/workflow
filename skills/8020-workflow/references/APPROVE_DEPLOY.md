# APPROVE_DEPLOY.md — Procedura /approva → deploy produzione

## Trigger
Davide scrive: `/approva #<N>` oppure `/merge #<N>`

## Regola d'oro
L'approvazione esplicita di Davide è sufficiente. **Non verificare prerequisiti**, non bloccarsi su stati intermedi.

## Procedura

1. **Merge PR su master**
```bash
export PATH=$PATH:/root/go/bin
gh pr merge <PR_N> --repo ecologicaleaving/<REPO> --merge --delete-branch
```

2. **Sposta card: `Test` → `Deploy`**
→ Vedi `KANBAN.md`

3. **Deploy in produzione**
→ Vedi `DEPLOY_PROD.md` per la procedura specifica per repo

4. **Sposta card: `Deploy` → `Done`**
→ Vedi `KANBAN.md`

5. **Chiudi la issue**
```bash
gh issue close <N> --repo ecologicaleaving/<REPO>
```

6. **Aggiorna PROJECT.md** nel repo con version bump + sezione DONE

7. **Notifica Davide**
```
🚀 #<N> live in produzione!
🔗 <URL prod>
```
