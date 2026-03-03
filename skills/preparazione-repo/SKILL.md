---
name: preparazione-repo
description: "Prepara una GitHub repo per essere lavorata con il workflow 8020. Controlla e allinea: labels agente/workflow, CLAUDE.md, issue templates, PROJECT.md. Usa quando: (1) si integra una repo nuova o esistente nel workflow, (2) si usa il comando /prepara-repo [owner/repo], (3) si vuole verificare che una repo sia allineata all'ultima versione del workflow."
---

# Preparazione Repo

Porta una repo GitHub all'allineamento completo con il workflow 8020.

## Flusso

1. **Identifica il repo** — dall'invocazione o chiedi a Davide
2. **Leggi PROJECT.md** — estrai stack, piattaforme, descrizione
3. **Controlla e crea labels** — confronta con lista standard, aggiungi le mancanti
4. **Controlla CLAUDE.md** — crea se assente
5. **Controlla issue templates** — crea se assenti
6. **Report finale** — elenca ✅ OK / 🆕 Creato / ⚠️ Da verificare

---

## STEP 1 — Leggi PROJECT.md

```powershell
$raw = gh api repos/{owner}/{repo}/contents/PROJECT.md --jq '.content'
[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($raw))
```

Se PROJECT.md manca → avvisa Davide e crea dal template `workflow-repo/PROJECT_MD_TEMPLATE.md`.  
Se presente → estrai: Stack, Platforms, Deploy Method, Description.

---

## STEP 2 — Labels

### Lista label standard

Vedi `references/labels.md` per la lista completa con colori e descrizioni.

### Recupera labels esistenti

```powershell
gh api repos/{owner}/{repo}/labels --jq '.[].name'
```

### Crea label mancante

```powershell
gh api repos/{owner}/{repo}/labels `
  --method POST `
  --field name="{name}" `
  --field color="{color}" `
  --field description="{description}"
```

Crea SOLO quelle mancanti. Non sovrascrivere quelle esistenti.

---

## STEP 3 — CLAUDE.md

### Verifica

```powershell
gh api repos/{owner}/{repo}/contents/CLAUDE.md 2>&1
```

Se 404 → crea dal template in `assets/CLAUDE.md.template`:  
1. Sostituisci `{owner}`, `{repo}`, `{stack}`, `{description}` con i valori da PROJECT.md  
2. Crea il file via commit diretto su `main` (o branch principale del repo)

```powershell
$body = Get-Content "C:\Users\KreshOS\.openclaw\workspace\workflow-repo\skills\preparazione-repo\assets\CLAUDE.md.template" -Raw
# sostituisci i placeholder
$body = $body -replace '\{owner\}', '{owner}' `
               -replace '\{repo\}', '{repo}' `
               -replace '\{stack\}', '{stack}' `
               -replace '\{description\}', '{description}'

$encoded = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($body))
gh api repos/{owner}/{repo}/contents/CLAUDE.md `
  --method PUT `
  --field message="chore: aggiungi CLAUDE.md per workflow agenti" `
  --field content="$encoded"
```

Se esiste → verifica che contenga il blocco "AVVIO SESSIONE". Se manca, aggiorna.

---

## STEP 4 — Issue Templates

### Verifica

```powershell
gh api repos/{owner}/{repo}/contents/.github/ISSUE_TEMPLATE 2>&1
```

Se 404 → crea i 3 template da `assets/`:
- `feature.md` → `assets/issue-template-feature.md`
- `bug.md` → `assets/issue-template-bug.md`
- `fix.md` → `assets/issue-template-fix.md`

Per ciascun file:

```powershell
$content = Get-Content "C:\Users\KreshOS\.openclaw\workspace\workflow-repo\skills\preparazione-repo\assets\issue-template-{type}.md" -Raw
$encoded = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($content))
gh api repos/{owner}/{repo}/contents/.github/ISSUE_TEMPLATE/{type}.md `
  --method PUT `
  --field message="chore: aggiungi issue template {type}" `
  --field content="$encoded"
```

---

## STEP 5 — Report Finale

Stampa un riepilogo chiaro:

```
📋 Preparazione repo: {owner}/{repo}

Labels
  ✅ già presenti: bug, enhancement, ...
  🆕 create: claude-code, ciccio, codex, in-progress, ...

CLAUDE.md
  🆕 Creato

Issue Templates
  🆕 Creati: feature.md, bug.md, fix.md

PROJECT.md
  ✅ Presente e completo

✅ Repo pronta per il workflow!
```

---

## Regole

- **Mai sovrascrivere** file esistenti senza confrontarli prima
- **Sempre commit su main** (o branch di default del repo) per i file di infrastruttura
- **Non creare PR** per questi file — sono setup, non feature
- Se PROJECT.md manca → avvisa prima di procedere con il resto
