---
name: issue-deploy-test
version: 1.0.0
description: >
  Procedura di deploy su ambiente test. Usata da Claudio (agenti PC)
  o Ciccio (agenti VPS) dopo che l'agente dev ha aperto la PR.
  Copre: verifica CI, deploy build su test, spostamento card → Test,
  notifica Davide con link. Termina con la card in colonna Test.
triggers:
  - "deploy test"
  - "metti in test"
  - "deploy su test"
  - "prepara test"
---

# Issue Deploy Test — Deploy su Ambiente Test

Questa skill è per **Claudio** (agenti PC) o **Ciccio** (agenti VPS).
Da leggere dopo che l'agente dev ha aperto la PR e la CI è partita.

---

## STEP 1 — Verifica CI verde

```bash
gh run list --repo <owner/repo> --branch feature/issue-<N>-<slug> \
  --limit 1 --json status,conclusion,name,url
```

- `status: completed` + `conclusion: success` → ✅ procedi
- `status: in_progress` → aspetta il completamento
- `conclusion: failure` → ❌ **non deployare**. Segnala all'agente dev che la CI è rossa. L'agente deve fixare e ripushare.

---

## STEP 2 — Scarica / verifica la build

### Flutter APK
La CI deploya automaticamente l'APK su:
```
https://apps.8020solutions.org/downloads/test/<repo-name>-<branch>.apk
```

> ⚠️ **Flavor**: per branch/test la CI deve usare `--debug --flavor dev`.
> Verifica in `PROJECT.md` del repo i flavor configurati.
> Il nome dell'app nel APK test deve essere quello del flavor dev (es. "Fin Dev").

Verifica che il link sia raggiungibile:
```bash
curl -sI "https://apps.8020solutions.org/downloads/test/<nome>.apk" | head -1
# atteso: HTTP/2 200
```

### Web App
```bash
# Verifica che il deploy su ambiente test sia avvenuto
curl -sI "https://test.<dominio>.8020solutions.org" | head -1
```

Se la build non è disponibile → verifica i log CI e attendi o ri-triggera.

---

## STEP 3 — Sposta card → Test

**Project ID**: `PVT_kwHODSTPQM4BP1Xp`
**Status Field ID**: `PVTSSF_lAHODSTPQM4BP1Xpzg-INlw`
**Option ID Test**: `1d6a37f9`

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
-f optionId="1d6a37f9"
```

---

## STEP 4 — Notifica Davide

Manda un messaggio con:
- Issue number e titolo
- Link diretto alla build/APK per il test
- Cosa testare (AC dell'issue, in breve)
- PR number per riferimento

**Esempio:**
> ✅ **Issue #22 pronta per test**
> 📲 APK: https://apps.8020solutions.org/downloads/test/beachref-issue-22.apk
> 🔍 Cosa verificare: tornei di luglio per 2+ arbitri — il totale deve contare eventi fisici, non tabelloni M+F separati
> PR: #23

---

## STEP 5 — Aggiungi commento sull'issue

> ⚠️ Il link alla build è **obbligatorio** nel commento. Davide non deve cercarlo — deve poter cliccare e testare subito.

```bash
gh issue comment <N> --repo <owner/repo> \
  --body "🧪 **Pronto per test.**

📲 **Link test:** <URL APK o web app>

🔍 **Cosa verificare (AC):**
- AC1: <descrizione breve>
- AC2: <descrizione breve>

PR: #<PR_N>
Rispondi con \`/approve #<N>\` o \`/reject #<N> \"feedback\"\`."
```

---

## ✅ Checklist

- [ ] CI verde sul branch della PR
- [ ] Build/APK disponibile e raggiungibile
- [ ] Card Kanban → Test
- [ ] Commento sull'issue con **link diretto** alla build + AC da verificare
- [ ] Davide notificato via Telegram con link + cosa testare

---

## ⏭️ Cosa succede dopo

**Davide testa sull'APK/app.**

- `/approve #N` → leggi la skill **`issue-deploy-prod`**
- `/reject #N "feedback"` → leggi la skill **`issue-reject`**
