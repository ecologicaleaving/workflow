# Skill: create-issue

**Trigger:** `/create-issue` o Davide descrive un problema/feature  
**Agente:** Claudio  
**Versione:** 2.0.0

---

## Obiettivo

Raccogliere tutte le informazioni necessarie e creare una issue GitHub autosufficiente — l'agente che la prenderà in lavorazione non dovrà fare domande.

---

## Procedura

### Step 1 — Raccolta informazioni

Fai le domande **una alla volta**. Se Davide ha già fornito un'informazione, non chiederla di nuovo.

**Informazioni obbligatorie:**
1. **Repo** → su quale progetto? (StageConnect, BeachRef, Finn, Maestro, AutoDrum, altro)
2. **Tipo** → bug / feature / improvement
3. **Obiettivo** → cosa deve fare in una riga
4. **Contesto** → comportamento attuale vs atteso
5. **Note tecniche** → file rilevanti, dipendenze, vincoli (se noti)
6. **Testing** → come verificare che sia fatto bene

### Step 2 — Acceptance Criteria

Proponi gli AC basandoti su quanto raccolto. Formato:
```
"È done quando..."
- AC 1
- AC 2
- AC 3
```
Aspetta approvazione/modifica di Davide prima di procedere.

### Step 3 — Checkpoint obbligatori

Proponi i checkpoint in base al tipo:

**Feature / Improvement:**
- CP1 — Piano: agente riporta piano + task checklist prima di scrivere codice
- CP2 — Implementazione: report dopo ogni iterazione
- CP3 — Test Suite: risultati completi lint / typecheck / unit / e2e
- CP4 — Pronto per push: AC verificati, PROJECT.md aggiornato

**Bug:**
- CP1 — Root Cause: agente identifica causa prima di toccare codice
- CP2 — Fix: report del fix con test di regressione
- CP3 — Test Suite: risultati completi
- CP4 — Pronto per push: AC verificati, PROJECT.md aggiornato

Aspetta approvazione di Davide.

### Step 4 — Creazione issue

Usa il template corretto (`templates/issue-feature.md`, `issue-bug.md`, `issue-improvement.md`).

```bash
gh issue create \
  --repo ecologicaleaving/<repo> \
  --title "<tipo>: <titolo>" \
  --body "<contenuto template compilato>" \
  --label "<tipo>,agent:<agente>"
```

**NON compilare la sezione Task Checklist** — la riempie l'agente nella fase di piano.

### Step 5 — Kanban

```bash
# Aggiungi la issue al project
gh project item-add 2 --owner ecologicaleaving --url <issue_url>

# La card parte in Backlog automaticamente
```

### Step 6 — Conferma a Davide

```
✅ Issue #N creata: <url>
📌 <titolo>
🏷️ Tipo: <tipo> | Repo: <repo> | Agente: <agente>
📋 Backlog — dimmi quando vuoi avviare il piano
```

---

## Regole

- Non creare la issue prima che Davide abbia approvato AC e checkpoint
- La issue deve essere autosufficiente: niente domande aperte, niente TODO vaghi
- I task li aggiunge l'agente, non Claudio
- Scegli l'agente giusto: Claude Code per sviluppo, Codex come alternativa, Ciccio per infra/VPS
