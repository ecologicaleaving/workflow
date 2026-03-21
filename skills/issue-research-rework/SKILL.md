# Skill: issue-research-rework

**Trigger:** Rework complicato dopo reject — serve analisi approfondita prima di implementare  
**Agente:** Claudio o Ciccio (chi supervisiona)  
**Versione:** 1.0.0

---

## Obiettivo

Lanciare un agente dedicato alla **ricerca e analisi** di un problema dopo reject ripetuti o complessi. L'agente NON implementa — produce solo un report con root cause, punti critici e piano di fix.

**Quando usarla:**
- Reject multipli sullo stesso bug (≥2 reject)
- Bug non riproducibile dall'agente ma confermato dal tester
- Problema che coinvolge flussi trasversali (startup, auth, cache, network)
- L'agente di implementazione non riesce a convergere

---

## Procedura

### Step 1 — Raccogli contesto reject

Prima di lanciare l'agente, il supervisore raccoglie:

1. **Storico reject** dalla issue (commenti con feedback Davide)
2. **Fix già tentati** (cosa è stato cambiato e perché non ha funzionato)
3. **AC non soddisfatti** (quali criteri falliscono ancora)
4. **Branch/PR attuale** con le modifiche in corso

```bash
# Storico commenti issue
gh issue view <N> --repo ecologicaleaving/<repo> --json comments \
  --jq '[.comments[] | select(.author.login != "github-actions") | {author:.author.login,body:.body[:300]}]'

# Se c'è una PR aperta
gh pr view <PR_N> --repo ecologicaleaving/<repo> --json comments \
  --jq '.comments[] | {author:.author.login,body:.body[:300]}'
```

### Step 2 — Lancia agente research

Clona il repo (se non presente) e checkout sul branch della PR:

```bash
# Se repo non presente
cd /home/kreshos/.openclaw/workspace
git clone https://github.com/ecologicaleaving/<repo>.git

# Checkout branch PR
cd <repo>
git fetch origin pull/<PR_N>/head:pr-<PR_N>
git checkout pr-<PR_N>
```

Lancia l'agente con queste istruzioni (adattare al progetto):

```
Sei l'agente di research per il progetto <repo>.
Il repo è in /home/kreshos/.openclaw/workspace/<repo>, branch `pr-<PR_N>`.

**OBIETTIVO: Analisi rework PR #<PR_N> — <titolo issue>**

Questa PR ha avuto <X> reject. Il problema principale: <descrizione sintetica>.

**Storia reject:**
<lista reject con feedback sintetico>

**Cosa devi fare:**
1. Leggi CLAUDE.md nella root del repo
2. Esplora il codebase in profondità — focus su:
   <lista aree rilevanti>
3. Analizza il flusso completo step by step
4. Identifica TUTTI i punti dove il problema può ancora verificarsi
5. Verifica se gli ultimi fix risolvono davvero o ci sono altri path problematici
6. Proponi soluzioni concrete con file e codice specifico

**OUTPUT RICHIESTO:**
- Root cause analysis dettagliata
- Lista di tutti i punti critici trovati
- Piano di fix con file specifici da modificare
- Rischi residui

⚠️ NON modificare alcun file. Solo analisi.
```

**Parametri consigliati:**
- `model`: sonnet (buon rapporto analisi/costo)
- `runTimeoutSeconds`: 600 (10 min — l'analisi richiede tempo)
- `mode`: run

### Step 3 — Valuta il report

Quando l'agente restituisce il report, il supervisore valuta:

**✅ Report utile se:**
- Root cause chiara e verificabile
- Punti critici specifici (file + riga + logica)
- Piano di fix concreto e non generico
- Rischi residui identificati

**⚠️ Report insufficiente se:**
- Root cause vaga ("potrebbe essere X o Y")
- Nessun riferimento a file/codice specifico
- Piano di fix generico senza dettagli implementativi

**Se insufficiente → rilancia con contesto più specifico o modello più potente (opus)**

### Step 4 — Notifica Davide con il report

```
🔍 [Issue #N/<repo>] Analisi rework completata

📌 **Root cause:** <sintesi in 2-3 righe>

🔴 **Punti critici trovati:**
<lista numerata>

🔧 **Piano di fix proposto:**
<lista step>

⚠️ **Rischi residui:**
<lista>

⏭️ Procedo con l'implementazione del fix? Scrivi /vai
```

### Step 5 — Passa alla skill `issue-reject`

Con il report in mano, segui la skill `issue-reject` per l'implementazione del rework, passando all'agente implementatore il report come contesto aggiuntivo.

---

## Note

- Questa skill è **complementare** a `issue-reject` — si usa PRIMA del rework quando la situazione è complessa
- Per reject semplici (1 reject, causa ovvia) → vai diretto con `issue-reject`
- Il supervisore NON implementa codice — se l'agente research fallisce, rilancialo
- Il report dell'agente va allegato come commento sulla issue per tracciabilità
