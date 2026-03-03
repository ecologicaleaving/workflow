---
name: create-feature-issue
description: "Crea una GitHub issue comprensiva per una feature complessa, con user stories, task checklist, dipendenze e riferimenti a documenti/mockup. Usare quando: (1) si usa il comando /create-feature [owner/repo], (2) la richiesta riguarda una funzionalità che tocca più aree del codice, (3) si vuole una issue autosufficiente e ben documentata invece di frammentarla in tante piccole. NON usare per bug o fix semplici — usare create-issue in quei casi."
---

# Create Feature Issue Skill

Crea una issue GitHub ricca e autosufficiente per una feature complessa. Una sola issue ben progettata con task checklist interna, invece di tante issue frammentate.

## Flusso

1. **Identifica il repo** — dall'invocazione `/create-feature owner/repo` o chiedi
2. **Leggi PROJECT.md** — fetch via `gh api` per stack, URL test, branch strategy
3. **Discovery questions** — UNA ALLA VOLTA (vedi Questions Protocol)
4. **Proponi la task breakdown** — lista checklist da approvare/modificare
5. **Crea la issue** — popola il template e usa `gh issue create`
6. **Aggiungi al Kanban in Backlog**

## Questions Protocol

⚠️ **Regola fondamentale**: fai UNA domanda alla volta. Suggerisci sempre 3 opzioni plausibili.

### Ordine domande

1. **Chi usa questa feature?**
   > A chi è rivolta?
   > 1. Utente finale dell'app
   > 2. Amministratore / back-office
   > 3. Sistema automatico / integrazione

2. **Cosa deve poter fare?** (job-to-be-done)
   > In una frase: "Come [persona], voglio [azione] per [beneficio]"
   > 1. [suggerimento A dal contesto]
   > 2. [suggerimento B]
   > 3. Lo descrivo io

3. **Comportamento attuale vs desiderato**
   > Cosa succede oggi che non va (o cosa manca)?
   > 1. La funzionalità non esiste ancora
   > 2. Esiste ma è parziale / ha problemi
   > 3. È una riscrittura / refactor di qualcosa che c'è

4. **Aree del codice coinvolte**
   > Quali parti dell'app tocca?
   > 1. Solo frontend / UI
   > 2. Frontend + backend/API
   > 3. Frontend + backend + DB / modello dati

5. **MVP vs nice-to-have**
   > Cosa è obbligatorio per la v1? Cosa può venire dopo?
   > 1. Tutto quello descritto è MVP
   > 2. Ho un MVP chiaro, il resto è nice-to-have
   > 3. Lo definiamo insieme

6. **Design / riferimenti esterni**
   > Hai mockup, spec, link a doc da allegare?
   > 1. Sì — ho link/file da allegare
   > 2. No, ma posso descrivere il comportamento atteso
   > 3. Nessun riferimento per ora

7. **Dipendenze**
   > Dipende da altre issue aperte o sistemi esterni?
   > 1. No, è standalone
   > 2. Sì — da un'altra issue (chiedi numero)
   > 3. Sì — da un sistema esterno (chiedi quale)

8. **Task breakdown**
   > Sulla base delle risposte, proponi una checklist di sotto-task (max 8 voci). Chiedi conferma:
   > "Ho ipotizzato questi task — modificali o approvali:"
   > - [ ] Task 1
   > - [ ] Task 2
   > - ...

Se Davide ha già fornito informazioni nell'invocazione, salta le domande già risposte.

## Comandi

### Leggi PROJECT.md
```powershell
$content = gh api repos/{owner}/{repo}/contents/PROJECT.md --jq '.content'
[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($content))
```

### Crea la issue
```powershell
gh issue create `
  --repo {owner}/{repo} `
  --title "Feature: {titolo}" `
  --body-file "C:\Users\KreshOS\.openclaw\workspace\feature-issue-body.md"
```

### Aggiungi al Kanban in Backlog
```powershell
$issueUrl = gh issue view {N} --repo {owner}/{repo} --json url -q .url
gh project item-add 2 --owner ecologicaleaving --url $issueUrl

$itemId = gh project item-list 2 --owner ecologicaleaving --format json |
  ConvertFrom-Json | Select-Object -ExpandProperty items |
  Where-Object { $_.title -like "*{titolo_parziale}*" } |
  Select-Object -ExpandProperty id

gh project item-edit `
  --id $itemId `
  --project-id PVT_kwHODSTPQM4BP1Xp `
  --field-id PVTSSF_lAHODSTPQM4BP1Xpzg-INlw `
  --single-select-option-id 2ab61313
```

## Kanban IDs
- **Project ID:** `PVT_kwHODSTPQM4BP1Xp`
- **Status field ID:** `PVTSSF_lAHODSTPQM4BP1Xpzg-INlw`
- **Backlog option ID:** `2ab61313`

## Template
Vedi `assets/feature-issue-template.md`. Salvare il file temporaneo in `C:\Users\KreshOS\.openclaw\workspace\feature-issue-body.md` ed eliminarlo dopo la creazione.

## Regole
- **Titolo:** sempre `Feature: {titolo descrittivo}`
- **Mai aggiungere label** — Davide le assegna dopo
- **Sempre Backlog** per le nuove issue
- **Branch name** nel body: `feature/issue-{N}-{slug}` (N assegnato da GitHub dopo creazione)
- **⚠️ OBBLIGATORIO:** aggiungere sempre al Kanban dopo `gh issue create`
