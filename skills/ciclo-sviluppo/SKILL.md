---
name: ciclo-sviluppo
description: >
  Ciclo autonomo, pezzo 2 (MaestroWeb #2281/#2304): a ogni giro prende LA PRIMA
  issue `ready` della coda e la porta fino a `beta` col flusso normale —
  precheck, dev-loop (Opus pianifica e verifica, Sonnet scrive), PR verso beta,
  CI verde con E2E, merge. Una issue alla volta, mai `main`, mai migration, mai
  Revisione. Si usa in una sessione Claude Code dedicata con `/loop`, distinta
  da quella del triage. Trigger: «/loop ciclo-sviluppo», «giro di sviluppo».
version: 1.3.0
---

# Skill: ciclo-sviluppo

> Riferimenti: `FLUSSO.md` punti 2-4, skill `dev-loop` (il *come* della singola
> issue), skill `commit`, MaestroWeb #2281 (disegno e decisioni di Davide del
> 21/09/2026), #2304 (lo strumento `ciclo:sviluppo`), skill `ciclo-triage`
> (pezzo 1, la sessione gemella).

## Perché esiste

Il triage (pezzo 1) trasforma le idee in issue `ready`. Senza questo pezzo le
issue restano in coda finché una sessione con Davide presente non le prende una
per una. Qui la coda si svuota da sola **fino a `beta`**, e si ferma lì: la
prova dal vivo, la Revisione di Ascanio e la produzione restano umane.

