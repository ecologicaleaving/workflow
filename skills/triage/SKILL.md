---
name: triage
description: >
  Screening in batch delle issue in Backlog per portarle a "ready to code".
  Valuta ogni issue contro una Definition of Ready, classifica (ready / needs-decision /
  needs-split / blocked), sposta le pronte in Todo e raccoglie in un unico blocco le
  decisioni che spettano a Davide. Trigger: /triage [repo] (tutto il Backlog) o /triage #N
  (singola). Usala quando arriva un'ondata di issue già scritte (es. create da Ascanio) e
  serve decidere quali sono davvero lavorabili senza fare una sessione interattiva per ognuna.
---

# Skill: triage

**Trigger:** `/triage [repo]` (batch su tutto il Backlog) · `/triage #N` (singola)
**Agente:** Claude Code (Claudio)
**Versione:** 1.0.0

> Riferimento flusso: `WORKFLOW.md` — Fase 1.5 (tra `create-issue`/`ascanio` e `issue-validate`)

---

## Obiettivo

Portare le issue da "create" a **ready to code** con uno screening **in batch** e **leggero**.
Le issue già ricche di AC (tipiche di `ascanio`) non hanno bisogno della sessione-domande di
`issue-validate`: hanno bisogno di un **gate** che verifichi che siano davvero lavorabili e
che intercetti i **nodi aperti** prima che un dev ci parta sopra (evita rework).

Output della skill:
1. Un **report a tabella** con la classificazione di ogni issue
2. Le issue **ready** spostate in **Todo**
3. Un **unico blocco di domande** per Davide (tutte le decisioni aperte insieme, non 11 conversazioni)
4. Le epiche marcate `epic`, le bloccate lasciate in Backlog con nota

---

## Quando usare `triage` vs `issue-validate`

| Situazione | Skill |
|---|---|
| Issue **già scritta bene** (AC, edge case, riferimenti) — serve solo verificare che sia pronta | **`triage`** |
| **Ondata** di issue da smaltire in un colpo (es. batch di Ascanio) | **`triage`** |
| Issue **scarna/grezza** da costruire con Davide (domande + research + piano) | `issue-validate` |
| Serve il **piano tecnico** come commento prima di implementare | `issue-validate` / la fase research di `issue-resolver` |

`triage` **non** fa il piano tecnico. Le issue che passano il gate vanno in Todo; il
research/piano avviene in fase di implementazione (`issue-resolver`).

---

## Definition of Ready (DoR) — i 5 gate

Una issue è **🟢 READY** solo se supera **tutti** e 5 i gate:

1. **AC chiusi** — Acceptance Criteria presenti e *decisi*. ❌ se contengono
   `"da definire"`, `"o X o Y"`, `"da valutare in fase tecnica"` su un punto che
   cambia il comportamento (non un semplice edge case).
2. **Scope singolo** — è UNA cosa, non un'epica travestita. ❌ se ha più aree (frontend
   *e* backend *e* ricerca), una "Task checklist" lunga, o più feature indipendenti.
3. **Dipendenze risolte** — le issue linkate come prerequisito sono chiuse o non bloccanti.
   ❌ se dipende da una issue aperta necessaria a partire.
4. **Nessuna decisione a Davide** — nessuna scelta aperta di **prodotto / budget / business**
   che spetta a lui (es. "passare a un servizio a pagamento?", "esclusiva sì/no?").
5. **Target identificabile** — i componenti/file da toccare sono nominati o inferibili dal
   riuso citato. ❌ se non è chiaro *dove* si interviene.

### Le 4 classi

| Classe | Condizione | Cosa NON va |
|---|---|---|
| 🟢 **READY** | tutti e 5 i gate ok | — |
| 🟡 **NEEDS-DECISION** | solo il gate 1 o 4 fallisce, per **una** scelta di Davide | serve una risposta di Davide, poi è ready |
| 🟠 **NEEDS-SPLIT** | il gate 2 fallisce | è un'epica → va scomposta |
| 🔴 **BLOCKED** | il gate 3 fallisce | dipendenza aperta → aspetta |

Priorità di classificazione se più gate falliscono: **SPLIT > BLOCKED > NEEDS-DECISION**.
(Un'epica bloccata è comunque un'epica; una bloccata con decisione aperta è comunque bloccata.)

---

## Definition of Done (DoD) — obbligatoria su ogni issue che va in Todo

La DoR dice *quando si può iniziare*; la **DoD dice quando si può chiudere**. Ogni issue che
il triage porta in Todo deve avere questo blocco negli AC (il triage lo **inietta** se manca —
vedi Step 3). Il dev **non chiude** la issue finché non sono veri **entrambi** i tipi di test:

