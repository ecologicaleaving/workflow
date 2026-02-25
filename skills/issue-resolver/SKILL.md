---
name: issue-resolver
version: 1.0.0
description: >
  Autonomous GitHub issue resolution. Guides Claude through a structured
  Research → Clarify → Plan → Iterative Implementation workflow.
triggers:
  - "resolve issue"
  - "implement issue"
  - "fix issue"
  - "process github issue"
  - "solve issue"
---

# Issue Resolver — Autonomous Workflow

When asked to resolve a GitHub issue in a repository, follow **exactly** this
four-phase process. Never skip phases. Never ask for user confirmation.

---

## PHASE 1 — RESEARCH (read-only, no code changes)

Goal: understand the project and the problem before writing a single line.

1. Read `README.md`, `CLAUDE.md`, `pubspec.yaml` / `package.json` / `Makefile`
   — whatever describes the project.
2. Explore the directory structure (`Glob "**/*"` on key directories).
3. Search for code related to the issue keywords (`Grep` for types, function
   names, widget names mentioned in the issue body).
4. Read the most relevant source files completely.
5. Find and read existing tests — they tell you what "correct" looks like.
6. Identify the project type and available test commands:
   - Flutter → `flutter test`, `flutter analyze`
   - Node.js/React → `npm test` (unit) + check `package.json scripts` for `test:e2e`, `playwright`, `cypress`
   - Python → `pytest`
   - Other → check `Makefile`, `package.json scripts`, `justfile`
   - **For web apps**: also detect lint (`lint`, `eslint`) and type-check (`typecheck`, `tsc`) scripts

Do **not** modify anything in this phase.

---

## PHASE 2 — CLARIFY & PLAN

Goal: turn the issue requirements into a concrete, unambiguous plan.

Answer these questions (internally — no need to write a file):

- What exactly is being asked? (restate in your own words)
- Which files need to be created or modified?
- Are there edge cases or ambiguities? How will you handle them?
- What is the simplest correct implementation?

Define your implementation steps in order. Prefer small, testable increments.

---

## PHASE 3 — ITERATIVE IMPLEMENTATION

Goal: implement → test → fix, looping until ALL test suites are green (max 5 iterations per suite).

```
iteration = 0
while iteration < 5:
    implement next logical unit of change

    # Run tests in order — stop at first failing suite and fix before continuing
    1. lint (if available)         → e.g. npm run lint / flutter analyze
    2. type-check (if available)   → e.g. npm run typecheck / tsc --noEmit
    3. unit tests                  → e.g. npm test / flutter test / pytest
    4. e2e / UI tests (if available) → e.g. npm run test:e2e (Playwright/Cypress)

    if all suites pass:
        move to next unit / proceed to Phase 4
    else:
        read the full error output carefully
        identify root cause (do not guess)
        fix the specific issue
        re-run only the failing suite to confirm the fix
        then re-run the full pipeline to check for regressions
        iteration++

if iteration == 5 and tests still failing:
    document what was attempted and why it is still failing
    stop (do not push broken code)
```

### Rules during implementation

- Follow the coding style already present in the project.
- One logical change at a time — do not implement everything at once.
- If a test was already failing before your changes, note it and continue.
- If the project has no test framework, do a careful code review of your own
  changes as a substitute (read every file you touched).
- Never skip or comment out a failing test — fix the code instead.
- Never run: `git add`, `git commit`, `git push`, `git merge`, `git checkout`,
  `git reset`. Git operations are handled in Phase 6.
- Never modify: `.git/` internals, lock files, auto-generated files.

---

## PHASE 4 — FINAL VERIFICATION

Before finishing:

1. Run the full test suite one final time.
2. Read through every file you created or modified — check for typos, missing
   imports, hardcoded values that should be configurable.
3. Confirm that each requirement from the issue is addressed.
4. If anything is still wrong, go back to Phase 3 for one more iteration.

### 4b — Playwright E2E verification (web apps only)

