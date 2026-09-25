---
name: dev-loop
description: >
  Implementazione di una issue con pianificazione e verifica AC affidate a
  Opus 5, scrittura del codice affidata a un secondo agente Opus 5 in worktree isolato
  (decisione di Davide del 24/09/2026: Opus per tutti e tre i ruoli, sempre tre agenti distinti).
  Loop automatico: pianifica → implementa → verifica ogni Acceptance
  Criterion → se qualcuno fallisce, riprova con il feedback, finché non sono
  tutti verdi o si raggiunge il tetto di tentativi. Repo come parametro —
  vale per qualunque progetto 8020, non solo MaestroWeb.
  Trigger: "implementa issue #N", "risolvi issue #N".
version: 2.6.0
---

# Skill: dev-loop

> Riferimento flusso: `FLUSSO.md` — punto 3

## Perché

Separare chi pianifica/giudica da chi scrive il codice riduce il rischio che
un'implementazione si autocertifichi "fatta" senza aver davvero soddisfatto
ogni Acceptance Criterion. Opus 5 pianifica e verifica con un giudizio più
affidabile su corner case e AC ambigui; dal 24/09/2026 anche il developer è
Opus 5 (decisione di Davide, presa dopo #2334: la qualità del codice del loop
vale più del risparmio). La separazione resta: chi scrive non è chi giudica,
tre agenti distinti con tre prompt distinti.

## ⛔ Prima di lanciare il loop: `npm run issue:precheck <N>` — obbligatorio

```bash
npm run issue:precheck 1234       # exit 1 = non lanciare il loop
```

Se il repo non ha ancora questo script, verifica a mano prima di partire:
la issue è già in `main`? Ha AC verificabili? Il testo dice «verificare se
già presente»? Ha dipendenze ancora aperte?

Introdotto dopo che due loop nello stesso giorno hanno lavorato a vuoto: una
issue era già in produzione da settimane con la card rimasta aperta, un'altra
aveva gli AC scritti su un meccanismo già implementato altrove. Un controllo
sistematico successivo trovò 18 issue aperte su 21 verificate già
implementate.

Due trappole che il solo `git log` non risolve, e per cui serve **leggere il
codice attuale**:

- un **revert** nella storia non significa lavoro annullato: può essere
  stato reintrodotto dopo.
- codice presente e testato può essere **irraggiungibile** dal flusso reale
  — un helper può avere test verdi ma non essere mai chiamato dal percorso
  di produzione perché il chiamante non gli passa i parametri giusti e cade
  sempre nel fallback.

---

## Quando si attiva

Claudio lo invoca quando Davide chiede di implementare una issue GitHub
concreta (`implementa issue #N`, `risolvi issue #N`), **non** per task
piccoli o conversazionali dove il loop è overkill (fix di una riga,
domande, refactor banali — lì Claudio implementa direttamente in un
worktree, sempre con PR verso `beta`, senza loop).

## Agenti coinvolti

| Ruolo | Modello | Fa cosa |
|---|---|---|
| Claudio (sessione corrente) | Opus 5 | Orchestra il loop via `Workflow` tool, riporta a Davide |
| Planner | Opus 5 (`model: 'opus'`) | Legge la issue, scompone in piano concreto (file, approccio, edge case) — non scrive codice |
| Developer | Opus 5 (`model: 'opus'`, worktree isolato, base `origin/beta`) — agente **distinto** dal planner e dal verificatore | Implementa secondo il piano (+ feedback se è un retry), commit, push, apre/aggiorna la PR verso `beta` |
| Verificatore | Opus 5 (`model: 'opus'`) | Confronta il **diff reale della PR** con OGNI Acceptance Criterion della issue, pass/fail + motivazione puntuale — non si fida del messaggio di commit, esegue lui stesso lint/test/build su un checkout del branch |

## Meccanica del loop

