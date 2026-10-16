---
name: ciclo-prova
description: >
  Ciclo autonomo, pezzo 3 (MaestroWeb #2791): a ogni giro prende LA PRIMA card
  in «In Test» (mergiata in beta, CI verde, manca la prova dal vivo), scrive ed
  esegue su beta uno spec Playwright per ogni punto di «Cosa provare» che può
  provare, e poi la porta in Revisione (nessun difetto: i punti che non può
  provare restano per la persona che rivede), la fa rientrare nella coda da cui
  era partita (almeno un difetto) o la lascia in In Test con un commento (esito
  malformato o punti non coperti). Dal 16/10/2026 (MaestroWeb #2885) verifica
  anche i punti `[Codice]` sul codice, con un verificatore Opus distinto e i
  controlli sul commit di merge. Una card alla volta, mai `main`, mai scritture
  su Supabase. Si usa in una sessione Claude Code dedicata con `/loop`, distinta
  da triage e sviluppo. Trigger: «/loop ciclo-prova», «giro di prova».
version: 1.3.0
---

# Skill: ciclo-prova

> Riferimenti: MaestroWeb #2791 (disegno e decisioni di Davide del 12/10/2026),
> #2772 («In Test»), #1723 (la card si sposta a mano), skill `ciclo-sviluppo`
> (pezzo 2, la sessione gemella), CLAUDE.md di MaestroWeb → «Ciclo di prova
> (#2791)».

## Perché esiste

Il ciclo di sviluppo si ferma alla card in **In Test**. Fino al 12/10/2026 la
prova dal vivo la faceva Davide a mano, una card alla volta. Qui la fa una
sessione dedicata, **ma le regole non stanno in questa skill: stanno nel
codice**. Tu scrivi gli spec e racconti cosa hai visto; chi decide se una card
può andare in Revisione sono tre script che ricalcolano il verdetto da zero e
rifiutano ciò che non torna. Se la skill e il codice non sono d'accordo,
vince il codice.

**Davide ha deciso (12/10/2026):**

- strumento: **Playwright** con i conti di prova dall'ambiente, contro **beta**;
- esito KO: la card torna nella coda **da cui era partita** (`pronte_auto` se
  partiva da lì, `pronte_sup` se partiva dal loop supervisionato);
- esito OK (cambiato il 13/10/2026, MaestroWeb #2830): il ciclo **esaurisce le
  prove che può fare** e, **se nessun punto è KO**, la card va in **Revisione**.
  I punti che non può provare (`[Azione]`, `[Campo]`, dati assenti nel sito di
  prova, ruolo senza conto) restano nel commento come «da provare a mano»: li
  prova la persona che rivede. Prima era «solo se OGNI punto è osservato»: una
  card con un `[Azione]` non arrivava mai in Revisione;
- i punti **`[Codice]`** (cambiato il 15/10/2026, MaestroWeb #2885): il ciclo
  **ripete le verifiche che faceva Claudio dopo l'implementazione**. La card che
  esce da In Test o va in Revisione, o torna nel ciclo di lavorazione. Un
  `[Codice]` non si prova nel browser: si verifica sul codice (punto 3b).

⚠️ Questo **supera**, per questo ciclo soltanto, la regola «in Revisione la
porta una persona che ha provato» (#1723). Ogni altro comando automatico
resta escluso.

⚠️ **Beta legge il DB di produzione** e parla con inverter veri. La prova è
carico reale: una card alla volta, sessioni brevi, mai un'azione che scriva.

## Il giro

Un giro = **una** card. In `/loop` il ritmo è **ogni 60 minuti**; un giro che
dura di più tiene il lock e il successivo esce `noop`.

### 0. Può partire?

```bash
cd ~/Documents/00-Progetti/MaestroWeb
git fetch -q origin beta
npm run -s ciclo:prova -- --json --lock
```

| esito | cosa fai |
|---|---|
| `Missing script` | #2791 non è nel checkout: `git pull` su `beta`; se manca ancora, fine, `noop`. Non improvvisare la selezione a mano |
| `{"ciclo":"spento"}` | fine, `noop`. Interruttore: `~/.claude/ciclo-autonomo.json` → `"prova": true`. **Lo accende solo Davide** |
| exit 2 «giro già in corso» | fine, `noop`. Il lock è di un altro giro: non toccarlo |
| `"prossima": null` | `--unlock`, fine, `noop`. Il JSON elenca le `scartate` col motivo: se ce ne sono, dillo in una riga |
| `"prossima": {...}` | vai al punto 1 con quella, **solo quella** |

Lo script è di **sola lettura**. `--lock` annota nel lock quale card stai
provando, così un secondo giro la riconosce (`giro-in-corso`).

La `prossima` porta: `cardNo`, `titolo`, `pr`, `issue`, `partenza` (la sezione
da cui la card è arrivata e da dove l'ha letta), `cosaProvare` e **`punti`**
(`n`, `testo`, `tag`, `automatizzabile`, e per i `[Codice]` `fonte: "codice"` con
`codice: {issue, ac, testoHash}`) più **`codice`**: l'elenco delle PR da verificare
sul codice (`[{pr, issue}]`). **I punti sono quelli, non li riscrivi e non ne
aggiungi**: un punto in più nell'esito rende l'esito `incompleto`. I punti
`fonte: "codice"` **non hanno uno spec**: non scrivere test per loro.

Da qui in poi, **qualunque uscita** passa dal punto 6 (lock rilasciato, riga
nel log).

```bash
npm run -s ciclo:prova -- --registra '{"card":N,"esito":"avviata"}'
```

### 1. Leggi la card prima di scrivere uno spec

Leggi la PR (`gh pr view <pr>`), la issue e il diff: capisci **dove** sta la
cosa da provare (route, schermata, ruolo che la vede). Se un punto richiede un
ruolo senza conto sul PC (`contoDisponibile: false` nel JSON della coda) **non
lo provi**: sarà `non-verificabile`. I ruoli (#2850, tabella `RUOLI_PROVA` in
`src/lib/ciclo-prova-ruoli.ts`): `azienda` (`E2E_SUPABASE_EMAIL`/`_PASSWORD`),
`superadmin` (`E2E_SUPABASE_ADMIN_*`), `proprietario` (`E2E_SUPABASE_PROP_*`);
`installatore`, `tecnico`, `azienda-base` non hanno conto (sempre non
verificabili). Per un ruolo diverso da `azienda` lo spec usa
`test.use({ ruolo: '<nome>' })` **solo a livello di file** (Playwright lo
rifiuta in un describe), mai `process.env` né `storageState`. Il punto porta
`ruolo`/`ruoloFonte` nel JSON (marcatura `[ruolo: <nome>]` oppure inferenza).
Limite: la guardia di rete lascia passare solo le **letture**: le pagine che
leggono via RPC (POST `/rest/v1/rpc/*`) restano non verificabili anche col
superadmin, e per il superadmin non c'è screenshot, solo l'esito testuale. Non cercare credenziali, non leggere `.env.local`, non
copiare un valore.

### 2. Scrivi gli spec — fuori dal repo

La cartella degli spec e degli artefatti sta **fuori dal repo** (il codice la
rifiuta se è dentro): usa lo scratchpad della sessione o `os.tmpdir()`, es.
`<tmp>/ciclo-prova/S<n>/`. Un file `.spec.ts` (o più) con **un test per punto**,
e il **titolo del test inizia con `P<n>`** (`test('P1 — il bottone X è visibile', …)`)
così il punto si ricava dal report.

Regole degli spec, tutte verificate dal codice:

- `test` e `expect` si importano **dalla fixture della prova**
  (`e2e/prova-dal-vivo/fixture`, percorso assoluto del checkout), **mai** da
  `@playwright/test`: la fixture interrompe ogni richiesta di scrittura verso
  Supabase;
- niente `unroute`, `newContext`, `APIRequest`, `request.post|put|patch|delete`:
  aggirano la guardia e lo spec viene rifiutato;
- **nessuna credenziale nello spec, nel nome di un file, in un commento**: il
  login è già fatto via API dal global-setup (`E2E_SUPABASE_EMAIL`/`PASSWORD`
  dall'ambiente). Non digiti mai una password;
- niente trace, niente video (spenti dalla config); screenshot solo sui
  fallimenti, e restano fuori dal repo;
- un punto **osservabile** si prova asserendo ciò che l'utente vede
  (`expect(locator).toBeVisible()`, testo, stato), non l'implementazione;
- un punto che per essere provato **scriverebbe** (salvare, inviare un comando,
  cambiare una modalità) non si prova: la guardia blocca la richiesta e il
  punto diventa `non-verificabile` — **non** `ko`. Un difetto che non esiste
  non si «ripara».

### 3. Esegui

```bash
npm run -s ciclo:prova -- --esegui <cartella> --card S<n>
```

Lo script rilegge la guardia sugli spec, lancia Playwright (un worker, nessun
retry) contro beta, oscura ogni valore segreto nell'output e scrive
**`<cartella>/esito-bozza.json`**: una bozza ricavata dal report con il formato

```json
{ "card": 123, "base": "https://…", "punti": [
  { "n": 1, "stato": "ok|ko|non-verificabile", "osservato": "testo", "test": "titolo del test" }
] }
```

**La bozza la puoi solo declassare** (un `ok` → `non-verificabile`/`ko`,
con la ragione in `osservato`), mai promuovere: i tre scrittori ricalcolano il
verdetto e un `ok` senza `test` o su un punto `[Campo]`/`[Azione]` viene
respinto o declassato dal codice.

Prima di classificare un `ko`, **distingui un difetto da una prova malfatta**:
selettore sbagliato, pagina non caricata, utente rimbalzato (`redirect`),
dati assenti nel sito di prova. Una prova che non dà risultato **non è** un
difetto dell'app: se il fallimento viene da te, correggi lo spec e riesegui
(al massimo **2 riesecuzioni**); se non riesci a osservare il punto, resta
`non-verificabile`.

Se un riesame manuale ti convince che un `ko` è un falso positivo, **non** lo
trasformi in `ok` a mano: correggi lo spec e riesegui.

### 3b. Verifica i punti `[Codice]` (MaestroWeb #2885)

Per **ogni PR** nell'elenco `codice` della coda (se è vuoto, salta il passo).
Le regole stanno nel codice (`docs/ciclo-prova-codice.md` di MaestroWeb): tu
orchestri.

```bash
npm run -s prova:codice -- --prompt --pr <n> --cartella <cartella>
# → <cartella>/prompt-verificatore-<n>.md
```

1. **Un agente Opus distinto** da chi ha scritto il codice e da te esegue il
   prompt: giudica ogni AC `[Codice]` sul **diff reale** della PR mergiata
   (non sulla descrizione) e salva il suo JSON in `<cartella>/verdetto.json`.
   Non dargli la descrizione né i commit del developer. Il verificatore non
   scrive su GitHub, non fa commit né push, non installa dipendenze (solo
   `worktree:link`, e il worktree si toglie con `worktree:remove`).
2. I **controlli li esegue il ciclo**, non l'agente, sul commit di merge in
   beta (tsc, lint, vitest sui file toccati, `deno test` se il diff tocca
   `supabase/functions/`):

```bash
npm run -s prova:codice -- --verifica --pr <n> --verdetto <cartella>/verdetto.json --cartella <cartella>
# → <cartella>/prova-codice-<n>.json
```

Dura **5-15 minuti** e tsc può superare i due minuti: lancialo **senza**
`timeout` davanti (un `timeout 115` lo uccide con uscita 143 e la prova non si
scrive) e, se la tua shell ha un limite, in background. Un solo lavoro pesante
alla volta oltre al browser.

Poi, **dopo** il passo 3 (e a prescindere da quanti punti ha il browser):

```bash
npm run -s ciclo:prova -- --componi <cartella> --card S<n>
# → <cartella>/esito.json (punti del browser + prove del codice)
```

Un `[Codice]` è `ok` solo con verdetto `pass` su QUELL'AC, CI di beta verde sul
commit di merge e controlli verdi; un `fail` o un controllo rosso lo rende `ko`
(la card rientra come per un ko del browser); tutto il resto è «da provare a
mano» o `incompleto`. Un `[Codice]` dichiarato `ok` con fonte `browser` il
codice lo declassa. **Se il verificatore non risponde o il verdetto è illeggibile
non inventare un `pass`**: la prova resta incompleta (punto 4).

### 4. Scegli lo scrittore (uno solo, sempre prima `--dry-run`)

Il verdetto lo calcola il codice; ti serve solo per sapere quale comando
lanciare. Sempre `--dry-run` per primo. Con la prova del codice incompleta il
verdetto è **incompleto** anche se il browser ha trovato un ko: la card non si
sposta (decisione di Davide del 16/10/2026).

| verdetto | comando | cosa fa |
|---|---|---|
| **ok** (nessun `ko`, ogni punto atteso ha la sua voce; i `non-verificabile` non bloccano) | `npm run -s card:in-revisione -- --card S<n> --esito <cartella>/esito.json [--dry-run]` | In Test → **Revisione**, commento «Claudio · ciclo» a tre gruppi: verificato dal browser, verificato sul codice (verdetto, commit di merge, controlli), da provare a mano (solo `[Campo]`, `[Azione]` e punti non verificabili, col motivo) |
| **ko** (almeno un punto `ko`) | vedi punto 5 | issue di fix + rientro |
| **incompleto** (punti senza voce nell'esito, o voci in più: esito da rifare) | `npm run -s card:prova-incompleta -- --card S<n> --esito <cartella>/esito.json [--dry-run]` | la card **resta in In Test**; un commento con il marcatore «Prova dal vivo del ciclo» elenca i punti non provati |

Se scegli il comando sbagliato il codice rifiuta (con `ok` rimanda a
`card:in-revisione`, con `ko` a `card:rientro-prova`): **non forzare**, non
esiste `--force`.

Dopo `card:in-revisione`: `npm run -s deps:schede` (CLAUDE.md di MaestroWeb:
fa comparire l'avviso «questa dipende da un'altra non ancora in produzione»).

### 5. Esito KO: issue di fix, poi rientro

La regola 3 vale anche qui: **nessun fix senza issue**. Per ogni difetto
trovato:

1. **Riproducilo davvero** (secondo giro dello stesso spec, o a mano) e scrivi
   cosa hai visto, con la route e il ruolo.
2. Crea la issue di fix su `ecologicaleaving/maestroweb` col template
   `create-issue`/`ascanio`: **prima riga `Scheda S<n>`**, titolo del
   difetto, **Acceptance Criteria verificabili** (input → comportamento
   atteso), il riferimento alla PR che l'ha introdotto, e lo spec che lo
   riproduce. Un difetto = una issue; se i difetti sono più d'uno sulla stessa
   card, una issue sola con un AC per difetto.
3. Se il difetto tocca migration, Edge Function, secret, cron, automation
   engine, vendor, deploy o VPS: **non** mettere `ready`, metti
   `needs-decision`. Il codice, comunque, fa il resto (vedi sotto).
4. Se invece passa il perimetro e gli AC sono chiari: label `ready`.

```bash
npm run -s card:rientro-prova -- --card S<n> --issue-fix <N> --esito <cartella>/esito.json --dry-run
npm run -s card:rientro-prova -- --card S<n> --issue-fix <N> --esito <cartella>/esito.json
```

Dove va la card lo decide il **codice** (`decidiRientro`), non tu:

- sezione di partenza letta dai commenti firmati Claudio; se non si legge →
  **Pronte supervisionate** (mai Pronte auto per ripiego);
- **Pronte auto** solo se la partenza era auto **e** la fix è nel perimetro del
  ciclo **e** ha `ready`;
- con `needs-decision` sulla fix o su una issue collegata: **I miei To Do**,
  assegnata a Davide (#2471). Davide va avvisato in chat (punto 7).

Il comando collega la fix alla card e scrive un commento firmato «Claudio ·
ciclo».

### 6. Fine del giro (sempre, anche dopo uno stop)

```bash
npm run -s ciclo:prova -- --registra '{"card":N,"esito":"revisione|rientro|incompleta|errore"}'
npm run -s ciclo:prova -- --unlock
```

`--registra` accetta **solo** `{card, esito}`: niente testo libero. Il
dettaglio sta nei commenti della card, non nel log.

### 7. Cosa dici in chat

Solo se è successo qualcosa: la card, l'esito, e le cose che aspettano
qualcuno (una card finita nei To Do di Davide, una issue `needs-decision`, un
punto che nessuno sa ancora come provare). `noop: false` in quel caso.

**Un giro che non produce un esito della card (`errore`) non si ritenta da
solo**: lascia il commento che spiega perché e passa al giro dopo. Il
ripetersi della stessa card in errore lo vede `npm run -s ciclo:log`.

## Perché non rifà la stessa card (AC7)

Una card già provata e rimasta in In Test **non rientra in coda** finché non
c'è una **novità**: un commento nuovo di una persona (o un nuovo `card:in-test`),
oppure una PR mergiata in beta che chiude una sua issue. I commenti di prova del
ciclo non contano. Se le PR di beta non si leggono (errore o 300 PR), la card
già provata resta fuori. Quindi non c'è modo che il ciclo ripeta all'infinito
una prova inconcludente: aspetta una persona o un nuovo commit.

## Divieti (non derogabili)

- **Mai** `main`: né merge, né push, né PR con `--base main`.
- **Mai** spostare una card in Approvate o BackLog; mai mettere `qa-approved`;
  mai scrivere «Revisione» con altro che `card:in-revisione`.
- **Mai** un punto `[Campo]` o `[Azione]` come `ok`: richiedono un impianto vero
  o una persona (e il codice lo declassa comunque).
- **Mai** un `[Codice]` come `ok` senza il verdetto di un verificatore distinto e la
  prova del codice completa: niente `pass` inventati, niente verdetti scritti a
  mano o dal developer.
- **Mai** impostare `CICLO_PROVA_MODO` (nemmeno `CICLO_PROVA_MODO=… npm run`, né in
  uno spec, né in `.env.local`): la modalità supervisionata della guardia di rete
  (MaestroWeb #2866) la accende solo una persona, nell'ambiente della sessione.
  Il ciclo gira sempre in modalità autonoma.
- **Mai** una scrittura verso Supabase dalla prova, né una richiesta diretta
  che aggiri la fixture. Beta è il DB di produzione.
- **Mai** una credenziale negli argomenti, negli spec, nei commenti, nei log o
  in uno screenshot dentro il repo. Non leggere `.env.local`, non stampare le
  variabili d'ambiente, non chiedere i valori.
- **Mai** modificare codice del repo, aprire PR, migration, workflow GitHub, VPS.
  Le uniche scritture consentite sono: gli spec nella cartella di prova (fuori
  dal repo), i tre script `card:*`, `ciclo:prova --registra|--lock|--unlock|--componi`,
  `prova:codice --prompt|--verifica` (scrivono solo nella cartella di prova), la
  issue di fix.
- **Mai** più di una card per giro, mai due giri insieme (il lock).
- Se qualcosa non torna (`gh` non autenticato, DB irraggiungibile, beta non
  risponde, la card cambia sezione mentre provi, un'asserzione che non sai
  spiegare): **fermati**, `--registra` con `errore`, rilascia il lock, scrivi il
  motivo nel commento della card e in chat. Non riprovare in loop.

## Limiti della v1 (dal disegno di #2791)

- Un solo PC con l'interruttore acceso: il lock è un file locale, non c'è una
  presa nel DB (come lo sviluppo prima di #2712).
- Installatore, tecnico e azienda base non hanno un conto di prova (#2850): i
  punti che li richiedono restano `non-verificabili`, da provare a mano in
  Revisione. Un conto proprietario che non ha accettato l'accordo utente resta
  fermo sull'`AgreementGate` (accettare è una scrittura bloccata):
  non-verificabile.
- L'accensione dell'interruttore è di **Davide**, dopo **almeno 3 giri**
  osservati con lui presente (AC11).
