---
name: issue-reject
version: 1.0.0
description: >
  Procedura di gestione /reject da parte di Davide.
  Usata da Claudio (agenti PC) o Ciccio (agenti VPS) quando Davide
  scrive /reject #N "feedback". Copre: registrazione feedback,
  spostamento card → Review, ri-assegnazione all'agente, notifica.
triggers:
  - "/reject"
  - "issue rifiutata"
  - "issue rejected"
  - "rework issue"
---

# Issue Reject — Gestione Rifiuto

Questa skill si attiva quando Davide scrive **`/reject #N "feedback"`**.

- **Agenti PC** (Claude Code, Codex) → eseguita da **Claudio**
- **Agenti VPS** (Ciccio) → eseguita da **Ciccio**

---

## STEP 1 — Leggi il feedback di Davide

Estrai chiaramente:
- Quale AC non è soddisfatto
- Cosa non funziona o cosa si aspetta di diverso
- Eventuali screenshot, log o esempi forniti

Se il feedback è ambiguo → **chiedi chiarimento a Davide prima di procedere**.
Non passare il feedback all'agente se non è chiaro — un rework basato su feedback vago produce un secondo reject.

---

## STEP 2 — Registra il feedback sull'issue

```bash
gh issue comment <N> --repo <owner/repo> \
  --body "❌ **Reject da Davide — rework richiesto.**

**Feedback:**
<testo feedback di Davide>

**AC non soddisfatto:**
<quale AC specifico ha fallito>

L'agente riprenderà la lavorazione sul branch \`feature/issue-<N>-<slug>\`."
```

---

## STEP 3 — Aggiorna label

```bash
gh issue edit <N> --repo <owner/repo> \
  --remove-label "review-ready" \
  --add-label "needs-fix"
```

---

## STEP 4 — Sposta card → Review

**Option ID Review**: da aggiornare quando la colonna Review sarà creata sul Kanban.
Nel frattempo usa **In Progress** (`47fc9ee4`) come proxy.

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
-f optionId="47fc9ee4"
```

---

## STEP 5 — Notifica l'agente e assegna il rework

Determina l'agente dalla label dell'issue:

| Label | Agente | Azione |
|-------|--------|--------|
| `claude-code` | Claude Code (PC) | Claudio notifica Davide per riaprire sessione Claude Code con branch + feedback |
| `codex` | Codex (PC) | Claudio rilancia Codex sul branch con il feedback come prompt |
| `ciccio` | Ciccio (VPS) | Ciccio spawna subagente con il feedback |

### Se agente PC (claude-code / codex)
Claudio avvisa Davide:
> ⚠️ **Issue #N — rework richiesto**
> Agente: Claude Code / Codex
> Branch: `feature/issue-<N>-<slug>`
> Feedback: "<testo>"
> Quando sei pronto, riavvia l'agente puntando a questo branch.

Oppure rilancia direttamente Codex/Claude Code in background con il feedback nel prompt, indicando di leggere `issue-review` prima di scrivere codice.

### Se agente VPS (ciccio)
Ciccio spawna subagente autonomamente con:
- Branch esistente
- Testo feedback completo
- Istruzione di leggere `issue-review`

---

## ✅ Checklist

- [ ] Feedback chiaro (se ambiguo → chiesto chiarimento a Davide)
- [ ] Commento registrato sull'issue con feedback dettagliato
- [ ] Label aggiornata → `needs-fix`
- [ ] Card Kanban → Review (o In Progress come proxy)
- [ ] Agente notificato / rilanciato con feedback
- [ ] Davide informato che il rework è in corso

---

## ⏭️ Cosa succede dopo

L'agente dev legge la skill **`issue-review`**, applica il fix e ripercorre **`issue-done`**.
Quando la nuova build è pronta → **`issue-deploy-test`** → Davide ritesta.