Cap a **4 tentativi**. Se dopo 4 tentativi restano AC rossi, il workflow si
ferma e Claudio lo segnala a Davide invece di continuare a girare a vuoto —
di solito significa che l'AC stesso è ambiguo o mal scritto (vedi "Scrivere
AC verificabili" sotto), non che il developer sbaglia il codice.

**Retry su errore API (529):** planner e verificatore ritentano fino a 3
volte su un errore 529 (sovraccarico) prima di considerarlo un fallimento
reale — non è un fallimento del piano/verdetto, è l'infrastruttura del
modello temporaneamente satura.

Va lanciato con lo strumento `Workflow` (loop-until pattern), non con
`Agent` semplice — serve il ciclo deterministico plan→implement→verify→retry.
Template dello script (Claudio lo adatta con repo e numero issue reali
prima di lanciarlo):

```js
export const meta = {
  name: 'issue-dev-loop',
  description: 'Opus pianifica e verifica AC, un secondo agente Opus implementa — loop fino a verde',
  phases: [
    { title: 'Piano', model: 'opus' },
    { title: 'Implementazione', model: 'opus' },
    { title: 'Verifica AC', model: 'opus' },
  ],
}

const REPO = args.repo // es. 'ecologicaleaving/maestroweb'

// #2398 — il nome del branch lo fissa lo SCRIPT, una volta sola, e il developer
// non puo' cambiarlo. Prima era lasciato a lui («<branch>»), e al tentativo dopo
// un push fallito se ne inventava un altro: due PR per la stessa issue.
const BRANCH = args.branch ?? `feature/issue-${args.issueNumber}`

phase('Piano')
const PLANNER_PROMPT = `Leggi la issue #${args.issueNumber} del repo ${REPO}
(gh issue view ${args.issueNumber} --repo ${REPO}).

