# Skill: issue-validate

**Trigger:** `/issue-validate #N` o `/valida #N`
**Agente:** Claude Code
**Versione:** 5.1.0

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

1. **Acceptance Criteria** — Cosa deve essere vero perché questa issue sia "done"? Raccogli l'obiettivo in linguaggio libero da Davide/Ascanio (non chiedere già una lista formale di AC — quella la produce il loop dello Step 1a).

2. **Edge case / comportamenti limite** — Ci sono casi particolari da gestire? (es. dati mancanti, utenti non autorizzati, file vuoti, ecc.)

3. **Dipendenze** — Ci sono issue che devono essere chiuse prima? Questa issue ne blocca altre? Verifica anche le issue future collegate (stessa epic, dipendenze tecniche) e segnala se serve aggiornarle per coerenza con quanto emerso nella validazione.

4. **Note tecniche** — File specifici da toccare, librerie preferite, vincoli di architettura? (se non lo sai, skip)

5. **Priorità** — Alta / Media / Bassa (le stime non interessano a Davide, skippa)

Se una risposta è già chiara dal contesto, skippa la domanda.

---

### Step 1a — Loop Sonnet (scrive) ↔ Opus (giudica): genera e verifica gli Acceptance Criteria (obbligatorio)

L'obiettivo grezzo raccolto allo Step 1 punto 1 (+ edge case dello Step 1 punto 2) va
trasformato in AC formali da un **loop Draft↔Critica**: Sonnet 5 scrive, Opus 4.8
giudica — mai lo stesso agente/modello si autovaluta.

**Bar di qualità** (lo stesso usato in fase di implementazione — vedi anche
`dev-loop-opus-sonnet` in MaestroWeb): ogni AC deve essere

- **atomico** — una "e" che unisce due comportamenti indipendenti va spezzata in due AC
- **input concreto → output/comportamento osservabile**, mai un obiettivo generico
  ("migliora le performance" ❌ → "la query risponde in una sola chiamata, non N+1" ✅)
- **verificabile leggendo diff, risposta API o screenshot** — niente giudizio soggettivo
  ("interfaccia più chiara" ❌ → "il bottone è raggiungibile senza scroll su 1280×800" ✅)
- **esaustivo sugli edge case** raccolti allo Step 1 punto 2
- **etichettato con il tipo** `[UI]` o `[Codice]` (vedi sotto) — obbligatorio, un AC senza
  tag non è considerato completo e fallisce la critica a prescindere dal resto

**Tipo di AC — chi lo verifica dopo**:

| Tag | Cos'è | Chi verifica | Dove |
|---|---|---|---|
| `[UI]` | Comportamento osservabile da chi **non** guarda il codice: colore, layout, testo, navigazione, screenshot | Claudio prima (Chrome, dati reali), **poi Ascanio** su `/qa` | Card AC mostrata su `/qa`, va approvata da Ascanio |
| `[Codice]` | Comportamento interno non osservabile senza ispezionare codice/query/stato — invarianti, riferimenti a funzioni, contratti tra moduli | **Solo** Claudio + l'agente developer (verifica Opus nel loop `dev-loop-opus-sonnet`, Fase 2) | Mai mostrata ad Ascanio — verificata e chiusa prima che la PR arrivi a `/qa` |

