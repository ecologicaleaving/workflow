# 80/20 Solutions — Workflow Hub

Repository centralizzato per workflow, script e skills del team AI di 80/20 Solutions.

---

## 🤖 Setup progetto (agenti)

Per includere il workflow in un progetto nuovo o esistente, esegui dalla **root del progetto**:

```bash
# Linux / Mac / WSL
curl -sSL https://raw.githubusercontent.com/ecologicaleaving/workflow/master/scripts/setup-project.sh | bash

# Windows (PowerShell)
iwr https://raw.githubusercontent.com/ecologicaleaving/workflow/master/scripts/setup-project.ps1 -OutFile setup-project.ps1; powershell -ExecutionPolicy Bypass -File setup-project.ps1; Remove-Item setup-project.ps1
```

Lo script aggiunge automaticamente:
- **`.workflow/`** — submodule puntato a questo repo (si aggiorna ad ogni sessione)
- **`CLAUDE.md`** — istruzioni di avvio per Claude Code
- **`AGENTS.md`** — istruzioni di avvio per Codex

Ogni agente che apre il progetto troverà il suo file nativo, sincronizzerà il workflow e leggerà le regole aggiornate — senza configurazione manuale.

---

## 🚀 Installazione rapida

```bash
# Auto-detect ambiente e installa il modulo giusto
curl -sSL https://raw.githubusercontent.com/ecologicaleaving/workflow/master/install.sh | bash
```

Oppure installa direttamente il modulo che ti serve:

| Componente | Comando |
|------------|---------|
| **Ciccio** (VPS OpenClaw) | `curl -sSL https://raw.githubusercontent.com/ecologicaleaving/workflow/master/scripts/install-ciccio.sh \| bash` |
| **Claude Code** (PC Linux/WSL) | `curl -sSL https://raw.githubusercontent.com/ecologicaleaving/workflow/master/scripts/install-claude-code.sh \| bash` |
| **Claude Code** (PC Windows) | `iwr https://raw.githubusercontent.com/ecologicaleaving/workflow/master/scripts/install-claude-code.ps1 \| iex` |
| **Telegram Bot** | `curl -sSL https://raw.githubusercontent.com/ecologicaleaving/workflow/master/scripts/install-telegram-bot.sh \| bash` |

> L'installazione è **una tantum**. Per gli aggiornamenti quotidiani vedi la sezione [Sync](#-sync-aggiornamento-quotidiano).

---

## 🏗️ Struttura

```
workflow/
├── install.sh                          # Master installer (auto-detect)
├── CLAUDE.md                           # Istruzioni globali per Claude Code
│
├── scripts/
│   ├── install-ciccio.sh               # Installa modulo Ciccio (VPS)
│   ├── install-claude-code.sh          # Installa modulo Claude Code (Linux/WSL)
│   ├── install-claude-code.ps1         # Installa modulo Claude Code (Windows)
│   ├── install-telegram-bot.sh         # Installa bot Telegram
│   ├── sync.ps1                        # Sync leggero skills+monitor (Windows, ogni sessione)
│   │
│   ├── project_board.py                # Helper: muove card GitHub Project board
│   ├── issue_slash_command.py          # Handler /issue e /reject (Telegram → GitHub)
│   ├── triage_command.py               # Handler /triage (assegnazione issue)
│   ├── auto_issue_parser.py            # Parser automatico issue
│   ├── ciccio-issue-monitor.sh         # Cron VPS: monitora issue label ciccio/needs-fix
│   ├── claude-code-issue-monitor.sh    # Cron PC: monitora issue label claude-code
│   ├── claude-monitor.ps1              # Monitor Windows (PowerShell)
│   └── ciccio-notify.sh                # Helper notifiche Telegram da CI/CD
│
└── skills/
    ├── SKILLS.md                       # Indice di tutte le skills
    ├── 8020-workflow/                  # Skill OpenClaw (Ciccio VPS)
    │   ├── SKILL.md
    │   └── references/
    │       ├── WORKFLOW_CICCIO.md
    │       ├── WORKFLOW_CLAUDE_CODE.md
    │       ├── WORKFLOW_DAVID.md
    │       ├── BRANCH_STRATEGY.md
    │       └── COMMIT_CONVENTIONS.md
    ├── 8020-commit-workflow/           # Skill Claude Code — commit corretto
    │   └── SKILL.md
    └── issue-resolver/                 # Skill Claude Code — risoluzione issue
        └── SKILL.md
```

---

## 📦 Moduli

### 🖥️ Ciccio (VPS OpenClaw)

