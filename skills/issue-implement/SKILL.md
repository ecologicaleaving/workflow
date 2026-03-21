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

## 📋 Istruzioni di Test per Davide (obbligatorie nella PR)

Quando Claudio notifica Davide che la PR è pronta, **deve sempre includere una sezione "Come testare"** con istruzioni chiare e pratiche.

### Formato notifica PR (template)

```
✅ [Issue #N] PR pronta → <link PR>
📌 <summary 1-2 righe>

🧪 **Come testare:**
<lista passi concreti che Davide deve fare per verificare>

⚠️ **Prerequisiti** (se ci sono):
<env vars, dipendenze, setup necessario>

💡 **Cosa aspettarsi:**
<risultato atteso se tutto funziona>
```

### Regole

1. **Sempre presente** — anche se "non c'è nulla da testare", scrivi comunque cosa verificare (es. "build ok, lint ok, struttura cartelle corretta")
2. **Passi concreti** — comandi da copiare-incollare, URL da visitare, cose da cliccare
3. **Setup-first** — se serve clonare, installare deps, configurare env → metti tutto prima
4. **Risultato atteso** — Davide deve sapere cosa deve vedere se funziona
5. **Se è solo infra/setup** — istruzioni di verifica build/struttura, non "non c'è niente da testare"

---

## 📨 Messaggio per Ciccio (obbligatorio dopo PR)

Subito dopo aver notificato Davide della PR, Claudio **prepara anche il messaggio per Ciccio** con tutto il necessario per merge e deploy.

### Formato messaggio Ciccio (template)

```
🔧 [<repo>] PR #N — <titolo>

Ciao Ciccio, c'è la PR #N pronta per merge: <link PR>

**Da fare:**
1. Merge PR #N su main (deploy automatico su test)
<eventuali step aggiuntivi: config, secrets, servizi esterni>

**Prerequisiti / Config** (se ci sono):
<env vars da aggiungere, servizi da configurare, migrazioni DB da applicare>

Dopo il deploy, Davide testa su: https://test-<repo>.8020solutions.org

Grazie! 🙌
```

### Regole

1. **Sempre presente** — anche se è solo "merge e basta", scrivi comunque il messaggio
2. **Prerequisiti espliciti** — se servono env vars, secrets, config Supabase, servizi esterni → elenca tutto
3. **Migrazioni DB** — se ci sono, specifica come applicarle (file, ordine, comandi)
4. **Non dare per scontato** — Ciccio non ha il contesto della issue, il messaggio deve essere autosufficiente

### Flusso completo post-PR

1. Claudio notifica **Davide** con: PR + istruzioni di test + cosa aspettarsi
2. Claudio prepara **messaggio per Ciccio** con: PR + cosa fare per deploy + prerequisiti
3. Davide decide se mandare il messaggio a Ciccio o se serve altro prima

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

### Avvio monitor (WSL / Linux / macOS)

```bash
# Avvia in background subito dopo aver lanciato l'agente
# Lo script è in workflow/scripts/agent-monitor.sh

# Solo monitoring commenti issue (per subagent / sessions_spawn):
bash scripts/agent-monitor.sh ISSUE_N REPO &

# Monitoring completo con exec session (per exec background):
bash scripts/agent-monitor.sh ISSUE_N REPO SESSION_ID &
```

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
- Su Linux/WSL/VPS: usare `scripts/agent-monitor.sh` (bash)
- Su Windows: usare il blocco PowerShell sopra
