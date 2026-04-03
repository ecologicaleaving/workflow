# Skill: issue-implement

**Trigger:** `/vai` di Davide — piano approvato, agente prosegue con implementazione
**Agente:** Claudio (supervisione) + stesso Sonnet della Fase 2 (esecuzione)
**Versione:** 4.0.0

> Riferimento flusso: vedi `WORKFLOW.md` — Fase 3
> L'agente è lo stesso della Fase 2 (research + piano) — mantiene il contesto.

---

## Obiettivo

Sbloccare l'agente per l'implementazione e supervisionare fino al gate finale.
L'agente lavora in autonomia — Claudio interviene solo al gate finale o su anomalie.

---

## Procedura

### Step 1 — Sblocca l'agente

Dopo `/vai` di Davide, Claudio:

1. Sposta card → InProgress: `./scripts/kanban-move.sh <N> <repo> InProgress`
2. Invia messaggio all'agente (stessa sessione della Fase 2):

```
Piano approvato da Davide. Procedi con l'implementazione.

Regole:
- Segui il piano che hai prodotto
- Commit atomici con Conventional Commits (feat:, fix:, chore:)
- Esegui test dopo ogni modifica significativa
- Se trovi un problema che non sai risolvere → FERMATI e segnala
- Quando hai finito: esegui security audit (scripts/security-audit.sh), poi posta il gate finale
```

3. Notifica Davide:
```
✅ [Issue #N] Agente al lavoro
📌 Implementazione avviata
```

### Step 2 — Monitora (non interrompere)

L'agente lavora. Claudio monitora via agent-monitor ma **non interviene** a meno di anomalie.

**Criteri anomalia (auto-blocco):**
- Test falliti per più di 3 tentativi sullo stesso errore
- File modificati fuori scope del piano
- Più di 5 iterazioni senza convergenza
- Errore grave o comportamento inatteso

Se anomalia → Claudio notifica Davide:
```
⚠️ [Issue #N] Anomalia — <descrizione>
📌 <cosa ha fatto l'agente>
❓ Come procedo?
```

### Step 3 — Gate finale

L'agente posta un commento sulla issue con questo formato:

```
## ✅ Gate Finale — Pronto per push

**Cosa è stato fatto:**
<descrizione>

**AC verificati:**
- ✅ AC1 — <come è stato verificato>
- ✅ AC2 — ...

**Test:**
- Lint: ✅/❌
- Typecheck: ✅/❌
- Unit test: ✅/❌
- Build: ✅/❌

**Security audit:**
<risultato scripts/security-audit.sh>

**File modificati:**
<lista>

**Aspetto conferma di Claudio prima di pushare.**
```

### Step 4 — Claudio valida il gate

**Checklist Claudio:**
- [ ] Tutti gli AC soddisfatti
- [ ] Test e build passati
- [ ] Security audit passato
- [ ] PROJECT.md aggiornato
- [ ] Nessun file anomalo (.env, debug, config sensibili)
- [ ] Migrazioni DB incluse (se applicabile)

**Se ok:** `✅ procedi` → agente pusha → Claudio segue skill `issue-pr-ready`

**Se problemi:** `🔴 bloccato — <motivo e istruzioni>` → agente fixa → ripete gate

---

## Build obbligatoria (l'agente la esegue prima del gate)

**Flutter (se `pubspec.yaml` presente):**
```bash
flutter analyze --no-fatal-infos && flutter test --no-pub && \
flutter build apk --debug --flavor dev --target-platform android-arm64
```

**Node.js (se `package.json` presente):**
```bash
npm ci && npm run build && npm test
```

---

## Convenzioni Agente

Vedi `WORKFLOW.md` per branch e convenzioni. Vedi `COMMIT_CONVENTIONS.md` per commit.

---

## 🔍 Agent Monitor (obbligatorio)

Vedi [agent-monitor.md](../references/agent-monitor.md) per istruzioni.

---

## Changelog

- **v4.0.0** (2026-04-03): Agente unico (stesso della Fase 2), gate finale unico, rimossi checkpoint intermedi
- **v3.0.0** (2026-04-03): Riduzione a 3 checkpoint, rimossa duplicazione
