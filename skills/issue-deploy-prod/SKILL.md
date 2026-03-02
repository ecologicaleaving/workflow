---
name: issue-deploy-prod
version: 1.0.0
description: >
  Procedura di deploy in produzione dopo /approve di Davide.
  Usata da Claudio (agenti PC) o Ciccio (agenti VPS).
  Copre: merge PR, deploy prod, chiusura issue, card → Done, notifica Davide.
triggers:
  - "deploy prod"
  - "metti in produzione"
  - "/approve"
  - "deploy production"
---

# Issue Deploy Prod — Deploy in Produzione

Questa skill si attiva quando Davide scrive **`/approve #N`**.

- **Agenti PC** (Claude Code, Codex) → eseguita da **Claudio**
- **Agenti VPS** (Ciccio) → eseguita da **Ciccio**

---

## STEP 1 — Verifica pre-merge

```bash
# Controlla che la CI sia verde sulla PR
gh pr view <PR_N> --repo <owner/repo> --json statusCheckRollup

# Controlla che non ci siano conflitti
gh pr view <PR_N> --repo <owner/repo> --json mergeable
# atteso: "mergeable": "MERGEABLE"
```

Se CI rossa o conflitti → **non mergare**. Segnala a Davide prima di procedere.

---

## STEP 2 — Merge PR

```bash
gh pr merge <PR_N> --repo <owner/repo> --squash \
  --subject "<type>: <descrizione breve> (#N)" \
  --delete-branch
```

Usa `--squash` per mantenere la history di master pulita.
`--delete-branch` elimina il branch remoto dopo il merge.

---

## STEP 3 — Deploy in produzione

### Flutter APK
La CI su master si triggera automaticamente dopo il merge e deploya l'APK in prod:
```
https://apps.8020solutions.org/downloads/<repo-name>-latest.apk
```
Attendi il completamento della CI run su master:
```bash
gh run list --repo <owner/repo> --branch master --limit 1 \
  --json status,conclusion,url
```

### Web App (eseguito da Ciccio su VPS)
```bash
cd /var/www/<project>/
git pull origin master
npm run build           # se necessario
systemctl restart <service>  # se necessario
# health check
curl -sI https://<dominio> | head -1
```

---

## STEP 4 — Chiudi issue e sposta card → Done

```bash
# Chiudi l'issue
gh issue close <N> --repo <owner/repo> \
  --comment "🚀 **Deploy in produzione completato.**

Merge: PR #<PR_N>
Build: <link prod se disponibile>
Issue chiusa."
```

**Sposta card → Done**
**Project ID**: `PVT_kwHODSTPQM4BP1Xp`
**Option ID Done**: `98236657`

```bash
ITEM_ID=$(gh api graphql -f query='
query($issueId: ID!) {
  node(id: $issueId) {
    ... on Issue { projectItems(first: 5) { nodes { id } } }
  }
}' -f issueId="$(gh issue view <N> --repo <owner/repo> --json id --jq '.id')" \
--jq '.data.node.projectItems.nodes[0].id')

gh api graphql -f query='
mutation($projectId: ID!, $itemId: ID!, $fieldId: ID!, $optionId: String!) {
  updateProjectV2ItemFieldValue(input: {
    projectId: $projectId, itemId: $itemId, fieldId: $fieldId
    value: { singleSelectOptionId: $optionId }
  }) { projectV2Item { id } }
}' \
-f projectId="PVT_kwHODSTPQM4BP1Xp" \
-f itemId="$ITEM_ID" \
-f fieldId="PVTSSF_lAHODSTPQM4BP1Xpzg-INlw" \
-f optionId="98236657"
```

---

## STEP 5 — Aggiorna PROJECT.md

```bash
# Nel repo del progetto, su master
git checkout master && git pull
```

Aggiorna PROJECT.md:
- `Last Deploy`: timestamp UTC corrente
- `Status`: `production` (se prima era `development`)
- Issue nel Backlog: sposta da `DONE` a sezione RELEASED se presente

```bash
git add PROJECT.md
git commit -m "chore: aggiorna PROJECT.md — issue #<N> in produzione"
git push origin master
```

---

## STEP 6 — Notifica Davide

Messaggio con:
- Conferma deploy avvenuto
- Link produzione (APK o URL)
- Issue e PR chiuse

**Esempio:**
> 🚀 **#22 in produzione!**
> 📲 APK: https://apps.8020solutions.org/downloads/beachref-latest.apk
> Issue #22 chiusa · PR #23 mergiata
> Kanban → Done ✅

---

## ✅ Checklist

- [ ] CI verde sulla PR prima del merge
- [ ] PR mergiata con `--squash --delete-branch`
- [ ] Deploy prod completato e verificato (CI master verde o health check)
- [ ] Issue chiusa con commento
- [ ] Card Kanban → Done
- [ ] PROJECT.md aggiornato e pushato su master
- [ ] Davide notificato con link prod

---

## 📊 Option ID colonne Kanban (riferimento rapido)

| Colonna | Option ID |
|---------|-----------|
| Backlog | `2ab61313` |
| Todo | `f75ad846` |
| In Progress | `47fc9ee4` |
| Test | `1d6a37f9` |
| Review | `03f548ab` |
| Deploy | `37c4aa50` |
| Done | `98236657` |
