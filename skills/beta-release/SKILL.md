---
name: beta-release
description: >
  Orchestrazione del ciclo di release beta: integra le feature testate nel branch `beta`
  (merge autonomo dopo CI verde, gestione conflitti), esegue il re-test aggregato, verifica
  che `beta` sia pubblicato sull'ambiente test su dati reali, e avvisa Davide che è pronta da
  testare. Il merge finale `beta`→`main` (prod) resta SEMPRE dietro `/approva` di Davide.
  Trigger: /beta-release [repo], o a fine di un'ondata di issue lavorate.
version: 2.0.0
---

# Skill: beta-release

**Trigger:** `/beta-release [repo]` · fine ondata (dopo `dev-loop` sulle issue ready)
**Agente:** Claudio — orchestra; delega implementazione/QA a subagenti

> Riferimento flusso: `FLUSSO.md` — punto 4 (su beta).

---

## Obiettivo

Portare un'ondata di feature **già testate** (ciascuna in PR verso `beta`, con CI verde) fino a
una **beta pubblicata su test su dati reali**, pronta perché Ascanio la provi. Poi consegnare a
Davide per il gate prod. È l'anello tra `dev-loop` (sviluppo per-issue) e il rilascio.

## Il pipeline completo (dove sta questa skill)

```
Ascanio crea issue (skill `ascanio`)
   │
   ▼  on-demand: Davide/Claudio "sviluppa le ready"
triage → dev-loop (dev in worktree, test, PR verso beta)      ← per-issue
   │
   ▼  ◀────────────── beta-release (QUESTA skill) ──────────────▶
1. merge autonomo delle PR verdi in `beta` (dopo CI)
2. re-test aggregato su `beta`
3. push su `beta` → deploy AUTOMATICO su test-maestro.8020solutions.org (DATI REALI)
4. avviso a Davide: "beta pronta da testare"
   │
   ▼  Ascanio testa su test-maestro (banner + conferma scritture) → dà l'ok a Davide  ← UMANO
   ▼  Davide `/approva`                                                                ← UMANO
merge `beta` → `main` → deploy PRODUZIONE
```

Due gate **umani**, non automatizzabili: Ascanio che valida la beta, Davide che autorizza la prod.

---

## Procedura

### Step 1 — Integra le PR verdi in `beta` (autonomo)
Per ogni PR di feature verso `beta` con **CI `Build & Deploy Test` verde** (`MERGEABLE/CLEAN`):
```bash
gh pr merge <PR> --repo ecologicaleaving/<repo> --merge --delete-branch=false
```
- Merge **autonomo** dopo test verdi: `beta` è branch di integrazione **non produttivo**, mergiarci non pubblica in prod. (Vedi [[project_beta_release_flow]].)
- **Conflitti**: se una PR diventa `CONFLICTING` (feature che toccano gli stessi file), riprendi il subagente che l'ha scritta (`SendMessage`) per fare `git merge origin/beta` + risolvere mantenendo ENTRAMBE le feature + ri-test + push. NON risolvere alla cieca.
- Se emerge un **flaky/regressione pre-esistente** che blocca la CI, fixalo con una PR mirata verso `beta` prima di proseguire.

### Step 2 — Re-test aggregato su `beta`
Spawna un subagente QA (worktree, `origin/beta`, `npm ci`) che gira la suite completa: `npm test`
(vitest) + `tsc --noEmit` + `npm run lint` + `npm run build` + `npm run e2e`. Deve distinguere i
fallimenti **noti/ambientali** (es. e2e onboarding/role-gating legati a ruolo utente) dalle
**regressioni reali**. Verdetto: `beta` pulito SÌ/NO. Se NO → fixa prima di procedere.

