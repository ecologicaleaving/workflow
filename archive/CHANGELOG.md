# Changelog — Workflow 8020

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

**Notifiche deploy con AC automatici (ciccio-notify)**
- Lo script `ciccio-notify` sulla VPS ora estrae gli Acceptance Criteria dalla issue GitHub
- Quando un branch `feature/issue-N-*` viene deployato, il messaggio Telegram include gli AC da verificare
- Documentato nella skill `issue-deploy-test`

### Modifiche
- `skills/issue-implement/SKILL.md` — CP3 include Build ✅, sezione build obbligatoria agente
- `skills/issue-deploy-test/SKILL.md` — documentato ciccio-notify + estrazione AC

---

## v2.3.0 — 2026-03-23

### Novità
- Modelli obbligatori per fase: Haiku (research), Opus (piano), Sonnet (implementazione)
- Weekly tracking con `memory/weekly/current.md`
- Claudio mergia direttamente su `/approva` (rimosso passaggio Ciccio per merge)

---

## v2.2.0 — 2026-03-21

### Novità
- Security audit skill obbligatorio pre-push
- Issue metrics script con rework tracking
- Agent retry wrapper con escalation
- Status dashboard script
- Unified issue-pr-ready skill
