---
name: loop-supervisionato
description: >
  Ramo supervisionato del ciclo di sviluppo (MaestroWeb): lo avvia SOLO Davide
  quando è presente («/loop-supervisionato» o «/loop /loop-supervisionato») e
  lavora le card in «Pronte supervisionate» (quelle che il ciclo autonomo non
  può prendere: migration, Edge Function, cron, vendor) e, dopo, anche quelle in
  «Pronte auto». Porta ogni issue fino a `beta`, applica le migration additive
  con Davide davanti, e lo avvisa appena serve lui. Mai `main`. Trigger:
  «/loop-supervisionato», «loop supervisionato», «macina le pronte, ci sono io».
version: 1.3.0
---

# Skill: loop-supervisionato

> Gemello di `ciclo-sviluppo` (#2281/#2304). Stesso giro, stesse regole di
> CI/merge/card; cambia **il perimetro**, perché c'è una persona presente.
> Nato il 29/09/2026: «Pronte» aveva 10 card e il ciclo autonomo ne poteva
> prendere una sola, le altre toccavano migration o Edge Function.

## Chi lo avvia

**Solo Davide, in una sessione in cui è presente.** Il fatto che l'abbia
lanciato lui è l'autorizzazione: vale per la sessione, non si eredita. Il
ciclo autonomo (`ciclo-sviluppo`) non entra mai in questo ramo, e questa
skill non si attiva da sola.

## La coda

Dal 10/10/2026 (#2754, decisione di Davide) «Pronte» è divisa in due sezioni,
e la sceglie il triage: **«Pronte supervisionate»** (`pronte_sup`) è la coda
di QUESTO loop; **«Pronte auto»** (`pronte_auto`) è quella del ciclo autonomo,
che questo loop può riprendere quando Davide è presente. Ognuna ha la sua
coda ordinabile (`coda_pos`, due code distinte).

1. Le card in **«Pronte supervisionate»** (`pronte_sup`), nell'ordine di
   `coda_pos` (`npm run -s card:stato -- --json`), poi per numero.
2. Poi le card in **«Pronte auto»** (`pronte_auto`), nel loro ordine di
   `coda_pos`. Prima di prenderne una, controlla che il ciclo autonomo non
   l'abbia già presa (`npm run ciclo:log`, sezione «prese»): se è sua, saltala.
3. Durante la transizione, le card ancora nella vecchia **«Pronte»**
   (`pronte`, nel pannello «Pronte (da riclassificare)»), nel loro ordine di
   `coda_pos`. Il ciclo autonomo non le prende: se non le prendi tu, restano
   ferme finché una persona non le riclassifica.
4. Per ogni card, le sue issue aperte con `ready` (per un'epica: le
   sotto-issue `ready`, in ordine). Poi le altre issue `ready` senza card.

Con un checkout **precedente** a #2754 esiste solo `pronte`: la coda è il
punto 3 da solo.

**Card a binari (#2860, #2863).** Per le card in `pronte_sup` divise in parti
(label `ciclo:auto` / `ciclo:super` sulle sotto-issue) la coda non si legge più
da `card:stato`: si chiede allo strumento, in sola lettura (nessun lock, nessuna
presa, vale anche a interruttore `sviluppo` spento):

```bash
npm run -s ciclo:sviluppo -- --binario super --json
```

L'uscita è `{prossima, scartate, senzaBinari}`. `prossima` è la prima parte
`ciclo:super` libera (o `ciclo:auto` fuori perimetro, che vale super) di una card
aperta in `pronte_sup`, con `prossima.card.taskId`; le parti `ciclo:auto` libere
sono scartate (la card andrebbe in Pronte auto: `ciclo:card-prossima-sezione`).
Le card in `senzaBinari` non hanno label `ciclo:*`: seguono la procedura di
sempre qui sotto (coda dei punti 1-4, una card = un binario).

Si **salta** (e si segnala a Davide al punto 6) una issue con:
- label `needs-decision`;
- dipendenza da un'altra issue non ancora in `beta` (la si riprende quando lo è);
- un AC che chiede una decisione di prodotto non scritta.

Il perimetro testuale (`ciclo-perimetro.ts`) **non** esclude qui: si legge
come informazione («tocca migration», «tocca Edge Function»), non come
cancello. Non si applica per questo la label `perimetro-verificato`: quella
serve al ciclo autonomo, non a questo ramo.

## Il giro (una issue)

1. **Card** → «In Lavorazione» con
   `npm run -s card:in-lavorazione -- --card S<n> --issue N` (o `--task <uuid>`,
   #2752): parte da `pronte_sup`, `pronte_auto`, dalla `pronte` provvisoria, dai
   To Do e da Revisione, e lascia il commento firmato «Claudio». **Mai**
   `ciclo:card-presa`: è del ciclo autonomo, filtra `stage=eq.pronte_auto` e
   su una card in `pronte_sup` non sposta niente (#2754). `card:in-lavorazione`
   è in `beta` (non ancora in `main`): lancialo da un checkout allineato a
   `origin/beta`. Per una parte a binari: `--task <prossima.card.taskId> --issue N`.
   `npm run issue:precheck N`: exit 1 → salta, segnala.
2. **Dev-loop** (skill `dev-loop`) col Workflow, con in più questo vincolo nei
   prompt di planner, developer e verificatore:
   > Modalità SUPERVISIONATA. Migration ed Edge Function si SCRIVONO nel
   > codice, ma: migration solo file NUOVI, additivi e idempotenti (IF NOT
   > EXISTS, mai modificare una migration esistente, mai DROP); niente si
   > applica né si deploya — nessun `gh workflow run`, nessun comando sul DB
   > di produzione, nessun deploy, nessuna scrittura verso inverter reali.
   > Se serve una decisione di prodotto, `blocked: true` col motivo.
   Max 2 dev-loop in parallelo, su issue che non toccano gli stessi file.
   Lo script è fisso: `Workflow({ scriptPath: "<USERPROFILE>\.claude\workflows\maestro\loop-supervisionato.js", args: { repo, issueNumber, branch } })`
   (allineato fra i PC dal repo `claude-config-maestro`, dal 06/10/2026). Il
   ciclo autonomo usa `ciclo-autonomo.js` nella stessa cartella.
3. **PR verso `beta`** con `Closes #N`; allineamento a `origin/beta` PRIMA di
   aspettare la CI (`gh pr update-branch`); `gh pr checks --watch` tutto
   verde, E2E compresi. Rosso → non si mergia sopra: si guarda e si segnala.
4. **Migration nella PR** → PRIMA del merge (regola «E2E: migration prima del
   push»): chiedi l'ok a Davide e **applicala solo dopo il suo ok esplicito
   in chat**, in modo supervisionato (memoria «migration idempotenti: le
   applico io, solo supervisionato»). Senza ok, la PR resta aperta e si passa
   alla issue successiva.

   **Come si chiede l'ok (Davide, 04/10/2026): UNA migration alla volta,
   spiegata, con le opzioni da scegliere** — mai un elenco di migration
   da approvare in blocco, mai solo il nome del file. Per ciascuna:
   - **A cosa serve**, in italiano semplice: quale card/issue, cosa vedrà
     l'utente dopo.
   - **Cosa fa sul database**, in parole: tabelle/colonne/funzioni/policy
     create o cambiate, se tocca dati esistenti, se tocca un cron, chi potrà
     leggere e scrivere. Fatti letti dal file, non dalla descrizione della PR.
   - **Rischio e reversibilità**: additiva o no, cosa succede se va male,
     se il deploy di `main` la rieseguirà (memoria «migration manuale non
     registrata»).
   - **Le opzioni** con `AskUserQuestion`, la consigliata per prima con
     «(Consigliata)»: di norma «Applicala ora», «Prima cambia X» (una
     variante concreta, se ce n'è una sensata), «Aspetta / non ora».
   Dopo la risposta: applicala (o no), verifica in sola lettura che gli
   oggetti esistano, una riga di esito, e solo allora la migration successiva.
5. **Edge Function nella PR** → il merge in `beta` NON la mette in linea su
   beta se non è in `BETA_ALLOWED_FUNCTIONS` (#2462). Aggiungerla lì è una
   decisione di Davide dopo aver letto il codice: chiedila, non farlo da solo.
   Le funzioni che scrivono su hardware reale restano fuori.
6. **Merge** `gh pr merge --merge` (mai `--squash`, mai `--admin`, mai
   `main`). Poi `npm run -s card:in-test -- --pr <PR>` (prima con `--dry-run`): la card passa
   da «In Lavorazione» a «In Test» solo con PR mergiata in `beta` e CI del merge verde
   (#2772). In «Revisione» la porta chi l'ha provata dal vivo (#1723).

   **Parte di una card a binari (#2863):** invece di `card:in-test`, a merge fatto
   e CI del push su `beta` verde (`gh run watch`), lancia lo stesso scrittore del
   ciclo autonomo: `npm run -s ciclo:card-prossima-sezione -- --task <uuid> --dry-run`,
   poi senza `--dry-run`. Decide lui dove va la card (anche In Test, o la coda
   dell'altro binario). Un rifiuto non si forza: la card resta dov'è e il motivo
   va nel resoconto a Davide. Le card senza binari continuano con `card:in-test`.
7. Log: `npm run -s ciclo:sviluppo -- --registra '{"issue":N,"esito":"...","pr":P,"motivo":"supervisionato"}'`.
   Poi subito la issue successiva.

## Avvisare Davide («avvisami quando servo»)

Con `PushNotification` (una riga) **e** in chat, appena succede, senza
aspettare la fine della coda:
- migration da approvare (file + effetto in una frase);
- Edge Function da ammettere in `BETA_ALLOWED_FUNCTIONS`;
- planner `blocked`, 4 tentativi senza verde, CI rossa non flaky;
- issue saltate per `needs-decision` o decisione di prodotto;
- coda finita: elenco di cosa è in `beta` da provare.

Mentre aspetta la sua risposta, il loop **non si ferma**: passa alla issue
successiva che non dipende da quella risposta.

## Divieti (non derogabili, anche con Davide presente)

- Mai `main`, mai `/promuovi`, mai `qa-approved`, mai card in Revisione o BackLog.
- Mai migration non additive, mai modificare una migration già registrata.
- Mai deploy di Edge Function in produzione, mai secret, mai VPS.
- Mai comandi verso inverter reali (gli AC `[Campo]` restano ad Ascanio).
- Mai `npm ci` nella radice: worktree con `npm run worktree:link`, rimossi
  con `npm run worktree:remove`.

## Fine

Quando la coda è vuota, o Davide dice basta: `ScheduleWakeup stop`, riepilogo
(mergiate, PR aperte in attesa di lui, saltate col motivo), e la card di ogni
issue in `beta` va in «In Test», in attesa della prova dal vivo.