### Step 3 — Verifica il deploy su test (dati reali)
Il push su `beta` (dai merge dello Step 1) triggera `deploy-test.yml` che pubblica `beta` alla
**root di `https://test-maestro.8020solutions.org`** puntando ai **dati di produzione**
(`NEXT_PUBLIC_ENV=test` → banner "dati reali" + conferma su ogni scrittura rischiosa).
```bash
curl -s -o /dev/null -w "%{http_code}\n" https://test-maestro.8020solutions.org
```
Atteso 200. (Setup infra e protezioni: vedi issue #1302/#1303 e `docs/test-environment.md`.)

### Step 3.4 — Migration additive in prod, prima della prova (gap #1915)

test-maestro legge i dati di **produzione**: se la PR ha migration, la prova
dal vivo dello Step 3.5 non può riuscire finché lo schema di prod non le ha.
Per ogni file di migration **additivo e idempotente** della PR:

```bash
gh workflow run run-migration.yml --repo ecologicaleaving/<repo> --ref beta \
  -f migration=<file.sql> -f conferma=PRODUZIONE
gh run list --repo ecologicaleaving/<repo> --workflow run-migration.yml --limit 1
# verifica: la colonna/tabella nuova risponde 200 in prod
curl -s "$PROD_URL/rest/v1/<tabella>?select=<colonna>&limit=1" -H "apikey: $SERVICE_KEY" -H "Authorization: Bearer $SERVICE_KEY"
```

Vietato per DROP, rinomine, cambi di semantica, cron: quelli aspettano la
promozione (`FLUSSO.md` punto 4b e punto 6).

### Step 3.5 — Prova dal vivo, poi sposta la card di Ascanio (obbligatoria, non delegabile)

**Mai in Revisione senza averla provata tu.** Per ogni issue appena
mergiata in `beta`:

1. Verifica se ha una card `qa_tasks` collegata (issue tecniche non ne
   hanno, e qui lo step finisce):
   ```bash
   curl -s "$NEXT_PUBLIC_SUPABASE_URL/rest/v1/qa_tasks?github_issue_number=eq.<N>&select=id,title,stage" \
     -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY"
   ```
2. Provala dal vivo su `test-maestro.8020solutions.org` — login, impianto
   vero, il comportamento descritto dagli AC. Non a occhio sul diff. Se
   restano AC `[Campo]`/`[Azione]` aperti, la card **non** si sposta: sono
   lavoro di Ascanio, non prova tua.
3. Solo dopo aver visto che funziona:
   ```bash
   curl -s -X PATCH "$NEXT_PUBLIC_SUPABASE_URL/rest/v1/qa_tasks?id=eq.<id>" \
     -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
     -H "Content-Type: application/json" \
     -d '{"stage":"revisione","review_notes":"<cosa provare, in italiano comune>"}'
   ```
4. Lancia `npm run deps:schede` — calcola gli avvisi di dipendenza tra
   schede non ancora in produzione. Va lanciato **in questo momento**: è un
   giro notturno più esecuzioni a mano, e se non lo lanci qui l'avviso non
   compare proprio quando serve (l'incidente che l'ha introdotto).

Non rimandare "al prossimo giro" — l'8 issue rimaste mergiate ma mai provate
né spostate il 02/09/2026 sono nate esattamente da questo rimando, ondata
dopo ondata.

Il **reject** di Ascanio è un commento sulla card + rientro in `lavorazione`
(non uno stato separato).

### Step 4 — Avvisa Davide (una volta, a ondata completa)
```
✅ Beta pronta da testare — https://test-maestro.8020solutions.org
   Include: #NNNN, #NNNN, … (N feature)
   Dati REALI di produzione · banner + conferma scritture attivi
⏭️ Ascanio la testa → ti dà l'ok → tu /approva per il merge in prod.
```
La conferma di Ascanio arriva **fuori sistema** (a voce/Telegram) e la recepisce Davide.

### Step 5 — Gate prod (SOLO con /approva di Davide)

**⚠️ Cambiato il 24/07/2026 (maestroweb, issue #1478/#1483 — vedi `dev-loop-opus-sonnet` per
il contesto):** con il flusso merge-diretto-in-beta (Ascanio/Davide revisionano DOPO il merge,
non prima), `beta` contiene sempre un mix di issue già approvate su `/qa` (label `qa-approved`)
e issue ancora in revisione. **Mergiare l'intero `beta` in `main` porterebbe in produzione anche
codice non approvato** — non è più sicuro farlo, se il repo ha lo script di promozione selettiva.

**Se il repo ha `scripts/approva-promote.ts` (oggi solo maestroweb — verifica con
`ls scripts/approva-promote.ts` prima di procedere)**, usa quello al posto del merge intero:

```bash
# 1. Sempre un dry-run PRIMA del run reale — non salta mai questo passaggio
npx tsx scripts/approva-promote.ts --dry-run
# Controlla il report: quali issue PROMOSSE, quali ESCLUSE (non approvate), quali NON
# RISOLVIBILI (nessuna PR/issue collegata — es. commit di manutenzione senza "Closes #N").

# 2. Se ci sono commit "NON RISOLVIBILE": lo script si rifiuta di procedere (fail-safe
#    intenzionale, vedi issue #1478). Serve intervento umano — di solito basta collegare
#    quel commit a una issue: crea una issue leggera di tracciamento, aggiungi "Closes #N"
#    al body della PR originale, applica la label qa-approved alla issue di tracciamento
#    (il lavoro è già mergiato e verificato, non serve rivalidare gli AC), poi ripeti dal
#    dry-run. NON bypassare il fail-safe in altro modo.

# 3. Solo se il dry-run è pulito (nessun blocco, elenco promosse coerente con quanto atteso):
npx tsx scripts/approva-promote.ts
# Apre una PR verso main con SOLO i commit delle issue approvate.

# 4. Attendi CI verde sulla PR, poi mergia con --merge (MAI --squash — romperebbe
#    l'idempotenza patch-id dello script, causando ri-promozioni duplicate al giro dopo):
gh pr merge <PR> --repo ecologicaleaving/<repo> --merge
```

**Se il repo NON ha lo script** (repo diversi da maestroweb, o prima che venga esteso):
resta il flusso precedente — **Non** mergiare `beta`→`main` senza `/approva` esplicito (legge
assoluta):
```bash
gh pr create --base main --head beta --title "release(beta): …" --body "…Closes #…"
# attendi CI verde, poi:
gh pr merge <PR> --repo ecologicaleaving/<repo> --merge
```
Va bene solo se **tutte** le issue in `beta` sono già state approvate su `/qa` — verificalo a
mano prima di procedere se il repo non ha ancora il meccanismo selettivo.

In entrambi i casi: il merge in `main` triggera il deploy di **produzione** (`deploy.yml`). Poi
sposta le card → Done, verifica il deploy prod, e — se un'ondata conteneva **migration** —
assicurati che fossero additive e già applicate (vincolo beta→prod, vedi
[[project_beta_release_flow]]).

---

## Vincoli assoluti
- **Merge in prod solo con `/approva` di Davide.** Il merge autonomo vale SOLO per `beta`.
- Su test i dati sono **reali di produzione**: il codice beta ci scrive davvero. Le protezioni
  (banner + conferma scritture, #1303) riducono il rischio ma NON coprono i bug del codice beta.
- Una feature con **migration** non può andare in beta→prod se la migration non è già in prod.
- Se il repo ha `scripts/approva-promote.ts`: **mai** mergiare l'intero `beta` in un colpo solo —
  usa sempre lo script, sempre con `--dry-run` prima, sempre `--merge` mai `--squash` sul merge
  finale della PR generata.
