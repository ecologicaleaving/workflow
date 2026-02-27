# ================================================================
# sync.ps1 — Sync workflow da GitHub (leggero, no Task Scheduler)
# Da eseguire all'avvio di ogni sessione Claude Code.
#
# Uso: .\sync.ps1
#      oppure automatico da CLAUDE.md
# ================================================================

$REPO_RAW   = "https://raw.githubusercontent.com/ecologicaleaving/workflow/master"
$SKILLS_DIR = "$env:USERPROFILE\.claude\skills"
$MONITOR    = "C:\claude-workspace\monitor\claude-monitor.ps1"

function dl($url, $dest) {
    try {
        $dir = Split-Path $dest
        if (-not (Test-Path $dir)) { New-Item -Path $dir -ItemType Directory -Force | Out-Null }
        Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing -ErrorAction Stop
        return $true
    } catch { return $false }
}

Write-Host "🔄 Sync workflow 80/20..." -NoNewline

$updated = 0

# Skills
$files = @{
    "skills/8020-commit-workflow/SKILL.md"                  = "$SKILLS_DIR\8020-commit-workflow\SKILL.md"
    "skills/8020-commit-workflow/references/workflow-rules.md" = "$SKILLS_DIR\8020-commit-workflow\references\workflow-rules.md"
    "skills/issue-resolver/SKILL.md"                        = "$SKILLS_DIR\issue-resolver\SKILL.md"
}
foreach ($src in $files.Keys) {
    if (dl "$REPO_RAW/$src" $files[$src]) { $updated++ }
}

# Monitor
if (Test-Path (Split-Path $MONITOR)) {
    if (dl "$REPO_RAW/scripts/claude-monitor.ps1" $MONITOR) { $updated++ }
}

Write-Host " ✅ ($updated file aggiornati)"
