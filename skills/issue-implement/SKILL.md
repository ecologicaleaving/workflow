# Skill: issue-implement

**Trigger:** `/vai` di Davide — piano approvato, implementazione parte
**Agente:** Claude Code
**Versione:** 5.0.0

> Riferimento flusso: vedi `WORKFLOW.md` — Fase 3

---

## Obiettivo

Implementare la issue seguendo il piano, auto-validare al gate finale, pushare e aprire PR.
L'agente lavora in autonomia — si blocca solo su anomalie o gate fallito.

---

## Procedura

### Step 1 — Sposta card → InProgress

```bash
./scripts/kanban-move.sh <N> <repo> InProgress
```

Notifica Davide:
```
✅ [Issue #N] Implementazione avviata
```

---

### Step 2 — Implementa

Segui il piano prodotto in `issue-validate`:
- Commit atomici con Conventional Commits (`feat:`, `fix:`, `chore:`)
- Esegui test dopo ogni modifica significativa
- Se trovi un problema non risolvibile → FERMATI e notifica Davide

**Criteri auto-blocco:**
- Test falliti per più di 3 tentativi sullo stesso errore
- File modificati fuori scope del piano
- Più di 5 iterazioni senza convergenza
- Errore grave o comportamento inatteso

Se anomalia:
```
⚠️ [Issue #N] Anomalia — <descrizione>
📌 <cosa è successo>
❓ Come procedo?
```

---

### Step 3 — Build obbligatoria

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

### Step 4 — Security audit (obbligatorio)

```bash
./scripts/security-audit.sh
```

Vedi skill `security-audit` per i check manuali aggiuntivi.

---

### Step 5 — Auto-gate finale

Verifica autonomamente prima di pushare:

- [ ] Tutti gli AC soddisfatti
- [ ] Test e build passati
- [ ] Security audit passato
- [ ] PROJECT.md aggiornato
- [ ] Nessun file anomalo (.env, debug, config sensibili)
- [ ] Migrazioni DB incluse (se applicabile)

**Se tutto ok** → procedi con il push (Step 6).

**Se problemi** → fixa e ripeti il gate. Dopo 3 tentativi falliti → blocca e notifica Davide.

---

### Step 6 — Push e PR

Gate superato → procedi con `issue-pr-ready`.

---

## 🔍 Agent Monitor

Vedi `skills/references/agent-monitor.md` per istruzioni.

---

## Changelog

- **v5.0.0** (2026-04-13): Rimosso ruolo Claudio — auto-gate, agente procede autonomamente al push
- **v4.0.0** (2026-04-03): Agente unico (stesso della Fase 2), gate finale unico, rimossi checkpoint intermedi
- **v3.0.0** (2026-04-03): Riduzione a 3 checkpoint, rimossa duplicazione
