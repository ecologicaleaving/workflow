# ================================================================
# sync.ps1 — Sync workflow → skill locali di Claude Code.
# Da eseguire all'avvio di ogni sessione (v. ~/.claude/CLAUDE.md).
#
# Uso:
#   .\sync.ps1            copia skills/ + tools/ in ~/.claude/skills/,
#                          poi ritira quanto elencato in RETIRED.txt
#   .\sync.ps1 -DryRun     stampa cosa copierebbe e cosa ritirerebbe,
#                          senza toccare nulla
#
# ── Perché copia dal clone e non da GitHub ───────────────────────
# Fino al 16/08/2026 questo script scaricava da raw.githubusercontent
# un elenco scritto a mano di file: la maggior parte delle skill
# restava ferma alla data in cui era stata installata, senza che
# nessuno se ne accorgesse — lo script diceva "aggiornato" ed era
# vero solo per i due file nell'elenco.
#
# Ora copia TUTTO da questo clone, che ~/.claude/CLAUDE.md aggiorna
# con `git pull origin master` una riga prima. Una skill nuova (o
# ritirata) si allinea da sé: non c'è nessun elenco da ricordare.
# ================================================================

param(
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

$REPO_ROOT    = Split-Path -Parent $PSScriptRoot
$SKILLS_SRC   = Join-Path $REPO_ROOT 'skills'
$TOOLS_SRC    = Join-Path $REPO_ROOT 'tools'
$RETIRED_FILE = Join-Path $REPO_ROOT 'RETIRED.txt'
$SKILLS_DIR   = "$env:USERPROFILE\.claude\skills"

Write-Host "Sync workflow 80/20$(if ($DryRun) { ' [DRY RUN]' })..." -NoNewline
if (-not $DryRun) { Write-Host "" }

if (-not (Test-Path $SKILLS_SRC)) {
    Write-Host " ERRORE: '$SKILLS_SRC' non esiste. Sei nel clone del repo workflow?" -ForegroundColor Red
    exit 1
}

function Sync-Tree {
    param($SrcRoot, [ref]$Copiati, [ref]$Saltati, [switch]$DryRun)

    foreach ($item in Get-ChildItem -Path $SrcRoot -Directory) {
        $dest = Join-Path $SKILLS_DIR $item.Name
        if ($DryRun) {
            Write-Host "  copierebbe: $($item.Name)"
            $Copiati.Value++
            continue
        }
        if (-not (Test-Path $dest)) { New-Item -Path $dest -ItemType Directory -Force | Out-Null }

        foreach ($file in Get-ChildItem -Path $item.FullName -Recurse -File) {
            $relativo = $file.FullName.Substring($item.FullName.Length).TrimStart('\')
            $destFile = Join-Path $dest $relativo
            $destDir  = Split-Path $destFile
            if (-not (Test-Path $destDir)) { New-Item -Path $destDir -ItemType Directory -Force | Out-Null }

            $identico = (Test-Path $destFile) -and
                        ((Get-FileHash $file.FullName).Hash -eq (Get-FileHash $destFile).Hash)
            if ($identico) { $Saltati.Value++; continue }

            Copy-Item -Path $file.FullName -Destination $destFile -Force
            $Copiati.Value++
        }
    }
}

$copiati = 0
$saltati = 0
$copiatiRef = [ref]$copiati
$saltatiRef = [ref]$saltati

if ($DryRun) {
    Write-Host "`nSkill/tool che verrebbero copiati in $SKILLS_DIR :"
}

Sync-Tree -SrcRoot $SKILLS_SRC -Copiati $copiatiRef -Saltati $saltatiRef -DryRun:$DryRun
if (Test-Path $TOOLS_SRC) {
    Sync-Tree -SrcRoot $TOOLS_SRC -Copiati $copiatiRef -Saltati $saltatiRef -DryRun:$DryRun
}

# ── Ritiro skill obsolete (RETIRED.txt) ─────────────────────────
$ritirate = 0
if (Test-Path $RETIRED_FILE) {
    if ($DryRun) { Write-Host "`nSkill che verrebbero ritirate (se presenti in $SKILLS_DIR):" }
    foreach ($line in Get-Content $RETIRED_FILE) {
        $nome = ($line -split '#')[0].Trim()
        if ([string]::IsNullOrWhiteSpace($nome)) { continue }
        $target = Join-Path $SKILLS_DIR $nome
        if (Test-Path $target) {
            if ($DryRun) {
                Write-Host "  ritirerebbe: $nome"
                $ritirate++
            } else {
                Remove-Item -Path $target -Recurse -Force
                Write-Host "  🗑️  ritirata: $nome"
                $ritirate++
            }
        }
    }
}

if ($DryRun) {
    Write-Host "`n[DRY RUN] $copiati skill/tool da copiare, $ritirate da ritirare. Nessuna modifica effettuata."
    exit 0
}

$totSkill = (Get-ChildItem -Path $SKILLS_SRC -Directory).Count
if (Test-Path $TOOLS_SRC) { $totSkill += (Get-ChildItem -Path $TOOLS_SRC -Directory).Count }

if ($copiati -eq 0 -and $ritirate -eq 0) {
    Write-Host "OK (gia allineato: $totSkill skill/tool, $saltati file)"
} else {
    Write-Host "OK ($copiati file aggiornati su $totSkill skill/tool, $saltati gia allineati, $ritirate ritirate)"
}
