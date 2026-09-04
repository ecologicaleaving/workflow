---
name: issue-validate
description: >
  Trasforma una issue Backlog leggera in una issue completa e pronta per la
  lavorazione: Acceptance Criteria verificabili e taggati, edge case,
  dipendenze, piano. Trigger: /issue-validate #N o /valida #N.
version: 2.0.0
---

# Skill: issue-validate

**Trigger:** `/issue-validate #N` o `/valida #N`

> Riferimento flusso: vedi `FLUSSO.md` — punto 1

---

## Obiettivo

Trasformare una issue Backlog leggera in una issue completa e pronta per la lavorazione.
Fase interattiva con Davide → poi research + piano → resta in **Backlog**, pronta:
il loop parte con `implementa #N` (skill `dev-loop`).

---

## Procedura

### Step 0 — Leggi la issue

```bash
gh issue view <N> --repo ecologicaleaving/<repo> --json title,body,labels
```

Prendi nota di cosa c'è già. Non chiedere cose che Davide ha già scritto.

---

### Step 0a — Il grep PRIMA di scrivere il meccanismo (obbligatorio)

**Regola: nella issue non entra una sola frase su COME funziona una cosa se non l'hai
appena verificata nel codice.** Il sintomo lo racconta chi segnala; il meccanismo lo
scrivi tu, e sei tu a doverlo provare.

Prima di scrivere una riga di «Perché», «Note tecniche» o Acceptance Criteria, apri il
codice e verifica ogni affermazione di meccanismo che stai per mettere nero su bianco:

```bash
# la funzione/variabile/tabella che stai per citare esiste, e fa quello che dici?
grep -rn "<identificatore>" src/ supabase/ --include=*.ts --include=*.tsx --include=*.sql

# la costante ha il valore che stai per scrivere?
grep -rn "NOME_COSTANTE" src/ | head
```

Cosa va verificato, e non dedotto:

| Se nella issue stai per scrivere… | …prima verifica che |
|---|---|
| «X non viene mai calcolato» | non esista già un altro percorso che lo calcola |
| «il dato arriva da Y» | Y sia davvero la sorgente, e non un commento rimasto indietro |
| «la tabella Z contiene…» | Z **esista**: un commento nel codice può citare una tabella mai creata |
| «la soglia è N» | N sia il valore attuale, non quello di quando fu scritta la documentazione |
| «le due schede fanno la stessa cosa» | le firme delle funzioni che le alimentano combacino |
| «basta riorganizzare la presentazione» | i due insiemi di dati abbiano la stessa semantica |

Se il codice contraddice quello che stavi per scrivere, **la scoperta è il valore della
validazione**: mettila nella issue al posto della tua ipotesi.

**Perché questo step esiste.** Il 27/08/2026 su MaestroWeb, tre issue su cinque scritte
nella stessa sessione sono state corrette dal planner in fase di implementazione, sempre
per lo stesso vizio: la segnalazione di Ascanio era giusta nel sintomo, ma la spiegazione
del meccanismo era stata aggiunta senza verificarla.

