---
name: issue-rework-fast
version: 1.0.0
description: >
  Fix diretto da orchestratore (Claudio o Ciccio) per problemi di CI/deploy
  risolvibili in poche righe, senza coinvolgere l'agente dev originale.
  Usata quando il problema è infrastrutturale/config e non riguarda logica di business.
triggers:
  - "ci fallita"
  - "build fallita"
  - "fix ci"
  - "issue-rework-fast"
  - "sistemalo tu"
  - "fix rapido"
---

# Issue Rework Fast — Fix Diretto dell'Orchestratore

Questa skill è per **Claudio** (PC) o **Ciccio** (VPS) quando:
- La CI è rotta per un motivo tecnico/config (non logica di business)
- Il fix richiede poche righe (workflow yml, dipendenza mancante, path errato, env var)
- Non ha senso rispedire il lavoro all'agente dev per una cosa banale

> ⚠️ **NON usare questa skill se:**
> - Il fix tocca logica applicativa o AC dell'issue
> - Il problema è ambiguo o richiede analisi approfondita
> - Hai dubbi → usa `issue-reject` e passa il feedback all'agente dev

---

## STEP 0 — Valuta se è un "fast fix"

Prima di procedere, rispondi a queste domande:

| Domanda | Fast fix? |
|---------|-----------|
| Il problema è in CI/CD, config, dipendenze, path? | ✅ Sì |
| Il fix è ≤ 10-15 righe di codice/config? | ✅ Sì |
| Non tocca logica di business o AC dell'issue? | ✅ Sì |
| Puoi verificare il fix senza ambiente dev completo? | ✅ Sì |

Se anche una sola risposta è ❌ → **non usare questa skill**, usa `issue-reject`.

---

## STEP 1 — Analizza il problema

Leggi i log della CI fallita:

```bash
gh run list --repo <owner/repo> --limit 5 --json status,conclusion,name,createdAt,url
gh run view <run-id> --repo <owner/repo> --log-failed
```

Identifica chiaramente:
- Quale step ha fallito
- Il messaggio di errore esatto
- Il file da modificare

---

## STEP 2 — Clona il branch e applica il fix

```bash
# Clona solo il branch (più veloce)
git clone --branch <branch-name> --single-branch \
  "https://<TOKEN>@github.com/<owner/repo>.git" /tmp/<repo>-fix

cd /tmp/<repo>-fix

# Applica il fix
# (modifica il file direttamente)
```

**Tipi di fix comuni:**

| Problema | Fix tipico |
|----------|------------|
| `npm install` mancante in CI | Aggiungi step `npm install` prima del build |
| Dipendenza mancante in `package.json` | `npm install <pkg> --save` o aggiungi manualmente |
| Path errato in workflow | Correggi `working-directory` o path artifact |
| Env var mancante | Aggiungi `env:` al job/step nel workflow |
| Permessi mancanti | Aggiungi `permissions:` al job |
| `flutter pub get` mancante | Aggiungi step prima del build Flutter |

---

## STEP 3 — Commit e push

```bash
git config user.name "Claudio"   # oppure "Ciccio" se su VPS
git config user.email "kresh@boilerapp.dev"

git add <file-modificato>
git status  # verifica sempre prima di committare

git commit -m "fix(ci): <descrizione breve del problema

Causa: <root cause>
Fix: <cosa è stato cambiato>

Fixes CI run <url-run-fallita>"

git push "https://<TOKEN>@github.com/<owner/repo>.git" <branch-name>
```

---

## STEP 4 — Commenta sull'issue

```bash
gh issue comment <N> --repo <owner/repo> \
  --body "🔧 **Fix CI/deploy applicato da <Claudio|Ciccio>.**

**Problema:** <descrizione errore>
**Fix:** <cosa è stato cambiato>
**Commit:** <sha-breve>

CI ripartita automaticamente. In attesa esito build."
```

---

## STEP 5 — Monitora la CI

Aspetta il completamento della nuova run:

```bash
# Aspetta qualche minuto poi controlla
gh run list --repo <owner/repo> --limit 3 --json status,conclusion,name,createdAt
```

**Se CI verde** → procedi con `issue-deploy-test` normalmente (card rimane in **Test**)

**Se CI ancora rossa** → valuta:
- È ancora un problema tecnico banale? → applica secondo fix (max 1 iterazione)
- È qualcosa di più complesso? → usa `issue-reject` e passa all'agente dev con log completi

---

## STEP 6 — Notifica Davide (solo se CI verde)

Aggiorna Davide che il fix è stato applicato e la build è ora verde, con link all'APK/artifact di test.

> Non notificare se la CI è ancora rotta — prima risolvi o scala.

---

## Checklist

- [ ] Valutato che è un fast fix (STEP 0 tutto ✅)
- [ ] Log CI letti e root cause identificata chiaramente
- [ ] Fix applicato su branch corretto (non master)
- [ ] Commit convenzionale con causa e fix nel body
- [ ] Commento sull'issue con spiegazione
- [ ] Card Kanban **NON spostata** (rimane dove era)
- [ ] CI monitorata → verde prima di notificare Davide

---

## Riferimento rapido

**Project ID**: `PVT_kwHODSTPQM4BP1Xp`
**Status Field ID**: `PVTSSF_lAHODSTPQM4BP1Xpzg-INlw`

| Colonna | Option ID |
|---------|-----------|
| Backlog | `2ab61313` |
| Todo | `f75ad846` |
| In Progress | `47fc9ee4` |
| Test | `1d6a37f9` |
| Review | `03f548ab` |
| Deploy | `37c4aa50` |
| Done | `98236657` |
