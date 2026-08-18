# WORKFLOW.md — 80/20 Solutions Development Workflow

**Versione:** 5.0.0 | **Aggiornato:** 2026-04-14

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
**Subagente** = spawna da Claudio con `Agent` tool **e `isolation: worktree`**, segue `issue-resolver`, ritorna al termine.

---

## 📋 Comandi Davide

| Comando | Effetto |
|---------|---------|
| Descrizione libera | Claudio crea issue e spawna subagente |
| `/vai #N` | Claudio spawna subagente per issue esistente |
| `/approva #N` | Claudio mergia PR → CI deploya prod |
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
    FASE 4 — PR + Deploy test automatico → Test
         ↓
    Davide testa
    ├── /approva → Agente mergia → CI deploya prod → Done
    └── /reject  → Rework → loop da Fase 3
```

---

## 🃏 La card di Ascanio (solo MaestroWeb)

> Vale **solo su MaestroWeb**, dove esiste la task list nel pannello laterale e
> in `/qa`. Sugli altri progetti non c'è nulla di tutto questo.

Ascanio non apre issue: scrive una **card** in «Idee ASCANIO». Quella card è
l'embrione dell'epica, vive nel nostro database (`qa_tasks.stage`) ed è **l'unica
cosa che lui vede**. Le issue GitHub restano roba nostra.

### Le cinque sezioni

`Revisione` · `Idee ASCANIO` · `To Do ASCANIO` · `In Lavorazione` · `BackLog`

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
| CI verde e mergiato in `beta` | **Revisione** | subito dopo il merge |
| Ascanio approva | **BackLog** | lo fa lui dal pannello |
| Ascanio rimanda indietro | **In Lavorazione** | lo fa lui, con nota obbligatoria |

**Appena è su `beta`, la card va in Revisione.** Non si aspetta che la provi
prima Davide o l'agente: **a testare è Ascanio** — è il suo lavoro, ed è l'unico
che la guarda su impianti veri. Trattenere una card «finché non la controllo io»
è tempo perso due volte, e Davide l'ha detto esplicitamente il 16/08/2026.

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
2. Agente apre PR con summary strutturato
3. CI deploya automaticamente su `test-<repo>.8020solutions.org`
4. **Agente monitora il deploy** — se fallisce: legge i log, fixa, re-push, reitera (max 3 volte)
5. Agente aggiunge label `review-ready` solo quando CI è verde
6. Agente notifica Davide con link, istruzioni di test e AC da verificare
7. **Solo MaestroWeb — la card di Ascanio NON si sposta ancora.** Va in
   «Revisione» dopo che l'abbiamo provata noi sul deploy, non appena la CI è
   verde: verde vuol dire che i test passano, non che la cosa funziona. Quando la
   sposti, scrivi **cosa provare** nelle note di revisione della card.

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
**Skill:** `issue-approve`
**Kanban:** Test → Done
**Card Ascanio (MaestroWeb):** la sposta **lui** in BackLog approvando dal
pannello — l'agente non la tocca

1. Agente mergia la PR su main: `gh pr merge --merge --delete-branch`
2. CI deploya automaticamente in produzione
3. **Agente monitora il deploy prod** — se fallisce: legge i log, fixa, reitera (max 3 volte)
4. Agente chiude la issue e aggiunge label `deployed-prod`
5. Agente notifica Davide con conferma
6. **Se servono azioni infra** (env vars, migrazioni DB) → Agente le esegue direttamente via SSH sul VPS

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
| **Todo** | Validata, piano pronto, aspetta /vai | Agente (issue-validate) |
| **InProgress** | Agente al lavoro | Agente (dopo /vai) |
| **Test** | PR aperta, CI ha deployato in test | Agente (issue-pr-ready) |
| **Review** | Reject, rework in corso | Agente (issue-reject) |
| **Done** | Mergiato, in produzione, chiuso | Agente (issue-approve) |

### Label

| Label | Significato |
|-------|-------------|
| `agent:claude-code` | Agente Claude Code assegnato |
| `in-progress` | Agente al lavoro |
| `review-ready` | PR pronta per test Davide |
| `deployed-test` | Live su test (aggiunta da CI) |
| `needs-fix` | Reject, rework in corso |
| `deployed-prod` | Live in produzione |

---

## 🗺️ Mappa Skill

| Skill | Quando si usa |
|-------|--------------|
| `create-issue` | Fase 1 — creazione issue leggera |
| `issue-validate` | Fase 2 — validazione completa + research + piano |
| `issue-implement` | Fase 3 — implementazione con auto-gate |
| `issue-pr-ready` | Fase 4 — checklist pre-PR, apertura PR, notifiche |
| `issue-approve` | Fase 5a — merge + chiusura dopo /approva |
| `issue-reject` | Fase 5b — rework dopo reject semplice |
| `issue-research-rework` | Fase 5b — research approfondita per reject complessi |
| `security-audit` | Pre-push — gate di sicurezza obbligatorio |
| `8020-commit-workflow` | Convenzioni commit |
| `create-prd` | Creazione PRD da brief |
| `prd-to-issues` | Breakdown PRD in issue |
| `preparazione-repo` | Setup iniziale repo per workflow 8020 |
| `pdf-to-md` | Converti PDF in Markdown prima di leggerli (obbligatoria per tutti) |

---

## 📂 Script condivisi

Usa sempre gli script in `scripts/` invece di comandi inline:

| Script | Cosa fa |
|--------|---------|
| `kanban-move.sh` | Sposta card Kanban (legge ID da config.json) |
| `generate-pr-body.sh` | Genera body PR dal template |
| `security-audit.sh` | Check automatici sicurezza pre-push |

---

## 📝 Convenzioni

- **Branch:** `feature/issue-N-slug`, `fix/issue-N-slug` — creato da `origin/<default-branch>` dentro un **worktree isolato** (mai `checkout -b` nella working dir condivisa)
- **Commit:** Conventional Commits (`feat:`, `fix:`, `chore:`, `docs:`)
- **Niente commit su main/master**
- **PROJECT.md** aggiornato prima di ogni PR
- **Weekly tracking:** dopo ogni merge, riga in `memory/weekly/current.md`
