# workflow

Repo che distribuisce le skill Claude Code del team 8020 Solutions. Il flusso
completo — ruoli, fasi, comandi — è in **[`FLUSSO.md`](FLUSSO.md)**, unica
fonte di verità.

## Installazione

```bash
git clone https://github.com/ecologicaleaving/workflow.git
cd workflow
powershell -ExecutionPolicy Bypass -File scripts\sync.ps1
```

Copia `skills/` e `tools/` in `~/.claude/skills/` e ritira le skill non più
in uso (vedi `RETIRED.txt`). Da rilanciare a ogni sessione dopo `git pull
origin master` (regola in `~/.claude/CLAUDE.md`).

Branch di sviluppo di questo repo: `master`, protetto — si apre PR, si
mergia solo dopo revisione.
