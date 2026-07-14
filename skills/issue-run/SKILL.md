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

> Riferimento flusso: `WORKFLOW.md` — Fase 3 (esecuzione). Wrappa `issue-start` →
> `issue-implement` → test UI Chrome → `issue-pr-ready`, con il **loop DoD** come spina dorsale.

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
| lint + `tsc --noEmit` | build | entrambi puliti (lint ≠ type-check) |
| curl test se tocca API/route | smoke | `tests/curl-tests.sh` aggiornato e verde |
| PROJECT.md aggiornato | chiusura | sezione backlog/stato aggiornata |

---

## Procedura

### Step 0 — Avvio (issue-start)

- Verifica precondizione (DoD presente). Sposta card → **In Progress**:
  ```bash
  ./scripts/kanban-move.sh <N> <repo> InProgress
  ```
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
- Procedi con `issue-pr-ready`: push, apertura PR (con nel corpo l'esito dei due test +
  screenshot), card → **Test**, notifica Davide.

```
✅ [Issue #N] DoD esaurita — pronta al test
   🤖 test automatici: verdi (M test)
   🌐 test UI Chrome: N AC verificati (screenshot in PR)
   🔗 PR #M · card → Test
⏭️ Testala e scrivi /approva per il merge.
```

---

## Note

- `issue-run` **non mergia** e **non chiude** la issue: si ferma alla colonna Test. Il merge
  resta a Davide dopo `/approva` (legge assoluta: mai merge senza ok esplicito).
- La forza della skill è il **loop-until-exhausted**: non esiste "abbastanza vicino". O la
  checklist è tutta verde, o si è in HARD-STOP con una domanda precisa a Davide.
- Se durante il loop emerge che un AC era ambiguo → è un segnale che il `triage` l'ha lasciato
  passare: HARD-STOP, chiudi la decisione con Davide, e nota il gap per tarare il triage.
- Test UI **sempre con Chrome** (`claude-in-chrome`), mai "verifica a mano dichiarata" senza prova.

---

## Changelog

- **v1.0.0** (2026-07-13): Prima versione — orchestratore Todo→PR con loop di controllo sulla Definition of Done; test UI obbligatori via Chrome; delega implementazione a subagente in worktree.
