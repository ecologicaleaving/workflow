# AGENTS.md — Project Workflow

## ⚠️ SESSION STARTUP — MANDATORY

Before doing anything else, complete these 3 steps in order:

### 1. Sync workflow
```bash
git submodule update --remote .workflow
```
*(Windows PowerShell: `git submodule update --remote .\.workflow`)*

> If the submodule is not yet initialized:
> ```bash
> git submodule update --init --remote .workflow
> ```

### 2. Read the full workflow
`.workflow/AGENTS.md`

Contains all team operational rules: branch strategy, commit conventions,
kanban workflow, roles, procedures. Do not improvise — everything is documented there.

### 3. Read the project context
`PROJECT.md`

Contains stack, URLs, deploy status, active backlog.

---

Do NOT proceed with any work before completing these 3 steps.
