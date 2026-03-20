# Skill: issue-implement

**Trigger:** Piano approvato, agente in fase di implementazione  
**Agente:** Claudio (supervisione) + Claude Code / Codex (esecuzione)  
**Versione:** 2.0.0

---

## Obiettivo

Supervisionare la lavorazione dell'agente, notificare Davide a ogni checkpoint obbligatorio, intervenire in caso di anomalie.

---

## Checkpoint Obbligatori

Ad ogni checkpoint Claudio notifica Davide con questo formato:

```
✅ [Issue #N] Checkpoint N — <titolo>
📌 <summary di cosa è successo>
🧪 Test: <risultato se applicabile>
⏭️ Prossimo step: <cosa fa l'agente ora>
```

### CP2 — Fine ogni iterazione di implementazione

L'agente deve riportare:
- Cosa ha implementato
- Test eseguiti e risultati
- Se ci sono stati problemi e come li ha risolti
- Cosa fa nella prossima iterazione

Claudio valuta e notifica Davide.

### CP3 — Fine test suite

L'agente deve riportare i risultati completi:

| Suite | Risultato | Dettagli |
|-------|-----------|---------|
| Lint | ✅/❌ | |
| Typecheck | ✅/❌ | |
| Unit tests | ✅/❌ | N passed / M failed |
| E2E | ✅/❌ | |

Se qualcosa è ❌ → Claudio valuta se è bloccante o accettabile. Se bloccante, l'agente deve fixare prima di procedere.

### CP4 — Pronto per push

L'agente riporta:
- AC verificati (lista spuntata)
- PROJECT.md aggiornato
- Nessun file anomalo
- Riepilogo modifiche

---

## Gestione Anomalie

**Se l'agente si blocca o riporta un problema:**
1. Claudio blocca l'agente
2. Notifica Davide:
   ```
   ⚠️ [Issue #N] Anomalia al CP-N
   📌 <descrizione problema>
   🔧 <cosa ha provato l'agente>
   ❓ Come procedo?
   ```
3. Aspetta istruzioni di Davide prima di riprendere

**Se l'agente supera le 5 iterazioni senza convergere:**
→ Blocca e notifica Davide automaticamente

---

## Regole per l'agente

L'agente deve:
- Riportare a ogni checkpoint **prima di procedere**
- Non saltare checkpoint
- Non modificare file fuori scope del piano approvato
- Aggiornare `PROJECT.md` prima del push
- Non committare file di debug, `.env`, config sensibili

---

## Convenzioni codice

- Commit atomici con formato convenzionale (`feat:`, `fix:`, `improve:`)
- Branch: `feature/issue-N-slug`, `fix/issue-N-slug`, `improve/issue-N-slug`
- Niente commit diretti su `main`/`master`
- Test prima di ogni push
