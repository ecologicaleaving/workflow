# Skill: issue-deploy-prod

**Trigger:** Davide scrive `/approva #N` → Claudio verifica → notifica Ciccio per il merge  
**Agente:** Claudio (verifica pre-merge) → Ciccio (merge + deploy)  
**Versione:** 2.1.0

---

## Obiettivo

Merge della PR su master, deploy in produzione, chiusura issue e card → Done.

---

## Procedura

### Step 0 — Pre-merge check (Claudio, dopo `/approva` di Davide)

Alla ricezione di `/approva #N` da Davide, Claudio verifica che tutto sia pronto prima di passare il via a Ciccio.

```bash
REPO="<repo>"
PR_NUMBER="<PR>"

# CI verde?
gh pr checks $PR_NUMBER --repo ecologicaleaving/$REPO

# Issue testata su test?
gh issue view <N> --repo ecologicaleaving/$REPO --json labels \
  | jq -r '.labels[].name' | grep "deployed-test" && echo "✅ testata" || echo "⚠️ non testata"

# Migrazioni DB nel branch?
gh pr diff $PR_NUMBER --repo ecologicaleaving/$REPO --name-only \
  | grep -E "migration|\.sql|supabase/migrations" && echo "⚠️ migrazioni presenti" || echo "✅ nessuna migrazione"
```

**Tabella decisione DB:**

| Situazione | Azione |
|-----------|--------|
| Nessuna modifica DB | Procedi — notifica Ciccio |
| Migrazioni nel branch, testate su test | Segnala a Ciccio — le applica lui in prod dopo il merge |
| Migrazioni nel branch, non testate | Blocca — notifica Davide |
| Migrazioni non nel branch | Blocca — le migrazioni devono stare nel branch, mai a mano in prod |

**Se tutto ok → notifica Ciccio:**
```
✅ [Issue #N/<repo>] /approva ricevuto — procedi con merge
🔧 CI: verde | Testato: sì | Migrazioni: nessuna / presenti in branch
PR: #<PR>
```

**Se qualcosa manca → blocca e notifica Davide:**
```
⚠️ [Issue #N/<repo>] Merge bloccato
📋 Problemi: <CI fallita / non testato su test / migrazioni non nel branch>
❓ Come procedo?
```

---

### Step 1 — Verifica CI (Ciccio) (Ciccio)

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