Criterio di classificazione: se per giudicare l'AC basta guardare la pagina/uno
screenshot senza sapere nulla dell'implementazione → `[UI]`. Se serve leggere una riga
di codice, una query, un nome di funzione/variabile per capire cosa si sta verificando
→ `[Codice]`, anche se l'effetto finale è (anche) visibile — es. "il bordo è rosso
perché `severityBySite` restituisce 'critico'" è `[Codice]` (cita l'implementazione),
mentre "il bordo è rosso quando l'impianto ha un guasto reale" è `[UI]` (stesso esito,
descritto senza nominare l'implementazione). Nel dubbio, classifica `[Codice]` — un AC
mostrato di troppo ad Ascanio è solo rumore, uno mancante è un buco di verifica.

**Meccanica del loop** (cap **4 iterazioni**):

1. `attempt = 0`, `clean = false`
2. Finché `!clean && attempt < 4`:
   - `attempt += 1`
   - **Draft** (`model: 'sonnet'` via `Agent` tool): genera/riscrive la lista AC da
     obiettivo + edge case + (se `attempt > 1`) il feedback della critica precedente
   - **Critica** (`model: 'opus'` via `Agent` tool, agente separato dal draft): per
     ogni AC del draft, verdetto `pass/fail` + motivo puntuale sulla bar di qualità
     sopra; verdetto complessivo `clean = true` solo se **tutti** gli AC passano
3. Se `clean` → procedi allo Step 2 con la lista AC finale
4. Se dopo 4 tentativi `!clean` → **non forzare**: presenta a Davide/Ascanio in chat i
   punti ancora ambigui con la motivazione della critica e chiedi chiarimento diretto,
   invece di scrivere sulla issue AC che il loop stesso giudica non verificabili

Solo dopo la conferma umana (esplicita, o convergenza pulita del loop) gli AC finali
entrano nel body della issue allo Step 2.

---

### Step 1b — Verifica versioni dipendenze (obbligatorio)

Prima di aggiornare la issue, verifica le versioni dei tool e librerie coinvolti:

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

Riporta le versioni rilevanti nel body aggiornato della issue nella sezione "Note tecniche".

---

### Step 1c — Verifica coerenza con issue future collegate (obbligatorio)

Dopo aver raccolto le risposte, prima di aggiornare la issue:

1. Identifica le issue future che dipendono da questa (stessa epic, stessa area funzionale)
2. Verifica se le decisioni prese nella validazione impattano quelle issue
3. Se sì → proponi aggiornamento a Davide e aggiorna anche quelle issue

```bash
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

Se qualcosa manca → blocca e notifica Davide.

---

### Step 4 — Research + piano

Esplora il codebase in modo approfondito, poi produci un piano dettagliato:

1. Struttura progetto e file rilevanti
2. Codice esistente collegato alla issue + versioni dipendenze
3. File da toccare (con motivazione)
4. Approccio tecnico step-by-step
5. Rischi e possibili problemi
6. Task checklist (lista di step implementativi)
7. Stima complessità

⚠️ NON modificare alcun file in questa fase. Solo lettura, analisi e piano.

---

### Step 5 — Auto-validazione piano

**✅ Piano ok se:**
- Copre tutti gli AC definiti con Davide
- File identificati sensati e in scope
- Nessun approccio rischioso
- Task checklist dettagliata e realistica
- Coerente con le decisioni prese nella validazione

**⚠️ Anomalia se:**
- Piano ignora degli AC
- Vuole toccare file fuori scope
- Approccio tecnico sbagliato o incongruente con il codebase esistente

Se anomalia → blocca e notifica Davide prima di procedere.

---

### Step 6 — Posta piano come commento sulla issue

```bash
gh issue comment <N> --repo ecologicaleaving/<repo> \
  --body "## 📝 Piano\n\n<piano completo>"
```

---

### Step 7 — Sposta card → Todo

```bash
./scripts/kanban-move.sh <N> <repo> Todo
```

---

### Step 8 — Notifica Davide e aspetta `/vai`

```
✅ [Issue #N] Piano pronto — <titolo>
📌 <summary piano in 2-3 righe>
⏭️ Scrivi /vai per avviare l'implementazione
```

⚠️ **L'agente NON avvia mai l'implementazione senza `/vai` esplicito di Davide.**

---

## Changelog

- **v5.1.0** (2026-07-22): Ogni AC ora obbligato a un tag `[UI]`/`[Codice]`. `[UI]` =
  osservabile senza guardare il codice → verificato da Claudio poi da Ascanio su `/qa`.
  `[Codice]` = richiede ispezionare implementazione/query/invarianti → verificato solo
  da Claudio + agente developer nel loop `dev-loop-opus-sonnet` (Fase 2), mai mostrato
  ad Ascanio. Riduce il rumore su `/qa` a ciò che Ascanio può davvero giudicare guardando
  la pagina. **Nota**: la parte consumer (`/qa` — parsing AC, cascade `qa-approved`) non
  filtra ancora per tag — serve un follow-up sul repo MaestroWeb per far sì che il
  merge automatico consideri "tutti gli AC approvati" come "tutti gli `[UI]` approvati
  da Ascanio + tutti i `[Codice]` già verdi dal loop di Fase 2", non tutti gli AC
  indistintamente.
- **v5.0.0** (2026-07-22): Reintrodotto Opus, stavolta solo per il giudizio degli AC —
  Step 1a: loop Draft (Sonnet 5) ↔ Critica (Opus 4.8, agente separato, cap 4
  iterazioni) genera e verifica gli Acceptance Criteria contro una bar di qualità
  esplicita (atomico, verificabile, esaustivo sugli edge case) prima che entrino nel
  body della issue. Simmetrico al loop Opus-pianifica/verifica ↔ Sonnet-implementa
  introdotto in fase di implementazione (skill `dev-loop-opus-sonnet`, per ora solo su
  MaestroWeb).
- **v4.0.0** (2026-04-13): Rimosso ruolo Claudio — agente unico gestisce tutto
- **v3.0.0** (2026-04-03): Agente unico Sonnet per research+piano+implementazione, rimosso Haiku separato
- **v2.0.0** (2026-04-03): Refactor — Opus→Sonnet per piano, rimossa duplicazione modelli
- **v1.0.0** (2026-03-31): Prima versione
