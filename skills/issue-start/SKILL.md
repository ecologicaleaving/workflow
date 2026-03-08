---
name: issue-start
version: 2.0.0
description: >
  Procedura di avvio lavorazione issue. L'agente dev legge questa skill
  prima di toccare qualsiasi codice. Copre: sync workflow, checkout branch,
  spostamento card Kanban → In Progress, lettura contesto progetto.
  ATTENZIONE: i controlli sono rigidi. Ogni check fallito è un BLOCCO DURO.
triggers:
  - "inizia issue"
  - "start issue"
  - "lavora issue"
  - "assegnata issue"
---

# Issue Start — Avvio Lavorazione

> ⛔ **REGOLA ZERO**: Non scrivere una sola riga di codice finché tutti gli STEP non sono completati senza errori.
> Ogni check fallito = STOP. Risolvi prima di andare avanti.

---

## STEP 1 — Aggiorna submodule .workflow ⛔ BLOCCO DURO

```bash
cd <repo-locale>
git submodule update --init --remote .workflow
```

**Verifica che il submodule sia aggiornato:**
```bash
cd .workflow && git log --oneline -1
```

Se `.workflow` non è presente o non è inizializzato:
```bash
git submodule add https://github.com/ecologicaleaving/workflow.git .workflow
git submodule update --init --remote .workflow
```

> ⛔ Se il submodule non si aggiorna correttamente → **FERMATI**. Non procedere.
> Segnala il problema a Ciccio prima di toccare qualsiasi file.

---

## STEP 2 — Verifica struttura repo ⛔ BLOCCO DURO

Esegui il pre-flight check canonico:

```bash
bash .workflow/scripts/validate-project.sh .
```

Output atteso: `✅ Pre-flight OK — puoi lanciare l'agente`

**Se il check fallisce** (exit code 1):
- Leggi gli errori uno per uno
- Crea i file mancanti usando i template in `.workflow/templates/`
- **Non procedere** finché `validate-project.sh` non ritorna exit 0

File obbligatori verificati:
| File | Scopo |
|------|-------|
| `AGENTS.md` | Istruzioni per Codex/agenti |
| `CLAUDE.md` | Istruzioni per Claude Code |
| `PROJECT.md` | Stato progetto, versione, stack |
| `.workflow` | Submodule workflow team |
| `.github/workflows/` | CI/CD configurata |
| `.gitignore` | Esclusioni git |

> ⛔ Anche un solo file mancante = STOP. Usa `scripts/setup-project.sh` per creare i mancanti.

---

## STEP 3 — Verifica template CI aggiornato ⛔ BLOCCO DURO

Il file `.github/workflows/build-apk.yml` deve essere allineato al template canonico del workflow.

**Controlla i trigger:**
```bash
grep -A5 "^on:" .github/workflows/build-apk.yml
```

Il trigger deve contenere **solo**:
```yaml
on:
  pull_request:
    branches: ['**']
  push:
    branches:
      - 'feature/**'
      - 'fix/**'
  workflow_dispatch:
```

Se il trigger è `branches: ['**']` (build su ogni branch) → **aggiorna il file** con il template corretto da `.workflow/templates/build-apk.yml` prima di procedere.

**Controlla la notifica Ciccio:**
```bash
grep -A5 "Notify Ciccio\|ciccio-notify" .github/workflows/build-apk.yml
```

La notifica deve includere issue # e PR #. Se non li include → aggiorna il template.

> ⛔ Un CI che builda su ogni branch genera notifiche false a Davide. Aggiornalo prima di pushare.

---

## STEP 4 — Leggi l'issue ⛔ BLOCCO DURO

```bash
gh issue view <N> --repo <owner/repo>
gh issue view <N> --repo <owner/repo> --comments
```

Prima di andare avanti devi sapere con certezza:
- [ ] Obiettivo principale dell'issue
- [ ] **Acceptance Criteria (AC)** — lista numerata, li conosci tutti?
- [ ] Branch da usare (indicato nell'issue o da creare)
- [ ] Stack tecnico (Flutter / Node / React)
- [ ] Se è un rework (/reject): feedback di Davide letto dai commenti

> ⛔ Se non ci sono AC chiari nell'issue → NON iniziare. Aggiungi un commento chiedendo chiarimento a Davide/Ciccio.

---

## STEP 5 — Verifica label agente ⛔ BLOCCO DURO

```bash
gh issue view <N> --repo <owner/repo> --json labels --jq '.labels[].name'
```

La tua label agente deve essere presente (`claude-code`, `codex` o `agent:claude-code`, `agent:codex`).

> ⛔ Se la label è `ciccio` o `agent:ciccio` → questa issue NON è tua. Fermati immediatamente.

---

## STEP 6 — Checkout branch

```bash
cd <repo-locale>
git checkout master
git pull origin master
git checkout -b feature/issue-<N>-<slug>
```

Se il branch esiste già (rework dopo /reject):
```bash
git checkout feature/issue-<N>-<slug>
git pull origin feature/issue-<N>-<slug>
```

**Formato branch obbligatorio:** `feature/issue-{N}-{slug}`
Esempi: `feature/issue-28-offline-cache-sync`, `feature/issue-42-fix-login`

> ⛔ Non usare branch diversi da questo formato. Il CI estrae l'issue # dal nome del branch per le notifiche.

---

## STEP 7 — Sposta card → In Progress

```bash
ISSUE_ID=$(gh issue view <N> --repo <owner/repo> --json id --jq '.id')

ITEM_ID=$(gh api graphql -f query='
query($issueId: ID!) {
  node(id: $issueId) {
    ... on Issue { projectItems(first: 5) { nodes { id } } }
  }
}' -f issueId="$ISSUE_ID" --jq '.data.node.projectItems.nodes[0].id')

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

## STEP 8 — Leggi contesto progetto

```bash
cat PROJECT.md
cat README.md
cat pubspec.yaml   # Flutter
# oppure
cat package.json   # Node/React
```

---

## ✅ Checklist pre-codice — TUTTI i check devono essere ✅

- [ ] `.workflow` submodule aggiornato all'ultima versione
- [ ] `validate-project.sh` → exit 0 (tutti i file obbligatori presenti)
- [ ] CI trigger corretto (solo `feature/**`, `fix/**`, `pull_request`)
- [ ] Notifica CI include issue # e PR #
- [ ] Issue letta, AC tutti chiari
- [ ] Branch nel formato `feature/issue-{N}-{slug}`
- [ ] Label agente verificata (non è `ciccio`)
- [ ] Card Kanban → In Progress
- [ ] PROJECT.md letto

> ⛔ Se anche un solo check è ❌ → NON iniziare a scrivere codice.

Quando la checklist è completa → inizia a sviluppare.
Quando hai finito → leggi **`issue-done`**.

---

## 📊 Kanban — Option ID colonne

| Colonna | Option ID |
|---------|-----------|
| Backlog | `2ab61313` |
| Todo | `f75ad846` |
| In Progress | `47fc9ee4` |
| Test | `1d6a37f9` |
| Review | `03f548ab` |
| Deploy | `37c4aa50` |
| Done | `98236657` |

> ℹ️ Valori strutturati completi in `.workflow/config.json`
