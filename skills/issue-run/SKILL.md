---
name: issue-run
description: >
  Orchestratore end-to-end di una issue "ready": la porta da Todo a PR passando per tutte le
  fasi (implementazione, test automatici, test UI da Chrome, lint/tsc, curl) con un LOOP di
  controllo che ri-verifica la Definition of Done a ogni ciclo e NON si ferma finché ogni voce
  della checklist non è verde. Trigger: /esegui #N (o /run-issue #N). Si usa dopo il triage,
  su una issue in Todo che porta già il blocco Definition of Done.
---

# Skill: issue-run

**Trigger:** `/esegui #N` · `/run-issue #N`
**Agente:** Claude Code (Claudio) — orchestra; delega l'implementazione a un subagente developer
**Versione:** 1.0.0

> Riferimento flusso: `WORKFLOW.md` — Fase 3 (esecuzione). Avvio (card → In Progress) →
> `issue-implement` → test UI Chrome → `issue-pr-ready`, con il **loop DoD** come spina dorsale.
> Su MaestroWeb la fase implementativa è la skill `dev-loop-opus-sonnet` del repo
> (planner Opus → developer Sonnet in worktree → verificatore AC, max 4 tentativi).

---

## Obiettivo

Eseguire una issue **fino a PR** guidati dalla sua **Definition of Done**: un **loop di
controllo** che, a ogni ciclo, ri-valuta l'intera checklist DoD e continua finché **ogni voce
non è verde**. Niente "compila quindi è fatto": ogni voce va **verificata**, e le due verifiche
di test — **automatici** e **UI da Chrome** — sono obbligatorie e non saltabili.

Differenza da `issue-implement`: quella fa un auto-gate a passata singola. `issue-run` è un
**loop esplicito sulla checklist**: se una voce fallisce, torna nella fase che la produce e
ri-controlla *tutta* la DoD, finché è esaurita.

---

## Precondizione

- Issue in **Todo**, con il blocco **`## Definition of Done`** nel body (lo mette il `triage`).
- Se la issue **non ha la DoD** → non partire: rimanda a `/triage #N` (o iniettala) prima.
- Se la issue è 🟡 in attesa di una tua decisione, 🟠 epica o 🔴 bloccata → non è eseguibile.

---

## Il loop DoD (cuore della skill)

```
carica la checklist DoD dalla issue
mantieni uno stato: ogni voce ∈ {da fare, fatta+verificata, bloccata}
ITERA:
  1. scegli la prossima voce NON verde
  2. esegui la FASE che la produce (mappa sotto)
  3. RI-VALUTA l'INTERA checklist (non solo la voce toccata: una fix può romperne un'altra)
  4. aggiorna le spunte nel commento di stato sulla issue
  fino a: tutte le voci verdi  → vai a "Chiusura"
HARD-STOP (blocca e notifica Davide) se:
  - stessa voce fallita 3 volte di fila
  - > 6 iterazioni totali senza convergenza
  - emerge una decisione di prodotto/budget/business (spetta a Davide)
  - file toccati fuori scope, o comportamento gravemente inatteso
```

### Mappa voce DoD → fase → come si verifica

| Voce DoD | Fase | Verifica |
|---|---|---|
| AC funzionali | implementazione | ogni AC esercitato (vedi test UI) |
| **Test automatici verdi** | scrittura test | `npm test` / `vitest` verde; se area senza framework → **segnalalo**, non saltare |
| **Test UI da Chrome** | verifica browser | `claude-in-chrome`: flusso reale + screenshot + console pulita |
| lint + `tsc --noEmit` | build | entrambi puliti **in locale** (lint ≠ type-check) |
| **Nessun check rimandato alla CI** | pre-push | v. `WORKFLOW.md` → «Check in locale». La CI conferma, non scopre |
| **Saltati riportati** | pre-push | un test che si auto-salta non verifica niente: va detto quanti e perché |
| curl test se tocca API/route | smoke | `tests/curl-tests.sh` aggiornato e verde |
| PROJECT.md aggiornato | chiusura | sezione backlog/stato aggiornata |

---

## Procedura

### Step 0 — Avvio

- Verifica precondizione (DoD presente). Su MaestroWeb: `npm run issue:precheck N`
  (blocca se manca la sezione Acceptance Criteria).
- Sposta card → **In Progress**:
  ```bash
  ./scripts/kanban-move.sh <N> <repo> InProgress
  ```
  Gli ID in `config.json` sono del board `ecologicaleaving`. Per un board di un'altra
  org **non cercare gli ID a mano**: questa query li ricava dalla card stessa e
  funziona ovunque.
  ```bash
  REPO="<owner/repo>"; N=<numero-issue>
  read -r ITEM_ID PROJECT_ID FIELD_ID OPTION_ID <<<"$(gh api graphql -f query='
  query($id: ID!) {
    node(id: $id) {
      ... on Issue {
        projectItems(first: 5) {
          nodes {
            id
            project { id }
            fieldValueByName(name: "Status") {
              ... on ProjectV2ItemFieldSingleSelectValue {
                field { ... on ProjectV2SingleSelectField { id options { id name } } }
              }
            }
          }
        }
      }
    }
  }' -f id="$(gh issue view "$N" --repo "$REPO" --json id --jq .id)" --jq '
    .data.node.projectItems.nodes[0] as $it
    | [$it.id, $it.project.id, $it.fieldValueByName.field.id,
       ($it.fieldValueByName.field.options[] | select(.name=="In Progress") | .id)]
    | @tsv')"

  if [ -z "$ITEM_ID" ]; then
    echo "La issue non e' su nessun board: salto lo spostamento e vado avanti."
  else
    gh api graphql -f query='
    mutation($projectId: ID!, $itemId: ID!, $fieldId: ID!, $optionId: String!) {
      updateProjectV2ItemFieldValue(input: {
        projectId: $projectId, itemId: $itemId, fieldId: $fieldId
        value: { singleSelectOptionId: $optionId }
      }) { projectV2Item { id } }
    }' -f projectId="$PROJECT_ID" -f itemId="$ITEM_ID" \
       -f fieldId="$FIELD_ID" -f optionId="$OPTION_ID"
  fi
  ```
  Una issue che non è su nessun board **non è un errore**: dillo una volta nel report e
  prosegui.
