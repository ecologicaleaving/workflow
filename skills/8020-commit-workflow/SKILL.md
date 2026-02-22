---
name: 8020-commit-workflow
description: >
  This skill should be used whenever a git commit or git push is requested in any 80/20 Solutions project.
  It enforces Claude Code's (Senior Developer) duties from the 80/20 Solutions workflow: conventional commits,
  semantic versioning, PROJECT.md validation, commit automation verification, branch strategy compliance,
  and post-push coordination with Ciccio. Trigger on any mention of "commit", "push", "git commit",
  "git push", or similar version control actions within the team's projects.
---

# 8020 Solutions - Commit & Push Workflow (Claude Code Duties)

## Role Context

In the 80/20 Solutions team, this agent acts as **Claude Code** (Senior Developer). The workflow involves:
- **David** = Product Owner (gives requirements, does final validation)
- **Claude Code** (this agent) = Senior Developer (develops, commits, notifies)
- **Ciccio** = Orchestrator on VPS (handles deploy, merge, infrastructure)

Read `references/workflow-rules.md` for full workflow documentation.

---

## Pre-Commit Checklist (ALWAYS verify before committing)

### 1. Branch Verification
- Verify current branch is `feature/nome-feature`, `fix/nome-issue`, or `hotfix/nome-critica`
- NEVER commit directly to `master` or `main`
- Run: `git branch --show-current`

### 2. Conventional Commit Format (MANDATORY)
The commit message MUST follow this exact format:
```
<type>[optional scope]: <short description>
```

Allowed types and their version impact:
- `feat:` -> MINOR bump (1.2.0 -> 1.3.0)
- `fix:` -> PATCH bump (1.2.0 -> 1.2.1)
- `feat!:` -> MAJOR bump (1.2.0 -> 2.0.0) - breaking change
- `docs:` -> PATCH (documentation only)
- `style:` -> PATCH (formatting, no logic change)
- `refactor:` -> PATCH (code restructure, no feature/fix)
- `test:` -> PATCH (adding tests)
- `chore:` -> PATCH (build process, dependencies)

Optional scopes: `ui`, `api`, `auth`, `db`, `config`, `deps`

Good examples:
- `feat(auth): add user login with JWT`
- `fix(db): resolve connection timeout on idle`
- `feat!: redesign REST API endpoints`
- `docs: update installation guide`

### 3. PROJECT.md Validation
Verify that `PROJECT.md` exists and is up to date:
- Version matches the expected bump based on commit type
- Status reflects current state
- Backlog items are current (move completed items to DONE)
- If commit automation is installed, it handles this automatically

### 4. Commit Automation Status
Check if commit automation is installed: `ls .commit-automation/project-config.json`
- If installed: automation auto-updates PROJECT.md, builds, packages artifacts
- If NOT installed: install it with:
  ```bash
  curl -sSL https://raw.githubusercontent.com/ecologicaleaving/workflow/master/scripts/install-commit-automation.sh | bash
  ```

---

## Commit Execution

After all checks pass, stage specific files and commit:
```bash
git add <specific-files>          # Never use git add -A blindly - no .env, no secrets
git commit -m "type: description"
```

If commit automation is active, it will automatically:
1. Parse commit type -> determine version bump
2. Update PROJECT.md (version + timestamp)
3. Detect project type (Flutter / Node.js / Static)
4. Build the app if applicable
5. Copy artifact to `releases/`
6. Stage everything and log to `.commit-automation/commit.log`

---

## Post-Push Protocol

After `git push origin feature/nome-feature`:

1. **Notify David** that the feature is ready for test
2. **Tell David to say to Ciccio**: "Deploy [project] su test" (David delegates to Ciccio via Telegram)
3. **Wait** for Ciccio to deploy to `test-*.8020solutions.org`
4. **David reviews** the test environment
5. If David says OK -> Ciccio handles merge to master + production deploy

> IMPORTANT: Never push to master directly. Never merge without David's approval.
> Never push anything that is broken or untested locally.

---

## Quick Reference

| Action | Command |
|--------|---------|
| Check branch | `git branch --show-current` |
| Check status | `git status` |
| Check automation | `ls .commit-automation/project-config.json` |
| Stage files | `git add <specific-files>` |
| Commit | `git commit -m "type: description"` |
| Push feature | `git push origin feature/nome-feature` |
| Check log | `cat .commit-automation/commit.log` |

## After Push - What to Tell David
> "Ho pushato [feature-name] su feature/nome-feature. Puoi dire a Ciccio di deployare su test."
