---
name: ciclo-triage
description: >
  Ciclo autonomo, pezzo 1 (MaestroWeb #2281/#2293): a ogni giro prende le card
  nuove in «Idee» e ne fa il triage — domanda nei To Do, issue con AC, accorpamento,
  o parcheggio con motivo. Scrive SOLO card, commenti, collegamenti e issue: mai
  codice, mai merge, mai migration. Si usa in una sessione Claude Code dedicata con
  `/loop`. Trigger: «/loop ciclo-triage», «giro di triage», «triage delle idee».
version: 1.0.0
---

# Skill: ciclo-triage

> Riferimenti: `FLUSSO.md` punto 0 (triage), skill `ascanio` → «Triage della card»
> (il *come* per la singola card), MaestroWeb #2281 (disegno e decisioni di Davide
> del 21/09/2026), #2293 (lo strumento `idee:da-triagiare`).

## Perché esiste

Ascanio (e Davide) scrivono idee a qualunque ora; il triage fatto a mano arriva
quando c'è una sessione aperta, e intanto le card restano in «Idee» senza risposta.
Il 21/09/2026 una sessione ha dovuto rileggerne 23 per scoprire che 8 erano già
state smistate. Questo ciclo risponde entro un giro, e solo alle card nuove.

**Davide ha deciso (21/09/2026):** a step; solo su questa macchina; una sessione
dedicata al triage e una allo sviluppo; il browser è quello del profilo Chrome
dedicato, in cui il login lo fa lui.

## Il giro

Un giro = un'esecuzione di questa skill. In `/loop` dinamico il ritmo è **ogni
60 minuti** salvo diversa indicazione di Davide.

### 0. Può partire?

```bash
cd C:\Users\KreshOS\Documents\00-Progetti\MaestroWeb
git fetch -q origin beta   # il codice da leggere è quello di origin/beta
npm run -s idee:da-triagiare -- --json --lock
```

| esito | cosa fai |
|---|---|
| `{"ciclo":"spento"}` | fine del giro, `noop`. L'interruttore è `~/.claude/ciclo-autonomo.json` → `"triage": true` |
| exit 2 «giro già in corso» | fine del giro, `noop`. Non togliere il lock di un altro |
| elenco vuoto | `npm run -s idee:da-triagiare -- --unlock`, fine, `noop` |
| elenco con card | vai al punto 1 |

Al massimo 5 card per giro (il comando le limita da sé): le altre al giro dopo.

### 1. Per ogni card: segui la skill `ascanio`, «Triage della card», passi 1-5

Leggi card, commenti **e allegati** nei dati. Poi scegli **uno** degli esiti:

| la card… | esito | la card va in |
|---|---|---|
| è chiara e fattibile | issue con AC (punto 2) | **In Lavorazione**, issue `ready` solo se il precheck è verde |
| ha un dubbio che solo chi l'ha scritta può sciogliere | commento con le domande | **To Do dell'owner** (`assigned_to` resta chi l'ha proposta) |
| ripete una card già aperta | commento «Confluisce nella scheda S…» | resta in Idee (la capofila la segue) |
| è già fatta / già in beta | commento che dice dove | **BackLog** + `status: done` |
| è un progetto grande o una scelta di priorità | commento che lo dice | resta in **Idee**, segnalata a Davide nel resoconto |
| richiede una decisione di **Davide** (perimetro escluso, sotto) | issue con l'analisi, label `needs-decision` | resta in **Idee** con commento «aspetta Davide», segnalata nel resoconto |

**Domande:** in italiano comune, numerate, **con opzioni A/B/C e la tua
raccomandazione**, poche (le 5 che bloccano davvero; il resto come «proposte se
non mi dici altrimenti»). Una domanda che si può risolvere leggendo il codice o i
dati non si fa: la si risolve.

**Scrivere ad Ascanio in una card rimasta «In Lavorazione» è come non scrivergli:
non la legge.** Una domanda vuole la card nei suoi To Do.

### 2. La issue

- Gli AC si scrivono **dopo aver letto il codice** di `origin/beta` (file:riga reali),
  mai dedotti. Per più card nello stesso giro, un agente (Opus) per 2-3 card che
  scrive **solo bozze** in scratchpad; la issue la crei tu dopo averla riletta.
- Prima riga del body `Scheda S<n>`; titolo leggibile da Ascanio; label
  `origine:ascanio`/`origine:davide`, tipo, priorità.
- **Mai** copiare nella issue token, link d'invito, chiavi, e-mail di clienti.
- Collega in `qa_task_issues` (`task_id`, `issue_number` — nessuna colonna `repo`).
- Card = epica: se ne escono più issue, epica + sotto-issue con
  `(sub-issue di #N)` nel titolo e `npm run subissue:collega -- --apply`.
- `npm run issue:precheck N`: `ready` solo se verde **e** fuori dal perimetro escluso.

### 3. Perimetro escluso — qui il ciclo si ferma e lascia a Davide

Se la card (o l'analisi) tocca uno di questi, la issue nasce `needs-decision`,
**senza** `ready`, e il resoconto lo dice:

- `supabase/migrations/`, `supabase/functions/` (Edge Function), secret, cron;
- automation engine (`src/lib/automation-*`), dispatch ai vendor, quote (Sungrow,
  ZCS, Solarman, Huawei), comandi agli inverter;
- `deploy*.yml`, `run-migration.yml`, VPS, qualunque cosa di produzione.

Una **migration additiva** in una feature non è di per sé esclusa, ma la issue lo
dichiara in una riga `RISCHIO:` e la decisione di applicarla resta del ciclo di
sviluppo (pezzo 2), non di questo.

### 4. Fine del giro

```bash
npm run -s idee:da-triagiare -- --unlock
npm run -s deps:schede          # se hai spostato card
```

Appendi una riga a `~/.claude/ciclo-triage.log`:
`<ISO ora> · <n card> · S<n>→<esito>, … · issue #… · da Davide: …`

E in chat, **solo se è successo qualcosa**: cosa hai smistato, le domande fatte e a
chi, e le cose che aspettano Davide. `noop: false` in quel caso.

## Divieti (non derogabili)

- **Mai** scrivere codice, aprire PR, mergiare, lanciare workflow GitHub.
- **Mai** scrivere su tabelle diverse da `qa_tasks` (solo `stage`, `status`,
  `assigned_to`), `qa_task_comments`, `qa_task_issues`.
- **Mai** spostare una card che non è in «Idee».
- **Mai** chiamare API dei vendor né Edge Function.
- Se qualcosa non torna (errore del DB, `gh` non autenticato, dati strani):
  **fermati**, togli il lock, scrivi il motivo nel log e in chat. Non riprovare in
  loop.
