---
name: create-issue
description: "Crea una GitHub issue strutturata per il team 8020/BeachRef e la aggiunge al backlog Kanban (senza label). Use when: (1) Davide vuole creare una nuova issue, (2) si usa il comando /create-issue [owner/repo], (3) si parla di aggiungere un task/feature/bug al backlog. Il flusso: legge PROJECT.md del repo, fa domande UNA ALLA VOLTA con 3 opzioni suggerite, genera la issue con template standard, la aggiunge al progetto Kanban in colonna Backlog."
---

# Create Issue Skill

Crea issue GitHub strutturate e le aggiunge al backlog Kanban.

## Flusso

1. **Identifica il repo** — dall'invocazione `/create-issue owner/repo` o chiedi a Davide se mancante
2. **Leggi PROJECT.md** — fetch via `gh api` per estrarre stack, URL test, branch strategy
3. **Fai le domande** — UNA ALLA VOLTA, con 3 opzioni suggerite (vedi Questions Protocol)
4. **Genera e crea la issue** — popola il template e usa `gh issue create`
5. **Aggiungi al Kanban in Backlog** — usa `gh project item-edit` con option ID Backlog

## Questions Protocol

⚠️ **Regola fondamentale**: fai UNA domanda alla volta. Suggerisci sempre 3 opzioni di risposta plausibili (Davide può scegliere un'opzione o rispondere liberamente).

Ordine delle domande:

1. **Tipo di issue**
   > Che tipo di issue è?
   > 1. 🚀 Feature — nuova funzionalità
   > 2. 🐛 Bug — qualcosa non funziona
   > 3. 🔧 Fix / Refactor — miglioramento interno

2. **Obiettivo** (solo se non già chiaro dall'invocazione)
   > Qual è l'obiettivo principale?
   > 1. [suggerimento A dedotto dal contesto]
   > 2. [suggerimento B]
   > 3. Descrivo io → (aspetta testo libero)

3. **Acceptance Criteria**
   > Come verifichi che sia fatto? Scegli il formato:
   > 1. Elenco comportamenti attesi (es. "cliccando X succede Y")
   > 2. Scenari utente (es. "come utente voglio...")
   > 3. Li definisco io → (aspetta testo libero)

4. **Playwright / test automatici** (solo per repo web)
   > Servono test automatici?
   > 1. Sì — Playwright (web)
   > 2. Sì — widget test Flutter (mobile)
   > 3. No — verifica manuale sull'APK/URL di test

5. **Out of scope** (opzionale — salta se ovvio)
   > Cosa NON va toccato?
   > 1. Tutto il resto dell'app
   > 2. [area specifica dedotta dal contesto]
   > 3. Nessuna restrizione particolare

Se Davide ha già fornito informazioni nell'invocazione, salta le domande già risposte.

## Comandi

### Leggi PROJECT.md dal repo (Windows PowerShell)
```powershell
$content = gh api repos/{owner}/{repo}/contents/PROJECT.md --jq '.content'
[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($content))
```

### Crea la issue
```powershell
gh issue create `
  --repo {owner}/{repo} `
  --title "{TIPO}: {titolo}" `
  --body-file "C:\Users\KreshOS\.openclaw\workspace\issue-body.md"
```

### Aggiungi al progetto e imposta Backlog
```powershell
# 1. Aggiungi al progetto
$issueUrl = gh issue view {N} --repo {owner}/{repo} --json url -q .url
gh project item-add 2 --owner ecologicaleaving --url $issueUrl

# 2. Recupera l'item ID appena aggiunto
$itemId = gh project item-list 2 --owner ecologicaleaving --format json |
  ConvertFrom-Json | Select-Object -ExpandProperty items |
  Where-Object { $_.title -like "*{titolo_parziale}*" } |
  Select-Object -ExpandProperty id

# 3. Imposta status = Backlog
gh project item-edit `
  --id $itemId `
  --project-id PVT_kwHODSTPQM4BP1Xp `
  --field-id PVTSSF_lAHODSTPQM4BP1Xpzg-INlw `
  --single-select-option-id 2ab61313
```

## Kanban IDs (progetto "80/20 Solutions - Development Hub")
- **Project ID:** `PVT_kwHODSTPQM4BP1Xp`
- **Status field ID:** `PVTSSF_lAHODSTPQM4BP1Xpzg-INlw`
- **Status options:**
  - Backlog → `2ab61313` ← usare sempre per le nuove issue
  - Todo → `f75ad846`
  - In Progress → `47fc9ee4`
  - PUSH → `03f548ab`
  - Test → `1d6a37f9`
  - Done → `98236657`

## Template body issue

Vedi `assets/issue-template.md` — popolarlo con le risposte prima di creare la issue.
Salvare il file temporaneo in `C:\Users\KreshOS\.openclaw\workspace\issue-body.md` ed eliminarlo dopo la creazione.

## Regole
- **Mai aggiungere label** — Davide le assegna manualmente dopo
- **Sempre Backlog** — mai Todo o altro per issue appena create
- **Branch name** (da inserire nel body): `feature/issue-{N}-{slug}` dove N è assegnato da GitHub dopo la creazione
- Se PROJECT.md non esiste, chiedere stack e URL test come domanda separata
