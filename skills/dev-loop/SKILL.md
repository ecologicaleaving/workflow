---
name: dev-loop
description: >
  Implementazione di una issue con pianificazione e verifica AC affidate a
  Fable 5, scrittura del codice affidata a Sonnet 5 in worktree isolato.
  Loop automatico: pianifica → implementa → verifica ogni Acceptance
  Criterion → se qualcuno fallisce, riprova con il feedback, finché non sono
  tutti verdi o si raggiunge il tetto di tentativi. Repo come parametro —
  vale per qualunque progetto 8020, non solo MaestroWeb.
  Trigger: "implementa issue #N", "risolvi issue #N".
version: 2.0.0
---

# Skill: dev-loop

> Riferimento flusso: `FLUSSO.md` — punto 3

## Perché

Separare chi pianifica/giudica da chi scrive il codice riduce il rischio che
un'implementazione si autocertifichi "fatta" senza aver davvero soddisfatto
ogni Acceptance Criterion. Fable 5 pianifica e verifica con un giudizio più
affidabile su corner case e AC ambigui; Sonnet 5 scrive il codice.

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
| Claudio (sessione corrente) | Fable 5 | Orchestra il loop via `Workflow` tool, riporta a Davide |
| Planner | Fable 5 (`model: 'fable'`) | Legge la issue, scompone in piano concreto (file, approccio, edge case) — non scrive codice |
| Developer | Sonnet 5 (`model: 'sonnet'`, worktree isolato, base `origin/beta`) | Implementa secondo il piano (+ feedback se è un retry), commit, push, apre/aggiorna la PR verso `beta` |
| Verificatore | Fable 5 (`model: 'fable'`) | Confronta il **diff reale della PR** con OGNI Acceptance Criterion della issue, pass/fail + motivazione puntuale — non si fida del messaggio di commit, esegue lui stesso lint/test/build su un checkout del branch |

## Meccanica del loop

Cap a **4 tentativi**. Se dopo 4 tentativi restano AC rossi, il workflow si
ferma e Claudio lo segnala a Davide invece di continuare a girare a vuoto —
di solito significa che l'AC stesso è ambiguo o mal scritto (vedi "Scrivere
AC verificabili" sotto), non che Sonnet sbaglia il codice.

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
  description: 'Fable pianifica e verifica AC, Sonnet implementa — loop fino a verde',
  phases: [
    { title: 'Piano', model: 'fable' },
    { title: 'Implementazione', model: 'sonnet' },
    { title: 'Verifica AC', model: 'fable' },
  ],
}

const REPO = args.repo // es. 'ecologicaleaving/maestroweb'

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
  plan = await agent(PLANNER_PROMPT, { model: 'fable', schema: PLAN_SCHEMA, label: `planner-${i + 1}` })
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

while (!verdict.allPassed && attempt < 4) {
  attempt++
  phase('Implementazione')
  await agent(`Implementa la issue #${args.issueNumber} (repo ${REPO}) secondo questo piano:
${JSON.stringify(plan)}
${feedback ? `Il tentativo precedente non ha soddisfatto questi AC:\n${feedback}\nCorreggi.` : ''}
Branch da origin/beta aggiornato. Segui CLAUDE.md del repo. Apri o aggiorna
la PR verso beta con "Closes #${args.issueNumber}" nel body, commit e push.`,
    { model: 'sonnet', label: `dev-attempt-${attempt}`, isolation: 'worktree' })

  phase('Verifica AC')
  const VERIFIER_PROMPT = `Verifica CIASCUN Acceptance Criterion della issue
#${args.issueNumber} (repo ${REPO}) — sia quelli taggati [UI] che quelli taggati
[Codice], TUTTI qui; salta SOLO i [Campo] e [Azione] (marcali "pending",
sono lavoro esclusivo di Ascanio, mai un agente) — contro il diff reale della
PR aperta (gh pr diff), non contro la descrizione del commit. Esegui tu
stesso lint/test/build su un checkout del branch, non fidarti del developer.
Per ogni AC: pass/fail/pending + motivazione puntuale e verificabile.`

  // Il verificatore puo cadere in DUE modi, e vanno gestiti entrambi (vedi sotto).
  const giudica = async (label) => {
    try {
      return await agent(VERIFIER_PROMPT, { model: 'fable', schema: VERDICT_SCHEMA, label })
    } catch (e) {
      log(`Verificatore caduto (${label}): ${e?.message?.slice(0, 160) ?? e}`)
      return null
    }
  }

  verdict = await giudica(`verify-${attempt}`)
  if (!verdict) verdict = await giudica(`verify-${attempt}-retry`)
  if (!verdict) {
    log(`Verificatore: nessun verdetto dopo 2 tentativi — tentativo ${attempt} non giudicato, si ritenta l'intero giro`)
    verdict = { allPassed: false, results: [] }
    continue
  }

  feedback = verdict.results.filter(r => !r.pass && r.status !== 'pending-campo' && r.status !== 'pending-azione')
    .map(r => `AC "${r.ac}": ${r.reason}`).join('\n')
  log(`Tentativo ${attempt}: ${verdict.results.filter(r => r.pass).length}/${verdict.results.length} AC verdi`)
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