If the project is a **web app** (React, Next.js, Node.js with frontend), and
Playwright is available or can be added:

```bash
# Check if Playwright is already configured
ls playwright.config.* 2>/dev/null || cat package.json | grep playwright

# If configured — run E2E suite
npx playwright test --reporter=list

# If NOT configured but the issue affects UI — set up minimal smoke test:
npx playwright install --with-deps chromium
```

Create or update `tests/e2e/smoke.spec.ts` with at minimum:
- Page loads without JS errors
- Key UI elements visible (nav, main content, no blank screen)
- The specific flow affected by the issue works end-to-end

**Playwright verification rules:**
- Run headless (`--headed` only if debugging)
- If tests fail: fix the code, not the test
- Max 3 fix iterations before documenting and stopping
- Include Playwright results in the commit message:
  `Tests: lint ✓ | typecheck ✓ | unit ✓ | e2e (playwright) ✓`
- If Playwright was not present before: commit `playwright.config.ts` +
  `tests/e2e/` as part of the fix (counts as infrastructure improvement)

---

## Project-type quick reference

| Type | Detect | Test command | Build check |
|------|--------|--------------|-------------|
| Flutter | `pubspec.yaml` | `flutter test` | `flutter analyze` |
| React | `package.json` + "react" | `npm test -- --watchAll=false` | `npm run build` |
| Node.js | `package.json` | `npm test` | `npm run build` (if exists) |
| Python | `*.py` + `requirements.txt` | `pytest` | `python -m py_compile` |
| Static | `index.html` | — | `htmlhint` (if available) |

---

## PHASE 5 — CREATE / UPDATE PROJECT.md

PROJECT.md is the **Single Source of Truth** for the entire team pipeline
(status dashboard, Telegram bot, Ciccio deploy system). Always update it.
Reference template: `workflow/PROJECT_MD_TEMPLATE.md`

---

### 5a. If PROJECT.md does NOT exist — CREATE it

Infer everything you can from the codebase. Never invent — leave `[TBD]` for
anything you cannot determine with confidence.

**MUST HAVE sections** (required, block commit if missing):

```markdown
## Project Info
- **Name**: [from package.json/pubspec.yaml "name" field]
- **Version**: v0.1.0  ← start here if no version found
- **Status**: development
- **Platforms**: [web|apk|ios|desktop — detect from project type]
- **Description**: [generic, privacy-friendly, no client names]

## Deployment
- **Live URL**: [if found in README/config, else N/A]
- **Deploy Method**: [netlify|vps-nginx|github-actions|manual|TBD]
- **Deploy Host**: [TBD]
- **CI Status**: passing  ← set based on Phase 4 result
- **Last Deploy**: [current UTC timestamp ISO 8601]

## Repository
- **Main Branch**: [master|main — detect from git]
- **Development Branch**: [current feature branch]
- **GitHub**: [from git remote url]

## Backlog
- **DONE**: [issue title — brief description of what was implemented]
```

**RECOMMENDED sections** (add if info is available):

```markdown
## Database
- **Provider**: [detect from dependencies: prisma→postgresql, sqflite→sqlite, etc.]
- **Schema**: [prisma|sql-migrations|sqflite|mongoose|none]
- **Migration Status**: current

## Tech Stack
- **Frontend**: [from package.json dependencies]
- **Backend**: [from package.json / requirements.txt]
- **Database**: [from schema/deps]
- **Auth**: [from deps — jwt, bcrypt, firebase-auth, etc.]
- **Deployment**: [TBD]
```

**Privacy rules** (always enforce):
- No client names, no real location names
- No credentials, tokens, connection strings
- Descriptions generic but professional

---

### 5b. If PROJECT.md EXISTS — UPDATE it

#### 1. Version bump
Read current version, then apply:

| Issue/change type | Bump | Example |
|-------------------|------|---------|
| `fix`, `bug` | PATCH | 1.2.3 → 1.2.4 |
| `feat`, new functionality | MINOR | 1.2.3 → 1.3.0 |
| Breaking change (`feat!`) | MAJOR | 1.2.3 → 2.0.0 |

