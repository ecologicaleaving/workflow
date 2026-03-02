---
name: issue-review
version: 1.0.0
description: >
  Procedura di rework dopo un /reject di Davide. L'agente dev legge
  questa skill quando riprende una issue rifiutata. Copre: lettura
  feedback, analisi root cause, fix mirato, verifica AC, poi rimanda
  a issue-done per commit e PR aggiornata.
triggers:
  - "rework issue"
  - "fix dopo reject"
  - "issue in review"
  - "riprendi issue"
---

# Issue Review — Rework dopo /reject

Leggi questa skill quando riprendi una issue che Davide ha rifiutato.

---

## STEP 1 — Leggi tutto il contesto

```bash
# Leggi l'issue completa con tutti i commenti
gh issue view <N> --repo <owner/repo> --comments
```

Cerca e leggi con attenzione:
1. **Gli AC originali** — cosa doveva fare la issue
2. **Il commento di reject** — quale AC ha fallito, cosa non funzionava
3. **I commenti precedenti** — storico di eventuali rework già fatti

> ⚠️ Non iniziare a toccare codice finché non hai capito esattamente
> cosa non andava. Un fix basato su un'analisi superficiale produce
> un secondo reject.

---

## STEP 2 — Checkout branch esistente

```bash
git checkout feature/issue-<N>-<slug>
git pull origin feature/issue-<N>-<slug>
```

**Non creare un nuovo branch** — riprendi sempre quello esistente.
La PR è già aperta: ogni nuovo push aggiornerà automaticamente la PR.

---

## STEP 3 — Analizza la root cause

Prima di modificare qualsiasi file:

- Rileggi il codice che hai scritto nel rework precedente
- Identifica **perché** l'AC ha fallito — non indovinare
- Scrivi (mentalmente o in un commento) la causa e il fix che intendi applicare

Se la root cause non è chiara:
- Rileggi i test esistenti
- Aggiungi un test che riproduce il problema segnalato da Davide
- Fai fallire il test → questo ti conferma la root cause

---

## STEP 4 — Applica il fix

- Fix **mirato**: tocca solo i file necessari per soddisfare l'AC fallito
- Non riscrivere parti funzionanti che non c'entrano con il reject
- Aggiorna o aggiungi test che dimostrano il fix

---

## STEP 5 — Verifica AC e DoD

Rileggi la skill **`issue-done`** da STEP 1 in poi.

In particolare:
- Verifica **ogni AC** uno per uno — inclusi quelli già passati (assicurati di non aver introdotto regressioni)
- Applica la **Definition of Done** completa
- Max 3 iterazioni fix → se ancora bloccato, segnala all'orchestratore

---

## STEP 6 — Aggiorna il commento sull'issue

Prima di pushare:

```bash
gh issue comment <N> --repo <owner/repo> \
  --body "🔧 **Rework completato.**

**Cosa è cambiato:**
<descrizione del fix applicato>

**Root cause:**
<spiegazione breve di perché l'AC aveva fallito>

**AC verificati:**
- [x] AC1: <descrizione> ✅
- [x] AC2: <descrizione> ✅

Test: <N> verdi, nessuna regressione."
```

---

## STEP 7 — Push e aggiorna PR

```bash
git push origin feature/issue-<N>-<slug>
```

La PR esistente si aggiorna automaticamente.
Aggiorna anche il body della PR se necessario:

```bash
gh pr edit <PR_N> --repo <owner/repo> \
  --body "<body aggiornato con descrizione fix rework>"
```

---

## ✅ Checklist

- [ ] Issue letta con tutti i commenti (feedback + storico)
- [ ] Root cause identificata (non "fix a tentativi")
- [ ] Fix mirato — solo i file necessari
- [ ] Tutti gli AC verificati (inclusi quelli precedenti)
- [ ] DoD completo (vedi issue-done STEP 1b)
- [ ] Commento sull'issue con root cause e AC verificati
- [ ] Push sul branch esistente
- [ ] PR aggiornata

---

## ⏭️ Cosa succede dopo

Leggi **`issue-done`** da STEP 2 in poi (PROJECT.md, commit, label).
Poi Claudio/Ciccio leggeranno **`issue-deploy-test`** per un nuovo giro di test.
