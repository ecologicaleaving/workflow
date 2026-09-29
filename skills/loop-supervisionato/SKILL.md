---
name: loop-supervisionato
description: >
  Ramo supervisionato del ciclo di sviluppo (MaestroWeb): lo avvia SOLO Davide
  quando è presente («/loop-supervisionato» o «/loop /loop-supervisionato») e
  lavora TUTTE le card in «Pronte», anche quelle che il ciclo autonomo scarta
  per perimetro (migration, Edge Function, cron, vendor). Porta ogni issue fino
  a `beta`, applica le migration additive con Davide davanti, e lo avvisa
  appena serve lui. Mai `main`. Trigger: «/loop-supervisionato», «loop
  supervisionato», «macina le pronte, ci sono io».
version: 1.0.0
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

1. Le card in **«Pronte»**, nell'ordine di `coda_pos` (`npm run -s card:stato
   -- --json`), poi per numero. Per ogni card, le sue issue aperte con `ready`
   (per un'epica: le sotto-issue `ready`, in ordine).
2. Poi le altre issue `ready` senza card.

Si **salta** (e si segnala a Davide al punto 6) una issue con:
- label `needs-decision`;
- dipendenza da un'altra issue non ancora in `beta` (la si riprende quando lo è);
- un AC che chiede una decisione di prodotto non scritta.

Il perimetro testuale (`ciclo-perimetro.ts`) **non** esclude qui: si legge
come informazione («tocca migration», «tocca Edge Function»), non come
cancello. Non si applica per questo la label `perimetro-verificato`: quella
serve al ciclo autonomo, non a questo ramo.

## Il giro (una issue)

1. **Card** → «In Lavorazione» (`npm run -s ciclo:card-presa -- --task <uuid>`
   se è in Pronte). `npm run issue:precheck N`: exit 1 → salta, segnala.
2. **Dev-loop** (skill `dev-loop`) col Workflow, con in più questo vincolo nei
   prompt di planner, developer e verificatore:
   > Modalità SUPERVISIONATA. Migration ed Edge Function si SCRIVONO nel
   > codice, ma: migration solo file NUOVI, additivi e idempotenti (IF NOT
   > EXISTS, mai modificare una migration esistente, mai DROP); niente si
   > applica né si deploya — nessun `gh workflow run`, nessun comando sul DB
   > di produzione, nessun deploy, nessuna scrittura verso inverter reali.
   > Se serve una decisione di prodotto, `blocked: true` col motivo.
   Max 2 dev-loop in parallelo, su issue che non toccano gli stessi file.
3. **PR verso `beta`** con `Closes #N`; allineamento a `origin/beta` PRIMA di
   aspettare la CI (`gh pr update-branch`); `gh pr checks --watch` tutto
   verde, E2E compresi. Rosso → non si mergia sopra: si guarda e si segnala.
4. **Migration nella PR** → PRIMA del merge (regola «E2E: migration prima del
   push»): avvisa Davide col nome del file e cosa fa, e **applicala solo dopo
   il suo ok esplicito in chat**, in modo supervisionato (memoria
   «migration idempotenti: le applico io, solo supervisionato»). Senza ok, la
   PR resta aperta e si passa alla issue successiva.
5. **Edge Function nella PR** → il merge in `beta` NON la mette in linea su
   beta se non è in `BETA_ALLOWED_FUNCTIONS` (#2462). Aggiungerla lì è una
   decisione di Davide dopo aver letto il codice: chiedila, non farlo da solo.
   Le funzioni che scrivono su hardware reale restano fuori.
6. **Merge** `gh pr merge --merge` (mai `--squash`, mai `--admin`, mai
   `main`). La card resta «In Lavorazione» col commento «in beta, pronta da
   provare: …». In «Revisione» la porta chi l'ha provata dal vivo (#1723).
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
issue in `beta` resta in «In Lavorazione» pronta da provare.