**Cosa installa `install-ciccio.sh`:**
- Script Python e bash in `workspace-ciccio/scripts/`
- Skill `8020-workflow` in `workspace-ciccio/skills/` (trigger automatico su task di workflow)
- `/usr/local/bin/ciccio-notify` per notifiche Telegram da GitHub Actions
- Cron ogni 10 min per `ciccio-issue-monitor.sh`

**Responsabilità:**
- Gestisce `/issue`, `/reject`, `/triage` da Telegram
- Muove card sul GitHub Project board automaticamente
- Spawna subagenti per issue con label `ciccio` o `needs-fix`
- Deploy su ambienti test

**Aggiornamento Ciccio:**
```bash
curl -sSL https://raw.githubusercontent.com/ecologicaleaving/workflow/master/scripts/install-ciccio.sh | bash
```

---

### 💻 Claude Code (PC)

**Cosa installa `install-claude-code.ps1` (una tantum):**
- Skills `8020-commit-workflow` e `issue-resolver` in `~\.claude\skills\`
- Script monitor in `C:\claude-workspace\monitor\`
- Task Scheduler: ogni 5 min + all'avvio

**Cosa fa `sync.ps1` (ogni sessione, automatico):**
- `git pull origin master` sul clone locale del workflow repo
- Aggiorna skills e monitor all'ultima versione
- Non tocca il Task Scheduler

**Responsabilità:**
- Processa issue con label `claude-code` autonomamente
- Commit convenzionali + push + PR
- Aggiorna `PROJECT.md` a ogni issue completata
- Sync workflow all'avvio di ogni sessione (definito in `CLAUDE.md`)

---

## 🔄 Sync — Aggiornamento quotidiano

Il repo è la **fonte unica** per tutti i componenti. Nessun file viene duplicato o mantenuto manualmente.

### Claude Code (PC) — automatico ad ogni sessione
`CLAUDE.md` istruisce Claude Code a syncronizzare all'avvio:
```powershell
cd C:\Users\KreshOS\Documents\00-Progetti\workflow
git pull origin master
powershell -ExecutionPolicy Bypass -File scripts\sync.ps1
```

### Ciccio (VPS) — su richiesta o dopo aggiornamenti workflow
```bash
curl -sSL https://raw.githubusercontent.com/ecologicaleaving/workflow/master/scripts/install-ciccio.sh | bash
```

### Flusso aggiornamenti
```
Davide aggiorna workflow repo (push su master)
        ↓
Claude Code: sync automatico alla prossima sessione
Ciccio: re-installa su richiesta (o heartbeat periodico)
```

---

## 🔄 Workflow completo

```
Davide: /issue - "descrizione"
        ↓
Ciccio: crea GitHub issue → card su 📋 Todo

Davide: assegna label (claude-code / ciccio)
        ↓
Monitor rileva → card su 🔄 In Progress
        ↓
Agente lavora → commit → push → review-ready
        ↓
Card su 🚀 PUSH → Ciccio deploya su test
        ↓
Card su 🧪 Test → Davide testa APK/URL

Davide: /approve → card ✔️ Done → deploy produzione
Davide: /reject "feedback" → card 🔄 In Progress → rework automatico
```

---

## 📋 GitHub Project Board

**Project**: [80/20 Solutions - Development Hub](https://github.com/users/ecologicaleaving/projects/2)

| Colonna | Chi sposta | Quando |
|---------|-----------|--------|
| `📋 Todo` | Ciccio | Issue creata |
| `🔄 In Progress` | Monitor | Inizio lavorazione / dopo /reject |
| `🚀 PUSH` | Agente | Commit completato (review-ready) |
| `🧪 Test` | Ciccio | Deploy test eseguito |
| `✔️ Done` | Ciccio | /approve + deploy prod |

**Helper**: `scripts/project_board.py` — importabile da qualsiasi script Python.

```bash
# CLI diretta
python3 project_board.py ecologicaleaving/finn 6 "In Progress"
```

---

## 🔧 Workflow files

| File | Ruolo |
|------|-------|
| `WORKFLOW_CICCIO.md` | Responsabilità e procedure Ciccio |
| `WORKFLOW_CLAUDE_CODE.md` | Workflow agente developer PC |
| `WORKFLOW_DAVID.md` | Flusso dal punto di vista di Davide |
| `BRANCH_STRATEGY.md` | Strategia branch Git |
| `COMMIT_CONVENTIONS.md` | Formato commit (Conventional Commits) |

---

*80/20 Solutions — AI-powered development workflows*
