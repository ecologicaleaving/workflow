---
name: create-issue
description: >
  Crea una issue GitHub leggera su ecologicaleaving e la aggiunge al Kanban in Backlog.
  Skill standalone — non richiede altri file del workflow.
  Trigger: utente descrive un bug/feature/improvement oppure scrive /create-issue.
---

# Skill: create-issue

**Trigger:** `/create-issue` o descrizione libera di un bug/feature/improvement
**Agente:** Claude Code
**Versione:** 4.0.0
**Standalone:** sì — non richiede workflow repo, config.json o script esterni

---

## Obiettivo

Creare una issue GitHub leggera e veloce e aggiungerla al Kanban in **Backlog**.
La issue è intenzionalmente leggera — i dettagli (AC, note tecniche, piano) vengono aggiunti dopo con `/issue-validate`.

---

## Prerequisiti

- `gh` CLI installata ([scarica qui](https://cli.github.com/))
- Account GitHub con accesso alla org `ecologicaleaving`

---

## Procedura

### Step 1 — Login GitHub

Verifica se `gh` è già autenticato:

```bash
gh auth status
```

**Se non autenticato** (errore o "not logged in"):

```bash
gh auth login
```

Segui il wizard interattivo:
- `GitHub.com` → invio
- `HTTPS` → invio
- `Login with a web browser` → invio
- Copia il codice mostrato, premi invio, si apre il browser → incolla il codice → autorizza

Verifica finale:
```bash
gh auth status
# deve mostrare: ✓ Logged in to github.com as <username>
```

> ⚠️ Senza login il Kanban (`gh project`) non è accessibile — questo step è obbligatorio.

---

### Step 2 — Raccolta info

Se l'utente non ha già fornito queste informazioni, chiedile **in un solo messaggio**:

```
Per creare la issue ho bisogno di:

1. **Repo** — su quale progetto?
   finn | StageConnect | BeachRef-app | BeachCRER | maestro | AutoDrum | musicbuddy-app | musicbuddy-web

2. **Tipo** — bug / feature / improvement

3. **Obiettivo** — cosa deve fare, in una riga
```

Non fare altre domande. Non raccogliere AC, note tecniche o dettagli implementativi.

---

### Step 3 — Crea la issue su GitHub

```bash
gh issue create \
  --repo "ecologicaleaving/<repo>" \
  --title "<tipo>: <titolo>" \
  --body "## Descrizione
<obiettivo in 1-2 righe>

> ⚠️ Issue da validare — AC, note tecniche e piano verranno aggiunti durante /issue-validate" \
  --label "<tipo>"
```

Salva l'URL della issue creata (lo usi nello step successivo).

---

### Step 4 — Aggiungi al Kanban (Backlog)

```bash
# Aggiungi la issue al project board
gh project item-add 2 \
  --owner ecologicaleaving \
  --url "<issue_url>"
```

La card parte automaticamente in **Backlog** (colonna di default).

> Se il comando fallisce con "project not found": verifica di avere i permessi sulla org `ecologicaleaving`.

---

### Step 5 — Conferma

```
✅ Issue #N creata: <url>
📌 <titolo>
🏷️ Tipo: <tipo> | Repo: <repo>
📋 In Backlog — usa /issue-validate #N per prepararla alla lavorazione
```

---

## Regole

- La issue NON deve essere completa — è intenzionalmente leggera
- Niente domande su AC, dipendenze, edge case — quelle vanno in `/issue-validate`
- Niente checkpoint, niente task checklist
- Crea subito, veloce
- Non modificare nessun file del progetto in questa fase

---

## Repos disponibili

| Alias | Repo completa |
|-------|--------------|
| finn | `ecologicaleaving/finn` |
| StageConnect | `ecologicaleaving/StageConnect` |
| BeachRef-app | `ecologicaleaving/BeachRef-app` |
| BeachCRER | `ecologicaleaving/BeachCRER` |
| maestro | `ecologicaleaving/maestro` |
| AutoDrum | `ecologicaleaving/AutoDrum` |
| musicbuddy-app | `ecologicaleaving/musicbuddy-app` |
| musicbuddy-web | `ecologicaleaving/musicbuddy-web` |