```markdown
## Definition of Done
- [ ] AC funzionali soddisfatti
- [ ] **Test automatici** scritti e verdi
      - logica pura (`src/lib/*`, moduli isomorfi) → unit test vitest
      - se l'area non ha ancora framework di test → il dev lo segnala esplicitamente, non salta in silenzio
- [ ] **Test UI da web interface con Chrome** — obbligatorio via `claude-in-chrome` (MCP
      `mcp__claude-in-chrome__*`): il dev apre l'app in Chrome (dev locale o test), esercita
      il flusso reale della issue, cattura **screenshot** e legge la **console** per errori, e
      **documenta l'esito** nel commento PR. Non basta che compili: va visto funzionare nel browser.
- [ ] `npm run lint` + `tsc --noEmit` puliti (lint ≠ type-check: girare entrambi)
- [ ] Curl test aggiornati se la issue tocca API/route (vedi `tests/curl-tests.sh`)
```

**Regola non derogabile:** i due test — **automatici** *e* **web interface** — sono **entrambi
obbligatori**. Una UISSUE non è "done" con i soli unit test, né con la sola verifica manuale.

> La *verifica* effettiva che la DoD sia stata rispettata avviene a fine lavoro
> (`issue-pr-ready` / `issue-done`, prima della PR). Il triage la **stabilisce**; le skill di
> chiusura la **controllano**.

---

## Procedura

### Step 0 — Raccogli le issue

**Batch** (`/triage [repo]`): tutte le issue in Backlog del Project, non ancora triate.

```bash
REPO="${1:-maestroweb}"
# Issue aperte in Backlog (via Project board — status Backlog)
gh issue list --repo ecologicaleaving/$REPO --state open --limit 100 \
  --json number,title,body,labels,createdAt \
  --jq 'sort_by(.createdAt) | reverse'
```

**Singola** (`/triage #N`): leggi solo quella issue.

```bash
gh issue view <N> --repo ecologicaleaving/$REPO --json number,title,body,labels
```

> Se non è chiaro quali issue siano "non ancora triate", considera quelle **senza label
> `ready` / `epic` / `blocked`** (le label che questa skill assegna).

---

### Step 1 — Valuta ogni issue contro i 5 gate

Per ogni issue, leggi il **body completo** e assegna una classe. Sii concreto: cita la riga
o il pezzo di AC che fa fallire il gate. Non essere pignolo sugli edge case — un `"da definire
in fase tecnica"` su un *edge case* non blocca; su un *comportamento centrale* sì.

Per **NEEDS-DECISION**, formula **la domanda esatta** da fare a Davide (secca, con opzioni se possibile).
Per **NEEDS-SPLIT**, abbozza in che sub-issue si spacchetta.
Per **BLOCKED**, indica **da quale issue** dipende.

---

### Step 2 — Report a Davide

Mostra una tabella unica:

```
## Triage <repo> — <N> issue

| # | Titolo | Classe | Nota |
|---|--------|--------|------|
| #1282 | Panel Stato rete zoom | 🟢 READY | — |
| #1287 | Batterie SOC | 🟡 DECISION | severità: max dei due segnali o separati? |
| #1290 | Onboarding 3 viste | 🟠 SPLIT | epica: 3 viste + ricerca cross-brand + decisione business |
| #1288 | Mappa onboarding | 🟡 DECISION | se Nominatim inaffidabile → Google Places (a pagamento)? |
...

🟢 READY: N   🟡 DECISION: N   🟠 SPLIT: N   🔴 BLOCKED: N
```

Poi, **sotto la tabella**, il blocco decisioni raccolte:

```
## Decisioni per te (una risposta e le sblocco)
1. #1287 — severità categoria batterie: max tra SOC e SOH, oppure due segnali separati?
2. #1288 — se Nominatim resta inaffidabile, autorizzi il passaggio a Google Places (a pagamento)?
...
```

---

### Step 3 — Azioni Kanban + label

**🟢 READY** → **inietta la DoD** (se manca) → sposta in **Todo** + label `ready`:

```bash
# 1. Se il body non contiene già "## Definition of Done", appendilo agli AC
gh issue edit <N> --repo ecologicaleaving/<repo> --body "<body + blocco Definition of Done>"
# 2. Sposta e marca
./scripts/kanban-move.sh <N> <repo> Todo
gh issue edit <N> --repo ecologicaleaving/<repo> --add-label ready
```

⚠️ **Nessuna issue va in Todo senza il blocco Definition of Done** (con i due test:
automatici + web interface). È la parte che rende il triage utile: il dev trova l'obbligo
test già scritto, non lo deve ricordare.

**🟠 NEEDS-SPLIT** → label `epic`, resta in Backlog, proponi le sub-issue a Davide
(crearle con `create-issue`/`ascanio` **solo dopo suo ok** — non spacchettare in autonomia):

```bash
gh issue edit <N> --repo ecologicaleaving/<repo> --add-label epic
```

**🔴 BLOCKED** → resta in Backlog, label `blocked`, commenta la dipendenza:

```bash
gh issue edit <N> --repo ecologicaleaving/<repo> --add-label blocked
gh issue comment <N> --repo ecologicaleaving/<repo> --body "🔴 Blocked: dipende da #<M> (aperta)."
```

**🟡 NEEDS-DECISION** → **non muovere** ancora. Aspetta le risposte di Davide (Step 4).

> Se una label non esiste nel repo, creala:
> `gh label create ready --repo ecologicaleaving/<repo> --color 0e8a16 -d "Triage: pronta a lavorare"`
> `gh label create blocked --repo ecologicaleaving/<repo> --color b60205 -d "Triage: dipendenza aperta"`
> (`epic` di solito esiste già)

> ⚠️ **Gotcha spostamento card (dal collaudo 2026-07-13):** il Project 80/20 (`PVT_kwHODSTPQM4BP1Xp`)
> ha **>300 item**. Se sposti via `gh project item-edit`, recupera gli item id con
> `gh project item-list 2 --owner ecologicaleaving --limit 2000` (NON 100/300, o le issue
> recenti restano fuori dal mapping e il move **fallisce in silenzio** con id vuoto).
> **Verifica sempre lo status dopo il move** (rileggi `.status` dell'item). In alternativa usa
> `./scripts/kanban-move.sh <N> <repo> Todo` dal workflow repo. Campi: Status field
> `PVTSSF_lAHODSTPQM4BP1Xpzg-INlw`, opzioni Backlog `2ab61313` · Todo `f75ad846`.

> ⚠️ **Gli ID qui sopra sono di `ecologicaleaving`.** Ogni org ha il suo board, e
> su un repo di un'altra org quel numero non esiste: `gh` risponde *"Could not
> resolve to a ProjectV2 with the number 2"*.
>
> | Organizzazione | Board | Numero | Project ID |
> |---|---|---|---|
> | `ecologicaleaving` | Development Hub | `2` | `PVT_kwHODSTPQM4BP1Xp` |
> | `80-20Solutions` | TunedIn | `3` | `PVT_kwDODt_H1s4BhfqB` |
>
> Per un board non in tabella non cercare gli ID a mano: la skill `issue-start`
> (STEP 3) ha una query che li ricava dalla card stessa. E un repo senza board
> non blocca il triage — segnalalo e prosegui.

---

### Step 4 — Chiudi le NEEDS-DECISION

Quando Davide risponde alle domande del blocco:

1. **Aggiorna gli AC** della issue con la decisione presa **+ inietta la DoD**:
   ```bash
   gh issue edit <N> --repo ecologicaleaving/<repo> --body "<body con AC chiuso + Definition of Done>"
   ```
2. **Sposta in Todo** + label `ready` (come le READY dello Step 3).
3. Se la decisione impatta **issue collegate** (stessa epic/area), segnalalo e proponi
   l'aggiornamento — coerente con `issue-validate` Step 1c.

---

### Step 5 — Notifica finale

```
✅ Triage <repo> completato
🟢 N pronte → Todo: #.., #.., #..
🟡 N in attesa di tua decisione (blocco domande sopra)
🟠 N epiche da scomporre: #.., #..
🔴 N bloccate: #.. (dip. #..)

⏭️ Rispondi alle domande per sbloccare le gialle. Le verdi sono lavorabili ora (/implementa-issue #N).
```

---

## Note

- `triage` **non implementa** e **non fa il piano**. Sposta al massimo in Todo.
- `triage` **non crea** sub-issue in autonomia: propone lo split, poi serve l'ok di Davide.
- Non ri-triare issue già marcate `ready`/`epic`/`blocked` salvo richiesta esplicita.
- Le stime di effort non interessano a Davide (come in `issue-validate`): niente story point,
  al massimo un S/M/L indicativo nel report se utile a decidere l'ordine.

---

## Changelog

- **v1.2.0** (2026-07-13): Test UI vincolati a Chrome (`claude-in-chrome`). Aggiunto gotcha spostamento card (Project >300 item → `--limit 2000` + verifica status; move falliva in silenzio). Emerso dal collaudo sulle 11 issue di Ascanio.
- **v1.1.0** (2026-07-13): Aggiunta Definition of Done standard iniettata su ogni issue → Todo: test automatici **e** web interface entrambi obbligatori.
- **v1.0.0** (2026-07-13): Prima versione — screening batch DoR, classi ready/decision/split/blocked, ready→Todo.
