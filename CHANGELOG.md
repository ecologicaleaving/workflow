# Changelog — Workflow 8020

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
