# Skills - Claude Code AI Skills

Questa directory contiene le **skills** per Claude Code, l'agente AI Senior Developer del team 80/20 Solutions.

Le skills sono moduli che estendono le capacita' di Claude Code con workflow specifici, procedure operative e knowledge di dominio. Vengono caricate automaticamente da Claude Code quando rileva il contesto appropriato.

---

## Skills Disponibili

| Skill | Descrizione |
|-------|-------------|
| `8020-commit-workflow` | Commit e push con convenzioni (Conventional Commits, branch check, PROJECT.md) |
| `8020-workflow` | Regole workflow per Ciccio (VPS) — Kanban, deploy, PR, APK |
| `create-issue` | Raccolta info e creazione issue GitHub strutturate |
| `create-prd` | Conversazione guidata per generare un PRD da brief/idea |
| `issue-approve` | Gestione `/approva` — label, card Deploy, notifica Ciccio |
| `issue-deploy-prod` | Merge PR e deploy in produzione (Ciccio) |
| `issue-deploy-test` | Deploy su ambiente test e notifica Davide (Ciccio) |
| `issue-done` | Checklist pre-PR, apertura PR, notifica |
| `issue-implement` | Supervisione agente con checkpoint vincolanti |
| `issue-pr-ready` | Unified post-implementation: pre-PR checklist, open PR, Kanban move, labels, notify Davide + prepare Ciccio message. Replaces issue-done → issue-deploy-test sequence |
| `issue-reject` | Gestione rework dopo reject di Davide |
| `issue-research-rework` | Research approfondita per reject complessi |
| `issue-start` | Avvio piano research-only su issue |
| `prd-to-issues` | Breakdown PRD in issue GitHub (max ~15 per PRD) |
| `preparazione-repo` | Setup repo per workflow 8020 |
| `repo-maintenance` | Manutenzione file di progetto |

---

## Come Installare le Skills su Claude Code

### Installazione manuale (una tantum per macchina)

Copiare la cartella della skill nella directory skills di Claude Code:

```bash
# Clona il workflow repo
git clone https://github.com/ecologicaleaving/workflow.git /tmp/workflow

# Copia la skill
cp -r /tmp/workflow/skills/8020-commit-workflow ~/.claude/skills/

# Verifica
ls ~/.claude/skills/8020-commit-workflow/
# -> SKILL.md  references/
```

### Installazione via script (consigliato)

```bash
curl -sSL https://raw.githubusercontent.com/ecologicaleaving/workflow/master/scripts/install-skills.sh | bash
```

> Lo script installa automaticamente tutte le skills dalla cartella `skills/` di questo repo nella directory `~/.claude/skills/` della macchina locale.

---

## Come Funzionano le Skills

Claude Code carica le skills automaticamente dalla directory `~/.claude/skills/`. Ogni skill ha:

```
nome-skill/
├── SKILL.md              # Istruzioni e trigger (obbligatorio)
└── references/           # Documentazione di approfondimento (opzionale)
    └── workflow-rules.md
```

Il file `SKILL.md` contiene nel frontmatter YAML la `description` che determina **quando** la skill viene attivata. Claude Code la legge e decide autonomamente se usarla in base al contesto della conversazione.

---

## Creare una Nuova Skill

Per aggiungere una skill al workflow del team:

1. Creare la cartella in `skills/nome-skill/`
2. Scrivere `SKILL.md` con frontmatter YAML (`name`, `description`) e istruzioni in markdown
3. Opzionale: aggiungere `references/` con documentazione dettagliata
4. Fare PR su questo repo con la nuova skill
5. Aggiornare questo file `SKILLS.md` con la descrizione della nuova skill
6. Ciccio mergera' e gli altri dev potranno installarla

### Template SKILL.md minimo
```markdown
---
name: nome-skill
description: >
  This skill should be used when [trigger condition].
  [What it does in 1-2 sentences].
---

# Nome Skill

## Quando si usa
...

## Procedura
...
```

---

## Aggiornare una Skill Esistente

Le skills sono versionated insieme al workflow repo. Per aggiornare:

```bash
cd /percorso/workflow
git pull origin master
cp -r skills/8020-commit-workflow ~/.claude/skills/
```

Oppure rieseguire lo script di installazione, che sovrascrive le versioni precedenti.

---

## Riferimenti

- [WORKFLOW_CLAUDE_CODE.md](../WORKFLOW_CLAUDE_CODE.md) - Workflow completo del Senior Developer
- [COMMIT_CONVENTIONS.md](../COMMIT_CONVENTIONS.md) - Standard commit messages
- [BRANCH_STRATEGY.md](../BRANCH_STRATEGY.md) - Git branching strategy
- [Claude Code Skills Documentation](https://github.com/anthropics/claude-code) - Docs ufficiali skills
