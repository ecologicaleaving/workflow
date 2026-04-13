# Skill: issue-research-rework

**Trigger:** Rework complicato dopo reject — serve analisi approfondita prima di implementare  
**Agente:** Claude Code  
**Versione:** 1.1.0

---

## Obiettivo

Analizzare un problema dopo reject ripetuti o complessi attraverso un processo strutturato: raccolta info dalla issue, intervista al tester (Davide), research nel codebase, e loop di domande/ricerche per convergere sulla root cause.

**Quando usarla:**
- Reject multipli sullo stesso bug (≥2 reject)
- Bug non riproducibile dall'agente ma confermato dal tester
- Problema che coinvolge flussi trasversali (startup, auth, cache, network)
- L'agente di implementazione non riesce a convergere

---

## Procedura

### Step 1 — Raccogli contesto dalla issue

Il supervisore raccoglie automaticamente:

1. **Storico reject** dalla issue (commenti con feedback)
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

### Step 2 — Intervista Davide

**Prima di lanciare qualsiasi agente**, il supervisore fa domande mirate a Davide per capire il problema dal punto di vista utente:

```
🔍 [Issue #N/<repo>] Preparo la research per il rework

Ho letto lo storico della issue. Per capire meglio il problema:

1. **Cosa succede esattamente?** (descrivi cosa vedi sullo schermo)
2. **Quando succede?** (al primo avvio? dopo logout? solo offline? sempre?)
3. **Cosa ti aspetti invece?** (comportamento corretto)
4. **Hai notato pattern?** (succede solo su certi device, con certi dati, ecc.)
```

**Regole:**
- Fai solo domande che NON puoi ricavare dalla issue
- Se la issue è già chiara → salta l'intervista e dillo a Davide
- Adatta le domande al tipo di bug (UI, performance, crash, dati)
- Massimo 4-5 domande, non interrogare

### Step 3 — Lancia agente research (round 1)

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

Lancia l'agente con il contesto raccolto (issue + feedback Davide):

```
Sei l'agente di research per il progetto <repo>.
Il repo è in /home/kreshos/.openclaw/workspace/<repo>, branch `pr-<PR_N>`.

**OBIETTIVO: Analisi rework PR #<PR_N> — <titolo issue>**

Questa PR ha avuto <X> reject. Il problema principale: <descrizione sintetica>.

**Storia reject:**
<lista reject con feedback sintetico>

**Feedback diretto dal tester (Davide):**
<risposte intervista step 2>

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
- Domande aperte (se ci sono dubbi che richiedono info dal tester o test specifici)

⚠️ NON modificare alcun file. Solo analisi.
```

**Parametri consigliati:**
- `model`: haiku (veloce, economico — research non richiede modelli pesanti)
- `runTimeoutSeconds`: 600 (10 min)
- `mode`: run

### Step 4 — Loop domande/ricerche (max 3 round)

Dopo il primo report, il supervisore valuta. Se ci sono **dubbi aperti**, avvia un loop:

**Round N (max 3):**

1. **Supervisore legge il report** dell'agente
2. **Se ci sono domande aperte** → le gira a Davide
3. **Se servono verifiche nel codice** → rilancia l'agente con domande specifiche
4. **Se il report è completo** → esci dal loop

```
🔍 [Issue #N] Research round N/3

L'agente ha trovato:
<sintesi findings>

Ha questi dubbi:
<domande per Davide>

<oppure>
Serve una verifica specifica nel codice:
<cosa deve controllare l'agente>
```

**Istruzioni per round successivi dell'agente:**

```
Continua l'analisi della PR #<PR_N>.

**Nuove informazioni da Davide:**
<risposte di Davide>

**Verifica richiesta:**
<cosa deve approfondire>

Aggiorna il report con i nuovi findings.
⚠️ NON modificare alcun file. Solo analisi.
```

**Criteri di uscita dal loop:**
- ✅ Root cause chiara e verificabile
- ✅ Piano di fix concreto (file + codice)
- ✅ Nessuna domanda aperta critica
- ⚠️ Raggiunto round 3 → esci comunque, presenta il meglio che hai

### Step 5 — Report finale a Davide

```
🔍 [Issue #N/<repo>] Analisi rework completata

📌 **Root cause:** <sintesi in 2-3 righe>

🔴 **Punti critici trovati:**
<lista numerata>

🔧 **Piano di fix proposto:**
<lista step con file specifici>

⚠️ **Rischi residui:**
<lista>

⏭️ Procedo con l'implementazione del fix? Scrivi /vai
```

**Allega il report come commento sulla issue per tracciabilità:**

```bash
gh issue comment <N> --repo ecologicaleaving/<repo> \
  --body "## 🔍 Report Research Rework\n\n<report completo>"
```

### Step 6 — Passa alla skill `issue-reject`

Con il report in mano, segui la skill `issue-reject` per l'implementazione del rework, passando all'agente implementatore il report come contesto aggiuntivo nel prompt.

---

## Note

- Questa skill è **complementare** a `issue-reject` — si usa PRIMA del rework quando la situazione è complessa
- Per reject semplici (1 reject, causa ovvia) → vai diretto con `issue-reject`
- Il supervisore NON implementa codice — se l'agente research fallisce, rilancialo
- Il loop max 3 round serve a evitare rabbit hole infiniti
- Se dopo 3 round la root cause non è chiara → escalate a Davide con tutto il contesto raccolto
