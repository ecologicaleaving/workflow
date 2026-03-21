# Skill: issue-implement

**Trigger:** Piano approvato, agente in fase di implementazione  
**Agente:** Claudio (supervisione) + Claude Code / Codex (esecuzione)  
**Versione:** 2.2.0

---

## Obiettivo

Supervisionare la lavorazione dell'agente tramite il **protocollo checkpoint vincolante**: l'agente non procede senza il via esplicito di Claudio. Notifica Davide a ogni step, interviene in caso di anomalie.

---

## Protocollo Checkpoint Vincolante

### Come funziona

1. L'agente completa uno step e **posta un commento sulla issue** con formato fisso
2. Claudio legge il commento e valuta
3. **Se ok** â†’ Claudio risponde sulla issue: `âœ… procedi`
4. **Se anomalia** â†’ Claudio risponde: `ðŸ”´ bloccato â€” <motivo>` + notifica Davide
5. L'agente **non procede** finchÃ© non riceve `âœ… procedi`

### Formato commento checkpoint (agente)

```
## âœ… Checkpoint N â€” <titolo>

**Stato:** completato

**Cosa Ã¨ stato fatto:**
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
âœ… procedi
```

**Blocco:**
```
ðŸ”´ bloccato
Motivo: <descrizione anomalia>
Istruzioni: <cosa deve fare l'agente>
```

---

## Checkpoint per tipo issue

### Feature / Improvement

| CP | Titolo | Cosa verifica Claudio |
|----|--------|----------------------|
| CP1 | Piano approvato | Piano copre tutti gli AC, file sensati, nessun rischio |
| CP2 | Fine iterazione N | Cosa implementato, test result, niente regressioni |
| CP3 | Test suite completa | Lint âœ…, Typecheck âœ…, Unit âœ…, E2E âœ… |
| CP4 | Pronto per push | AC verificati, PROJECT.md ok, nessun file anomalo |

### Bug

| CP | Titolo | Cosa verifica Claudio |
|----|--------|----------------------|
| CP1 | Root cause identificata | Causa chiara, approccio fix sensato |
| CP2 | Fix applicato | Fix mirato, test di regressione ok |
| CP3 | Test suite completa | Lint âœ…, Typecheck âœ…, Unit âœ…, E2E âœ… |
| CP4 | Pronto per push | AC verificati, PROJECT.md ok, nessun file anomalo |

---

## Gestione Anomalie

**Criteri anomalia:**
- Piano ignora degli AC
- Test falliti non risolti
- File modificati fuori scope
- PiÃ¹ di 5 iterazioni senza convergenza
- Comportamento inatteso o errori gravi

**Procedura anomalia:**
1. Claudio posta `ðŸ”´ bloccato` sulla issue con istruzioni
2. Notifica Davide:
   ```
   âš ï¸ [Issue #N] Anomalia al CP-N â€” <titolo>
   ðŸ“Œ <descrizione problema>
   ðŸ”§ <cosa ha fatto l'agente>
   â“ Come procedo?
   ```
3. Aspetta istruzioni di Davide prima di sbloccare l'agente

**Se l'agente supera 5 iterazioni senza convergere â†’ blocco automatico + notifica Davide**

---

## Notifiche a Davide (formato)

Ad ogni checkpoint Claudio notifica Davide su Telegram:

```
âœ… [Issue #N] CP-N â€” <titolo>
ðŸ“Œ <summary in 1-2 righe>
â­ï¸ Prossimo step: <cosa fa l'agente ora>
```

In caso di anomalia:
```
âš ï¸ [Issue #N] Anomalia CP-N â€” <titolo>
ðŸ“Œ <descrizione>
â“ <domanda / cosa serve da Davide>
```

---

## Convenzioni Agente

L'agente deve rispettare:
- Commit atomici: `feat:`, `fix:`, `improve:`, `docs:`, `chore:`
- Branch: `feature/issue-N-slug`, `fix/issue-N-slug`, `improve/issue-N-slug`
- Niente commit su `main`/`master`
- Niente `.env`, config sensibili, file di debug
- `PROJECT.md` aggiornato prima del push
