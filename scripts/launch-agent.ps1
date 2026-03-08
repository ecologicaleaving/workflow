# launch-agent.ps1 — Lancio agente con pre-flight obbligatorio
# USO: .\launch-agent.ps1 -Repo finn -Issue 28 -Agent claude -Prompt "Descrizione task"
#
# PARAMETRI:
#   -Repo        Nome repo (es. "finn") o full path locale
#   -Issue       Numero issue GitHub
#   -Agent       "claude" o "codex"
#   -Prompt      Task da passare all'agente
#   -Branch      Branch su cui lavorare (default: auto-generato da issue number)
#   -ProjectsDir Directory progetti (default: C:\Users\KreshOS\Documents\00-Progetti)

param(
    [Parameter(Mandatory=$true)][string]$Repo,
    [Parameter(Mandatory=$true)][int]$Issue,
    [Parameter(Mandatory=$true)][ValidateSet("claude","codex")][string]$Agent,
    [Parameter(Mandatory=$true)][string]$Prompt,
    [string]$Branch = "",
    [string]$ProjectsDir = "C:\Users\KreshOS\Documents\00-Progetti",
    [string]$WorkspaceDir = "C:\Users\KreshOS\.openclaw\workspace"
)

$ErrorActionPreference = "Stop"

# --- Helpers ---
function Write-Step($msg) { Write-Host "`n[$msg]" -ForegroundColor Cyan }
function Write-OK($msg)   { Write-Host "  ✓ $msg" -ForegroundColor Green }
function Write-Fail($msg) { Write-Host "  ✗ $msg" -ForegroundColor Red }
function Write-Info($msg) { Write-Host "  → $msg" -ForegroundColor Yellow }

Write-Host "`n🚀 launch-agent.ps1" -ForegroundColor Magenta
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Magenta

# --- Risolvi path repo ---
Write-Step "1/5 Risoluzione path repo"

$repoName = $Repo -replace ".*/" , ""   # supporta sia "finn" che "owner/finn"
$repoPath = Join-Path $ProjectsDir $repoName

if (-not (Test-Path $repoPath)) {
    Write-Fail "Repo non trovato in: $repoPath"
    Write-Info "Clono da GitHub..."
    $fullRepo = if ($Repo -match "/") { $Repo } else { "ecologicaleaving/$Repo" }
    git clone "https://github.com/$fullRepo.git" $repoPath
    if ($LASTEXITCODE -ne 0) {
        Write-Fail "Clone fallito. Uscita."
        exit 1
    }
}
Write-OK "Repo: $repoPath"

Set-Location $repoPath

# --- Step 1: Submodule update (regola Ciccio — OBBLIGATORIO) ---
Write-Step "2/5 git submodule update --init --remote .workflow"

git submodule update --init --remote .workflow 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Fail "Submodule update fallito — verificare .gitmodules"
    exit 1
}
Write-OK "Submodule .workflow aggiornato"

# --- Step 2: Validate project ---
Write-Step "3/5 Validate project (pre-flight check)"

$validateScript = Join-Path $WorkspaceDir "workflow-repo\scripts\validate-project.ps1"
$checks = @("AGENTS.md","CLAUDE.md","PROJECT.md",".workflow",".github\workflows",".gitignore")
$missing = @()
foreach ($c in $checks) {
    if (Test-Path (Join-Path $repoPath $c)) {
        Write-OK $c
    } else {
        Write-Fail "$c — MANCANTE"
        $missing += $c
    }
}

if ($missing.Count -gt 0) {
    Write-Host "`n❌ PRE-FLIGHT FALLITO — $($missing.Count) file mancanti." -ForegroundColor Red
    Write-Info "Esegui setup-project.ps1 prima di rilanciare."
    exit 1
}
Write-OK "Pre-flight OK"

# --- Step 3: Branch setup ---
Write-Step "4/5 Preparazione branch"

if ($Branch -eq "") {
    # Auto-genera slug dall'issue title
    try {
        $issueTitle = (gh issue view $Issue --repo "ecologicaleaving/$repoName" --json title -q ".title") 2>$null
        $slug = $issueTitle -replace "[^a-zA-Z0-9 ]","" -replace " +","-" -replace "-+"," " 
        $slug = ($slug.Split(" ") | Select-Object -First 5) -join "-"
        $slug = $slug.ToLower() -replace "-$",""
        $Branch = "feature/issue-$Issue-$slug"
    } catch {
        $Branch = "feature/issue-$Issue-fix"
    }
}
Write-Info "Branch: $Branch"

