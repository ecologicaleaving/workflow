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

## PHASE 5 — UPDATE PROJECT.md

PROJECT.md is the **Single Source of Truth** for the entire team pipeline
(status dashboard, Telegram bot, Ciccio deploy system). Always update it.

### 5a. If PROJECT.md exists

1. **Version bump** — read current version, apply:
   - Issue type `fix` / `bug` → PATCH bump (1.2.3 → 1.2.4)
   - Issue type `feat` / `feature` / new functionality → MINOR bump (1.2.3 → 1.3.0)
   - Determine type from the issue title/labels or the nature of your changes

2. **Backlog** — find the issue in the backlog section and move it:
   - If listed as `TODO` or `IN PROGRESS` → move to `DONE`
   - If not listed → add it under `DONE`:
     `- **DONE**: [issue title — brief description of what was implemented]`

3. **Timestamp** — update the last line:
   `*Last Updated: YYYY-MM-DDTHH:MM:SSZ*` with current UTC time

4. **CI Status** — set to `passing` if tests passed, `failing` if they did not

### 5b. If PROJECT.md does NOT exist

Create it from the standard template. Fill in only what you can infer from
the codebase (project name, platform, tech stack, GitHub URL, main branch).
Leave unknown fields as `[TBD]`. Add the resolved issue under `DONE`.

Minimum required sections: `Project Info`, `Repository`, `Backlog`.

### 5c. Version consistency

If the project has a version declared elsewhere, align them:
- Flutter → `pubspec.yaml` (version field)
- Node.js → `package.json` (version field)
- Both must match the version in PROJECT.md after your update

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
| React | `package.json` + "react" | `npm run lint` | `npm run typecheck` | `npm test -- --watchAll=false` | `npm run test:e2e` |
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
- PROJECT.md updated: version bumped, issue moved to DONE, timestamp current.
- Commit created with correct conventional format and test summary in body.
