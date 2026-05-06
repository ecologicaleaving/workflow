# Skill: issue-implement

**Trigger:** `/vai` di Davide — piano approvato, implementazione parte
**Agente:** Claude Code
**Versione:** 5.1.0

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

### Step 4b — Verifica AC nel browser (solo progetti web)

**Si applica se:** il progetto ha frontend web (Next.js, React, ecc.) **e** il MCP Chrome DevTools è configurato nella sessione.

Leggi skill `frontend-debug` per l'uso del MCP.

1. Avvia il dev server locale (`npm run dev` o equivalente)
2. Per ogni AC della issue, verifica direttamente nel browser:
   - Esegui le azioni descritte nell'AC
   - Comportamento corrispondente all'atteso → ✅
   - Errori in console → ❌ torna allo Step 2
3. Tutti gli AC verificati → procedi al gate finale

**Se il MCP Chrome DevTools non è disponibile:** salta questo step e segnalalo nel commento PR:
```
⚠️ Verifica browser non eseguita — MCP Chrome DevTools non configurato nel progetto
```

> **Nota sul caricamento MCP:** gli MCP si configurano a livello di progetto in `.claude/settings.json`
> così caricano solo quando si lavora su quel repo. Non aggiungere MCP pesanti al profilo globale.

---

### Step 4c — Smoke test path completo (se la issue tocca DB con RLS)

**Si applica se:** la issue aggiunge/modifica una migration con `ENABLE ROW LEVEL SECURITY` o policy nuove, **e** introduce o modifica endpoint API che scrivono/leggono quella tabella.

**Perché esiste questo step:** build verde + schema corretto + lint pulito **non** garantiscono che la policy RLS conceda le operazioni che l'API tenta. Errore tipico:
- API usa `upsert` → richiede permission sia `INSERT` che `UPDATE`
- Policy concede solo `INSERT` (caso comune: tabella write-only pubblica tipo lead capture)
- → 500 silenzioso in produzione, smoke test in CI lo passa perché non gira mai sul DB reale con la policy applicata

Questo è successo realmente, due hot-fix consecutivi post-merge — è il motivo per cui questo step esiste.

**Procedura:**

1. **Applica la migration sul DB di test** (psql diretto o `supabase db reset`)
2. **Avvia l'app contro lo schema reale** (`npm run dev`)
3. **Chiama l'endpoint via curl con i payload reali della UI** — testa almeno: caso felice, duplicato/conflict, payload invalido
4. **Verifica nel DB** che la riga sia stata effettivamente scritta:
   ```bash
   psql -c "SELECT ... FROM <tabella> WHERE ... LIMIT 1;"
   ```
5. **Se l'endpoint usa `upsert`, `update`, `delete`, `select`** → verifica esplicitamente che la policy concede TUTTI i verbi richiesti, non solo `INSERT`

**Regola:** ogni verbo che l'API chiama (`insert`, `update`, `upsert`, `delete`, `select`) deve avere una policy `FOR <verbo>` esplicita nella migration, oppure essere `FOR ALL`. `upsert` = `INSERT` + `UPDATE` insieme.

**Failure** → torna allo Step 2: policy e API code devono essere coerenti, non solo schema.

**Se la migration NON è applicabile in locale** (es. dipende da VPS Supabase self-hosted): documenta nel commento PR e marca la verifica come "manuale post-deploy" — l'orchestratore farà lo smoke test post-merge prima di chiudere la issue.

---

### Step 5 — Auto-gate finale

Verifica autonomamente prima di pushare:

- [ ] Tutti gli AC soddisfatti
- [ ] Test e build passati
- [ ] AC verificati nel browser (**o** MCP non disponibile — documentato)
- [ ] **Smoke test RLS-aware passato (se applicabile — vedi Step 4c)**
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

- **v5.1.0** (2026-05-06): Aggiunto Step 4c — smoke test RLS-aware quando issue tocca migration con policy + endpoint API. Lezione da rilibro #71/#73/#74: build verde non basta, serve eseguire l'API contro la policy applicata. Aggiornata checklist auto-gate.
- **v5.0.0** (2026-04-13): Rimosso ruolo Claudio — auto-gate, agente procede autonomamente al push
- **v4.0.0** (2026-04-03): Agente unico (stesso della Fase 2), gate finale unico, rimossi checkpoint intermedi
- **v3.0.0** (2026-04-03): Riduzione a 3 checkpoint, rimossa duplicazione
