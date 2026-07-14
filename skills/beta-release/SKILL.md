---
name: beta-release
description: >
  Orchestrazione del ciclo di release beta: integra le feature testate nel branch `beta`
  (merge autonomo dopo CI verde, gestione conflitti), esegue il re-test aggregato, verifica
  che `beta` sia pubblicato sull'ambiente test su dati reali, e avvisa Davide che è pronta da
  testare. Il merge finale `beta`→`main` (prod) resta SEMPRE dietro `/approva` di Davide.
  Trigger: /beta-release [repo], o a fine di un'ondata di issue lavorate.
---

# Skill: beta-release

**Trigger:** `/beta-release [repo]` · fine ondata (dopo `issue-run` sulle issue ready)
**Agente:** Claude Code (Claudio) — orchestra; delega implementazione/QA a subagenti
**Versione:** 1.0.0

> Riferimento flusso: `WORKFLOW.md` — Fase 4 (integrazione beta → test → prod).

---

## Obiettivo

Portare un'ondata di feature **già testate** (ciascuna in PR verso `beta`, con CI verde) fino a
una **beta pubblicata su test su dati reali**, pronta perché Ascanio la provi. Poi consegnare a
Davide per il gate prod. È l'anello tra `issue-run` (sviluppo per-issue) e il rilascio.

## Il pipeline completo (dove sta questa skill)

```
Ascanio crea issue (skill `ascanio`)
   │
   ▼  on-demand: Davide/Claudio "sviluppa le ready"
triage → issue-run (dev in worktree, test, PR verso beta)     ← per-issue
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

### Step 4 — Avvisa Davide (una volta, a ondata completa)
```
✅ Beta pronta da testare — https://test-maestro.8020solutions.org
   Include: #NNNN, #NNNN, … (N feature)
   Dati REALI di produzione · banner + conferma scritture attivi
⏭️ Ascanio la testa → ti dà l'ok → tu /approva per il merge in prod.
```
La conferma di Ascanio arriva **fuori sistema** (a voce/Telegram) e la recepisce Davide.

### Step 5 — Gate prod (SOLO con /approva di Davide)
**Non** mergiare `beta`→`main` senza `/approva` esplicito (legge assoluta). Su `/approva`:
```bash
gh pr create --base main --head beta --title "release(beta): …" --body "…Closes #…"
# attendi CI verde, poi:
gh pr merge <PR> --repo ecologicaleaving/<repo> --merge
```
Il merge in `main` triggera il deploy di **produzione** (`deploy.yml`). Poi sposta le card → Done,
verifica il deploy prod, e — se un'ondata conteneva **migration** — assicurati che fossero
additive e già applicate (vincolo beta→prod, vedi [[project_beta_release_flow]]).

---

## Vincoli assoluti
- **Merge in prod solo con `/approva` di Davide.** Il merge autonomo vale SOLO per `beta`.
- Su test i dati sono **reali di produzione**: il codice beta ci scrive davvero. Le protezioni
  (banner + conferma scritture, #1303) riducono il rischio ma NON coprono i bug del codice beta.
- Una feature con **migration** non può andare in beta→prod se la migration non è già in prod.

## Changelog
- **v1.0.0** (2026-07-14): Prima versione — integrazione beta + re-test + deploy test su dati reali + avviso + gate prod. Estratta dal ciclo collaudato sulle 9 issue Ascanio.
