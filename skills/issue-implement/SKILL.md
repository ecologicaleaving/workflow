# Skill: issue-implement

**Trigger:** Piano approvato, agente in fase di implementazione  
**Agente:** Claudio (supervisione) + Claude Code / Codex (esecuzione)  
**Versione:** 2.1.0

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
| CP1 | Piano approvato | Piano copre tutti gli AC, file sensati, nessun rischio |
| CP2 | Fine iterazione N | Cosa implementato, test result, niente regressioni |
| CP3 | Test suite completa | Lint ✅, Typecheck ✅, Unit ✅, E2E ✅ |
| CP4 | Pronto per push | AC verificati, PROJECT.md ok, nessun file anomalo, sistema test pronto |

### Bug

| CP | Titolo | Cosa verifica Claudio |
|----|--------|----------------------|
| CP1 | Root cause identificata | Causa chiara, approccio fix sensato |
| CP2 | Fix applicato | Fix mirato, test di regressione ok |
| CP3 | Test suite completa | Lint ✅, Typecheck ✅, Unit ✅, E2E ✅ |
| CP4 | Pronto per push | AC verificati, PROJECT.md ok, nessun file anomalo, sistema test pronto |

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

## CP4 — Checklist completa "Pronto per PR"

Al CP4 l'agente ha finito. Prima di dare `✅ procedi` al push e apertura PR, Claudio verifica tutto in una volta sola.

**Codice:**
- [ ] Tutti gli AC della issue sono soddisfatti
- [ ] `PROJECT.md` aggiornato con le modifiche
- [ ] Nessun file anomalo (`.env`, debug, config sensibili)
- [ ] Lint ✅, Typecheck ✅, Test ✅

**Sistema test (verificato ora, non dopo):**
```bash
REPO="<repo>"
echo "=== CI pipeline ===" && \
  gh api repos/ecologicaleaving/$REPO/contents/.github/workflows/deploy.yml 2>/dev/null \
  | jq -r '.content' | base64 -d | grep -q "rsync\|ssh" && echo "✅ presente" || echo "❌ assente"
echo "=== Secrets ===" && gh secret list --repo ecologicaleaving/$REPO
echo "=== Sottodominio test ===" && \
  curl -s -o /dev/null -w "HTTP %{http_code}" "https://test-$REPO.8020solutions.org"
```

**DB (solo se la issue tocca schema/dati):**
- [ ] Migrazioni incluse nel branch (non applicate a mano)
- [ ] Migrazioni descritte nel commento PR

Se sistema test non è pronto (CI assente, secrets mancanti, sottodominio down) → **blocca, segnala a Ciccio** prima di procedere:
```
⚠️ [Issue #N] CP4 — Blocco pre-PR
📋 Problema: <CI assente / secrets mancanti / sottodominio irraggiungibile>
👉 @Ciccio: puoi sistemare prima che mergiamo?
```

Solo quando tutto è verde → `✅ procedi` all'agente per il push e apertura PR.

---

## Convenzioni Agente

L'agente deve rispettare:
- Commit atomici: `feat:`, `fix:`, `improve:`, `docs:`, `chore:`
- Branch: `feature/issue-N-slug`, `fix/issue-N-slug`, `improve/issue-N-slug`
- Niente commit su `main`/`master`
- Niente `.env`, config sensibili, file di debug
- `PROJECT.md` aggiornato prima del push

---

## 🔍 Agent Monitor (obbligatorio durante implementazione)

Dopo ogni `exec background` su un agente, avvia subito il monitor leggero.
Non aspettare — il monitor deve girare in parallelo all'agente per tutta la durata della lavorazione.

**Obiettivo:** ricevere notifiche proattive su checkpoint, errori e completamento, con costo token minimo.

### Come funziona

- Loop ogni 60s: legge output nuovo del processo
- Keyword matching senza LLM (zero token per la maggior parte dei check)
- Solo su output rilevante → spawn Haiku per summary (micro-costo)
- Si auto-termina quando il processo finisce

### Avvio monitor (PowerShell — Windows)

```powershell
$sessionId = "SESSION_ID"
$issueN = "ISSUE_N"
$repo = "REPO"
$lastOffset = 0
$silentMinutes = 0
$keywords = @("error", "failed", "fail", "exception", "bloccato", "blocked", "?", "ask", "done", "completed", "finished", "push", "checkpoint", "CP")

while ($true) {
    Start-Sleep -Seconds 60
    $silentMinutes++

    # Controlla se il processo è ancora vivo
    $status = openclaw process poll --session $sessionId 2>&1
    $alive = $status -notmatch "exited|not found|No session"

    # Leggi nuovo output
    $log = openclaw process log --session $sessionId --offset $lastOffset 2>&1
    if ($log) {
        $lastOffset += ($log | Measure-Object -Line).Lines
        $silentMinutes = 0

        # Keyword match (zero LLM)
        $hit = $keywords | Where-Object { $log -match $_ }
        if ($hit) {
            $summary = if ($log.Length -gt 500) {
                $log | claude --model claude-haiku-4-5 --print "Riassumi in max 2 righe cosa sta succedendo all'agente:" 2>&1
            } else {
                $log.Trim()
            }
            openclaw system event --text "👀 [Issue #$issueN/$repo] $summary" --mode now
        }
    }

    # Silenzio > 10 min → anomalia potenziale
    if ($silentMinutes -ge 10 -and $alive) {
        openclaw system event --text "⚠️ [Issue #$issueN/$repo] Agente silenzioso da 10+ minuti. Verificare." --mode now
        $silentMinutes = 0
    }

    # Processo terminato → notifica finale e stop
    if (-not $alive) {
        openclaw system event --text "🏁 [Issue #$issueN/$repo] Agente terminato. Controlla output e commenti sulla issue." --mode now
        break
    }
}
```

### Regole token

| Caso | LLM usato | Costo |
|------|-----------|-------|
| Nessun keyword trovato | Nessuno | 0 token |
| Keyword trovato, output < 500 chars | Nessuno | 0 token |
| Keyword trovato, output ≥ 500 chars | Haiku | Micro |
| Silenzio > 10 min | Nessuno | 0 token |

### ⚠️ Note

- Non usare modelli pesanti (Sonnet/Opus) per il monitor
- Il monitor non interagisce mai con l'agente, solo osserva
- Su Linux/VPS (Ciccio): sostituire la sintassi PowerShell con bash equivalente
