# ============================================================
# setup-project.ps1 — Inizializza workflow context in un progetto
#
# Aggiunge il submodule .workflow e crea CLAUDE.md + AGENTS.md
# dal template, in modo che qualsiasi agente possa lavorare
# sul progetto sapendo come sincronizzarsi e cosa leggere.
#
# Uso (dalla root del progetto):
#   powershell -ExecutionPolicy Bypass -File path\to\workflow\scripts\setup-project.ps1
#   oppure (se workflow è già clonato localmente):
#   powershell -ExecutionPolicy Bypass -File C:\Users\KreshOS\.openclaw\workspace\workflow-repo\scripts\setup-project.ps1
# ============================================================

$ErrorActionPreference = "Stop"

$WORKFLOW_REPO = "https://github.com/ecologicaleaving/workflow.git"
$WORKFLOW_DIR  = ".workflow"
$RAW_BASE      = "https://raw.githubusercontent.com/ecologicaleaving/workflow/master"

Write-Host "🔧 Setup workflow context nel progetto..." -ForegroundColor Cyan

# ── Verifica che siamo in una repo git ──────────────────────
try {
    git rev-parse --is-inside-work-tree 2>&1 | Out-Null
} catch {
    Write-Host "❌ Errore: questa cartella non è una repository git." -ForegroundColor Red
    Write-Host "   Esegui prima: git init"
    exit 1
}

# ── Aggiungi submodule .workflow ─────────────────────────────
$submoduleExists = Test-Path (Join-Path $WORKFLOW_DIR ".git")
if ($submoduleExists) {
    Write-Host "⚡ Submodule .workflow già presente — aggiorno all'ultima versione..." -ForegroundColor Yellow
    git submodule update --remote $WORKFLOW_DIR
} else {
    Write-Host "📦 Aggiungo submodule .workflow..." -ForegroundColor Cyan
    git submodule add $WORKFLOW_REPO $WORKFLOW_DIR
    git submodule update --init --remote $WORKFLOW_DIR
}

# ── Crea CLAUDE.md ───────────────────────────────────────────
if (Test-Path "CLAUDE.md") {
    Write-Host "⚠️  CLAUDE.md già esistente — backup in CLAUDE.md.bak" -ForegroundColor Yellow
    Copy-Item "CLAUDE.md" "CLAUDE.md.bak" -Force
}
Write-Host "📝 Creo CLAUDE.md..." -ForegroundColor Cyan
Invoke-WebRequest -Uri "$RAW_BASE/templates/CLAUDE.md" -OutFile "CLAUDE.md" -UseBasicParsing

# ── Crea AGENTS.md ──────────────────────────────────────────
if (Test-Path "AGENTS.md") {
    Write-Host "⚠️  AGENTS.md già esistente — backup in AGENTS.md.bak" -ForegroundColor Yellow
    Copy-Item "AGENTS.md" "AGENTS.md.bak" -Force
}
Write-Host "📝 Creo AGENTS.md..." -ForegroundColor Cyan
Invoke-WebRequest -Uri "$RAW_BASE/templates/AGENTS.md" -OutFile "AGENTS.md" -UseBasicParsing

# ── Risultato ───────────────────────────────────────────────
Write-Host ""
Write-Host "✅ Setup completato!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Prossimi step:" -ForegroundColor Cyan
Write-Host "   git add .gitmodules .workflow CLAUDE.md AGENTS.md"
Write-Host "   git commit -m 'chore: aggiungi workflow context (CLAUDE.md, AGENTS.md, .workflow submodule)'"
Write-Host "   git push"
