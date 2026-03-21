# Skill: issue-start

**Trigger:** Claudio avvia la fase di piano su una issue  
**Agente:** Claudio  
**Versione:** 2.2.0

---

## Obiettivo

Avviare la lavorazione di una issue: lanciare l'agente in modalità research-only, valutare il piano prodotto, aggiornare la issue con la task checklist.

---

## Procedura

### Step 0 — Verifica sistema deploy (obbligatorio prima di iniziare)

Prima di avviare qualsiasi lavorazione, Claudio verifica che il progetto abbia il sistema di deploy e deploy-test configurato. Meglio scoprirlo subito che alla fine.

```bash
REPO="<repo>"

echo "=== CI pipeline (deploy.yml) ==="
gh api repos/ecologicaleaving/$REPO/contents/.github/workflows/deploy.yml 2>/dev/null \
  | jq -r '.content' | base64 -d | grep -q "rsync\|ssh" && echo "✅ presente" || echo "❌ assente"

echo "=== Secrets GitHub ==="
gh secret list --repo ecologicaleaving/$REPO

echo "=== Sottodominio test ==="
curl -s -o /dev/null -w "HTTP %{http_code}" "https://test-$REPO.8020solutions.org"

echo "=== Sottodominio produzione ==="
curl -s -o /dev/null -w "HTTP %{http_code}" "https://$REPO.8020solutions.org"
```

**Valutazione:**

| Stato | Azione |
|-------|--------|
| ✅ CI + secrets + test + prod ok | Procedi con Step 1 |
| ❌ CI pipeline assente | Blocca — segnala a Ciccio, non si può procedere senza deploy automatico |
| ❌ Secrets infra VPS mancanti | Blocca — segnala a Ciccio per aggiungerli |
| ❌ Secrets specifici progetto mancanti | Blocca — notifica Davide per fornirli |
| ❌ Sottodominio test non raggiungibile | Blocca — segnala a Ciccio |
| ❌ Sottodominio prod non raggiungibile | Segnala a Ciccio — non blocca la lavorazione ma va risolto prima del deploy prod |

**Se qualcosa manca → notifica Davide e aspetta risoluzione prima di procedere:**
```
⚠️ [Issue #N/<repo>] Sistema deploy non pronto — lavorazione sospesa
📋 Problemi:
  - CI pipeline: presente / ❌ assente
  - Secrets: ok / ❌ mancanti: <lista>
  - test-<repo>.8020solutions.org: ✅ ok / ❌ non raggiungibile
  - <repo>.8020solutions.org: ✅ ok / ❌ non raggiungibile
👉 Ciccio: puoi sistemare?
```

**Solo quando tutto è verde → procedi con Step 1.**

---

### Step 1 — Sposta card → Todo

```bash
# Recupera item ID dalla issue
ITEM_ID=$(gh project item-list 2 --owner ecologicaleaving --format json \
  | jq -r '.items[] | select(.content.number == <N> and (.content.repository | contains("<repo>"))) | .id')

# Sposta in Todo
gh api graphql -f query='
mutation {
  updateProjectV2ItemFieldValue(input: {
    projectId: "PVT_kwHODSTPQM4BP1Xp"
    itemId: "'$ITEM_ID'"
    fieldId: "PVTSSF_lAHODSTPQM4BP1Xpzg-INlw"
    value: { singleSelectOptionId: "f75ad846" }
  }) { projectV2Item { id } }
}'
```

### Step 2 — Lancia agente in research-only

Istruzioni da passare all'agente (Claude Code o Codex):

```
Leggi la issue #N su ecologicaleaving/<repo>.
Clona o aggiorna il repo localmente.
Esplora il codebase in modo approfondito.

Produci un piano dettagliato che includa:
1. Comprensione del problema / obiettivo
2. File da toccare (con motivazione)
3. Approccio tecnico step-by-step
4. Rischi e possibili problemi
5. Task checklist (lista di step implementativi)
6. Stima complessità

⚠️ NON modificare alcun file in questa fase.
Riporta il piano completo e aspetta istruzioni prima di procedere.
```

### Step 3 — Valuta il piano (CP1)

Quando l'agente riporta il piano, Claudio valuta:

**✅ Piano ok se:**
- Copre tutti gli AC della issue
- I file identificati sono sensati
- Nessun approccio rischioso o out-of-scope
- Task checklist dettagliata e realistica

**⚠️ Anomalia se:**
- Piano ignora degli AC
- Vuole toccare file fuori scope
- Approccio tecnico sembra sbagliato
- Stima irrealistica

**Se ok:** Claudio notifica Davide e aspetta `/vai`:
```
✅ [Issue #N] Piano pronto
📌 <summary piano in 2-3 righe>
⏭️ Scrivi /vai per avviare l'implementazione
```

**Se anomalia:** blocca agente e notifica Davide:
```
⚠️ [Issue #N] Anomalia nel piano
📌 <descrizione problema>
❓ Come procedo?
```

⚠️ **Claudio NON avvia mai l'implementazione senza `/vai` esplicito di Davide.**

### Step 4 — Aggiorna issue con task checklist

```bash
# Aggiungi la task checklist come commento alla issue
gh issue comment <N> --repo ecologicaleaving/<repo> \
  --body "## 📝 Task Checklist (generata dall'agente)\n\n<checklist>"
```

### Step 4b — Attendi `/vai` di Davide

Claudio aspetta il comando `/vai` di Davide prima di procedere.
Non avviare l'implementazione, non rispondere all'agente, non spostare la card.

---

### Step 5 — Sposta card → InProgress

```bash
gh api graphql -f query='
mutation {
  updateProjectV2ItemFieldValue(input: {
    projectId: "PVT_kwHODSTPQM4BP1Xp"
    itemId: "'$ITEM_ID'"
    fieldId: "PVTSSF_lAHODSTPQM4BP1Xpzg-INlw"
    value: { singleSelectOptionId: "47fc9ee4" }
  }) { projectV2Item { id } }
}'
```

### Step 6 — Notifica Davide

```
✅ [Issue #N] CP1 — Piano approvato
📌 <summary piano in 2-3 righe>
⏭️ Agente al lavoro sull'implementazione
```

### Step 7 — Avvia Agent Monitor (obbligatorio)

Dopo aver lanciato l'agente in background, avvia subito il monitor leggero.
Vedi sezione **Agent Monitor** in fondo a questa skill.

---

## 🔍 Agent Monitor

Dopo ogni `exec background` su un agente (research o implementazione), avvia questo monitor.

**Obiettivo:** ricevere notifiche proattive senza polling manuale, con costo token minimo.

### Come funziona

- Loop ogni 60s: legge output nuovo del processo con `process log`
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
# Avvia in background subito dopo exec background dell'agente
# Sostituisci SESSION_ID e ISSUE_N con i valori reali

$sessionId = "SESSION_ID"
$issueN = "ISSUE_N"
$repo = "REPO"
$lastOffset = 0
$keywords = @("error", "failed", "fail", "exception", "bloccato", "blocked", "?", "ask", "done", "completed", "finished", "push")

while ($true) {
    Start-Sleep -Seconds 60

    # Controlla se il processo è ancora vivo
    $status = openclaw process poll --session $sessionId 2>&1
    $alive = $status -notmatch "exited|not found|No session"

    # Leggi nuovo output
    $log = openclaw process log --session $sessionId --offset $lastOffset 2>&1
    if ($log) {
        $lastOffset += ($log | Measure-Object -Line).Lines

        # Keyword match (zero LLM)
        $hit = $keywords | Where-Object { $log -match $_ }
        if ($hit) {
            # Output rilevante → notifica (Haiku per summary se output lungo)
            $summary = if ($log.Length -gt 500) {
                # Spawn Haiku solo se necessario
                $log | claude --model claude-haiku-4-5 --print "Riassumi in max 2 righe cosa sta succedendo all'agente:" 2>&1
            } else {
                $log.Trim()
            }
            openclaw system event --text "👀 [Issue #$issueN] Agente: $summary" --mode now
        }
    }

    # Processo terminato → notifica finale e stop
    if (-not $alive) {
        openclaw system event --text "🏁 [Issue #$issueN/$repo] Agente terminato. Controlla output." --mode now
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

### ⚠️ Note

- Non usare modelli pesanti (Sonnet/Opus) per il monitor
- Se il processo non risponde per >10 min → notifica Davide
- Il monitor non interagisce mai con l'agente, solo osserva