- **Solo MaestroWeb:** se la issue nasce da una card di Ascanio, la sua card va in
  **«In Lavorazione»** adesso (`qa_tasks.stage`) — v. `WORKFLOW.md` → «La card di Ascanio».
- Apri un **commento di stato** sulla issue con la checklist DoD copiata: sarà il registro
  vivo del loop (aggiornato a ogni ciclo).
- Spawna il **subagente developer in worktree isolato** (`isolation: worktree`) per le fasi
  implementative — coerente col modello team (Claudio orchestra, il dev implementa).

### Step 1..N — Loop DoD

Applica il loop qui sopra. Per le fasi implementative il subagente segue `issue-implement`
(commit atomici Conventional Commits, build, security audit, smoke RLS-aware se tocca policy).
Dopo ogni ritorno del subagente, **l'orchestratore ri-verifica la checklist di persona** —
in particolare le due voci di test, che non delega alla parola del subagente ma controlla.

#### Fase test UI (obbligatoria, non delegabile alla sola build)

**Nel loop autonomo (default): Playwright e2e su Chromium.** Il subagente scrive e gira un
test `playwright` headless sul flusso reale della issue (il repo ha già `playwright.config.ts`
+ `npm run e2e`). È ripetibile, non presidiato, gira su Chromium (= "test con Chrome" in senso
automatico). Ogni subagente usa una **porta dev dedicata** per il `webServer` Playwright per
non collidere con gli altri worktree. Gate: e2e verde.

**Verifica presidiata (opzionale, quando c'è un umano + browser):** passata `claude-in-chrome`
per il controllo visivo reale. Guida via MCP `mcp__claude-in-chrome__*` (carica gli strumenti
con una sola `ToolSearch`:
`tabs_context_mcp, navigate, computer, read_page, tabs_create_mcp, read_console_messages`,
+ `gif_creator` se vuoi registrare):

1. Avvia il dev server (`npm run dev`) o punta all'ambiente test.
2. `tabs_context_mcp` → apri una **nuova tab** (`tabs_create_mcp`), naviga alla pagina della issue.
3. Per **ogni AC**: esegui le azioni reali nel browser, verifica il comportamento atteso.
4. **Screenshot** dello stato finale + `read_console_messages` per intercettare errori JS.
5. Errori/console rossa o comportamento difforme → la voce **resta da fare** → torna al loop.
6. Tutti gli AC ok nel browser → spunta la voce, allega screenshot/nota al commento di stato.

> Evita azioni che aprono `alert/confirm/prompt` (bloccano l'estensione). Se un tool Chrome
> fallisce 2-3 volte → fermati e chiedi a Davide, non insistere.

### Chiusura — quando la DoD è esaurita

- Riporta la checklist DoD **tutta verde** nel commento della issue, con link screenshot.
- Procedi con `issue-pr-ready`: push, apertura PR **verso `beta`** con `Closes #N` nel body
  (con nel corpo l'esito dei due test + screenshot), notifica Davide. Il merge in `beta`,
  la label `deployed-test` e la card → **Test** sono di `beta-release` (Step 1).

```
✅ [Issue #N] DoD esaurita — pronta al test
   🤖 test automatici: verdi (M test)
   🌐 test UI Chrome: N AC verificati (screenshot in PR)
   🔗 PR #M · card → Test
⏭️ Testala e scrivi /approva per il merge.
```

---

## Note

- `issue-run` **non chiude** la issue: si ferma alla PR verso `beta`. Il merge in `beta` lo fa
  Claudio a CI verde (`beta-release` Step 1); il merge in `main` resta dietro `/approva` di
  Davide (legge assoluta: mai prod senza ok esplicito).
- La forza della skill è il **loop-until-exhausted**: non esiste "abbastanza vicino". O la
  checklist è tutta verde, o si è in HARD-STOP con una domanda precisa a Davide.
- Se durante il loop emerge che un AC era ambiguo → è un segnale che il `triage` l'ha lasciato
  passare: HARD-STOP, chiudi la decisione con Davide, e nota il gap per tarare il triage.
- Test UI **sempre con Chrome** (`claude-in-chrome`), mai "verifica a mano dichiarata" senza prova.

---

## Changelog

- **v1.0.0** (2026-07-13): Prima versione — orchestratore Todo→PR con loop di controllo sulla Definition of Done; test UI obbligatori via Chrome; delega implementazione a subagente in worktree.
