# WORKFLOW.md — 80/20 Solutions Development Workflow

**Versione:** 5.1.0 | **Aggiornato:** 2026-09-04

> Fonte di verità unica per il flusso di sviluppo del team.
> I valori strutturati (ID Kanban, repo, label) stanno in `config.json`.
> Le procedure dettagliate stanno nelle skill — qui c'è il "cosa e chi", le skill hanno il "come".

---

## 👥 Ruoli

| Chi | Ruolo | Cosa fa | Cosa NON fa |
|-----|-------|---------|-------------|
| **Davide** | Product Owner | Decide, testa, approva/reject, dà i comandi | Non implementa, non deploya |
| **Claudio** (Claude Code) | Orchestratore | Interfaccia con Davide, crea issue, coordina, spawna subagenti developer, gestisce deploy | Non implementa codice direttamente |
| **Subagente developer** | Developer | Implementa, testa, commit, PR — spawna da Claudio via `Agent` tool con `isolation: worktree` | Non parla con Davide |
| **Ascanio** | Co-fondatore, dominio pratico | Scrive le card in «Idee ASCANIO» (MaestroWeb), prova su impianti veri, approva dal pannello | Non apre issue GitHub su MaestroWeb |
| **Gaia** | Business + governance | BP, GTM, pricing, OKR, memoria/ADR della repo madre `ecologicaleaving`. Ha assorbito il ruolo del precedente «Ciccio» (ADR 0009) | Non tocca codice, issue tecniche, deploy |

> ⚖️ **LEGGE 1 — Merge:** MAI fare merge senza `/approva` esplicito di Davide. Commit e push OK, merge NO.
> ⚖️ **LEGGE 2 — Sync:** All'inizio di ogni sessione: `git pull` workflow repo + `sync.ps1` prima di qualsiasi operazione.
> ⚖️ **LEGGE 3 — Worktree isolato:** ogni modifica di codice passa da un subagente con `isolation: worktree`, branch creato da `origin/<default-branch>`. Claudio non edita mai codice nella working dir condivisa (più agenti in parallelo "risucchiano" le modifiche non committate).
> ⚠️ **Regola:** Nessun fix/patch senza autorizzazione esplicita di Davide.
> ⚠️ **Repo workflow:** Solo Claudio modifica `ecologicaleaving/workflow` su indicazione di Davide.

---

## 🤖 Architettura

```
Davide ←→ Claudio (questa sessione Claude Code)
               ↓ Agent tool (isolation: worktree)
          Subagente developer (worktree isolato, lavora in silenzio)
               ↓
          GitHub: branch (da origin/default) → commit → PR
               ↓
          CI/CD → deploy test automatico
               ↓
          Claudio notifica Davide
```

**Claudio** = la chat aperta da Davide. Non un processo background, non un VPS.
**Subagente** = spawna da Claudio con `Agent` tool **e `isolation: worktree`**, segue `issue-run` (su MaestroWeb: `dev-loop-opus-sonnet` del repo), ritorna al termine.

---

## 📋 Comandi Davide

| Comando | Effetto |
|---------|---------|
| Descrizione libera | Claudio crea issue e spawna subagente |
| `/vai #N` | Claudio spawna subagente per issue esistente |
| `/approva` | Claudio mette `qa-approved`, promuove `beta`→`main` (`approva-promote.ts`, dry-run prima) → CI deploya prod |
| `/reject #N <feedback>` | Claudio registra feedback e rilancia rework |
| `/stato` | Claudio mostra issue in corso |
| `/create-issue` | Claudio crea issue leggera → Backlog |

---

## 🔄 Flusso Completo

```
Davide descrive problema/feature
         ↓
    FASE 1 — Creazione issue → Backlog
         ↓
    FASE 2 — Validazione + Piano → Todo
         ↓
    /vai (Davide)
         ↓
    FASE 3 — Implementazione (auto-gate) → InProgress
         ↓
    FASE 4 — PR verso beta → CI verde → merge in beta → deploy test → Test
         ↓
    Prova dal vivo (chi ha lavorato) · Ascanio approva dal pannello
    ├── /approva (Davide) → qa-approved → promozione beta→main → CI deploya prod → Done
    └── /reject  → Rework → loop da Fase 3
```