Determine type from issue labels, title, or nature of your changes.

#### 2. Backlog
- Find the issue in the `Backlog` section
- If `TODO` or `IN PROGRESS` → move to `DONE`
- If not present → add under `DONE`:
  `- **DONE**: [issue title — brief description of what was implemented]`
- If you introduced new known limitations or follow-up work → add as `TODO`

#### 3. CI Status
- Tests green (Phase 4 passed) → `CI Status: passing`
- Tests failed → `CI Status: failing`

#### 4. Timestamp
Update the last line:
```
*Last Updated: YYYY-MM-DDTHH:MM:SSZ*
```
Use current UTC time in ISO 8601 format.

#### 5. Other fields — update only if changed by this issue
- `Status`: only change if the issue moves the project to a new lifecycle stage
- `Live URL`: update if a new endpoint was added/changed
- `Tech Stack`: update if a new library/framework was introduced
- `Database → Migration Status`: set to `pending` if you added migrations not yet applied to prod

---

### 5c. Version consistency — MANDATORY

After updating PROJECT.md, align the version in all other version files:

| Project type | File | Field |
|-------------|------|-------|
| Flutter | `pubspec.yaml` | `version:` |
| Node.js | `package.json` | `"version":` |
| Both present | Both files | Must match PROJECT.md |

If the files disagree, PROJECT.md wins — update the others to match.

---

---

## PHASE 6 — PRODUCTION-READY COMMIT

Only execute this phase after ALL of the following are true:
- Phase 4 full test suite passed (lint + typecheck + unit + e2e)
- Phase 5 PROJECT.md is updated

### 6a. Pre-commit safety checks
```bash
git status          # confirm only expected files are modified
git diff --name-only  # review list of changed files
```
- Verify no `.env`, secrets, or credentials are staged
- Verify `.gitignore` is correct

### 6b. Stage and commit
```bash
git add <specific files>   # never git add -A blindly
git commit -m "<type>(<scope>): <short description>

- <bullet: what changed>
- <bullet: why>

Tests: lint ✓ | typecheck ✓ | unit ✓ | e2e ✓
Closes #<issue-number>"
```

Commit type rules (from 8020-commit-workflow):
- `feat:` → new functionality (MINOR bump)
- `fix:` → bug fix (PATCH bump)
- `feat!:` → breaking change (MAJOR bump)
- `docs:`, `style:`, `refactor:`, `test:`, `chore:` → PATCH

**Do NOT push.** Push is Davide's responsibility. After committing, report:
> "Implementazione completata e committata. Tutti i test passano. Puoi pushare e dire a Ciccio di deployare su test."

---

## Project-type quick reference

| Type | Detect | Lint | Type-check | Unit test | E2E test |
|------|--------|------|------------|-----------|----------|
| Flutter | `pubspec.yaml` | `flutter analyze` | — | `flutter test` | — |
| React | `package.json` + "react" | `npm run lint` | `npm run typecheck` | `npm test -- --watchAll=false` | `npx playwright test` |
| Next.js | `package.json` + "next" | `npm run lint` | `npm run typecheck` | `npm test -- --watchAll=false` | `npx playwright test` |
| Node.js | `package.json` | `npm run lint` | `npm run typecheck` | `npm test` | — |
| Python | `*.py` | `flake8` / `ruff` | `mypy` | `pytest` | — |
| Static | `index.html` | `htmlhint` | — | — | — |

---

## What success looks like

- All pre-existing tests still pass.
- New tests (if required by the issue) pass.
- lint, typecheck, unit, and e2e suites all green.
- The implementation matches every requirement stated in the issue.
- No broken imports, no syntax errors, no TODO left behind.
- PROJECT.md exists, version bumped, CI Status = passing, issue moved to DONE, timestamp current.
- Version consistent across PROJECT.md + pubspec.yaml / package.json.
- Commit created with correct conventional format and test summary in body.
