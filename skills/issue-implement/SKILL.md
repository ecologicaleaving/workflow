# Skill: issue-implement

**Trigger:** `/vai` di Davide — piano approvato, agente in fase di implementazione  
**Agente:** Claudio (supervisione) + Sonnet `anthropic/claude-sonnet-4-6` (esecuzione)  
**Versione:** 3.0.0

> Riferimento flusso: vedi `WORKFLOW.md` — Fase 3  
> Modelli agente: vedi `WORKFLOW.md` — tabella modelli

---

## Obiettivo

Supervisionare la lavorazione dell'agente tramite il **protocollo checkpoint vincolante**: l'agente non procede senza il via esplicito di Claudio. Notifica Davide a ogni step, interviene in caso di anomalie.

---

## Protocollo Checkpoint Vincolante

### Come funziona

1. L'agente completa uno step e **posta un commento sulla issue** con formato fisso
2. Claudio legge il commento e valuta
3. **Se ok** → Claudio risponde sulla issue: `✅ procedi`
4. **Se anomalia** → Claudio risponde: `🔴 bloccato — <motivo>` + notifica Davide
5. L'agente **non procede** finché non riceve `✅ procedi`

### Formato commento checkpoint (agente)

```
## ✅ Checkpoint N — <titolo>

**Stato:** completato

**Cosa è stato fatto:**
<descrizione dettagliata>

**Risultati test (se applicabile):**
<risultati lint / typecheck / unit / e2e>

**Prossimo step pianificato:**
<cosa farei dopo>

**Aspetto conferma di Claudio prima di procedere.**
```

### Risposta Claudio (via commento issue)

**Via libera:**
```
✅ procedi
```

**Blocco:**
```
🔴 bloccato
Motivo: <descrizione anomalia>
Istruzioni: <cosa deve fare l'agente>
```

---

## Checkpoint per tipo issue

### Feature / Improvement

| CP | Titolo | Cosa verifica Claudio |
|----|--------|----------------------|
| CP1 | Piano confermato | Piano copre tutti gli AC, file sensati, nessun rischio |
| CP2 | Implementazione + test | Codice fatto, lint/typecheck/test/build passati, niente regressioni |
| CP3 | Pronto per push | AC verificati, security audit ok, PROJECT.md ok, nessun file anomalo |

### Bug

| CP | Titolo | Cosa verifica Claudio |
|----|--------|----------------------|
| CP1 | Root cause + fix applicato | Causa chiara, fix mirato, test regressione ok |
| CP2 | Test suite completa | Lint ✅, Typecheck ✅, Unit ✅, Build ✅ |
| CP3 | Pronto per push | AC verificati, security audit ok, PROJECT.md ok, nessun file anomalo |

> CP2 e CP3 possono essere unificati se l'implementazione è semplice.

**Security Audit (obbligatorio al CP3):** Esegui la skill `security-audit` prima di procedere al push.

---

## Gestione Anomalie

**Criteri anomalia:**
- Piano ignora degli AC
- Test falliti non risolti
- File modificati fuori scope
- Più di 5 iterazioni senza convergenza
- Comportamento inatteso o errori gravi

**Procedura anomalia:**
1. Claudio posta `🔴 bloccato` sulla issue con istruzioni
2. Notifica Davide:
   ```
   ⚠️ [Issue #N] Anomalia al CP-N — <titolo>
   📌 <descrizione problema>
   🔧 <cosa ha fatto l'agente>
   ❓ Come procedo?
   ```
3. Aspetta istruzioni di Davide prima di sbloccare l'agente

**Se l'agente supera 5 iterazioni senza convergere → blocco automatico + notifica Davide**

---

## Notifiche a Davide (formato)

Ad ogni checkpoint Claudio notifica Davide su Telegram:

```
✅ [Issue #N] CP-N — <titolo>
📌 <summary in 1-2 righe>
⏭️ Prossimo step: <cosa fa l'agente ora>
```

In caso di anomalia:
```
⚠️ [Issue #N] Anomalia CP-N — <titolo>
📌 <descrizione>
❓ <domanda / cosa serve da Davide>
```

---

## CP3 — Checklist "Pronto per push"

Al CP3 l'agente ha finito. Claudio verifica tutto prima di dare `✅ procedi`.

**Codice:**
- [ ] Tutti gli AC della issue sono soddisfatti
- [ ] `PROJECT.md` aggiornato
- [ ] Nessun file anomalo (`.env`, debug, config sensibili)
- [ ] Lint ✅, Typecheck ✅, Test ✅, Build ✅
- [ ] Security audit passato (skill `security-audit`)

**Build Flutter (se `pubspec.yaml` presente):**
```bash
flutter analyze --no-fatal-infos && flutter test --no-pub && \
flutter build apk --debug --flavor dev --target-platform android-arm64
```

**Build Node.js (se `package.json` presente):**
```bash
npm ci && npm run build && npm test
```

**DB (solo se la issue tocca schema/dati):**
- [ ] Migrazioni incluse nel branch
- [ ] Migrazioni descritte nel commento PR

Solo quando tutto è verde → `✅ procedi` per push e apertura PR (skill `issue-pr-ready`).

---

## Post-implementazione

Dopo CP3 approvato, l'agente fa push. Claudio segue la skill `issue-pr-ready` per aprire la PR.
Per `/approva` e `/reject` vedi `WORKFLOW.md` e le skill dedicate.

---

## Convenzioni Agente

Vedi `WORKFLOW.md` per branch, commit, build. Vedi `COMMIT_CONVENTIONS.md` per dettagli commit.

---

## 🔍 Agent Monitor (obbligatorio)

Vedi [agent-monitor.md](../references/agent-monitor.md) per istruzioni complete.