Se è una issue di tipo bug: PRIMA di pianificare, leggi il codice reale dei file
plausibilmente coinvolti e verifica che la root cause dichiarata negli AC/Note
tecniche regga davvero — non dare per buona la spiegazione scritta nella issue
solo perché è lì. Presta attenzione soprattutto ai dettagli temporali/di stato
del sintomo (transitorio? ricorrente? legato a un'azione specifica?) — sono
quelli che falsificano ipotesi plausibili ma sbagliate.
Se la tua lettura del codice CONTRADDICE la root cause su cui sono scritti gli
AC esistenti (non solo dettagli implementativi, ma il meccanismo del bug), NON
pianificare un'implementazione contro AC sbagliati: restituisci `blocked: true`
con la motivazione e la root cause corretta che hai trovato — il chiamante deve
tornare a issue-validate per riscrivere gli AC prima di procedere, non forzare
un fix che risolve un sintomo diverso da quello osservato.

Se la root cause regge (o la issue non è un bug): scomponi in un piano di
implementazione concreto — file da toccare, approccio, edge case, eventuali
migration. NON scrivere codice, solo piano.`

let plan = null
for (let i = 0; i < 3 && !plan; i++) {
  if (i) log(`Planner: nessuna risposta (probabile 529), tentativo ${i + 1}/3`)
  plan = await agent(PLANNER_PROMPT, { model: 'opus', schema: PLAN_SCHEMA, label: `planner-${i + 1}` })
}
if (!plan) {
  return { blocked: true, reason: 'planner non ha risposto dopo 3 tentativi (errore API)' }
}

if (plan.blocked) {
  log(`Piano bloccato: la root cause negli AC non regge — ${plan.reason}. Torna a issue-validate.`)
  return { blocked: true, reason: plan.reason, correctedRootCause: plan.correctedRootCause }
}

let attempt = 0
let verdict = { allPassed: false, results: [] }
let feedback = null
let prPrecedente = null   // #2398 — la PR del tentativo precedente, per accorgersi se il giro si sdoppia

while (!verdict.allPassed && attempt < 4) {
  attempt++
  phase('Implementazione')
  await agent(`Implementa la issue #${args.issueNumber} (repo ${REPO}) secondo questo piano:
${JSON.stringify(plan)}
${feedback ? `Il tentativo precedente non ha soddisfatto questi AC:\n${feedback}\nCorreggi.` : ''}
PRIMA DI TOCCARE QUALUNQUE FILE, allinea il worktree — non fidarti di com'e':
  git fetch origin && git checkout -B <branch> origin/beta
e verifica di essere davvero sulla punta di beta:
  git rev-list --count $(git merge-base HEAD origin/beta)..origin/beta   # deve dare 0
Se non da' 0, fermati e dillo invece di procedere.

UN SOLO BRANCH per tutto il giro: ${BRANCH}. Non cambiarlo, in nessun caso.
Se il push fallisce — conflitto, storia divergente, qualunque motivo — FERMATI e
dillo. NON aprire un branch nuovo (${BRANCH}-v2, -8, -bis) e NON aprire una
seconda PR: e' il difetto #2398, successo tre volte il 24/09/2026.
Prima di aprire una PR, guarda se ne esiste gia' una: gh pr list --head ${BRANCH}.
Se c'e', si AGGIORNA quella.

Segui CLAUDE.md del repo. Apri o aggiorna
la PR verso beta con "Closes #${args.issueNumber}" nel body, commit e push.`,
    { model: 'opus', label: `dev-attempt-${attempt}`, isolation: 'worktree' })

  phase('Verifica AC')
  const VERIFIER_PROMPT = `Verifica CIASCUN Acceptance Criterion della issue
#${args.issueNumber} (repo ${REPO}) — sia quelli taggati [UI] che quelli taggati
[Codice], TUTTI qui; salta SOLO i [Campo] e [Azione] (marcali "pending",
sono lavoro esclusivo di Ascanio, mai un agente) — contro il diff reale della
PR aperta (gh pr diff), non contro la descrizione del commit. Esegui tu
stesso lint/test/build su un checkout del branch, non fidarti del developer.
Per ogni AC: pass/fail/pending + motivazione puntuale e verificabile.

Riporta anche prNumber: il numero della PR che hai davvero giudicato. Se per
questa issue ne trovi PIU' DI UNA aperta, dillo esplicitamente col numero di
tutte — e' il difetto #2398, e chi mergia deve sapere quale hai guardato.`

  // Il verificatore puo cadere in DUE modi, e vanno gestiti entrambi (vedi sotto).
  const giudica = async (label) => {
    try {
      return await agent(VERIFIER_PROMPT, { model: 'opus', schema: VERDICT_SCHEMA, label })
    } catch (e) {
      log(`Verificatore caduto (${label}): ${e?.message?.slice(0, 160) ?? e}`)
      return null
    }
  }

  verdict = await giudica(`verify-${attempt}`)
  if (!verdict) verdict = await giudica(`verify-${attempt}-retry`)
  // Un verdetto può arrivare anche SENZA `results`: schema rispettato a metà,
  // cioè un oggetto che non porta l'elenco degli AC. Vale come «non giudicato»
  // esattamente come il null, e va normalizzato qui — altrimenti
  // `verdict.results.filter` più sotto esplode e porta giù l'INTERO workflow.
  // Successo il 15/09/2026 su #2132: tre giri di lavoro già fatti, PR aperta,
  // e il loop caduto sull'ultima riga invece di dire che gli AC erano 8 su 12.
  if (!verdict || !Array.isArray(verdict.results)) {
    log(`Verificatore: nessun verdetto utilizzabile dopo 2 tentativi — tentativo ${attempt} non giudicato, si ritenta l'intero giro`)
    verdict = { allPassed: false, results: [] }
    continue
  }

  feedback = verdict.results.filter(r => !r.pass && r.status !== 'pending-campo' && r.status !== 'pending-azione')
    .map(r => `AC "${r.ac}": ${r.reason}`).join('\n')
  log(`Tentativo ${attempt}: ${verdict.results.filter(r => r.pass).length}/${verdict.results.length} AC verdi`)

  // #2398 — una PR sola per giro. Il verificatore dichiara `prNumber`: se al
  // tentativo N e' diversa da quella del tentativo N-1, il giro si e' sdoppiato
  // e ci si ferma, invece di proseguire su due strade. Il 24/09/2026 e' successo
  // tre volte, e le due stesure NON erano equivalenti: quella scartata su #2389
  // aveva un test di isolamento che SOPRAVVIVEVA alla mutazione, cioe' non
  // provava niente. Sceglierla sarebbe stato peggio che perdere il lavoro.
  if (prPrecedente && verdict.prNumber && verdict.prNumber !== prPrecedente) {
    log(`Il giro si e' sdoppiato: PR #${prPrecedente} al tentativo precedente, #${verdict.prNumber} adesso. Mi fermo.`)
    return { blocked: true, reason: `due PR per la stessa issue (#${prPrecedente} e #${verdict.prNumber}) — difetto #2398`, verdict }
  }
  if (verdict.prNumber) prPrecedente = verdict.prNumber
}

