# FLUSSO — 80/20 Solutions Workflow v2

Unica fonte di verità del flusso. Deciso da Davide il 04/09/2026. Le skill
rimandano qui invece di ripetere le procedure: se una skill e questo file
sono in disaccordo, vince questo file.

## Ruoli

| Chi | Cosa fa |
|---|---|
| **Davide** | Decide, testa, approva (`/approva`) |
| **Ascanio** | Co-fondatore. Prova sul campo, approva dal suo pannello (`/qa`) |
| **Claudio** | Orchestratore — gira su **Fable 5** (alias `model: 'fable'`). Pianifica, verifica, coordina. Non implementa. |
| **developer** | Subagente **Sonnet 5** (alias `model: 'sonnet'`), in worktree isolato. Implementa. |
| **Gaia** | Business e governance — vive nel repo `ecologicaleaving`. Citata qui solo per completezza dei ruoli. |

## Branch e merge

```
feature/issue-N-slug  →  beta  →  main
     (sviluppo)      (test, dati reali)  (produzione, CI deploya)
```

Merge sempre `--merge`, **mai `--squash`**. Nessun merge in `main` senza
`/approva` di Davide.

---

## 0. Dall'idea di Ascanio alla issue

Due ingressi. Le richieste di Davide diventano issue direttamente (punto 1).
Le segnalazioni di Ascanio nascono come **card in «Idee ASCANIO»**
(`qa_tasks`, stage `idee`) dal pannello laterale o da `/qa` — la card è
**l'unica cosa che lui vede**.

**Triage della card**, fatto da Claudio (spesso insieme a Davide):

1. Leggi la card **nei dati** — titolo, descrizione, allegati, commenti
   (`qa_tasks`, `qa_task_comments`, `qa_task_attachments` via REST con
   service key) — non a schermo, il pannello ne mostra solo alcune.
2. Capisci se esiste già: grep del meccanismo nel codice, controllo in
   produzione, `git log origin/main..origin/beta`. «Un'assenza è quasi
   sempre una decisione già presa», e «il fix può essere già scritto e solo
   non promosso».
3. Se serve una decisione o una prova sua → card in **To Do ASCANIO** con
   la domanda scritta in `review_notes`, in italiano comune. Quando
   risponde, la card compare in «Fatte da Ascanio» e torna a noi.
4. Se è già fatto o già coperto da un'altra issue → chiudi la card con un
   commento che dice dove sta.
5. Altrimenti scrivi la issue.

**Come si scrive la issue dalla card:**

- Titolo = **cosa cambia per chi usa Maestro**, non il meccanismo (regola
  «issue leggibili da Ascanio»).
- Prima riga del body: `Ascanio, gg/mm: …` con la sua richiesta citata.
- Poi: «Cosa succede oggi» (verificato sul codice), «Cosa deve cambiare»,
  gli AC con i tag (punto 1), «Come verificare».
- Il collegamento card↔issue si registra in `qa_task_issues`.
- Label `ascanio`, Kanban Backlog, precheck.

