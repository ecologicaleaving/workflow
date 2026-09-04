# validate-project.ps1 — Pre-flight check (Windows PowerShell)
# Uso: powershell -File validate-project.ps1 [path\to\project]
# Exit 0 = tutto ok | Exit 1 = check fallito

param([string]$ProjectDir = ".")

$errors = @()
$warnings = @()

function Check-Required($label, $path) {
    $full = Join-Path $ProjectDir $path
    if (Test-Path $full) {
        Write-Host "✓ $label" -ForegroundColor Green
    } else {
        Write-Host "✗ $label — MANCANTE: $path" -ForegroundColor Red
        $script:errors += $label
    }
}

function Check-Optional($label, $path) {
    $full = Join-Path $ProjectDir $path
    if (Test-Path $full) {
        Write-Host "✓ $label" -ForegroundColor Green
    } else {
        Write-Host "⚠ $label — non trovato: $path (opzionale)" -ForegroundColor Yellow
        $script:warnings += $label
    }
}

Write-Host ""
Write-Host "🔍 Validazione progetto: $ProjectDir"
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

Check-Required "AGENTS.md (Codex)"       "AGENTS.md"
Check-Required "CLAUDE.md (Claude Code)" "CLAUDE.md"
Check-Required "PROJECT.md"              "PROJECT.md"
Check-Required ".workflow submodule"     ".workflow"
Check-Required "CI/CD configurata"       ".github\workflows"
Check-Required ".gitignore"              ".gitignore"

Check-Optional "PR template"             ".github\pull_request_template.md"
Check-Optional "Test directory"          "test"

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if ($errors.Count -eq 0) {
    Write-Host "✅ Pre-flight OK — puoi lanciare l'agente" -ForegroundColor Green
    exit 0
} else {
    Write-Host "❌ Pre-flight FALLITO — $($errors.Count) check obbligatori mancanti:" -ForegroundColor Red
    foreach ($e in $errors) {
        Write-Host "   → $e" -ForegroundColor Red
    }
    Write-Host ""
    Write-Host "👉 Esegui scripts/setup-project.ps1 per correggere, poi riprova."
    exit 1
}
