---
name: create-issue
description: "Crea una GitHub issue strutturata per il team 8020/BeachRef e la aggiunge al backlog Kanban (senza label). Use when: (1) Davide vuole creare una nuova issue, (2) si usa il comando /create-issue [owner/repo], (3) si parla di aggiungere un task/feature/bug al backlog. Il flusso: legge PROJECT.md del repo, fa domande mirate, genera la issue con template standard, la aggiunge al progetto Kanban."
---

# Create Issue Skill

Crea issue GitHub strutturate e le aggiunge al backlog Kanban.

## Flusso

1. **Identifica il repo** — dall'invocazione `/create-issue owner/repo` o chiedi a Davide se mancante
2. **Leggi PROJECT.md** — fetch da GitHub raw per estrarre stack, URL test, branch strategy
3. **Fai le domande** — vedi sezione Questions Protocol
4. **Genera e crea la issue** — usa `gh issue create` con il body dal template
5. **Aggiungi al Kanban** — usa `gh project item-add`

## Questions Protocol

Fai SOLO le domande necessarie, in un unico blocco. Non inventare mai informazioni.

Domande sempre obbligatorie:
- Tipo: **feature** / **bug** / **fix** / **refactor** / **docs**?
- Titolo breve della issue (max 60 caratteri)?
- Obiettivo: cosa deve fare esattamente (2-3 righe)?
- Task: elenca i sotto-task (anche bullet generici se non li sai ancora)?
- Acceptance criteria: come verifichi che sia fatto? (elenca 1+ criteri concreti)
- Serve Playwright? (sì/no — se sì, descrivere il comportamento da testare)
- Out of scope: cosa NON va toccato?

Domande opzionali (solo se non deducibili da PROJECT.md):
- Stack / ambiente test specifico?
- Issue correlate?
- Link design/screenshot?

## Comandi

### Leggi PROJECT.md dal repo
```bash
gh api repos/{owner}/{repo}/contents/PROJECT.md --jq '.content' | base64 -d
```

### Crea la issue
```bash
gh issue create \
  --repo {owner}/{repo} \
  --title "{TIPO} {titolo}" \
  --body-file /tmp/issue-body.md
```

### Aggiungi al progetto Kanban (project ID: 2, owner: ecologicaleaving)
```bash
# Prima ottieni l'issue URL
ISSUE_URL=$(gh issue view {N} --repo {owner}/{repo} --json url -q .url)

# Poi aggiungila al progetto
gh project item-add 2 --owner ecologicaleaving --url "$ISSUE_URL"
```

## Template body issue

Vedi `assets/issue-template.md` — popolarlo con le risposte di Davide prima di creare la issue.

## Note

- **Mai aggiungere label** — Davide le assegna manualmente dopo
- **Branch name**: `feature/issue-{N}-{slug}` dove N è il numero assegnato da GitHub dopo la creazione
- Su Windows: `base64 -d` potrebbe non esistere → usa PowerShell: `[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($content))`
- Se PROJECT.md non esiste nel repo, segnalarlo e chiedere stack e URL test manualmente