> Il dettaglio di come gira **davvero**, passo per passo, è nella sezione
> «Il flusso, come gira davvero» qui sotto.

---

## 🃏 La card di Ascanio (solo MaestroWeb)

> Vale **solo su MaestroWeb**, dove esiste la task list nel pannello laterale e
> in `/qa`. Sugli altri progetti non c'è nulla di tutto questo.

Ascanio non apre issue: scrive una **card** in «Idee ASCANIO». Quella card è
l'embrione dell'epica, vive nel nostro database (`qa_tasks.stage`) ed è **l'unica
cosa che lui vede**. Le issue GitHub restano roba nostra.

### Le sezioni

`Revisione` · `To Do ASCANIO` · `Fatte da Ascanio` · `Idee ASCANIO` · `In Lavorazione` · `BackLog`

«Revisione» sta in cima perché è la risposta alla domanda per cui il pannello si
apre: *cosa aspetta me adesso*.

### ⛔ Spostare la card è OBBLIGATORIO, e lo fa l'agente

La sezione **non si deduce da niente**: non guarda GitHub, non si aggiorna da
sola, non c'è nessun automatismo che la corregge. Se l'agente non sposta la card,
Ascanio continua a vedere lo stato di ieri — e non ha modo di accorgersene.

| Quando | La card va in | Insieme a |
|--------|---------------|-----------|
| Prendo in carico la richiesta di Ascanio | **In Lavorazione** | Fase 2 → Fase 3 (`/vai`) |
| Serve una sua decisione o una prova sul campo | **To Do ASCANIO** | in qualsiasi momento |
| In `beta` **e provata dal vivo da chi ha lavorato** | **Revisione** + `review_notes` | dopo la prova su test-maestro, poi `npm run deps:schede` |
| Ascanio approva | **BackLog** | lo fa lui dal pannello |
| Ascanio rimanda indietro | **In Lavorazione** | lo fa lui, con nota obbligatoria |

