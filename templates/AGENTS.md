# AGENTS.md — Project Workflow

## ⚠️ SESSION STARTUP — MANDATORY

Before doing anything else, complete these steps in order. Do not skip any.

### 1. Sync workflow
```bash
git submodule update --init --remote .workflow
```

### 2. Read the operational rules
`.workflow/skills/issue-implement/SKILL.md`

Contains the implementation protocol, auto-gate, commit conventions, branch strategy.
**Do not improvise — everything is documented there.**

### 3. Read the project context
`PROJECT.md`

Contains stack, URLs, deploy status, active backlog.

### 4. Read the assigned issue
```bash
gh issue view <N> --repo ecologicaleaving/<repo>
```

Read everything: objective, context, AC, technical notes.

---

## ⛔ BINDING RULES

### Mandatory Auto-Gate

Before pushing, verify autonomously:
1. All AC satisfied
2. Tests and build passed
3. Security audit passed (`scripts/security-audit.sh`)
4. PROJECT.md updated
5. No anomalous files in commit

If all ok → proceed to push autonomously.
If you find unresolvable problems → **STOP and notify Davide** on the issue:

```
## ⚠️ Blocked — <problem title>

**What happened:**
<description>

**Cause:**
<analysis>

**Options:**
<what I could do>

**Waiting for Davide's instructions.**
```

### Branch

- Always work on `feature/issue-N-slug` (or `fix/` or `improve/`)
- NEVER commit directly to `main` or `master`
- Create the branch at start: `git checkout -b feature/issue-N-slug`

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
- [ ] Auto-gate passed (tests, build, security audit)
- [ ] PROJECT.md updated
- [ ] No anomalous files in commit
- [ ] Correct branch (not master/main)
