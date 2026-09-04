# CLAUDE.md — repo `workflow`

Questo repo è la **fonte di verità del flusso di lavoro** del team 8020 Solutions.
Le regole non stanno qui: stanno in **[`WORKFLOW.md`](WORKFLOW.md)** (ruoli, leggi
assolute, fasi, la card di Ascanio, il flusso come gira davvero) e nelle skill in
`skills/` (indice: [`skills/SKILLS.md`](skills/SKILLS.md)).

- All'avvio di ogni sessione: `git pull origin master` + `powershell -ExecutionPolicy Bypass -File scripts\sync.ps1`
  (copia le skill in `~/.claude/skills` e **ritira** quelle in `skills/RETIRED.txt`).
- Il ruolo dell'agente e le istruzioni personali di Davide vivono nel `CLAUDE.md` globale (`~/.claude/CLAUDE.md`), non qui.
- Solo Claudio modifica questo repo, su indicazione di Davide. Branch di default: `master` (il repo workflow non ha `beta`).
