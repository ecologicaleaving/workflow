# Skill: issue-deploy-prod

**Trigger:** Davide scrive `/merge #N` dopo `/approva`  
**Agente:** Ciccio  
**Versione:** 2.1.0

---

## Obiettivo

Merge della PR su master, deploy in produzione se necessario, chiusura issue e card → Done.

---

## Procedura

### Step 0 — Pre-deploy check (obbligatorio — Claudio)

Prima di autorizzare il merge in produzione, Claudio verifica che tutto sia pronto.

```bash
REPO="<repo>"
PR_NUMBER="<N>"

echo "=== CI verde? ==="
gh pr checks $PR_NUMBER --repo ecologicaleaving/$REPO

echo "=== PR testata su test? ==="
gh issue view <N> --repo ecologicaleaving/$REPO --json labels \
  | jq -r '.labels[].name' | grep "deployed-test" && echo "✅ testata" || echo "⚠️ non risulta testata"
```

**Controlla se la issue tocca il DB:**

| Situazione | Azione |
|-----------|--------|
| Nessuna modifica DB | Procedi normalmente |
| Migrazioni incluse nel branch | Verifica che siano state testate sull'ambiente test prima del merge |
| Migrazioni non incluse | **Blocca** — le migrazioni vanno nel branch, non applicate a mano in prod |
| Nuove variabili d'ambiente necessarie | Verifica che i secrets GitHub siano aggiornati prima del merge |

**Se ci sono migrazioni DB → notifica Ciccio con dettaglio:**
```
🗄️ [Issue #N/<repo>] Merge con migrazioni DB
📋 File migrazioni: <lista file .sql o supabase/migrations/*>
⚠️ Verifica che le migrazioni siano già state applicate su test prima di procedere
```

**Se tutto ok → notifica Ciccio per procedere con il merge:**
```
✅ [Issue #N/<repo>] Pre-deploy prod check ok
🔧 CI: verde
🧪 Testato su test: sì
🗄️ Migrazioni: nessuna / presenti e testate
```

**Se qualcosa manca → blocca e notifica Davide:**
```
⚠️ [Issue #N/<repo>] Pre-deploy prod check fallito
📋 Problemi: <CI fallita / non testato / migrazioni mancanti>
❓ Come procedo?
```

---

### Step 1 — Verifica CI

```bash
gh pr checks <PR_NUMBER> --repo ecologicaleaving/<repo>
```

Se CI non è verde → notifica Davide prima di procedere.

### Step 2 — Merge PR

```bash
gh pr merge <PR_NUMBER> \
  --repo ecologicaleaving/<repo> \
  --squash \
  --delete-branch
```

### Step 3 — Deploy produzione (se necessario)

In base al tipo di progetto:

**App web (VPS):**
```bash
cd /var/www/<repo>
git pull origin master
npm install && npm run build
cp -r build/ /var/www/<repo>-prod/
nginx -s reload
```

**App mobile (APK):** GitHub Actions gestisce il build → release automatica

**VPS infra:** applica le modifiche manualmente in base al contesto

### Step 4 — Aggiorna label e chiudi issue

```bash
# Aggiorna label
gh issue edit <N> --repo ecologicaleaving/<repo> \
  --remove-label "review-ready,deployed-test,needs-fix" \
  --add-label "deployed-prod"

# Chiudi issue
gh issue close <N> --repo ecologicaleaving/<repo>
```

### Step 5 — Sposta card → Done

```bash
gh api graphql -f query='
mutation {
  updateProjectV2ItemFieldValue(input: {
    projectId: "PVT_kwHODSTPQM4BP1Xp"
    itemId: "'$ITEM_ID'"
    fieldId: "PVTSSF_lAHODSTPQM4BP1Xpzg-INlw"
    value: { singleSelectOptionId: "98236657" }
  }) { projectV2Item { id } }
}'
```

### Step 6 — Notifica Davide

```
✅ [Issue #N] Live in produzione
🔗 <url produzione se applicabile>
📌 Issue chiusa, card → Done
```

---

## Note

- Mai fare merge senza `/approva` esplicito di Davide
- Se deploy produzione fallisce → rollback al commit precedente e notifica Davide
- Branch feature viene eliminato dopo il merge
