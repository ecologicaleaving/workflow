# AGENTS.md — Project Workflow

## ⚠️ SESSION STARTUP — MANDATORY

Before doing anything else, complete these steps in order. Do not skip any.

### 1. Sync workflow
```bash
git submodule update --init --remote .workflow
```

### 2. Read the operational rules
`.workflow/skills/issue-implement/SKILL.md`

Contains the mandatory checkpoint protocol, commit conventions, branch strategy.
**Do not improvise — everything is documented there.**

### 3. Read the project context
`PROJECT.md`

Contains stack, URLs, deploy status, active backlog.

### 4. Read the assigned issue
```bash
gh issue view <N> --repo ecologicaleaving/<repo>
```

Read everything: objective, context, AC, technical notes, mandatory checkpoints.

---

## ⛔ BINDING RULES

### Mandatory Checkpoints

At every checkpoint defined in the issue, you must:

1. **Post a comment on the issue** with this exact format:

```
## ✅ Checkpoint N — <title>

**Status:** completed

**What was done:**
<description>

**Test results (if applicable):**
<results>

**Planned next step:**
<what I would do next>

**Waiting for Claudio's confirmation before proceeding.**
```

2. **Stop and wait** for Claudio's reply on the issue
3. Proceed **only** when Claudio writes "procedi" or "✅ procedi"
4. If Claudio writes "bloccato" or asks for clarification → wait for instructions

### Branch

- Always work on `feature/issue-N-slug` (or `fix/` or `improve/`)
- NEVER commit directly to `main` or `master`
- Branch already created by Claudio at start — use it

### Commit

- Conventional format: `feat:`, `fix:`, `improve:`, `docs:`, `chore:`
- Atomic commits per logical step
- No `.env`, sensitive configs, debug files

### PROJECT.md

- Update version, date and issue in done list **before final push**

---

## 📋 Pre-push Checklist

Before pushing, verify:
- [ ] All issue AC satisfied
- [ ] All checkpoints completed and confirmed by Claudio
- [ ] Test suite passed (lint, typecheck, unit, e2e)
- [ ] PROJECT.md updated
- [ ] No anomalous files in commit
- [ ] Correct branch (not master/main)