- **#1797** — «nessun controllo incrocia capacità configurata e reale»: **esistevano già
  entrambi** (`battery-soh.ts` e `battery-power-anomaly.ts`, quest'ultimo da #703). Un
  `grep` avrebbe cambiato la issue da «costruisci il controllo» a «perché quel controllo,
  che c'è, non ha segnalato?».
- **#1794** — diagnosi giusta ma parziale: mancava un secondo punto con lo stesso difetto,
  e il vero produttore dei dati scriveva in una tabella diversa da quella citata dal
  commento nel codice.
- **#1799** — la premessa («le due schede sono entrambe legate al periodo») era **falsa su
  tre punti**: il planner si è rifiutato di implementare e la issue è tornata in decisione.

Il loop di implementazione le ha intercettate tutte e tre, quindi in produzione non è
arrivato nulla di sbagliato. Ma un loop che ripianifica costa giri, e una issue rimandata
indietro costa una decisione umana in più: il `grep` costa secondi.

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

### Step 0b — Scegli il tier di rigore (obbligatorio, prima del loop)

Il loop Draft↔Critica dello Step 1a è costoso — ogni giro è un'investigazione completa
(un agente rilegge codice/branch/API reali da zero, non si fida del testo). Applicarlo
sempre allo stesso livello sprecherebbe token su issue banali e rischierebbe di essere
troppo permissivo su issue che governano rilascio/dati/soldi. Scegli il **tier** prima di
partire, dichiaralo in una riga a Davide ("Tier: leggero — fix di wording, nessun
meccanismo critico") e procedi subito — non aspettare conferma, salvo che Davide non ti
corregga (in quel caso, ripeti da questo step col tier giusto).

| Tier | Quando | Giri massimi | Critica |
|---|---|---|---|
| **Leggero** | Wording, copy, fix estetici minori, nessun meccanismo toccato | 1 (raramente 2) | Fable critica solo se il draft ha AC vaghi/non atomici a occhio; se il draft è ovviamente pulito, può essere skippata — annotalo esplicitamente ("critica skippata: AC banali, nessun rischio") |
| **Standard** | Bug/feature UI o logica applicativa normale, non tocca rilascio/dati/auth | 2 | Sempre almeno un giro Sonnet↔Fable |
| **Critico** | Tocca meccanismi di **rilascio** (deploy, `/approva`, promozione beta→main), **dati** (migrazioni, scritture irreversibili, denaro), **auth/permessi**, o qualunque cosa che finirebbe in produzione senza un secondo controllo umano prima di avere effetto | fino a **6** (vedi cap Step 1a) | Sempre, rigore massimo, non fermarsi al primo verdetto pulito se la critica stessa segnala incertezza residua |

Esempi dalla sessione del 22-24/07/2026 (maestroweb): #1470 (wording di un messaggio) →
leggero, 1 giro, 5 AC. #1462/#1463/#1466/#1468/#1475 (bug/feature UI normali) →
standard, 1-2 giri. #1478 (promozione selettiva `beta`→`main`, esegue `/approva`) →
critico, 6 giri — ha trovato 2 bug che avrebbero reso la feature completamente non
funzionante in produzione. La differenza di costo tra leggero e critico è reale (un
ordine di grandezza in agenti spawnati) — è il punto: non pagarla quando non serve.

Se in dubbio tra due tier, scegli quello più alto — costa un giro in più, non un
incidente in produzione.

---

### Step 1a — Loop Sonnet (scrive) ↔ Fable (giudica): genera e verifica gli Acceptance Criteria (obbligatorio)

L'obiettivo grezzo raccolto allo Step 1 punto 1 (+ edge case dello Step 1 punto 2) va
trasformato in AC formali da un **loop Draft↔Critica**: Sonnet 5 scrive, Fable 5
giudica — mai lo stesso agente/modello si autovaluta. Numero di giri governato dal
**tier** scelto allo Step 0b.

**Bar di qualità** (lo stesso usato in fase di implementazione — vedi anche
skill `dev-loop`): ogni AC deve essere

- **atomico** — una "e" che unisce due comportamenti indipendenti va spezzata in due AC
- **input concreto → output/comportamento osservabile**, mai un obiettivo generico
  ("migliora le performance" ❌ → "la query risponde in una sola chiamata, non N+1" ✅)
- **verificabile leggendo diff, risposta API o screenshot** — niente giudizio soggettivo
  ("interfaccia più chiara" ❌ → "il bottone è raggiungibile senza scroll su 1280×800" ✅)
- **esaustivo sugli edge case** raccolti allo Step 1 punto 2
- **formattato come riga checkbox markdown**: `- [ ] **[UI]** testo` / `- [ ] **[Codice]** testo`
  — **MAI lista numerata** (`1. **[UI]** testo`). `parseAcceptanceCriteria` in
  `src/lib/qa-checklist.ts` riconosce SOLO righe che iniziano con `- [ ]`/`* [ ]`; una
  lista numerata produce zero AC estratti e `/qa` non mostra nulla per quella issue
  (bug reale trovato il 22/07/2026 su #1462/#1463/#1466, scritte come lista numerata
  al primo giro e dovute essere corrette a mano dopo la validazione)
- **etichettato con il tipo** `[UI]` o `[Codice]` (vedi sotto) — obbligatorio, un AC senza
  tag non è considerato completo e fallisce la critica a prescindere dal resto

**Tipo di AC — chi lo verifica dopo**:

| Tag | Cos'è | Chi verifica | Dove |
|---|---|---|---|
| `[UI]` | Comportamento osservabile da chi **non** guarda il codice: colore, layout, testo, navigazione, screenshot | Claudio prima (Chrome, dati reali), **poi Ascanio** su `/qa` | Card AC mostrata su `/qa`, va approvata da Ascanio |
| `[Codice]` | Comportamento interno non osservabile senza ispezionare codice/query/stato — invarianti, riferimenti a funzioni, contratti tra moduli | **Solo** Claudio + l'agente developer (verifica il loop `dev-loop`, fase Verifica AC) | Mai mostrata ad Ascanio — verificata e chiusa prima che la PR arrivi a `/qa` |

Criterio di classificazione: se per giudicare l'AC basta guardare la pagina/uno
screenshot senza sapere nulla dell'implementazione → `[UI]`. Se serve leggere una riga
di codice, una query, un nome di funzione/variabile per capire cosa si sta verificando
→ `[Codice]`, anche se l'effetto finale è (anche) visibile — es. "il bordo è rosso
perché `severityBySite` restituisce 'critico'" è `[Codice]` (cita l'implementazione),
mentre "il bordo è rosso quando l'impianto ha un guasto reale" è `[UI]` (stesso esito,
descritto senza nominare l'implementazione). Nel dubbio, classifica `[Codice]` — un AC
mostrato di troppo ad Ascanio è solo rumore, uno mancante è un buco di verifica.

**Meccanica del loop** (cap dipendente dal tier — Step 0b: leggero 1-2, standard 2,
critico fino a 6):

1. `attempt = 0`, `clean = false`, `maxAttempts` = cap del tier
2. Finché `!clean && attempt < maxAttempts`:
   - `attempt += 1`
   - **Draft** (`model: 'sonnet'` via `Agent` tool): genera/riscrive la lista AC da
     obiettivo + edge case + (se `attempt > 1`) il feedback della critica precedente
   - **Critica** (`model: 'fable'` via `Agent` tool, agente separato dal draft) — su
     tier leggero con draft ovviamente pulito, questo passo può essere skippato
     esplicitamente (vedi Step 0b): per ogni AC del draft, verdetto `pass/fail` + motivo
     puntuale sulla bar di qualità sopra; verdetto complessivo `clean = true` solo se
     **tutti** gli AC passano
3. Se `clean` → procedi allo Step 2 con la lista AC finale
4. Se dopo `maxAttempts` tentativi `!clean` → **non forzare**: presenta a Davide/Ascanio
   in chat i punti ancora ambigui con la motivazione della critica e chiedi chiarimento
   diretto, invece di scrivere sulla issue AC che il loop stesso giudica non
   verificabili. Su tier critico, se la critica converge ma segnala ancora incertezza
   residua non risolta, non fermarti al primo `clean = true` — un altro giro di
   verifica mirata su quel punto specifico costa molto meno di un incidente in prod
   (vedi #1478, 6 giri, 2 bug bloccanti trovati proprio negli ultimi giri).

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

### Step 7 — La issue è pronta

Resta in **Backlog**, con la sezione Acceptance Criteria e il piano postato
come commento (Step 6). Non c'è una colonna "Todo" nel flusso reale — il
Kanban GitHub passa direttamente da Backlog a **In Progress** quando parte
il loop di implementazione (`FLUSSO.md` punto 2), non a un passaggio
intermedio qui.

---

### Step 8 — Notifica Davide

```
✅ [Issue #N] Pronta — <titolo>
📌 <summary piano in 2-3 righe>
✓ precheck verde
⏭️ Parte con "implementa #N"
```

Il comando di Davide che avvia il loop è **`implementa #N`** (o `risolvi
issue #N`), non `/vai` — vedi skill `dev-loop`.

---
