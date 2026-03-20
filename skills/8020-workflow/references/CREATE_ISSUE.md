# CREATE_ISSUE.md — Procedura creazione issue

## Checklist OBBLIGATORIA (prima di creare)

**Chiedi a Davide se non è già specificato:**
1. ✅ Repo corretto? (conferma sempre)
2. ✅ Tipo: bug / feature / improvement / question?
3. ✅ Descrizione chiara con comportamento attuale vs atteso?

**Non chiedere:**
- Agente da assegnare → NON di tua competenza (lo fa Claudio)
- Priorità → Davide la gestisce con il Kanban

---

## Procedura

### 1. Crea la issue su GitHub
```bash
gh issue create \
  --repo ecologicaleaving/<REPO> \
  --title "<TITOLO>" \
  --body "<CORPO>"
```

**Corpo issue — struttura minima:**
```markdown
## 📋 Descrizione
[Cosa deve fare / qual è il problema]

## 🔧 Comportamento attuale
[Solo per bug]

## 🎯 Comportamento atteso / Requisiti
[Cosa deve succedere]

## ✅ Acceptance Criteria
- [ ] AC1: ...
- [ ] AC2: ...
```

### 2. NON assegnare label agente
La label agente (`agent:claude-code`, `agent:ciccio`, `agent:codex`) viene assegnata da Claudio su indicazione di Davide quando si avvia la lavorazione.

### 3. Aggiungi al Kanban in colonna **Backlog**
```bash
export PATH=$PATH:/root/go/bin

# Aggiungi al project
ITEM_ID=$(gh project item-add 2 --owner ecologicaleaving \
  --url https://github.com/ecologicaleaving/<REPO>/issues/<N> \
  --format json | jq -r '.id')

# Imposta colonna Backlog
gh project item-edit \
  --project-id PVT_kwHODSTPQM4BP1Xp \
  --id "$ITEM_ID" \
  --field-id PVTSSF_lAHODSTPQM4BP1Xpzg-INlw \
  --single-select-option-id 2ab61313
```

### 4. Notifica Davide
```
✅ Issue creata: <REPO>#<N> — <TITOLO>
📋 Kanban: Backlog
🔗 <URL>
```

---

## IDs di riferimento Kanban
- **Project ID**: `PVT_kwHODSTPQM4BP1Xp`
- **Field ID (Status)**: `PVTSSF_lAHODSTPQM4BP1Xpzg-INlw`
- **Backlog**: `2ab61313`
- **Todo**: `f75ad846`
- **In Progress**: `47fc9ee4`
- **Test**: `1d6a37f9`
- **Review**: `03f548ab`
- **Deploy**: `37c4aa50`
- **Done**: `98236657`
