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

**Security Audit (obbligatorio):** Esegui la skill `security-audit` prima di procedere al push. Vedi `skills/security-audit/SKILL.md`.

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
- [ ] Curl test aggiunti a `tests/curl-tests.sh` (se la issue tocca API/route/endpoint)

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

## 📨 Post-PR: Merge e notifica Ciccio

### Flusso `/approva`

Quando Davide scrive `/approva`:
1. Claudio **mergia la PR direttamente** su main (`gh pr merge --merge --delete-branch`)
2. Il deploy parte automaticamente (CI/CD)
3. Claudio notifica Davide con conferma merge + URL produzione/test
4. Se ci sono prerequisiti infra (env vars, migrazioni DB, config) → Claudio prepara messaggio per Ciccio e lo propone a Davide

### Messaggio per Ciccio (solo se servono azioni infra)

```
🔧 [<repo>] PR #N mergiata — <titolo>

Ciao Ciccio, la PR #N è stata mergiata: <link PR>

**Azioni richieste:**
<env vars da aggiungere, migrazioni DB, servizi da configurare>

Grazie! 🙌
```

Se non servono azioni infra → nessun messaggio a Ciccio, il deploy è automatico.

### Weekly Tracking (obbligatorio dopo merge/chiusura)

Dopo ogni merge PR o chiusura issue, Claudio aggiunge una riga a `memory/weekly/current.md`:

```markdown
| YYYY-MM-DD | PR/Issue | <repo> | #N | <titolo> | ✅ merged/closed |
```

Non saltare mai questo step. Il file viene archiviato automaticamente ogni lunedì.

---
## Convenzioni Agente

L'agente deve rispettare:
- Commit atomici: `feat:`, `fix:`, `improve:`, `docs:`, `chore:`
- Branch: `feature/issue-N-slug`, `fix/issue-N-slug`, `improve/issue-N-slug`
- Niente commit su `main`/`master`
- Niente `.env`, config sensibili, file di debug
- `PROJECT.md` aggiornato prima del push

---

## 🔍 Agent Monitor (obbligatorio)

Vedi [agent-monitor.md](../references/agent-monitor.md) per istruzioni complete sull'avvio e configurazione del monitor.
