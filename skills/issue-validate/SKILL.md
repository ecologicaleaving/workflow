# Skill: issue-validate

**Trigger:** `/issue-validate #N` o `/valida #N`
**Agente:** Claudio (interattivo con Davide) + Haiku (research) + Sonnet (piano)
**Versione:** 2.0.0

> Riferimento flusso: vedi `WORKFLOW.md` — Fase 2

---

## Obiettivo

Trasformare una issue Backlog leggera in una issue completa e pronta per la lavorazione.
Fase interattiva con Davide → poi research + piano → card → **Todo** → aspetta `/vai`.

---

## Procedura

### Step 0 — Leggi la issue

```bash
gh issue view <N> --repo ecologicaleaving/<repo> --json title,body,labels
```

Prendi nota di cosa c'è già. Non chiedere cose che Davide ha già scritto.

---

### Step 1 — Sessione domande interattiva

Fai le domande **una alla volta**, in ordine. Aspetta la risposta prima di passare alla prossima.

**Domande standard (adatta al tipo bug/feature/improvement):**

1. **Acceptance Criteria** — Cosa deve essere vero perché questa issue sia "done"? Proponi una lista basandoti sulla descrizione e aspetta conferma/modifica.

2. **Edge case / comportamenti limite** — Ci sono casi particolari da gestire? (es. dati mancanti, utenti non autorizzati, file vuoti, ecc.)

3. **Dipendenze** — Ci sono issue che devono essere chiuse prima? Questa issue ne blocca altre? Verifica anche le issue future collegate (stessa epic, dipendenze tecniche) e segnala se serve aggiornarle per coerenza con quanto emerso nella validazione.

4. **Note tecniche** — File specifici da toccare, librerie preferite, vincoli di architettura? (se non lo sai, skip)

5. **Priorità** — Alta / Media / Bassa (le stime non interessano a Davide, skippa)

Se una risposta è già chiara dal contesto, skippa la domanda.

---

### Step 1b — Verifica versioni dipendenze (obbligatorio)

Prima di aggiornare la issue, verifica le versioni dei tool e librerie coinvolti nell'implementazione:

```bash
cd /tmp/<repo>

# Versioni principali framework
cat package.json | jq '{
  dependencies: .dependencies,
  devDependencies: .devDependencies
} | to_entries | .[] | select(.value | type == "object") | .value | to_entries | .[]' 2>/dev/null \
  || cat package.json | grep -E '"(next|react|typescript|supabase|flutter|dart)" *:'

# Versione Node
node --version 2>/dev/null

# Per Flutter
flutter --version 2>/dev/null | head -3
```

**Perché:** le dipendenze esistenti determinano quale approccio tecnico è compatibile (es. Next.js 15 vs 14 ha API diverse, googleapis richiede versione specifica di Node, ecc.).

Riporta le versioni rilevanti nel body aggiornato della issue nella sezione "Note tecniche".

---

### Step 1c — Verifica coerenza con issue future collegate (obbligatorio)

Dopo aver raccolto le risposte, prima di aggiornare la issue:

1. Identifica le issue future che dipendono da questa (stessa epic, stessa area funzionale)
2. Verifica se le decisioni prese nella validazione impattano quelle issue (es. cambio architettura, nuovi campi DB, nuova logica)
3. Se sì → proponi aggiornamento a Davide e aggiorna anche quelle issue

```bash
# Controlla issue aperte della stessa epic
gh issue list --repo ecologicaleaving/<repo> --state open \
  --label "<epic>" --json number,title,body | jq '.[]'
```

---

### Step 2 — Aggiorna la issue su GitHub

Con le risposte di Davide, aggiorna la issue con il body completo:

```bash
gh issue edit <N> --repo ecologicaleaving/<repo> \
  --body "<body completo con: Descrizione, Acceptance Criteria, Edge case, Dipendenze, Note tecniche>"
```

Aggiungi label priorità se non presente:

```bash
gh issue edit <N> --repo ecologicaleaving/<repo> --add-label "priorità:<alta|media|bassa>"
```

