# Skill: create-issue

**Trigger:** `/create-issue` o Davide descrive un bug/feature in modo grezzo
**Agente:** Claudio
**Versione:** 3.0.0

---

## Obiettivo

Creare una issue GitHub leggera e veloce dal report grezzo di Davide.
**Non è necessario approfondire** — la issue viene messa in Backlog e verrà completata durante `/issue-validate`.

---

## Procedura

### Step 1 — Raccolta minima

Se Davide non ha già fornito queste info, chiedile **in un solo messaggio**:

1. **Repo** → su quale progetto? (BeachCRER, Finn, StageConnect, Maestro, AutoDrum, altro)
2. **Tipo** → bug / feature / improvement
3. **Obiettivo** → cosa deve fare in una riga

Non fare altre domande. Non approfondire. Non raccogliere AC, note tecniche o testing.

### Step 2 — Creazione issue

Crea la issue con le informazioni minime raccolte.

```bash
gh issue create \
  --repo ecologicaleaving/<repo> \
  --title "<tipo>: <titolo>" \
  --body "## Descrizione\n<obiettivo in 1-2 righe>\n\n> ⚠️ Issue da validare — AC, note tecniche e checklist verranno aggiunti durante /issue-validate" \
  --label "<tipo>"
```

### Step 3 — Kanban → Backlog

```bash
# Aggiungi la issue al project
gh project item-add 2 --owner ecologicaleaving --url <issue_url>

# La card parte in Backlog automaticamente (nessuna modifica Status necessaria)
```

### Step 4 — Conferma a Davide

```
✅ Issue #N creata: <url>
📌 <titolo>
🏷️ Tipo: <tipo> | Repo: <repo>
📋 In Backlog — scrivi /issue-validate #N quando vuoi prepararla per la lavorazione
```

---

## Regole

- La issue NON deve essere completa — è intenzionalmente leggera
- Niente domande su AC, dipendenze, edge case — quelle vanno in `/issue-validate`
- Niente checkpoint, niente task checklist
- Crea subito, veloce
