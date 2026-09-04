# Changelog — Workflow 8020

## v2.6.0 — 2026-09-04

### Pulizia: file morti, skill ritirate, riferimenti rotti

**Il flusso non cambia.** Quello eseguito il 03-04/09/2026 su MaestroWeb è ora scritto
in `WORKFLOW.md` → «Il flusso, come gira davvero» (7 punti) e le contraddizioni sono
sciolte in quel senso.

- **`scripts/sync.ps1` ora RITIRA**: legge `skills/RETIRED.txt` e cancella da
  `~/.claude/skills` le skill che il repo non ha più. Rimosso il blocco «monitor» che
  copiava uno `scripts/claude-monitor.ps1` inesistente.
- **Skill ritirate** (10, in `skills/RETIRED.txt`): `issue-resolver`, `issue-start`,
  `issue-done`, `issue-review`, `issue-deploy-test`, `issue-deploy-prod`,
  `issue-rework-fast`, `ciccio`, `create-feature-issue`, `prd-creator`. Le citazioni sono
  ripuntate su `issue-run` / `beta-release` (in `WORKFLOW.md`, `claudio`, `triage`,
  `issue-run`). La query GraphQL di `issue-start` che ricava gli ID del board dalla card
  vive ora in `issue-run` Step 0.
- **File morti eliminati** (0 citazioni): `CLAUDIO_MEMORY_NOTE.md`,
  `docs/CHECKPOINT_FORMAT.md`, `templates/agent-prompt.md`, `templates/reject.md`,
  `notifications/build-log.jsonl`, e in `scripts/`: `sync-build-log.sh`,
  `install-skills.sh`, `agent-retry.sh`, `auto_issue_parser.py`, `project_board.py`,
  `metrics.sh`, `status.sh`, `safe-github.sh`, `setup-project.{sh,ps1}`,
  `validate-project.{sh,ps1}`, `install-{kanban,pr-template,commit-automation}.sh`,
  `sync-templates.sh`, `update-claude-skills.sh`.
- **Contraddizione Revisione sciolta**: la card di Ascanio va in «Revisione» **solo
  dopo la prova dal vivo** di chi ha lavorato, con `review_notes`, poi
  `npm run deps:schede`. La variante «appena è su beta, testa Ascanio» (16/08) è
  superata — corretto in `WORKFLOW.md`, `claudio`, `issue-pr-ready`.
- **Riferimenti rotti**: `install-claudio-skin.sh` → `commit-automation/install.sh`
  (`8020-commit-workflow` + references); `BRANCH_STRATEGY.md` non ammette più
  `--squash` e descrive `beta`; `memory/weekly/current.md` (mai esistito) rimosso da
  `WORKFLOW.md` e `issue-approve`; «Review Ascanio» → «Revisione».
- **`WORKFLOW.md` aggiornato**: versione 5.1.0, ruoli con Ascanio e Gaia (ADR 0009),
  Kanban e label con `beta`/`qa-approved`, mappa skill completa (`triage`, `issue-run`,
  `beta-release`, `ascanio`, `repo-maintenance`, `beachcrer-sync-group`), script
  condivisi reali, sei sezioni delle card di Ascanio.
- **`CLAUDE.md` del repo** ridotto a un puntatore a `WORKFLOW.md` (era una copia di
  aprile del CLAUDE.md globale, senza Gaia).

## v2.5.0 — 2026-08-30

### Novità

**Check in locale obbligatori prima del push — la CI conferma, non scopre**
- Nuova sezione canonica in `WORKFLOW.md` → «Check in locale (obbligatorio pre-push)»:
  lint, `tsc --noEmit`, test unitari ed e2e devono essere verdi **sulla macchina**
  prima di un push che apre o aggiorna una PR
- `issue-pr-ready`: nuovo **Step 0** come gate non saltabile prima del push
- `8020-commit-workflow`: nuovo punto **0** nella pre-commit checklist
- `issue-run`: due voci in più nella mappa DoD — nessun check rimandato alla CI,
  e i test saltati vanno riportati
- Motivo: un giro di CI costa ~12 minuti e dice *quanti* test cadono; un giro in
  locale dice *quale asserto* cade. Il 30/08/2026 su MaestroWeb 57 e2e rosse
  sembravano «test da adattare ai dati»: erano una chiave di sessione scritta a
  mano: in CI si vedeva solo il numero (#1856)
- Documentati i tre ostacoli che facevano credere impossibile il ciclo locale, e
  che invece si risolvono: Playwright non parte su Node 24 (serve il 22), le
  `NEXT_PUBLIC_*` sono congelate nel bundle al momento della build, un modulo
  nativo in un workspace non necessario può bloccare `npm ci`
- Regola nuova sulla lettura degli esiti: **un test saltato non è un verde**, e un
  job `skipped` non è un job verde — vanno riportati accanto ai passati, non
  dentro

## v2.4.0 — 2026-03-25

### Novità

**Build obbligatoria pre-PR (Flutter + Node.js)**
- L'agente DEVE eseguire `flutter build apk` (o `npm run build`) al CP3, prima di dichiarare pronto
- Se la build fallisce → fix obbligatorio, niente PR con build rotta
- Aggiunto alla tabella checkpoint CP3 + sezione dedicata nelle Convenzioni Agente
- Vale per TUTTE le app Flutter (Finn, StageConnect, Metronomo, etc.) e Node.js

**Notifiche deploy con AC automatici (ciccio-notify)** *(storico — lo script `ciccio-notify` e la skill `issue-deploy-test` non esistono più, v. v2.6.0)*
- Lo script `ciccio-notify` sulla VPS estraeva gli Acceptance Criteria dalla issue GitHub
- Quando un branch `feature/issue-N-*` veniva deployato, il messaggio Telegram includeva gli AC da verificare

### Modifiche
- `skills/issue-implement/SKILL.md` — CP3 include Build ✅, sezione build obbligatoria agente
- `skills/issue-deploy-test/SKILL.md` — documentato ciccio-notify + estrazione AC *(skill ritirata)*

---

## v2.3.0 — 2026-03-23

### Novità
- Modelli obbligatori per fase: Haiku (research), Opus (piano), Sonnet (implementazione)
- Weekly tracking con `memory/weekly/current.md` *(mai creato; rimosso in v2.6.0)*
- Claudio mergia direttamente su `/approva` (rimosso passaggio Ciccio per merge)

---

## v2.2.0 — 2026-03-21

### Novità
- Security audit skill obbligatorio pre-push
- Issue metrics script con rework tracking
- Agent retry wrapper con escalation
- Status dashboard script
- Unified issue-pr-ready skill