---

### Step 3 — Verifica sistema deploy (solo se primo lavoro su questa repo)

Verifica CI pipeline, secrets, sottodomini. Se già verificato per questa repo, salta.

```bash
REPO="<repo>"
echo "=== CI pipeline ==="
gh api repos/ecologicaleaving/$REPO/contents/.github/workflows/deploy.yml 2>/dev/null \
  | jq -r '.content' | base64 -d | grep -q "rsync\|ssh" && echo "✅" || echo "❌ assente"
echo "=== Secrets ==="
gh secret list --repo ecologicaleaving/$REPO
echo "=== Test ==="
curl -s -o /dev/null -w "HTTP %{http_code}" "https://test-$REPO.8020solutions.org"
```

Se qualcosa manca → blocca e notifica Davide + Ciccio.

---

### Step 4 — Lancia Research (Haiku)

```
Leggi la issue #N su ecologicaleaving/<repo>.
Clona o aggiorna il repo localmente.
Esplora il codebase in modo approfondito.

Riporta:
- Struttura progetto e file rilevanti
- Codice esistente collegato alla issue
- Versioni delle dipendenze rilevanti (framework, librerie coinvolte dalla issue)
- Dipendenze mancanti da installare (con versione consigliata compatibile)
- Vincoli tecnici imposti dalle versioni correnti
- Qualsiasi info utile per pianificare l'implementazione

⚠️ NON modificare alcun file. Solo lettura e analisi.
```

Modello: `anthropic/claude-haiku-4-5`

---

### Step 5 — Lancia Piano (Sonnet)

Quando Haiku restituisce la research, lancia Sonnet con il contesto:

```
Basandoti sulla seguente analisi del codebase:
<output research Haiku>

E sulla issue #N (ecologicaleaving/<repo>):
<body issue aggiornato>

Produci un piano dettagliato che includa:
1. Comprensione del problema / obiettivo
2. File da toccare (con motivazione)
3. Approccio tecnico step-by-step
4. Rischi e possibili problemi
5. Task checklist (lista di step implementativi)
6. Stima complessità

⚠️ NON modificare alcun file in questa fase.
```

Modello: `anthropic/claude-sonnet-4-6`

---

### Step 6 — Valuta il piano

**✅ Piano ok se:**
- Copre tutti gli AC definiti con Davide
- File identificati sensati e in scope
- Nessun approccio rischioso
- Task checklist dettagliata e realistica
- Coerente con le decisioni prese nella validazione (es. architettura DB, logica business)

**⚠️ Anomalia se:**
- Piano ignora degli AC
- Vuole toccare file fuori scope
- Approccio tecnico sbagliato o incongruente con il codebase esistente
- Propone soluzioni già escluse durante la validazione

Se anomalia → blocca e notifica Davide prima di procedere.

---

### Step 7 — Posta piano come commento sulla issue

```bash
gh issue comment <N> --repo ecologicaleaving/<repo> \
  --body "## 📝 Piano (generato da Sonnet)\n\n<piano completo>"
```

---

### Step 8 — Sposta card → Todo

```bash
./scripts/kanban-move.sh <N> <repo> Todo
```

---

### Step 9 — Notifica Davide e aspetta `/vai`

```
✅ [Issue #N] Piano pronto — <titolo>
📌 <summary piano in 2-3 righe>
⏭️ Scrivi /vai per avviare l'implementazione
```

⚠️ **Claudio NON avvia mai l'implementazione senza `/vai` esplicito di Davide.**

---

## Changelog

- **v2.0.0** (2026-04-03): Refactor — Opus→Sonnet per piano, rimossa duplicazione modelli (vedi WORKFLOW.md), verifica deploy condizionale, assorbita issue-start
- **v1.2.0** (2026-03-31): Aggiunto Step 1b — verifica versioni dipendenze
- **v1.1.0** (2026-03-31): Aggiunto Step 1b — verifica coerenza issue future collegate
- **v1.0.0** (2026-03-31): Prima versione
