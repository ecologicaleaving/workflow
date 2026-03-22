# Skill: issue-deploy-prod

**Trigger:** Davide scrive `/approva #N` dopo aver testato il link → Ciccio procede con merge e deploy prod  
**Agente:** Ciccio  
**Versione:** 2.1.0

---

## Obiettivo

Merge della PR su master, deploy in produzione, chiusura issue e card → Done.

> **Nota flusso:** `/approva` arriva solo dopo che Davide ha testato il link su test — il deploy test è già avvenuto per forza. Non servono check ridondanti: Ciccio procede direttamente.

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

### Step 3 — Deploy produzione

In base al tipo di progetto:

**App web con CI (standard):**
Il merge su master triggera automaticamente la CI pipeline che builda e deploya in produzione. Il bot Telegram notifica a deploy avvenuto. Nessuna azione manuale richiesta.

**App web senza CI (fallback):**
```bash
cd /var/www/<repo>
git pull origin master
npm install && npm run build
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