if (!verdict.allPassed) {
  log(`Dopo ${attempt} tentativi restano AC non soddisfatti — serve intervento umano`)
}
return { attempt, verdict, planUsed: plan }
```

`PLAN_SCHEMA`/`VERDICT_SCHEMA` sono JSON Schema minimi:

```js
const PLAN_SCHEMA = {
  type: 'object',
  properties: {
    blocked: { type: 'boolean' },
    reason: { type: 'string' },
    correctedRootCause: { type: 'string' },
    steps: { type: 'array', items: { type: 'string' } },
    filesToTouch: { type: 'array', items: { type: 'string' } },
    edgeCases: { type: 'array', items: { type: 'string' } },
    migrations: { type: 'array', items: { type: 'string' } },
  },
}

const VERDICT_SCHEMA = {
  type: 'object',
  properties: {
    allPassed: { type: 'boolean' },
    // #2398 — il numero della PR giudicata. Serve a due cose: chi mergia usa
    // QUESTO numero (non «la PR che vedo aperta»), e lo script se ne serve per
    // accorgersi se il giro si e' sdoppiato fra un tentativo e l'altro.
    prNumber: { type: 'number' },
    results: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          ac: { type: 'string' },
          pass: { type: 'boolean' },
          status: { type: 'string', enum: ['pass', 'fail', 'pending-campo', 'pending-azione'] },
          reason: { type: 'string' },
        },
      },
    },
  },
}
```

**Il verificatore cade in due modi diversi, e servono due difese.**

Nel `Workflow` tool `agent()` **non** lancia su un errore API (529,
sovraccarico): restituisce `null`. Per quello serve il controllo esplicito
`if (!risultato)` — un `try/catch` da solo non intercetterebbe niente.

Ma esiste un secondo modo di cadere, e quello **lancia**: il subagente finisce
senza chiamare `StructuredOutput`, cioè risponde in prosa invece che nello schema
chiesto. Lì `agent()` solleva un'eccezione che, senza `catch`, **uccide l'intero
workflow**.

Il 05/09/2026 è successo su #1799: il piano era fatto, l'implementazione era fatta
e la PR era già aperta: tutto buttato via perché un verdetto non era formattato
bene. Un giudizio mancante deve costare un giro, non il lavoro di tre ore.

Quindi il verificatore va avvolto in una funzione che fa **entrambe** le cose —
`catch` che ritorna `null`, più il controllo su `null` a valle — come nello script
sopra. Il planner ha lo stesso problema e la stessa cura.

**Se un workflow muore così, il lavoro non è perso:** la PR è già su GitHub e i
risultati degli agenti completati sono in cache. Si corregge lo script e si
riprende con `Workflow({scriptPath, resumeFromRunId})` — chi ha già finito replica
dalla cache, riparte solo chi è caduto.
---

## Il worktree del developer va allineato, non dato per allineato

Il primo comando del developer deve essere un allineamento esplicito a
`origin/beta`, seguito dalla verifica che il merge-base sia la punta:

```bash
git fetch origin && git checkout -B <branch> origin/beta
git rev-list --count $(git merge-base HEAD origin/beta)..origin/beta   # deve dare 0
```

**Perché non basta scrivere «parti da beta aggiornata».** Il 06/09/2026 su
MaestroWeb #1984 il developer ha lavorato in un worktree fermo a `31a04367`, una
promozione vecchia di **150 commit**. La PR si è aperta lo stesso, la CI è passata,
e il difetto si è visto solo perché qualcuno ha guardato il conteggio dei file: 250
file e +16.716 righe per un fix di paginazione.

Il danno non era il rumore nel diff. Quel branch conteneva la versione **vecchia e
corrotta** di `overlay-chart.tsx`, cioè il file che #1977 aveva appena sistemato:
mergiarlo avrebbe **reintrodotto in silenzio un bug chiuso il giorno prima**, dentro
una PR il cui titolo parlava d'altro. Sono 811.000 token buttati e una trappola
evitata per un pelo.

La verifica del merge-base conta quanto il `fetch`: un worktree può sembrare pulito
(`git status` linda) ed essere indietro di mesi. «Pulito» e «aggiornato» sono due
cose diverse, e il primo non implica il secondo.

**Come accorgersene a valle**, quando il loop ha già finito e la PR è aperta:

```bash
git fetch origin <branch>
MB=$(git merge-base origin/beta origin/<branch>)
git rev-list --count $MB..origin/beta        # quanto e indietro la base: deve essere 0
```

Un numero diverso da zero **per il lavoro che il loop ha prodotto** significa che
la PR va rifatta, non aggiustata: il piano e il censimento si conservano
(commentandoli sulla issue), il branch si chiude. È il caso di #1984: il worktree
era partito da una base vecchia di 150 commit.

**Diverso è il caso normale in cui `beta` è avanzata mentre il loop lavorava.**
Un giro dura decine di minuti; se nel frattempo entra un'altra PR, il branch
risulta indietro di quei commit senza che il lavoro sia sbagliato. Lì si
riallinea, non si butta:

```bash
gh pr update-branch <PR>
```

**E si fa PRIMA di mettersi ad aspettare la CI.** Aspettare la CI e scoprire
dopo che il branch era indietro vuol dire buttare quel giro di verifiche — 16
minuti di E2E per niente, successo tre volte il 23/09/2026. Riallineare fa
ripartire la CI da sé, e quel commit di allineamento servirebbe comunque: farlo
prima non costa nulla, farlo dopo costa un giro intero.

Come si distinguono i due casi: guarda **da dove parte** il branch. Se la base è
un commit che al momento dell'apertura della PR era la punta di `beta`, è il caso
normale (riallinea). Se era già vecchia quando il loop è partito, è #1984
(rifai).


## Un solo branch, una sola PR per giro (#2398)

Il 24/09/2026 il loop ha aperto **due PR per la stessa issue tre volte**: #2313 →
#2382 e #2383, #2389 → #2392 e #2396, più una terza. Il nome del branch era
lasciato al developer (`<branch>` nel prompt); quando un push falliva, al
tentativo successivo se ne inventava un altro (`-v2`, `-8`) e apriva una PR nuova.

Finora è andata bene perché il verificatore dichiara quale PR ha giudicato e
Claudio chiude l'altra a mano. Ma il margine era sottile, e su #2389 le due
stesure **non erano equivalenti**: quella scartata aveva un test di isolamento
che **sopravviveva alla mutazione** — toglieva il filtro per azienda e il test
restava verde, cioè non provava quello che dichiarava di provare. Scegliere male
non avrebbe perso del lavoro: avrebbe tenuto la versione con la garanzia finta.

C'è anche un costo diretto: due branch, due CI complete (~16 minuti di E2E
ciascuna), due PR da riconciliare.

Da questa versione:

- il nome del branch lo fissa **lo script** (`const BRANCH`), una volta sola;
- il prompt del developer vieta di cambiarlo: se il push fallisce, **si ferma e
  lo dice** invece di aprire un branch nuovo, e prima di aprire una PR guarda se
  ne esiste già una per quel branch;
- il verificatore riporta `prNumber` e segnala se ne trova più di una aperta;
- lo script confronta `prNumber` fra un tentativo e l'altro: se cambia, il giro
  si è sdoppiato e **si ferma**, invece di proseguire su due strade.

Chi mergia usa il `prNumber` del verdetto, non «la PR che vedo aperta».

## Gli AC `[Campo]`/`[Azione]` non entrano nel criterio di uscita

**`[Campo]`** — un AC la cui verifica comporta **scrivere su un impianto
reale** (dispatch Modbus, autotest, cambio di modalità, qualunque comando
che arrivi all'hardware) non viene verificato né da un agente né da
Claudio: la prova spetta **esclusivamente ad Ascanio**, l'unico a poterla
fare sull'impianto con la responsabilità di quello che succede. Il
verificatore li marca `pending-campo`, non `pass`/`fail` — un agente che
dichiarasse verde un AC `[Campo]` starebbe certificando una prova che non
ha fatto. Verificare il **codice** del percorso resta doveroso; quello che
non si fa è **eseguirlo** contro un impianto vero.

**`[Azione]`** — distinto da `[Campo]`: qui la funzionalità esiste ma resta
**inerte** finché Ascanio non fa qualcosa (es. importare un elenco da un
portale esterno), non solo "confermare che si comporta così". Stesso
trattamento: il verificatore lo salta, non entra nel criterio di uscita.

In entrambi i casi la PR è pronta se il resto degli AC è verde — gli AC
`[Campo]`/`[Azione]` restano aperti in attesa di Ascanio dopo il merge in
`beta` (vedi skill `beta-release`, step "prova dal vivo").

---

## Step finale obbligatorio dopo il merge in `beta`

Subito dopo il merge (non "al prossimo giro"): sposta il Kanban GitHub della
issue e — su MaestroWeb — la card `qa_tasks` collegata, solo dopo averla
provata dal vivo. Procedura completa: skill `beta-release`, step "Prova dal
vivo, poi sposta la card di Ascanio". Non è un passo opzionale: una issue
mergiata ma mai provata né spostata è invisibile ad Ascanio quanto una mai
scritta.

---

## Scrivere AC verificabili (in fase di validazione)

Il verificatore può giudicare solo AC che descrivono un comportamento
osservabile. Alla creazione della issue (skill `issue-validate`), ogni AC
deve:

- Descrivere **input concreto → output/comportamento atteso**, non un
  obiettivo generico ("migliora le performance" ❌ → "la query risponde in
  una sola chiamata, non N+1" ✅).
- Essere verificabile leggendo il **diff, una risposta API, o uno
  screenshot** — non richiedere giudizio soggettivo ("l'interfaccia è più
  chiara" ❌ → "il pulsante di conferma è raggiungibile senza scroll su
  viewport 1280×800" ✅).
- Essere una unità **atomica**: una "e" che unisce due comportamenti
  indipendenti va spezzata in due AC — un verdetto parziale non è
  esprimibile nel loop.
- Includere il caso limite quando è quello il punto della issue.

Se una issue esistente ha AC vaghi, il planner può proporne una riscrittura
più specifica **prima** di far partire il developer — meglio un giro in più
di chiarimento che un loop che non converge mai.
