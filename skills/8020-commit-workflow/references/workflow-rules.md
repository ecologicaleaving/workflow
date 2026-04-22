> ⚠️ **DEPRECATO** — Questo file è storico. Fonte di verità aggiornata: `WORKFLOW.md`
> Ruoli attivi: solo **Davide** (Product Owner) e **Agente** (Claude Code). Claudio e Ciccio non sono più ruoli attivi.

# 80/20 Solutions - Workflow Rules Complete Reference

## Team Roles

| Role | Person | Responsibilities |
|------|--------|-----------------|
| Product Owner | Davide | Vision, requirements, final validation, business decisions |
| Agente | Claude Code (this agent) | Development, commits, builds, code quality, deploy, merge, infrastructure |

**Communication channels:**
- Davide <-> Agente: Claude Code sessions, GitHub activity
- Team group: Telegram 8020dev

---

## Full Workflow Process

```
1.  Davide        -> Descrive feature/fix all'Agente
2.  Agente        -> Crea issue, crea feature branch: git checkout -b feature/issue-N-slug
3.  Agente        -> Sviluppa + commit con conventional commits
4.  Agente        -> Push: git push origin feature/issue-N-slug
5.  Agente        -> Apre PR, monitora CI su test-*.8020solutions.org
6.  Agente        -> Notifica Davide: "PR pronta per review — CI verde"
7.  Davide        -> Review sul test environment
8.  Davide (OK)   -> "/approva #N"
9.  Agente        -> Merge to master -> CI deploya in produzione
10. Agente        -> Monitora deploy prod, notifica Davide con URL live
```

---

## Branch Strategy

### Branch Types
| Branch | Purpose | Lifetime |
|--------|---------|----------|
| `master` | Production (protected) | Permanent |
| `feature/nome-feature` | New features | Temporary (deleted after merge) |
| `fix/nome-issue` | Bug fixes | Temporary |
| `hotfix/nome-critica` | Critical production fixes | Temporary (immediate) |
| `docs/nome-doc` | Documentation only | Temporary |

### Branch Naming Rules
- GOOD: `feature/user-authentication`, `fix/login-timeout-error`, `hotfix/critical-security`
- BAD: `dev`, `temp-branch`, `feature-1`, `working-branch`, `myfix`

### Branch Protection (master/main)
- 1 PR reviewer required before merge
- Status checks must pass
- Up-to-date with base branch required
- Dismiss stale reviews on new commits
- **NEVER push directly to master**

---

## Conventional Commits Standard

### Format
```
<type>[optional scope]: <short description>

[optional body]

[optional footer]
```

### Types & Semantic Version Impact
| Type | Version Bump | When to Use |
|------|-------------|-------------|
| `feat:` | MINOR (1.2.0 -> 1.3.0) | New feature for the user |
| `fix:` | PATCH (1.2.0 -> 1.2.1) | Bug fix for the user |
| `feat!:` | MAJOR (1.2.0 -> 2.0.0) | Breaking change |
| `docs:` | PATCH | Documentation only |
| `style:` | PATCH | Formatting, no logic change |
| `refactor:` | PATCH | Code restructure |
| `test:` | PATCH | Adding/fixing tests |
| `chore:` | PATCH | Build process, deps update |

### Optional Scopes
`ui`, `api`, `auth`, `db`, `config`, `deps`

### Examples
```bash
# Good
feat(auth): add JWT user authentication
fix(db): resolve connection timeout on idle pool
feat!: redesign REST API response format - BREAKING
docs: update deployment guide for VPS
refactor(ui): extract navigation into separate component
chore(deps): update Flutter to 3.24.0

# Bad
fixed stuff
WIP
update
asdfgh
```

---

## PROJECT.md - Single Source of Truth

Every project MUST have a `PROJECT.md` at root with these sections:

### Required Sections
```markdown
# Project Name

## Project Info
- **Version**: 1.2.3
- **Status**: development | staging | production
- **Description**: Brief description

## Deployment
- **Live URL**: https://app.8020solutions.org
- **Deploy Method**: vps-nginx | netlify | github-pages
- **Last Deploy**: 2026-02-22

## Repository
- **Main Branch**: master
- **GitHub**: https://github.com/ecologicaleaving/project-name

## Backlog
### TODO
- [ ] Feature to implement

### IN PROGRESS
- [ ] Current work item

### DONE
- [x] Completed item
```

### Privacy Rules for PROJECT.md
- No client names, no credentials, no sensitive data
- Generic business terms
- Vague but professional descriptions

---

## Commit Skin (Automation Tool)

### Installation (per project)
```bash
curl -sSL https://raw.githubusercontent.com/ecologicaleaving/workflow/master/scripts/install-claudio-skin.sh | bash
```

### What it Does Automatically (pre-commit hook)
1. Parses commit message type -> determines version bump
2. Updates PROJECT.md: version + last_updated timestamp
3. Detects project type: flutter | nodejs | static
4. Runs build:
   - Flutter: `flutter build apk --release` + `flutter build web --release`
   - Node.js/React: `npm run build`
   - Static: zip packaging
5. Copies artifact to `releases/` directory
6. Naming pattern: `{project}-{type}-v{version}.{ext}`
7. Stages all changes (PROJECT.md + artifacts)
8. Logs everything to `.commit-skin/commit.log`

### Config Files Created
- `.commit-skin/project-config.json` - project name, type, github URL, skin version
- `.commit-skin/version-rules.json` - semantic versioning rules
- `.commit-skin/commit.log` - execution log

### Verify Installation
```bash
ls .commit-skin/project-config.json  # exists = installed
cat .commit-skin/project-config.json  # check configuration
```

---

## Quality Standards

Before every commit/push, verify:
- [ ] Conventional commit format used
- [ ] No broken builds (app compiles/runs)
- [ ] PROJECT.md is updated (or commit skin handles it)
- [ ] On correct feature branch (not master)
- [ ] Only relevant files staged (no .env, secrets, binaries)
- [ ] Linting passes (if configured)

### Non-negotiables
- NEVER commit to master directly
- NEVER push broken code
- NEVER commit credentials or secrets
- NEVER skip PROJECT.md update
- ALWAYS use conventional commits

---

## Infrastructure Reference

- **VPS**: 46.225.60.101, Ubuntu 22.04 LTS
- **Database**: PostgreSQL Docker (porta 5433 local), Neon/Supabase cloud
- **Deploy targets**: VPS nginx + SSL, Netlify (static), GitHub APK distribution
- **Test environments**: test-*.8020solutions.org
- **Production**: app.8020solutions.org (and project-specific)

### KPI Targets
- Deploy success rate: >95%
- System uptime: 99.5% for critical
- Deploy response: <2h from request
- Emergency response: <30min

---

## Active Projects
- Maestro
- StageConnect
- BeachRef
- (future projects follow same workflow)

All at: https://github.com/ecologicaleaving/
Workflow hub: https://github.com/ecologicaleaving/workflow
