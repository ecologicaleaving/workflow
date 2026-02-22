# 80/20 Solutions - Workflow Rules Complete Reference

## Team Roles

| Role | Person | Responsibilities |
|------|--------|-----------------|
| Product Owner | David (Davide) | Vision, requirements, final validation, business decisions |
| Senior Developer | Claude Code (this agent) | Development, commits, builds, code quality |
| Orchestrator | Ciccio (OpenClaw VPS) | Deploy, merge, infrastructure, DB, monitoring |

**Communication channels:**
- David <-> Ciccio: Telegram (@dadecresce) for task delegation
- Ciccio <-> Claude Code: sessions_send HTTP + GitHub activity
- Team group: Telegram 8020dev

---

## Full Workflow Process

```
1.  David         -> Telegram a Ciccio: richiesta feature/fix
2.  Ciccio        -> Delega a Claude Code via sessions_send
3.  Claude Code   -> Crea feature branch: git checkout -b feature/nome
4.  Claude Code   -> Sviluppa + commit con conventional commits
5.  Claude Code   -> Push: git push origin feature/nome
6.  Claude Code   -> Notifica David: "Pronto per deploy su test"
7.  David         -> Dice a Ciccio: "Deploy [progetto] su test"
8.  Ciccio        -> Build + deploy su test-*.8020solutions.org
9.  Ciccio        -> Notifica David: "Test ready: [URL]"
10. David         -> Review sul test environment
11. David (OK)    -> "Vai in produzione"
12. Ciccio        -> Merge to master -> build prod -> deploy production
13. Ciccio        -> Report a David con URL live
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
- **NEVER push directly to master**

---

## Conventional Commits Standard

### Format
```
<type>[optional scope]: <short description>
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
temp
```

---

## PROJECT.md - Single Source of Truth

Every project MUST have a `PROJECT.md` at root. Template in `PROJECT_MD_TEMPLATE.md`.

### Required Fields
- `Version` - semantic version (auto-updated by commit automation)
- `Status` - development | staging | production
- `Live URL` - deploy target
- `Last Deploy` - ISO timestamp
- `Backlog` - TODO / IN PROGRESS / DONE sections

### Privacy Rules
- No client names, no credentials, no sensitive data
- Generic business terms only

---

## Commit Automation Tool

### Installation (per project, from project root)
```bash
curl -sSL https://raw.githubusercontent.com/ecologicaleaving/workflow/master/scripts/install-commit-automation.sh | bash
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
6. Naming: `{project}-{type}-v{version}.{ext}`
7. Stages all changes + logs to `.commit-automation/commit.log`

### Verify Installation
```bash
ls .commit-automation/project-config.json   # exists = installed
cat .commit-automation/commit.log           # check execution log
```

### Troubleshoot
```bash
# Reinstall
rm -rf .commit-automation .git/hooks/pre-commit
curl -sSL https://raw.githubusercontent.com/ecologicaleaving/workflow/master/scripts/install-commit-automation.sh | bash
```

---

## Claude Code Quality Standards

Non-negotiables before every commit/push:
- [ ] Conventional commit format used
- [ ] On correct feature branch (not master/main)
- [ ] No broken builds - tested locally
- [ ] PROJECT.md is updated (or automation handles it)
- [ ] Only relevant files staged (no .env, secrets, large binaries)

---

## Infrastructure Reference (Ciccio manages)

- **VPS**: Hetzner CiccioHouse 46.225.60.101, Ubuntu 22.04 LTS
- **Database**: PostgreSQL Docker (porta 5433 local), Neon/Supabase cloud
- **Deploy targets**: VPS nginx + SSL, Netlify (static), GitHub APK distribution
- **Test environments**: `test-*.8020solutions.org`
- **Production**: `app.8020solutions.org` (project-specific)

---

## Active Projects
- Maestro, StageConnect, BeachRef, (+ future projects)
- All at: https://github.com/ecologicaleaving/
- Workflow hub: https://github.com/ecologicaleaving/workflow
