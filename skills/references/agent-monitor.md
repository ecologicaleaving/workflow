# 🔍 Agent Monitor

Dopo ogni `exec background` su un agente (research o implementazione), avvia subito il monitor leggero.
Non aspettare — il monitor deve girare in parallelo all'agente per tutta la durata della lavorazione.

**Obiettivo:** ricevere notifiche proattive su checkpoint, errori e completamento, con costo token minimo.

## Come funziona

- Loop ogni 60s: legge output nuovo del processo con `process log`
- Keyword matching senza LLM (zero token per la maggior parte dei check)
- Solo su output rilevante → spawn Haiku per summary (micro-costo)
- Si auto-termina quando il processo finisce

## Avvio monitor (WSL / Linux / macOS)

```bash
# Avvia in background subito dopo aver lanciato l'agente
# Lo script è in workflow/scripts/agent-monitor.sh

# Solo monitoring commenti issue (per subagent / sessions_spawn):
bash scripts/agent-monitor.sh ISSUE_N REPO &

# Monitoring completo con exec session (per exec background):
bash scripts/agent-monitor.sh ISSUE_N REPO SESSION_ID &
```

## Avvio monitor (PowerShell — Windows)

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

## Regole token

| Caso | LLM usato | Costo |
|------|-----------|-------|
| Nessun keyword trovato | Nessuno | 0 token |
| Keyword trovato, output < 500 chars | Nessuno | 0 token |
| Keyword trovato, output ≥ 500 chars | Haiku | Micro |
| Silenzio > 10 min | Nessuno | 0 token |

## ⚠️ Note

- Non usare modelli pesanti (Sonnet/Opus) per il monitor
- Se il processo non risponde per >10 min → notifica Davide
- Il monitor non interagisce mai con l'agente, solo osserva
- Su Linux/WSL/VPS: usare `scripts/agent-monitor.sh` (bash)
- Su Windows: usare il blocco PowerShell sopra
