---
description: Applica il workflow 8020 per implementare una GitHub issue (validazione se necessaria + subagente developer Sonnet in worktree isolato)
argument-hint: [n_issue] [owner/repo]
---

Sei Claudio (orchestratore). Applica il workflow 8020 per implementare la issue **#$1** del repo **$2**.

## Step 0 — Validazione input

Se `$1` è vuoto o non numerico, o `$2` non è nel formato `owner/repo`:
- Mostra l'uso corretto: `/implementa-issue 129 ecologicaleaving/maestroweb`
- Stop.

Se `$2` non è passato ma siamo in un contesto progetto chiaro (es. cartella corrente è una repo clonata), chiedi conferma a Davide: *"Uso il repo X dedotto dalla cartella corrente?"*. Altrimenti stop.

## Step 1 — Leggi la issue

```bash
gh issue view $1 --repo $2 --json title,body,labels,state,projectItems
```

Se la issue è **CLOSED** o non esiste → avvisa Davide e stop.

## Step 2 — Controllo conformità al template workflow

Il body della issue deve essere conforme al template corrispondente in `~/.claude/skills/` o nel workflow repo (`templates/issue-improvement.md`, `templates/issue-feature.md`, `templates/issue-bug.md`).

Sezioni attese minime:
- Obiettivo / Descrizione breve
- **Acceptance Criteria** come checklist
- **Note Tecniche** (file coinvolti, dipendenze, rischi)
- **Testing**
- **Checkpoint** CP1-CP4
- **Task Checklist**
- **Info Issue** (Repo, Tipo, Agente, Branch)

**Segnali di issue NON validata:**
- Body contiene `⚠️ Issue da validare` o `/issue-validate`
- Mancano AC espliciti
- Mancano Note Tecniche
- Mancano Checkpoint

## Step 3 — Se issue NON validata → avvia `issue-validate` interattivo

Segui la skill `issue-validate` (in `~/.claude/skills/issue-validate/SKILL.md` o nel workflow repo):

1. Fai le domande **una alla volta** (AC, edge case, dipendenze, note tecniche, priorità). Adatta al tipo bug/feature/improvement. Skippa quelle già chiare dal contesto.
2. Per ogni risposta, aggiorna il tuo piano interno.
3. Research: esplora il codebase per capire il contesto e confermare il piano.
4. Aggiorna il body della issue su GitHub con il template completo via `gh issue edit $1 --repo $2 --body "<body completo>"`.
5. Mostra a Davide un riassunto di 2-3 righe + link issue + chiedi conferma esplicita *"procedo con l'implementazione?"*.

**NON spawnare il subagente prima che Davide confermi.** Se conferma → Step 4. Se no → fermati.

## Step 4 — Se issue validata → spawna subagente developer

Verifica stato repo locale:
```bash
cd <repo-path-locale>
git fetch origin
git status
```

Se sono presenti uncommitted changes o branch in-progress non correlati → usa `isolation: worktree` (obbligatorio) per non interferire.

Spawna il subagente con questi parametri:
- **subagent_type:** `Claudio` (se presente, altrimenti generico developer del workflow)
- **model:** `sonnet`
- **isolation:** `worktree`
- **run_in_background:** `true`

Il prompt del subagente deve includere:
1. Riferimento completo a issue e repo (`gh issue view $1 --repo $2` come prima cosa da fare)
2. Obbligo di leggere le skill `issue-start`, `issue-implement`, `issue-done`, `8020-commit-workflow` prima di toccare codice
3. Branch naming: `feature/issue-$1-<slug>`, `improve/issue-$1-<slug>`, o `fix/issue-$1-<slug>` in base alla label
4. Partire da `origin/main` aggiornato (il default branch è **`main`**, non `master`, per progetti ecologicaleaving — verifica con `gh repo view $2 --json defaultBranchRef`)
5. Rispettare **tutti** gli AC e la Task Checklist dichiarati nel body validato
6. `npm run lint` + `npm run build` (o equivalente dello stack) verdi prima di ogni commit
7. Aggiornare PROJECT.md (se esiste) con sezione "Modifiche Recenti — Issue #$1" in cima, bump versione coerente, branch attivo
8. Commit convenzionali atomici per task logici, trailer `Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>`
9. **STOP prima del `git push`. NON aprire PR. NON fare merge.** Davide autorizza a valle
10. Report finale max 400 parole: branch, commit (hash+subject), file toccati, build/lint stato, AC checked one-by-one, Task checklist, decisioni prese, dubbi/domande per Davide

## Step 5 — Notifica Davide al completamento

Alla notifica completamento del subagente:
1. Sintetizza il report del subagente in 5-10 righe
2. Presenta AC realizzati vs residui
3. Presenta dubbi/domande esplicite
4. Chiedi autorizzazione per: push branch + apertura PR

Se Davide autorizza push/PR:
- Push del branch
- Apertura PR con template: title conforme conventional commit, body con Summary, Test plan, `Closes #$1`, trailer Claude
- Base branch: default del repo (di solito `main`)

## Regole vincolanti

- **MAI** spawnare il subagente se issue non validata senza conferma esplicita di Davide
- **MAI** fare push / apertura PR / merge automaticamente senza autorizzazione esplicita
- **MAI** inventare informazioni (credenziali, endpoint, API key)
- **SEMPRE** worktree isolato se il repo ha lavori in corso
- **SEMPRE** controllo conformità template prima di procedere
- Se il subagente fallisce o si blocca → stop e notifica, non insistere con retry ciechi
