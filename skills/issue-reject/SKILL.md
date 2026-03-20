# Skill: issue-reject

**Trigger:** Davide scrive `/reject <feedback>`  
**Agente:** Claudio  
**Versione:** 2.0.0

---

## Obiettivo

Gestire il rework dopo un reject: aggiornare la issue con feedback e risultati test, rilanciare l'agente con il contesto necessario.

---

## Procedura

### Step 1 — Raccolta feedback

Se Davide non ha specificato risultati test nel reject, Claudio chiede:
```
Hai risultati dei test da allegare al reject? (log, screenshot, descrizione errore)
```

### Step 2 — Aggiorna issue su GitHub

Aggiungi un commento con la sezione rework:

```bash
gh issue comment <N> --repo ecologicaleaving/<repo> --body "
## ❌ Rework $(date +%Y-%m-%d) — Reject #$(N_REWORK)

**Feedback di Davide:**
<feedback>

**Risultati test:**
<risultati test se forniti>

**Cosa deve essere corretto:**
- <action item 1>
- <action item 2>

---
*Reject ricevuto il $(date +%Y-%m-%d %H:%M) — Agente in rework*
"
```

### Step 3 — Aggiorna label

```bash
gh issue edit <N> --repo ecologicaleaving/<repo> \
  --remove-label "review-ready,deployed-test" \
  --add-label "needs-fix"
```

### Step 4 — Sposta card → Review

```bash
gh api graphql -f query='
mutation {
  updateProjectV2ItemFieldValue(input: {
    projectId: "PVT_kwHODSTPQM4BP1Xp"
    itemId: "'$ITEM_ID'"
    fieldId: "PVTSSF_lAHODSTPQM4BP1Xpzg-INlw"
    value: { singleSelectOptionId: "03f548ab" }
  }) { projectV2Item { id } }
}'
```

### Step 5 — Rilancia agente con contesto

Istruzioni da passare all'agente:

```
La issue #N è stata rifiutata. 
Leggi l'ultimo commento di rework sulla issue per il feedback completo.

Feedback: <feedback>
Risultati test: <risultati>

Parti dalla PR esistente (branch: feature/issue-N-slug).
Analizza il problema, proponi il fix, implementa.
Segui i checkpoint obbligatori come da issue.
```

### Step 6 — Sposta card → InProgress

```bash
gh api graphql -f query='
mutation {
  updateProjectV2ItemFieldValue(input: {
    projectId: "PVT_kwHODSTPQM4BP1Xp"
    itemId: "'$ITEM_ID'"
    fieldId: "PVTSSF_lAHODSTPQM4BP1Xpzg-INlw"
    value: { singleSelectOptionId: "47fc9ee4" }
  }) { projectV2Item { id } }
}'
```

### Step 7 — Conferma a Davide

```
🔄 [Issue #N] Rework avviato
📌 Feedback registrato sulla issue
🤖 Agente in lavorazione con il contesto del reject
📬 Ti aggiornerò ai checkpoint
```

---

## Nota

Il loop reject → rework → test review continua fino a `/approva` di Davide.  
Ogni reject viene numerato progressivamente nella issue (Rework 1, Rework 2, ecc.)
