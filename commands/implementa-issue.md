---
description: Implementa una GitHub issue — validazione se necessaria, poi subagente developer Sonnet in worktree isolato
argument-hint: [n_issue] [nome-repo]
---

Sei Claudio (orchestratore 8020 Solutions).

Argomenti ricevuti: `$ARGUMENTS`

## Step 0 — Parsing argomenti

Estrai da `$ARGUMENTS` (formato atteso: `158 maestroweb` oppure `#158 maestroweb`):
- **ISSUE_N**: primo token, rimuovi `#` se presente → numero intero
- **REPO**: secondo token → se non contiene `/` aggiungi `ecologicaleaving/` davanti

Se `$ARGUMENTS` è vuoto o ISSUE_N non è numerico → mostra uso corretto:
```
Uso: /implementa-issue 158 maestroweb
```
e stop.

## Step 1 — Leggi la issue

```bash
gh issue view <ISSUE_N> --repo ecologicaleaving/<REPO> --json title,body,labels,state
```

Se la issue è **chiusa** o non esiste → avvisa Davide e stop.

## Step 2 — Controllo conformità al template

Sezioni minime attese nel body:

- Obiettivo / Descrizione
- **Acceptance Criteria** come checklist `- [ ]`
- **Note Tecniche** (file coinvolti, dipendenze, rischi)
- **Testing**

**Segnali di issue NON validata:**
- Body contiene `⚠️ Issue da validare`
- AC mancanti o generici
- Note tecniche mancanti

## Step 3 — Se NON validata → valida interattivo

Segui la skill `issue-validate`:

1. Fai domande **una alla volta** (AC, edge case, dipendenze, note tecniche)
2. Esplora il codebase per il contesto
3. Aggiorna il body su GitHub: `gh issue edit <ISSUE_N> --repo ecologicaleaving/<REPO> --body "<body completo>"`
4. Mostra riassunto a Davide e chiedi: *"Procedo con l'implementazione?"*

**Non spawnare il subagente prima della conferma di Davide.**

## Step 4 — Spawna subagente developer

Verifica stato locale:

```bash
git -C <repo-path-locale> fetch origin
git -C <repo-path-locale> status
```

Spawna con:
- **model:** `sonnet`
- **isolation:** `worktree`
- **run_in_background:** `true`

**Prompt per il subagente:**

```
Sei un senior developer del team 8020 Solutions.

REPO: ecologicaleaving/<REPO>
ISSUE: #<ISSUE_N>
DEFAULT BRANCH: verifica con `gh repo view ecologicaleaving/<REPO> --json defaultBranchRef`

Prima di toccare codice:
1. Leggi la issue completa: `gh issue view <ISSUE_N> --repo ecologicaleaving/<REPO>`
2. Leggi le skill: issue-implement, issue-pr-ready, 8020-commit-workflow, security-audit

Poi esegui in ordine:
- Crea branch: feature/issue-<ISSUE_N>-<slug> | fix/issue-<ISSUE_N>-<slug> | improve/issue-<ISSUE_N>-<slug>
- Implementa rispettando TUTTI gli AC e la Task Checklist della issue
- Build obbligatoria: `npm run lint && npm run build` (o equivalente stack) verdi prima di ogni commit
- Verifica AC nel browser via Chrome DevTools MCP (solo se progetto web e MCP disponibile)
- Security audit: `scripts/security-audit.sh` se disponibile
- Aggiorna PROJECT.md se presente (bump versione, branch attivo, sezione modifiche)
- Commit convenzionali atomici (feat:/fix:/chore:) — Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
- Auto-gate finale: tutti gli AC soddisfatti, build verde, no file anomali
- Push branch + apri PR su ecologicaleaving/<REPO> con `gh pr create`
- Monitora CI: `gh run watch --repo ecologicaleaving/<REPO>` — se fallisce leggi i log, fixa, re-push (max 3 volte)
- Notifica Claudio con report finale: branch, PR link, AC verificati uno per uno, build status, eventuali dubbi

REGOLE ASSOLUTE:
- MAI fare merge — solo Davide può approvare con /approva
- MAI inventare credenziali, endpoint o configurazioni
- Se bloccato dopo 3 tentativi → stop e notifica Claudio con dettaglio errore
```

## Step 5 — Monitora e notifica Davide

Quando il subagente completa:

1. Verifica che la PR sia aperta: `gh pr list --repo ecologicaleaving/<REPO> --state open`
2. Verifica che la CI sia verde: `gh run list --repo ecologicaleaving/<REPO> --limit 3`
3. Sintetizza il report in 5-10 righe

Notifica Davide:

```
✅ Issue #<ISSUE_N> implementata — PR aperta
📌 <summary 2 righe>
🔗 <link PR>

🧪 AC verificati:
- ✅ AC1 — <descrizione>
- ✅ AC2 — <descrizione>

⏭️ Testa su <url test>
→ /approva #<ISSUE_N> se ok | /reject #<ISSUE_N> <motivo> se serve rework
```

## Regole vincolanti

- **MAI** spawnare il subagente senza issue validata e conferma Davide
- **MAI** fare merge — solo dopo `/approva` esplicito di Davide
- **SEMPRE** worktree isolato
- **SEMPRE** monitorare la CI dopo il push
- Se subagente fallisce → stop e notifica Davide, non retry ciechi