**In Revisione SOLO dopo la prova dal vivo di chi ha lavorato.** La CI verde
dice che i test passano, non che la cosa funziona: si prova su
test-maestro.8020solutions.org, poi si sposta la card, con le `review_notes`,
e si lancia `npm run deps:schede` (è il calcolo che fa comparire l'avviso «questa
dipende da un'altra non ancora in produzione»). La variante «va in Revisione
appena è su `beta`, testa Ascanio» è **superata**: vale il punto 4 de «Il flusso,
come gira davvero».

Quando sposti in «Revisione», **scrivi cosa provare** nel campo delle note di
revisione (form di modifica della card). Quella è la parte che non si salta:
senza, Ascanio non sa cosa guardare e la card torna indietro per il motivo
sbagliato. Le note si scrivono per chi apre l'app, non per chi legge il diff —
cosa aprire, cosa deve succedere, e i casi strani da provare apposta.

Se il lavoro tocca dati veri (anagrafiche, import, comandi), **dillo nelle
note**: l'ambiente di test scrive in produzione.

### Il lavoro che nasce strada facendo

Bug che troviamo noi, refactor, issue tecniche: **niente card**. Si gestiscono
interamente su GitHub e si testano come da workflow — sono propedeutici a ciò che
Ascanio conferma, non oggetto della sua revisione.

### Card ≠ Kanban GitHub

Sono due cose diverse e vanno mosse **entrambe**:

- **card Ascanio** (`qa_tasks.stage`, database Maestro) → questa sezione;
- **card Kanban** (Project V2 su GitHub) → la tabella qui sotto.

> ⛔ **La card di Ascanio viene PRIMA della issue.** Quando lavori qualcosa che
> nasce da una sua segnalazione, il primo gesto è aggiornare la SUA card
> (`qa_tasks`), poi la issue/PR. Vale anche per una card che parte da **«Idee
> ASCANIO»**: appena diventa lavoro pronto da provare, la porti tu da *Idee* a
> *Revisione* con le note — non resta in Idee. Muovere la issue o il Kanban
> GitHub **non** muove la sua card, e lui vede solo quella. *(Inciso il 26/08/2026
> dopo che una card Solarman è rimasta in «Idee» mentre la issue era già in
> Review: Davide non la vedeva nel pannello. A noi interessano le card di
> Ascanio: quelle vanno SEMPRE tenute allineate al lavoro reale.)*

Una issue lavorata sposta la sua card Kanban *e*, se nasce da una segnalazione di
Ascanio, anche la sua card nel pannello.


### ⛔ Una scheda di Ascanio = UN'EPICA, e l'approvazione è una sola

La scheda che scrive Ascanio è **l'embrione di un'epica**, non di una issue. Quasi
sempre quello che chiede è una cosa sola per lui — «l'anagrafica», «la ricerca
dell'inverter» — e diventa molte issue solo perché **noi** la scomponiamo per
lavorarla.

Quella scomposizione è roba nostra e deve restare invisibile:

| | dove vive | chi la vede | chi la approva |
|---|---|---|---|
| **la scheda** | `qa_tasks` | Ascanio | Ascanio, **una volta sola** |
| **l'epica** | GitHub | noi | — |
| **le sotto-issue** | GitHub | noi | **nessuno**: si chiudono e basta |

**Le sotto-issue non compaiono mai nel pannello di Ascanio** e non ricevono mai
una `qa-approved` propria: la eredita dall'epica quando lui approva la scheda.

#### Perché non è una preferenza organizzativa

Il 18/08/2026 la promozione in produzione **si è spezzata** proprio su questo.
L'anagrafica clienti era nata come quindici issue sorelle invece che come
un'epica con figlie. Conseguenze, tutte misurate:

- Ascanio ha dovuto approvare **quindici volte** una cosa che aveva chiesto una
  volta sola;
- il lavoro era **intrecciato** (le sotto-feature si costruiscono l'una
  sull'altra, sugli stessi file) mentre l'approvazione era **frammentata**:
  promuoverne alcune e non altre ha prodotto **dieci gruppi caduti per
  conflitto** di cherry-pick;
- alcune sotto-issue non avevano approvazione perché non dovevano averla — ed
  erano comunque necessarie a far funzionare quelle approvate.

La promozione selettiva regge **solo** se l'unità approvata coincide con l'unità
di lavoro. Un'epica è quell'unità. Una issue figlia non lo è mai.

#### In pratica

Quando prendi in carico una scheda di Ascanio:

1. apri **un'epica** collegata alla scheda (`qa_task_issues` punta all'epica);
2. le sotto-issue sono **figlie dell'epica**, mai collegate alla scheda;
3. lavori le figlie come al solito — PR, CI, merge in `beta`;
4. quando l'epica è completa, la scheda va in **Revisione**;
5. Ascanio approva **la scheda**: da lì la `qa-approved` arriva all'epica e a
   tutte le sue figlie.

**Se una scheda ha più di una issue collegata, è il segnale che la regola non è
stata seguita.** Non è vietato, ma va guardato: significa che Ascanio dovrà
approvare più volte, e che la promozione potrà spezzarsi.

---

## ⛔ Nessun lavoro senza issue — nemmeno un fix

**Ogni commit che finisce su `beta` deve essere riconducibile a una issue, con
`Closes #N` nel corpo o nel titolo della PR.** Vale per le feature, vale per i
bug, e vale soprattutto per i fix piccoli e "di servizio" — quelli che sembrano
troppo brevi per meritare una issue. Sono esattamente quelli che creano il
debito.

**Non è burocrazia: è ciò che tiene in piedi il rilascio.** `approva-promote.ts`
attribuisce ogni commit alla sua issue per decidere cosa promuovere. Un commit
che non riesce ad attribuire è **`NON RISOLVIBILE`**, e uno solo così **fa
abortire l'intera promozione** — bloccando anche il lavoro di altri che era
pronto e approvato.

Successo il **31/08/2026**: una PR di una riga sullo strumento di precheck,
aperta al volo senza issue perché "era un fix di processo". Risultato al
`--dry-run`:

```
❌ NON RISOLVIBILE ad01e0f7 — PR #1864 senza closing-keyword nel body/titolo
❌ ABORT — 1 commit non risolvibile su beta (AC11). Nessun branch creato.
```

Quel singolo commit avrebbe bloccato la messa in produzione di due bug ad alta
priorità già provati. Rimediato aprendo la issue a posteriori (#1869) e
aggiungendo `Closes` alla PR già mergiata — si può fare, ma è lavoro in più
fatto nel momento peggiore, cioè quando si vuole rilasciare.


> **Dove va il `Closes`: nel body (o titolo) della PR — non nel messaggio di
> commit.** `approva-promote.ts` interroga la PR via API GitHub, non legge il
> commit. Un `Closes #N` messo solo nel merge commit **non viene visto** e il
> commit resta `NON RISOLVIBILE`: sbagliato il 31/08 subito dopo aver scritto
> questa regola, e scoperto solo col `--dry-run`.

**Prima di aprire una PR, sempre:**

1. esiste una issue? se no, si apre — anche breve, anche a posteriori, anche per
   tre righe di codice
2. la PR ha `Closes #N` nel body o nel titolo?
3. nel dubbio, `npx tsx scripts/approva-promote.ts --dry-run`: gira in locale,
   non pusha nulla, e dice subito se la promozione si bloccherebbe

> Il corollario: **un fix non può creare debito tecnico.** Se per andare più
> veloce salti la issue, il conto arriva al rilascio successivo — e lo paga chi
> sta aspettando che il suo lavoro vada in produzione.

---

## 🔁 Il flusso, come gira davvero (03-04/09/2026)

> Questo è il flusso **eseguito** sulle ultime issue di MaestroWeb il 03-04/09/2026.
> Le fasi qui sotto lo descrivono nel dettaglio; dove una skill o una frase di questo
> file dovesse contraddirlo, **vale questo**. Non va cambiato: va solo descritto
> senza contraddizioni.

1. **Issue con Acceptance Criteria verificabili** (skill `issue-validate`). Prima del
   loop di implementazione: `npm run issue:precheck N` — blocca se manca la sezione AC.
2. **Card Kanban GitHub → In Progress.** Se esiste una card di Ascanio in `qa_tasks`
   → **«In Lavorazione»**.
3. **Implementazione** con la skill `dev-loop-opus-sonnet` del repo MaestroWeb
   (Workflow tool: planner → developer in worktree isolato → verificatore AC, max 4
   tentativi). Branch `feature/issue-N-slug`, **PR verso `beta`** con `Closes #N` nel
   body. I fix piccoli li fa Claudio direttamente in un worktree, sempre con PR verso
   `beta`.
4. **CI verde sulla PR → Claudio mergia in `beta` con `--merge`** (mai squash), label
   `deployed-test`, Kanban → Test. Prova dal vivo su test-maestro.8020solutions.org.
   La card di Ascanio va in **«Revisione» SOLO dopo la prova dal vivo di chi ha
   lavorato**, con `review_notes` che dicono cosa provare; poi `npm run deps:schede`.
   *(La variante «va in Revisione appena è su beta, testa Ascanio» è SUPERATA.)*
5. **Ascanio dal pannello** clicca «Approva» (card → «BackLog» = approvato e in
   produzione, commento «✅ Approvata da Revisione a BackLog») oppure risponde. La label
   `qa-approved` sulla issue **non** arriva da lì: la mette Claudio dopo aver letto i
   commenti.
6. **Davide scrive `/approva`** → Claudio mette `qa-approved`, lancia
   `npx tsx scripts/approva-promote.ts --dry-run`, poi il run reale → PR verso `main` →
   CI → merge `--merge` → deploy prod → smoke test → chiude le issue, label
   `deployed-prod`, card Kanban Done.
   Se lo script esclude gruppi per conflitto: cherry-pick a mano in worktree da
   `origin/main` in ordine cronologico di `beta`; conflitti su `PROJECT.md` /
   `package.json` / `package-lock.json` risolti prendendo la versione in arrivo (alla
   fine `package.json` + lock presi interi da `beta`); conflitti su altri file → l'issue
   esce con tutti i suoi commit; PR verso `main` a mano.
7. **Sezioni delle card di Ascanio:** Revisione · To Do ASCANIO · Fatte da Ascanio ·
   Idee ASCANIO · In Lavorazione · BackLog. Nessuna colonna «Review Ascanio» né
   «Test-ready». **Branch:** `feature/*` → `beta` (test) → `main` (prod). **Ruoli:**
   Davide, Ascanio, Claudio (tech), Gaia (business + governance; ha assorbito Ciccio,
   ADR 0009). Nessun «Ciccio»; nessun `master` come branch di prod dei progetti (il
   solo repo `workflow` usa `master` come default, e resta così).

---

## FASE 1 — Creazione Issue

**Chi:** Agente
**Skill:** `create-issue`
**Kanban:** → Backlog

Raccolta rapida: repo, tipo (bug/feature/improvement), obiettivo in una riga.
Issue leggera — i dettagli arrivano nella Fase 2.

---

## FASE 2 — Validazione + Piano

**Chi:** Agente (interattivo con Davide)
**Skill:** `issue-validate`
**Kanban:** Backlog → Todo

1. **Domande a Davide** — AC, edge case, dipendenze, note tecniche (una alla volta)
2. **Verifica deploy** — CI pipeline, secrets, sottodomini (una volta per repo)
3. **Esplora + pianifica** — research e piano in un colpo solo
4. **Auto-validazione** — check formale: AC coperti, scope ok, niente red flag
5. **Notifica Davide** — piano pronto, aspetta `/vai`

> ⚠️ L'agente NON avvia mai l'implementazione senza `/vai` esplicito di Davide.

---

## FASE 3 — Implementazione

**Chi:** Agente
**Skill:** `issue-implement`
**Kanban:** Todo → InProgress (dopo `/vai`)
**Card Ascanio (MaestroWeb):** → **In Lavorazione** — obbligatorio se la issue
nasce da una sua segnalazione
**Su MaestroWeb:** prima `npm run issue:precheck N`, poi la skill `dev-loop-opus-sonnet`
del repo (planner → developer in worktree → verificatore AC, max 4 tentativi).
Branch `feature/issue-N-slug`, PR **verso `beta`** con `Closes #N` nel body.

### Auto-gate

L'agente procede in autonomia e si auto-blocca solo su anomalie o al gate finale.

| Momento | Cosa succede |
|---------|-------------|
| Dopo `/vai` | Agente implementa in autonomia |
| Anomalia | Agente si blocca e notifica Davide |
| **Gate finale** | Agente verifica: AC ok, test ok, build ok, security audit ok |
| Gate superato | Agente procede a push + PR automaticamente |
| Gate fallito | Agente fixa e ripete il gate |

### Notifica a Davide (dopo push + PR)

```
✅ [Issue #N] Implementazione completata, PR aperta
📌 <summary cosa è stato fatto>
🔗 <link PR>
⏭️ Testa su test-<repo>.8020solutions.org
```

Anomalia non risolvibile → blocca, notifica Davide, aspetta istruzioni.
Più di 5 iterazioni senza convergere → blocco automatico.

### Check in locale (obbligatorio pre-push)

**I check girano in locale PRIMA del push. La CI conferma, non scopre.**

Prima di ogni push che apre o aggiorna una PR, sulla macchina dell'agente devono
essere verdi:

| Check | Comando | Nota |
|---|---|---|
| Lint | `npm run lint` | lint ≠ type-check: servono entrambi |
| Tipi | `npx tsc --noEmit` | la build passa dove `tsc` fallisce, e viceversa |
| Test unitari | `npm test` / `vitest` | se l'area non ha framework → **dillo**, non saltare |
| E2E | `npx playwright test` | vedi sotto: girano in locale, davvero |

**Perché non basta la CI.** Un giro di CI costa ~12 minuti e restituisce *quanti*
test falliscono. Un giro in locale costa minuti e mostra *quale asserto* cade, su
quale elemento, con quale errore in console. Sono due informazioni diverse, e solo
la seconda fa avanzare il lavoro.

Il 30/08/2026 la suite E2E di MaestroWeb aveva 57 rossi che sembravano «test da
adattare ai dati». Erano una chiave di sessione scritta a mano nel `global-setup`:
i test non entravano mai nell'applicazione e aspettavano il timeout. In CI si
vedeva solo il numero 57, e da quel numero la diagnosi non si ricava. In locale il
primo screenshot mostrava la pagina di login, e da lì al colpevole c'è voluta
mezz'ora. (#1856)

**Gotcha che rendono impossibile il ciclo locale, e che si risolvono:**

- **Playwright non parte su Node 24** (`TypeError: context.conditions?.includes is
  not a function`). Serve Node 22 — basta anteporre la cartella al `PATH`, senza
  `nvm use`:
  `export PATH="$HOME/AppData/Local/nvm/v22.20.0:$PATH"`
- **Le `NEXT_PUBLIC_*` entrano nel bundle alla build.** Cambiarle nella shell dopo
  `npm run build` non ha alcun effetto: se cambi backend, ricompila.
- **Un modulo nativo può bloccare `npm ci`.** Se il fallimento è in un workspace che
  ai test non serve, escludilo (`--workspaces=false --include-workspace-root`)
  invece di rinunciare.

**Un «saltato» non è un verde.** A fine run leggi anche quanti test sono stati
saltati e perché: un test che si auto-salta per una precondizione mancante non sta
verificando niente, e va riportato accanto al numero dei passati — non nascosto
dentro di esso.

**Se un check è davvero impossibile in locale**, lo dici a Davide dicendo *quale* e
*perché*, e la CI resta l'unica prova per quel check. Non lo si salta in silenzio,
e non si spaccia il verde della CI per una verifica che non ha fatto: controlla
sempre **quali job** ha eseguito davvero (un job `skipped` non è un job verde).

### Security Audit (obbligatorio pre-push)

**Skill:** `security-audit`
L'agente esegue `scripts/security-audit.sh` + check manuali prima del push.

---

## FASE 4 — PR + Deploy Test

**Chi:** Agente + CI (deploy automatico)
**Skill:** `issue-pr-ready`
**Kanban:** InProgress → Test
**Card Ascanio (MaestroWeb):** resta **In Lavorazione** — v. punto 7

1. Agente verifica checklist pre-PR (AC, test, PROJECT.md, niente file anomali)
2. Agente apre PR **verso `beta`** (se il repo ha `beta`; altrimenti verso il default) con
   summary strutturato e `Closes #N` nel body
3. **CI verde sulla PR → Claudio mergia in `beta` con `--merge`** (mai squash), label
   `deployed-test`, Kanban → Test. È il push su `beta` che deploya su
   `test-<repo>.8020solutions.org` (skill `beta-release`, Step 1-3)
4. **Agente monitora il deploy** — se fallisce: legge i log, fixa, re-push, reitera (max 3 volte)
5. Agente notifica Davide con link, istruzioni di test e AC da verificare
6. **Prova dal vivo** su test da parte di chi ha lavorato
7. **Solo MaestroWeb — la card di Ascanio NON si sposta ancora.** Va in
   «Revisione» dopo che l'abbiamo provata noi sul deploy, non appena la CI è
   verde: verde vuol dire che i test passano, non che la cosa funziona. Quando la
   sposti, scrivi **cosa provare** nelle `review_notes` della card, poi lancia
   `npm run deps:schede`.

### Notifica Davide

```
✅ [Issue #N] PR pronta → <link PR>
📌 <summary>

🧪 Come testare:
<passi concreti>

💡 Cosa aspettarsi:
<risultato atteso>

→ /approva se ok | /reject <motivo> se serve rework
```

---

## FASE 5a — Approvazione

**Chi:** Agente
**Skill:** `issue-approve` (guardia beta, Step 0) → `beta-release` (Step 5)
**Kanban:** Test → Done
**Card Ascanio (MaestroWeb):** la sposta **lui** in BackLog approvando dal
pannello («✅ Approvata da Revisione a BackLog») — l'agente non la tocca. La label
`qa-approved` sulla issue **non** arriva da lì: la mette Claudio dopo aver letto i commenti.

1. `/approva` di Davide → Claudio mette `qa-approved` alle issue approvate
2. `npx tsx scripts/approva-promote.ts --dry-run`, poi il run reale → PR verso `main`
   con i soli commit delle issue approvate (repo senza `beta`/script: merge classico
   della PR in `main` con `--merge`)
3. CI verde → merge `--merge` (mai squash) → CI deploya in produzione → smoke test
4. **Agente monitora il deploy prod** — se fallisce: legge i log, fixa, reitera (max 3 volte)
5. Agente chiude le issue e aggiunge label `deployed-prod`, card → Done
6. Agente notifica Davide con conferma
7. **Se lo script esclude gruppi per conflitto:** cherry-pick a mano in worktree da
   `origin/main` in ordine cronologico di `beta`; conflitti su `PROJECT.md` /
   `package.json` / `package-lock.json` → versione in arrivo (alla fine `package.json` +
   lock presi interi da `beta`); conflitti su altri file → l'issue esce con tutti i suoi
   commit; PR verso `main` a mano
8. **Se servono azioni infra** (env vars, migrazioni DB) → Agente le esegue direttamente via SSH sul VPS

---

## FASE 5b — Reject + Rework

**Chi:** Agente
**Skill:** `issue-reject` (per reject semplici) | `issue-research-rework` (per reject complessi ≥2)
**Kanban:** Test → Review → InProgress → Test (loop)
**Card Ascanio (MaestroWeb):** se il reject viene da lui, la card è **già**
tornata In Lavorazione col suo «Rimanda» — leggi la nota che ha lasciato nel
thread prima di rimettere mano al codice

1. Agente registra feedback + risultati test come commento sulla issue
2. Label: rimuove `review-ready`, aggiunge `needs-fix`
3. Agente rilancia rework con feedback come contesto
4. Stesso flusso Fase 3 → Fase 4
5. Loop fino a `/approva`

---

## 📊 Kanban (Project V2 su GitHub)

> Da non confondere con **la card di Ascanio** (sopra), che vive nel database di
> Maestro ed è un oggetto diverso. Su MaestroWeb vanno mosse **entrambe**.

| Colonna | Significato | Chi sposta |
|---------|-------------|------------|
| **Backlog** | Issue creata | Agente (create-issue) |
| **Todo** | Validata, AC verificabili, aspetta /vai | Agente (issue-validate / triage) |
| **InProgress** | Agente al lavoro, branch `feature/issue-N-slug`, PR verso `beta` | Agente (dopo /vai) |
| **Test** | PR mergiata in `beta` (`--merge`), label `deployed-test`, live su test-<repo> | Agente (beta-release Step 1) |
| **Review** | Reject, rework in corso | Agente (issue-reject) |
| **Done** | Promossa `beta`→`main` dopo `/approva`, in produzione, chiusa | Agente (beta-release Step 5) |

### Label

| Label | Significato |
|-------|-------------|
| `agent:claude-code` | Agente Claude Code assegnato |
| `in-progress` | Agente al lavoro |
| `review-ready` | PR pronta per test Davide |
| `deployed-test` | Mergiata in `beta`, live su test |
| `needs-fix` | Reject, rework in corso |
| `qa-approved` | Approvata da Ascanio (la mette Claudio dopo aver letto i commenti); è ciò che `approva-promote.ts` promuove |
| `deployed-prod` | Live in produzione |

---

## 🗺️ Mappa Skill

| Skill | Quando si usa |
|-------|--------------|
| `claudio` | Chi sei in ogni sessione: ruolo, comandi, Kanban, card di Ascanio |
| `8020-workflow` | Regola cardinale + indice operazioni |
| `create-issue` | Fase 1 — creazione issue leggera (non su MaestroWeb per Ascanio: lì c'è la card) |
| `ascanio` | Fase 1 — issue già validate scritte dall'agente di Ascanio (progetti diversi da MaestroWeb) |
| `triage` | Fase 1.5 — screening batch del Backlog → Definition of Ready → Todo |
| `issue-validate` | Fase 2 — AC verificabili (loop Sonnet↔Opus), research, piano |
| `issue-run` | Fase 3 — porta unica: loop sulla Definition of Done fino alla PR verso `beta` |
| `issue-implement` | Fase 3 — fasi implementative dentro `issue-run` (build, security audit, RLS smoke, auto-gate) |
| `issue-pr-ready` | Fase 4 — check locali, apertura PR verso `beta`, notifiche |
| `beta-release` | Fase 4/5a — merge in `beta` a CI verde, deploy test, promozione `beta`→`main` dopo `/approva` |
| `issue-approve` | Fase 5a — guardia beta su `/approva`, poi `beta-release` |
| `issue-reject` | Fase 5b — rework dopo reject semplice |
| `issue-research-rework` | Fase 5b — research approfondita per reject complessi |
| `security-audit` | Pre-push — gate di sicurezza obbligatorio |
| `8020-commit-workflow` | Convenzioni commit |
| `create-prd` | Creazione PRD da brief |
| `prd-to-issues` | Breakdown PRD in issue |
| `preparazione-repo` | Setup iniziale repo per workflow 8020 |
| `repo-maintenance` | Manutenzione file di progetto |
| `pdf-to-md` | Converti PDF in Markdown prima di leggerli (obbligatoria per tutti) |
| `beachcrer-sync-group` | BeachCRER — gruppo mail «arbitri beach» ↔ arbitri attivi |

Skill che vivono nel repo del progetto, non qui: `dev-loop-opus-sonnet` (MaestroWeb,
implementazione Fase 3). Skill ritirate: `skills/RETIRED.txt`.

---

## 📂 Script condivisi

Usa sempre gli script in `scripts/` invece di comandi inline:

| Script | Cosa fa |
|--------|---------|
| `sync.ps1` | Avvio sessione: copia le skill in `~/.claude/skills`, ritira quelle in `skills/RETIRED.txt` |
| `kanban-move.sh` → `gh-kanban-move.sh` | Sposta card Kanban (legge ID da config.json; usato anche dalla GitHub Action `kanban-automation.yml`) |
| `generate-pr-body.sh` | Genera body PR dal template |
| `security-audit.sh` | Check automatici sicurezza pre-push |
| `parse-checkpoint.sh` | Estrae i checkpoint dai commenti di una issue (legacy) |

Nel repo MaestroWeb: `npm run issue:precheck N`, `npx tsx scripts/approva-promote.ts [--dry-run]`,
`npm run deps:schede`.

---

## 📝 Convenzioni

- **Branch:** `feature/issue-N-slug`, `fix/issue-N-slug` — creato da `origin/<default-branch>` dentro un **worktree isolato** (mai `checkout -b` nella working dir condivisa). Flusso: `feature/*` → `beta` (test) → `main` (prod)
- **Commit:** Conventional Commits (`feat:`, `fix:`, `chore:`, `docs:`)
- **Merge:** sempre `--merge`, mai `--squash`
- **Niente commit su `beta`/`main`** (né su `master` nel repo workflow)
- **PROJECT.md** aggiornato prima di ogni PR