# Checkout o crea branch
$existingBranch = git branch --list $Branch
if ($existingBranch) {
    git checkout $Branch 2>&1 | Out-Null
    git pull origin $Branch 2>&1 | Out-Null
    Write-OK "Branch esistente: checkout + pull"
} else {
    $remoteBranch = git ls-remote --heads origin $Branch
    if ($remoteBranch) {
        git checkout -b $Branch "origin/$Branch" 2>&1 | Out-Null
        Write-OK "Branch da remote: $Branch"
    } else {
        git checkout -b $Branch 2>&1 | Out-Null
        Write-OK "Nuovo branch creato: $Branch"
    }
}

# --- Step 4: Costruisci prompt finale ---
Write-Step "5/5 Lancio agente ($Agent)"

$fullRepo = "ecologicaleaving/$repoName"
$issueUrl = "https://github.com/$fullRepo/issues/$Issue"
$notifyCmd = "openclaw system event --text `"Agente $Agent completato: issue #$Issue $repoName - verifica in corso`" --mode now"

$fullPrompt = @"
Prima di tutto: git submodule update --init --remote .workflow, poi leggi .workflow/AGENTS.md e PROJECT.md.

Issue: #$Issue ($issueUrl)
Branch: $Branch

$Prompt

---
Quando completato (PR aperta o push finale), esegui:
$notifyCmd
"@

# Scrivi prompt su file temp
$promptFile = Join-Path $env:TEMP "agent-prompt-$Issue.txt"
$fullPrompt | Set-Content $promptFile -Encoding UTF8
Write-OK "Prompt scritto: $promptFile"

# --- Lancia agente ---
$agentsFile = Join-Path $WorkspaceDir "agents-running.json"
$now = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")

if ($Agent -eq "claude") {
    Write-Info "Avvio Claude Code in background..."
    $proc = Start-Process -FilePath "claude" `
        -ArgumentList "--permission-mode", "bypassPermissions", "--print", $fullPrompt `
        -WorkingDirectory $repoPath `
        -PassThru -NoNewWindow `
        -RedirectStandardOutput (Join-Path $env:TEMP "claude-out-$Issue.log") `
        -RedirectStandardError  (Join-Path $env:TEMP "claude-err-$Issue.log")
    $pid = $proc.Id
    $sessionLabel = "claude-pid-$pid"
} else {
    Write-Info "Avvio Codex in background..."
    $proc = Start-Process -FilePath "codex" `
        -ArgumentList "--yolo", $fullPrompt `
        -WorkingDirectory $repoPath `
        -PassThru -NoNewWindow `
        -RedirectStandardOutput (Join-Path $env:TEMP "codex-out-$Issue.log") `
        -RedirectStandardError  (Join-Path $env:TEMP "codex-err-$Issue.log")
    $pid = $proc.Id
    $sessionLabel = "codex-pid-$pid"
}

Write-OK "Agente avviato — PID: $pid"

# --- Aggiorna agents-running.json ---
$entry = @{
    id         = $sessionLabel
    repo       = $fullRepo
    issue      = $Issue
    branch     = $Branch
    task       = ($Prompt.Split("`n")[0].Trim())
    startedAt  = $now
    status     = "running"
    notifyOn   = "pr_opened"
    notified   = $false
    pid        = $pid
}

$existing = @()
if (Test-Path $agentsFile) {
    $existing = Get-Content $agentsFile | ConvertFrom-Json
    if ($existing -isnot [System.Array]) { $existing = @($existing) }
}
$existing += $entry
$existing | ConvertTo-Json -Depth 5 | Set-Content $agentsFile -Encoding UTF8

Write-Host "`n✅ Agente lanciato correttamente!" -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Magenta
Write-Host "  Repo:    $fullRepo"
Write-Host "  Issue:   #$Issue"
Write-Host "  Branch:  $Branch"
Write-Host "  Agente:  $Agent (PID $pid)"
Write-Host "  Log:     $env:TEMP\${Agent}-out-$Issue.log"
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Magenta
