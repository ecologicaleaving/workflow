---
name: issue-start
version: 1.0.0
description: >
  Procedura di avvio lavorazione issue. L'agente dev legge questa skill
  prima di toccare qualsiasi codice. Copre: checkout branch, spostamento
  card Kanban → In Progress, lettura contesto progetto.
triggers:
  - "inizia issue"
  - "start issue"
  - "lavora issue"
  - "assegnata issue"
---

# Issue Start — Avvio Lavorazione

Leggi questa skill **prima di scrivere qualsiasi codice**.

---

## STEP 1 — Aggiorna submodule .workflow

**Prima di qualsiasi altra operazione**, assicurati che il submodule `.workflow` sia all'ultima versione disponibile:

```bash
cd <repo-locale>
git submodule update --init --remote .workflow
```

Questo garantisce che CLAUDE.md, AGENTS.md e tutte le skill che leggi siano aggiornate all'ultima versione del workflow del team.

> ⚠️ Se `.workflow` non è presente o non è inizializzato, esegui prima il setup del progetto.

---

## STEP 2 — Leggi l'issue

```bash
gh issue view <N> --repo <owner/repo>
```

Capisci:
- Obiettivo e contesto
- Task da svolgere
- Acceptance Criteria (AC) — sono i tuoi criteri di successo
- Branch suggerito (solitamente indicato nell'issue)
- Repo e stack tecnico

---

## STEP 3 — Checkout branch

```bash
cd <repo-locale>
git checkout master          # o main, verifica quale è il branch principale
git pull origin master
git checkout -b feature/issue-<N>-<slug>
# usa il branch name indicato nell'issue se presente
```

Se il branch esiste già (rework dopo /reject):
```bash
git checkout feature/issue-<N>-<slug>
git pull origin feature/issue-<N>-<slug>
# leggi i commenti dell'issue per il feedback di Davide
gh issue view <N> --repo <owner/repo> --comments
```

---

## STEP 4 — Sposta card → In Progress

**Project ID**: `PVT_kwHODSTPQM4BP1Xp`
**Status Field ID**: `PVTSSF_lAHODSTPQM4BP1Xpzg-INlw`
**Option ID In Progress**: `47fc9ee4`

```bash
# Recupera item ID della card
ITEM_ID=$(gh api graphql -f query='
query($issueId: ID!) {
  node(id: $issueId) {
    ... on Issue { projectItems(first: 5) { nodes { id } } }
  }
}' -f issueId="$(gh issue view <N> --repo <owner/repo> --json id --jq '.id')" \
--jq '.data.node.projectItems.nodes[0].id')

# Sposta In Progress
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

## STEP 5 — Leggi il contesto del progetto

```bash
cat PROJECT.md          # versione, stack, stato, backlog
cat README.md           # overview progetto
cat pubspec.yaml        # Flutter: dipendenze e versione
# oppure
cat package.json        # Node/React: dipendenze e script
```

Tieni PROJECT.md come riferimento attivo per tutto il lavoro.

---

## STEP 6 — Esplora il codice rilevante

- Cerca i file correlati all'issue (widget, service, provider, datasource...)
- Leggi i test esistenti — ti dicono cosa "corretto" significa
- Identifica il comando di test: `flutter test` / `npm test` / `pytest`

---

## ✅ Checklist pre-codice

- [ ] Submodule `.workflow` aggiornato all'ultima versione (`git submodule update --init --remote .workflow`)
- [ ] Issue letta e AC chiari
- [ ] Branch creato e aggiornato da master
- [ ] Card Kanban → In Progress
- [ ] PROJECT.md letto
- [ ] File rilevanti esplorati
- [ ] Comando di test identificato

Quando la checklist è completa → inizia a scrivere codice.  
Quando hai finito → leggi la skill **`issue-done`**.

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
