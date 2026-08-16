# ================================================================
# sync.ps1 — Sync workflow → skill locali di Claude Code.
# Da eseguire all'avvio di ogni sessione (v. CLAUDE.md).
#
# Uso: .\sync.ps1
#
# ── Perché copia dal clone e non più da GitHub ──────────────────
# Fino al 16/08/2026 questo script scaricava da raw.githubusercontent
# un ELENCO SCRITTO A MANO di file: due skill su ventitré. Le altre
# ventuno restavano ferme alla data in cui erano state installate — in
# locale erano al 27 aprile — e nessuno se ne accorgeva, perché lo
# script diceva «✅ 3 file aggiornati» ed era vero.
#
# È il difetto peggiore che possa avere uno strumento di sync: dice di
# aver funzionato. Modificare una skill nel repo non cambiava niente
# nella skill che l'agente legge davvero.
#
# Ora copia TUTTO da questo clone, che il CLAUDE.md aggiorna con
# `git pull origin master` una riga prima. Una skill nuova si
# sincronizza da sé: non c'è nessun elenco da ricordarsi di aggiornare.
# ================================================================

$ErrorActionPreference = 'Stop'

$REPO_ROOT    = Split-Path -Parent $PSScriptRoot
$SKILLS_SRC   = Join-Path $REPO_ROOT 'skills'
$COMMANDS_SRC = Join-Path $REPO_ROOT 'commands'
$SKILLS_DIR   = "$env:USERPROFILE\.claude\skills"
$COMMANDS_DIR = "$env:USERPROFILE\.claude\commands"
$MONITOR      = "C:\claude-workspace\monitor\claude-monitor.ps1"

Write-Host "Sync workflow 80/20..." -NoNewline

if (-not (Test-Path $SKILLS_SRC)) {
    Write-Host " ERRORE: '$SKILLS_SRC' non esiste. Sei nel clone del repo workflow?" -ForegroundColor Red
    exit 1
}

$copiati = 0
$saltati = 0

# ── Skill ────────────────────────────────────────────────────────
# Ogni cartella sotto skills/ con dentro il suo SKILL.md e tutto ciò
# che si porta (references/, assets/): si copia l'albero intero.
foreach ($skill in Get-ChildItem -Path $SKILLS_SRC -Directory) {
    $dest = Join-Path $SKILLS_DIR $skill.Name
    if (-not (Test-Path $dest)) { New-Item -Path $dest -ItemType Directory -Force | Out-Null }

    foreach ($file in Get-ChildItem -Path $skill.FullName -Recurse -File) {
        $relativo = $file.FullName.Substring($skill.FullName.Length).TrimStart('\')
        $destFile = Join-Path $dest $relativo
        $destDir  = Split-Path $destFile
        if (-not (Test-Path $destDir)) { New-Item -Path $destDir -ItemType Directory -Force | Out-Null }

        # Si riscrive solo ciò che è cambiato: così il conteggio finale
        # dice quante skill si sono MOSSE, non quante ne esistono.
        $identico = (Test-Path $destFile) -and
                    ((Get-FileHash $file.FullName).Hash -eq (Get-FileHash $destFile).Hash)
        if ($identico) { $saltati++; continue }

        Copy-Item -Path $file.FullName -Destination $destFile -Force
        $copiati++
    }
}

# ── Slash command ────────────────────────────────────────────────
if (Test-Path $COMMANDS_SRC) {
    if (-not (Test-Path $COMMANDS_DIR)) { New-Item -Path $COMMANDS_DIR -ItemType Directory -Force | Out-Null }
    foreach ($cmd in Get-ChildItem -Path $COMMANDS_SRC -File -Filter *.md) {
        $destFile = Join-Path $COMMANDS_DIR $cmd.Name
        $identico = (Test-Path $destFile) -and
                    ((Get-FileHash $cmd.FullName).Hash -eq (Get-FileHash $destFile).Hash)
        if ($identico) { $saltati++; continue }
        Copy-Item -Path $cmd.FullName -Destination $destFile -Force
        $copiati++
    }
}

# ── Monitor ──────────────────────────────────────────────────────
# Solo se la cartella esiste già: su una macchina senza monitor non si
# crea nulla.
$monitorSrc = Join-Path $REPO_ROOT 'scripts\claude-monitor.ps1'
if ((Test-Path (Split-Path $MONITOR)) -and (Test-Path $monitorSrc)) {
    $identico = (Test-Path $MONITOR) -and
                ((Get-FileHash $monitorSrc).Hash -eq (Get-FileHash $MONITOR).Hash)
    if (-not $identico) { Copy-Item -Path $monitorSrc -Destination $MONITOR -Force; $copiati++ }
    else { $saltati++ }
}

$totSkill = (Get-ChildItem -Path $SKILLS_SRC -Directory).Count
if ($copiati -eq 0) {
    Write-Host " OK (gia allineato: $totSkill skill, $saltati file)"
} else {
    Write-Host " OK ($copiati file aggiornati su $totSkill skill, $saltati gia allineati)"
}