**Una card = un'epica.** Se dalla card escono più issue, apri un'epica
collegata alla card e le sotto-issue sono figlie — nel pannello di Ascanio
compare solo l'epica, e la `qa-approved` la eredita da lei. Una card con più
di una issue collegata è il segnale che la regola non è stata seguita
(incidente 18/08/2026: promozione spezzata in dieci gruppi per
un'anagrafica nata come quindici issue sorelle).

**Quando parte il lavoro:** card → **In Lavorazione** (punto 2). Quando è
in `beta` e provata → **Revisione** (punto 4). Il lavoro tecnico che nasce
strada facendo (bug nostri, refactor) **non ha card**: sta solo su GitHub.

Dettaglio (template della issue, come si leggono allegati e commenti):
skill `ascanio`.

---

## 1. Issue con Acceptance Criteria verificabili

Ogni issue ha una sezione `## Acceptance Criteria` con checkbox, AC atomici
(input concreto → esito osservabile), taggati:

| Tag | Significa | Chi verifica |
|---|---|---|
| `[UI]` | Osservabile senza guardare il codice | Claudio, poi Ascanio |
| `[Codice]` | Serve leggere codice/query/stato | Solo Claudio + developer |
| `[Campo]` | Richiede scrivere su un impianto reale | Solo Ascanio, mai un agente |
| `[Azione]` | Richiede che Ascanio faccia qualcosa (non solo confermi) | Solo Ascanio |

### Come si scrive un AC

1. **Atomico** — una "e" che unisce due comportamenti indipendenti si
   spezza in due AC.
2. **Input concreto → esito osservabile**, mai un obiettivo generico
   ("migliora le performance" ✗ → "la query su `historical_readings` per
   30 giorni risponde in una chiamata, non N+1" ✓).
3. **Verificabile** leggendo il diff, una risposta API o lo schermo — mai
   giudizio soggettivo ("interfaccia più chiara" ✗ → "il pulsante è
   raggiungibile senza scroll a 1280×800" ✓).
4. Include il **caso limite** quando è quello il punto della issue ("campo
   null → il derivato `*_pct` è null, non 0").
5. Se l'AC dice **"grep → zero occorrenze"**, il grep si esegue **prima**
   di scriverlo, non dopo (episodio #1758 — un AC scritto sulla fiducia
   che poi il grep smentiva).
6. **Tag obbligatorio** su ogni AC — un AC senza tag non è completo.
7. **Formato**: `- [ ] [Tag] ACn — testo`.

Il loop che genera e verifica gli AC (Draft↔Critica, con il tier di rigore
da scegliere prima di partire) è nella skill `issue-validate`.

Prima del loop di implementazione:

```bash
npm run issue:precheck N
```

Blocca se: la issue è già in main, non ha AC verificabili, il testo dice
«verificare se già presente», o ha dipendenze ancora aperte.

Su MaestroWeb **Ascanio non apre issue**: scrive una card in «Idee ASCANIO».
**Una card = un'epica** — le sotto-issue tecniche non vanno mai nel suo
pannello e non ricevono mai una `qa-approved` propria: la ereditano
dall'epica quando lui approva la scheda. Vedi skill `ascanio`.

---

## 2. Presa in carico

Due card diverse, entrambe da spostare a mano — non c'è automatismo:

**Kanban GitHub** (project `PVT_kwHODSTPQM4BP1Xp`, field
`PVTSSF_lAHODSTPQM4BP1Xpzg-INlw`):

| Colonna | Option ID |
|---|---|
| Backlog | `2ab61313` |
| In Progress | `47fc9ee4` |
| Test | `1d6a37f9` |
| Done | `98236657` |

```bash
gh project item-edit --id "$ITEM_ID" \
  --project-id PVT_kwHODSTPQM4BP1Xp \
  --field-id PVTSSF_lAHODSTPQM4BP1Xpzg-INlw \
  --single-select-option-id 47fc9ee4
```

`$ITEM_ID` si prende via GraphQL (`issue.projectItems`), non enumerando la
lista item — su un board grande l'enumerazione può mancare l'item cercato.

**Card di Ascanio** (`qa_tasks.stage`, solo MaestroWeb): se la card esiste,
va in `lavorazione` appena si prende in carico la segnalazione.

---

## 3. Implementazione col loop

Workflow tool, tre fasi:

```
phase Piano            planner    (model: 'fable')
phase Implementazione   developer  (model: 'sonnet', isolation: 'worktree', base: origin/beta)
phase Verifica AC       verificatore (model: 'fable')
```

- Il **developer** crea il branch dalla base `origin/beta` aggiornata,
  commit convenzionali, apre la PR **verso `beta`** con `Closes #N` nel body.
- Il **verificatore** giudica sul `gh pr diff` reale — non si fida del
  developer — ed esegue lui stesso lint/test/build su un checkout del
  branch.
- Retry con feedback puntuale, **max 4 tentativi**. Se dopo 4 tentativi
  restano AC rossi, ferma e segnala a Davide: di solito è l'AC ad essere
  ambiguo, non il developer a sbagliare.
- Retry **3 volte** su errore API (529) per planner e verificatore — non
  abortire il loop per un errore transitorio.
- Gli AC `[Campo]`/`[Azione]` **non** entrano nel criterio di uscita del
  loop: restano aperti in attesa di Ascanio, la PR è comunque pronta se il
  resto è verde.

Per fix piccoli (poche righe, non serve il loop completo): Claudio lavora in
un worktree isolato, sempre con PR verso `beta`.

Dettaglio operativo (script Workflow completo, PLAN_SCHEMA/VERDICT_SCHEMA,
regole per scrivere AC verificabili): skill `dev-loop`.

---

## 4. Su beta

CI verde sulla PR → merge `--merge` in `beta`, label `deployed-test`, Kanban
GitHub → Test. **Poi**, non prima:

1. Prova dal vivo su `https://test-<repo>.8020solutions.org` (per MaestroWeb
   `test-maestro`) — login, dati veri, il flusso descritto dagli AC. Mai
   fidarsi del solo diff.
2. Solo dopo aver visto che funziona: card di Ascanio → `revisione`, con
   `review_notes` che dice cosa guardare e dove cliccare, in italiano
   comune — non un changelog.
3. `npm run deps:schede` — calcola gli avvisi di dipendenza tra schede non
   ancora in produzione. Va lanciato **in questo momento**, non prima: è un
   giro notturno più esecuzioni a mano, e dopo 72 ore l'avviso smette da sé
   di mostrarsi.

### 4b. Le migration vanno in prod PRIMA della prova (gap #1915)

La build di test-maestro fatta da `beta` punta al Supabase di **produzione**
(`deploy-test.yml`, blocco `NEXT_PUBLIC_SUPABASE_URL`), mentre le migration di
`beta` vanno solo sul DB di test del VPS. Una feature con migration, su
test-maestro, mostra codice nuovo con schema vecchio: badge assenti (#1956),
CHECK violati al salvataggio (#1958). Solo le anteprime di branch `/b/<branch>/`
usano il DB di test.

Quindi, se la PR mergiata in `beta` contiene migration **additive e
idempotenti** (ADD COLUMN IF NOT EXISTS, CHECK allargato, tabella nuova con
RLS, indice), Claudio le applica in prod subito dopo il merge, una per file:

```bash
gh workflow run run-migration.yml --repo ecologicaleaving/<repo> --ref beta \
  -f migration=<file.sql> -f conferma=PRODUZIONE
```

`--ref beta` perché su `main` il file non c'è ancora; `conferma` è il freno di
#1949. Poi verifica in prod con una query REST sulla colonna o tabella nuova
(200, non 42703). Solo dopo: prova dal vivo e card in Revisione. Il deploy di
`main` ritroverà la migration già applicata: per questo deve essere
idempotente.

**Mai con questo dispatch**: DROP, rinomina, cambio di semantica di dati
esistenti, migration che schedulano cron. Quelle aspettano la promozione; per i
cron vale la regola del punto 6.

**Mai in Revisione senza averla provata tu.** Il reject di Ascanio è un
commento sulla card + rientro in `lavorazione`.

Dettaglio: skill `beta-release`.

---

## 5. Ascanio approva dal pannello

«Approva» sposta la card da `revisione` a `backlog` (per lui vuol dire
«approvato e in produzione») e scrive «✅ Approvata da Revisione a BackLog»
nei commenti. Spesso aggiunge lì una richiesta di modifica — va letta e
trasformata in issue, non persa nel commento.

La label `qa-approved` **non** arriva dallo spostamento della card: la mette
Claudio dopo aver letto i commenti, risalendo dalla card alla issue (tabella
`qa_task_issues`, o dal titolo).

Dettaglio, sezioni del pannello, come si crea la issue dalla card: skill
`ascanio`.

---

## 6. `/approva` di Davide

1. Claudio mette la label `qa-approved` sulle issue approvate (e sui fix
   tecnici che Davide include esplicitamente).
2. `npx tsx scripts/approva-promote.ts --dry-run` — sempre prima del run
   reale. Se esclude gruppi «per conflitto»: quasi sempre è
   `package.json`/`PROJECT.md` (versione/changelog), non un conflitto reale.
3. Run reale → PR verso `main` con tutti i `Closes` → CI verde → merge
   `--merge` (**mai `--squash`**, romperebbe l'idempotenza patch-id dello
   script) → deploy → smoke test (`tests/curl-tests.sh`) → chiude le issue,
   label `deployed-prod`, Kanban → Done.

**Procedura manuale** (se lo script non c'è, o va rifatta a mano):
worktree da `origin/main`, cherry-pick in ordine cronologico di `beta`.
Conflitto solo su `PROJECT.md`/`package.json`/`package-lock.json` →
`checkout --theirs`. Conflitto su altri file → l'intera issue esce con tutti
i suoi commit e si riparte (esclusione a gruppi, iterare). Alla fine
`package.json` + lock presi interi da `beta`. PR verso `main` a mano con
tutti i `Closes`. I conflitti veri restanti sono filoni intrecciati: si
promuovono in blocco, non si spezzano.

Un cron nuovo si schedula con il JWT dal Vault, mai con chiavi in chiaro. Una
migration che ri-schedula un cron cambia l'header dello schedule, non decide
da sola cosa gira.

Dettaglio completo: skill `approva`.

---

## Le verifiche, in ordine

| # | Quando | Cosa | Chi | Comando / esito atteso |
|---|---|---|---|---|
| 1 | Prima del loop | Precheck della issue | Claudio | `npm run issue:precheck N` → exit 0 |
| 2 | Fase 1 (validazione) | Grep del meccanismo prima di scrivere gli AC | Claudio | vedi punto 1, "Come si scrive un AC" #5 |
| 3 | Dopo ogni tentativo del loop | Il verificatore Fable giudica OGNI AC sul `gh pr diff`, esegue lui stesso lint/test/build/audit su un checkout del branch — `[Campo]`/`[Azione]` restano `pending` | Verificatore (Fable) | pass/fail per AC |
| 4 | Sulla PR | CI verde: type check, test unitari, schema da zero, E2E dove gira | CI | verde. Un "fail" può essere un `cancelled` di concorrenza — controlla sempre `.conclusion` via API prima di trattarlo come rosso vero |
| 5 | Dopo il merge in `beta` | Deploy test verde, prova dal vivo su `test-<repo>` con dati veri, poi card in Revisione | Claudio | vedi punto 4 |
| 5b | Dopo il merge in `beta`, se la PR ha migration additive | Applicate in prod via `run-migration.yml` (ref beta, `conferma=PRODUZIONE`) e verificate con una query REST sulla colonna nuova; prima della prova dal vivo | Claudio | 200, non 42703 — vedi punto 4b |
| 6 | Dopo `/approva` | Dry-run pulito, CI della PR verso `main`, deploy prod verde, smoke `tests/curl-tests.sh`, sonde specifiche dell'issue in prod (es. 401 senza auth, CORS, query SQL) | Claudio | poi chiusura issue |
| 7 | — | Prova sul campo degli AC `[Campo]`/`[Azione]`, approvazione dal pannello | Ascanio | card `revisione` → `backlog` |

**Verde ≠ verificato: la CI dice che i test passano, non che la cosa
funziona; a dati fermi la verifica è cieca.**

---

## 7. Sezioni del pannello di Ascanio

Revisione · To Do ASCANIO · Fatte da Ascanio · Idee ASCANIO · In Lavorazione
· BackLog.

Le card si cercano **nei dati** (`qa_tasks` via REST con service key), non a
schermo — il DOM del pannello ne mostra solo alcune.

**Ogni sessione di Claudio inizia con:**

```bash
# 1. Controllo build sui repo attivi (segnala solo i failure)
for repo in maestroweb finn BeachRef-app StageConnect GridConnect AutoDrum smartscore; do
  gh run list --repo "ecologicaleaving/$repo" --branch "$(gh api repos/ecologicaleaving/$repo --jq '.default_branch')" \
    --limit 1 --json conclusion,displayTitle,url -q \
    '.[] | select(.conclusion=="failure") | "❌ '"$repo"' — \(.displayTitle)\n   🔗 \(.url)"'
done

# 2. Sync del workflow
cd C:\Users\KreshOS\Documents\00-Progetti\workflow
git pull origin master
powershell -ExecutionPolicy Bypass -File scripts\sync.ps1

# 3. Lettura di PROJECT.md del progetto attivo
```

Dettaglio: skill `claudio`.