**Davide ha deciso (21-22/09/2026):** a step; solo su questa macchina; una
sessione per il triage e una per lo sviluppo; la coda sono **tutte** le issue
`ready` aperte, con o senza scheda; si accende **dopo** una settimana di solo
triage (AC9 di #2281).

## Il giro

Un giro = **una** issue. In `/loop` il ritmo è **ogni 60 minuti**; un giro che
dura di più tiene il lock, e il giro successivo esce `noop`.

### 0. Può partire?

```bash
cd C:\Users\KreshOS\Documents\00-Progetti\MaestroWeb
git fetch -q origin beta
npm run -s ciclo:sviluppo -- --json --lock
```

| esito | cosa fai |
|---|---|
| lo script non esiste (`Missing script`) | #2304 non è ancora in `beta`: fine, `noop`. Non improvvisare la selezione a mano |
| `{"ciclo":"spento"}` | fine, `noop`. Interruttore: `~/.claude/ciclo-autonomo.json` → `"sviluppo": true` |
| exit 2 «giro già in corso» | fine, `noop`. Il lock è di un altro giro: non toccarlo |
| `"prossima": null` | `--unlock`, fine, `noop` |
| `"prossima": {numero, ...}` | vai al punto 1 con quella, **solo quella** |

Non c'è più un tetto giornaliero (decisione di Davide del 23/09/2026, #2325): il
ciclo non esce mai con `{"ciclo":"tetto"}`. `npm run -s ciclo:log` mostra
quanti giri di sviluppo sono partiti oggi e con quale esito — è il modo per
accorgersi di un ciclo che gira a vuoto, non più un freno automatico.

Da qui in poi, **qualunque uscita** passa dal punto 5 (lock rilasciato, riga
nel log).

### 1. Precheck e perimetro

```bash
npm run -s ciclo:sviluppo -- --registra '{"issue":N,"esito":"avviata"}'
npm run issue:precheck N
```

- precheck con exit 1 → non lanciare il loop. Commento sulla issue con il
  segnale del precheck, label `ready` **tolta**, esito `ferma`.
- La issue è già stata filtrata dal perimetro (#2304 AC4), ma se leggendola
  ti accorgi che tocca migration, Edge Function, secret, cron, automation
  engine, vendor, deploy o VPS: **ferma**, label `needs-decision`, `ready`
  tolta, esito `fuori-perimetro`. La lista è uno sbarramento minimo, non ti
  esonera dal leggere.

### 2. Il dev-loop

Segui la skill `dev-loop` **così com'è**: Workflow con planner Opus,
developer Sonnet in worktree isolato allineato a `origin/beta`, verificatore
Opus, al massimo 4 tentativi.

- **Il Workflow si lancia solo in un turno aperto dal prompt del loop**
  («esegui la skill ciclo-sviluppo»), mai in risposta a un altro messaggio.
  Il Workflow inoltra a ogni subagente il messaggio utente che l'ha fatto
  partire, con la regola «in conflitto vince la richiesta»: il 22/09/2026
  (#2277) il messaggio era una domanda di Davide sul triage, e i quattro
  developer Sonnet hanno **risposto alla domanda invece di implementare** —
  nessun branch, giro perso. Planner e verificatore Opus l'avevano ignorata.
  Se il giro nasce da una conversazione, fermati e chiedi a Davide di
  lanciarlo col prompt del loop.
- Planner `blocked: true` (root cause diversa da quella degli AC) → esito
  `ferma`, commento sulla issue col motivo, `ready` tolta. Non si riscrivono
  gli AC da soli: tornano al triage o a Davide.
- Se il **piano** prevede file nel perimetro escluso → ferma prima del
  developer, come al punto 1.
- 4 tentativi senza verde → PR lasciata **aperta** in draft, commento con gli
  AC rossi, esito `ferma`.

### 3. Il merge in `beta` — solo se tutto questo è vero

1. tutti gli AC `[Codice]`/`[UI]` **pass** dal verificatore (i `[Campo]` e
   `[Azione]` restano aperti, non bloccano);
2. `npm run -s ciclo:sviluppo -- --verifica-pr <PR> --json` → exit 0 (il diff
   vero non tocca il perimetro);
3. la PR punta a `beta` e il body ha `Closes #N` (skill `commit`);
4. **l'allineamento si verifica PRIMA di aspettare la CI, non dopo.** Un
   dev-loop dura decine di minuti e `beta` intanto si muove: se aspetti la CI
   e solo alla fine scopri che il branch è indietro, quella CI è da buttare —
   sedici minuti di E2E per niente (successo tre volte il 23/09/2026).
   Quindi, appena la PR è aperta:

   ```bash
   git fetch -q origin
   git rev-list --count $(git merge-base origin/beta origin/<branch>)..origin/beta   # 0 = allineato
   gh pr update-branch <PR>    # solo se il numero sopra non è 0
   ```

   Riallineare **fa ripartire la CI**: è il motivo per cui si fa prima. Non
   costa nulla in più — quel commit di allineamento servirebbe comunque;
5. `gh pr checks <PR> --watch` **tutto verde, E2E compresi**. Un rosso che
   sembra flaky **non** si ritenta a mano e non si mergia sopra: esito
   `ferma` col nome del job.
6. **Prima del merge, l'allineamento si ricontrolla**: fra la CI verde e il
   merge può essere entrato altro. Se è indietro, si torna al punto 4 — è il
   prezzo di lavorare in parallelo, e la catena del punto 5b lo rende raro
   perché i giri del ciclo sono in fila, non simultanei.

Allora: `gh pr merge <PR> --merge` (mai `--squash`, mai `--admin`), esito
`mergiata`.

Se la PR contiene una **migration additiva** passata dal piano con la riga
`RISCHIO:` della issue, **non** la applichi: il merge avviene, e il resoconto
dice a Davide che c'è una migration che aspetta lui.

### 4. Dopo il merge

- Card collegata (`qa_task_issues`): resta **In Lavorazione**, con un commento
  «In beta dalla PR #…, pronta da provare: <cosa guardare>». **Mai** in
  Revisione: la prova dal vivo è del pezzo 3, che è umano.
- Nessuna card: niente da spostare.
- `npm run -s deps:schede` se hai commentato una card.

### 5. Fine del giro (sempre, anche dopo uno stop)

```bash
npm run -s ciclo:sviluppo -- --registra '{"issue":N,"esito":"...","pr":P,"motivo":"..."}'
npm run -s ciclo:sviluppo -- --unlock
```

In chat, **solo se è successo qualcosa**: la issue, l'esito, la PR, e le cose
che aspettano Davide (migration, `needs-decision`, rossi). `noop: false` in
quel caso.

### 5b. Il giro dopo parte al merge, non al minuto tondo

**Dopo un merge riuscito**, rilasciato il lock si ricomincia **subito** dal
punto 0 con la issue successiva, finché la coda non è vuota. Il `/loop` a ora
fissa resta come rete di sicurezza — serve a far ripartire il ciclo quando la
catena si è interrotta, non è il ritmo normale (decisione di Davide,
23/09/2026).

**Si incatena SOLO dopo `mergiata`.** Un giro che esce `ferma` o
`fuori-perimetro`, o una coda che risponde `null`, **chiude la catena** e
aspetta il giro a ora fissa. Se qualcosa non va — un rosso che torna, un
planner che si blocca, una issue scritta male — ripartire subito vuol dire
ripetere lo stesso errore più in fretta, e senza che nessuno lo guardi.

## Divieti (non derogabili)

- **Mai** `main`: né merge, né push, né PR con `--base main`. La produzione
  passa da `/promuovi` di Davide e da nessun'altra strada.
- **Mai** lanciare workflow GitHub (`run-migration.yml`, `deploy*.yml`, `gh
  workflow run`), applicare migration, toccare secret, VPS, Edge Function in
  produzione.
- **Mai** più di una issue per giro, mai due giri insieme (il lock).
- **Mai** spostare una card in Revisione né in BackLog; mai mettere
  `qa-approved`.
- **Mai** installare dipendenze nella radice del repo: i worktree si collegano
  allo store con `npm run worktree:link` e si rimuovono con `npm run
  worktree:remove` (CLAUDE.md di MaestroWeb).
- Se qualcosa non torna (`gh` non autenticato, DB irraggiungibile, worktree
  rotto, CI che non parte): **fermati**, rilascia il lock, scrivi il motivo nel
  log e in chat. Non riprovare in loop.
