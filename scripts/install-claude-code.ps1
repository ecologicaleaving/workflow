# ================================================================
# install-claude-code.ps1 — Setup Claude Code (PC Windows)
# Fonte unica: scarica tutto dal repo workflow al momento dell'install.
#
# Uso:
#   iwr https://raw.githubusercontent.com/ecologicaleaving/workflow/master/scripts/install-claude-code.ps1 | iex
#   oppure: .\install-claude-code.ps1
#   oppure: .\install-claude-code.ps1 -Update   (aggiorna senza ricreare task)
# ================================================================

param(
    [switch]$Update,
    [string]$InstallPath = "C:\claude-workspace"
)

$REPO_RAW  = "https://raw.githubusercontent.com/ecologicaleaving/workflow/master"
$SKILLS_DIR = "$env:USERPROFILE\.claude\skills"
$MONITOR_DIR = "$InstallPath\monitor"
$LOG_DIR     = "$InstallPath\logs"

$Green  = "`e[32m"; $Yellow = "`e[33m"; $Red = "`e[31m"; $Bold = "`e[1m"; $Reset = "`e[0m"
function ok($m)   { Write-Host "${Green}✅ $m${Reset}" }
function warn($m) { Write-Host "${Yellow}⚠️  $m${Reset}" }
function err($m)  { Write-Host "${Red}❌ $m${Reset}"; exit 1 }
function h($m)    { Write-Host "`n${Bold}▸ $m${Reset}" }
function dl($url, $dest) {
    try {
        Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing -ErrorAction Stop
        return $true
    } catch {
        warn "Download fallito: $url ($_)"
        return $false
    }
}

Write-Host "${Bold}80/20 Solutions — Claude Code Setup (Windows)${Reset}"
Write-Host "================================================"

# ── Prerequisiti ──────────────────────────────────────────────
h "Verifica prerequisiti"

if (-not (Get-Command gh -ErrorAction SilentlyContinue))    { err "gh CLI non trovato. Installa: https://cli.github.com" }
if (-not (Get-Command git -ErrorAction SilentlyContinue))   { err "git non trovato. Installa: https://git-scm.com/download/win" }
if (-not (Get-Command claude -ErrorAction SilentlyContinue)) { warn "claude CLI non trovato — le skills verranno installate ma il monitor richiede Claude CLI" }

# Verifica scopes GitHub
$authOut = gh auth status 2>&1
if ($authOut -notmatch "read:project|project") {
    warn "Scope 'project' mancante su gh — necessario per il Project board"
    warn "Esegui dopo: gh auth refresh -s project"
} else {
    ok "gh auth scopes OK"
}

ok "Prerequisiti OK"

# ── Directory ─────────────────────────────────────────────────
h "Creazione directory"

@($InstallPath, $MONITOR_DIR, $LOG_DIR, $SKILLS_DIR) | ForEach-Object {
    if (-not (Test-Path $_)) { New-Item -Path $_ -ItemType Directory -Force | Out-Null }
}
ok "Directory pronte"

# ── Skills Claude Code ────────────────────────────────────────
h "Installazione skills"

# Struttura: skill -> lista file da scaricare
$skills = [ordered]@{
    "8020-commit-workflow" = @(
        "SKILL.md",
        "references/workflow-rules.md"
    )
    "issue-resolver" = @(
        "SKILL.md"
    )
}

foreach ($skillName in $skills.Keys) {
    $skillDir = "$SKILLS_DIR\$skillName"
    New-Item -Path "$skillDir\references" -ItemType Directory -Force | Out-Null

    foreach ($file in $skills[$skillName]) {
        $url  = "$REPO_RAW/skills/$skillName/$file"
        $dest = "$skillDir\$($file -replace '/', '\')"
        $ok = dl $url $dest
        if ($ok) { ok "  $skillName/$file" }
    }
}

# ── Monitor script ────────────────────────────────────────────
h "Download monitor"

$monitorScript = "$MONITOR_DIR\claude-monitor.ps1"
if (dl "$REPO_RAW/scripts/claude-monitor.ps1" $monitorScript) {
    ok "claude-monitor.ps1"
}

# Batch wrapper per Task Scheduler
$batchContent = "@echo off`r`npowershell -ExecutionPolicy Bypass -File `"$monitorScript`" >> `"$LOG_DIR\monitor.log`" 2>&1`r`n"
$batchContent | Out-File -FilePath "$MONITOR_DIR\claude-monitor.bat" -Encoding ASCII
ok "claude-monitor.bat (wrapper)"

# ── Task Scheduler ────────────────────────────────────────────
h "Task Scheduler"

if ($Update) {
    ok "Modalità update — Task Scheduler non modificato"
} else {
    $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    $taskXml = @"
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.3" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo>
    <Description>Claude Code Issue Monitor — 80/20 Solutions</Description>
    <URI>\Claude Code Issue Monitor</URI>
  </RegistrationInfo>
  <Triggers>
    <LogonTrigger><Enabled>true</Enabled><Delay>PT1M</Delay></LogonTrigger>
    <TimeTrigger>
      <Repetition><Interval>PT5M</Interval><StopAtDurationEnd>false</StopAtDurationEnd></Repetition>
      <StartBoundary>$(Get-Date -Format 'yyyy-MM-ddTHH:mm:ss')</StartBoundary>
      <Enabled>true</Enabled>
    </TimeTrigger>
  </Triggers>
  <Principals>
    <Principal id="Author">
      <UserId>$currentUser</UserId>
      <LogonType>InteractiveToken</LogonType>
      <RunLevel>LeastPrivilege</RunLevel>
    </Principal>
  </Principals>
  <Settings>
    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
    <StartWhenAvailable>true</StartWhenAvailable>
    <RunOnlyIfNetworkAvailable>true</RunOnlyIfNetworkAvailable>
    <Enabled>true</Enabled>
    <ExecutionTimeLimit>PT2H</ExecutionTimeLimit>
  </Settings>
  <Actions Context="Author">
    <Exec>
      <Command>$MONITOR_DIR\claude-monitor.bat</Command>
      <WorkingDirectory>$InstallPath</WorkingDirectory>
    </Exec>
  </Actions>
</Task>
"@
    $taskXml | Out-File -FilePath "$MONITOR_DIR\task.xml" -Encoding UTF8

    try {
        $existing = Get-ScheduledTask -TaskName "Claude Code Issue Monitor" -ErrorAction SilentlyContinue
        if ($existing) { Unregister-ScheduledTask -TaskName "Claude Code Issue Monitor" -Confirm:$false }
        Register-ScheduledTask -TaskName "Claude Code Issue Monitor" -Xml (Get-Content "$MONITOR_DIR\task.xml" -Raw) -Force | Out-Null
        Start-ScheduledTask -TaskName "Claude Code Issue Monitor"
        ok "Task Scheduler configurato (ogni 5 min + all'avvio)"
    } catch {
        warn "Task Scheduler fallito ($_) — esegui come amministratore per installarlo"
        warn "Manuale: Register-ScheduledTask -TaskName 'Claude Code Issue Monitor' -Xml (Get-Content '$MONITOR_DIR\task.xml' -Raw)"
    }
}

# ── Riepilogo ─────────────────────────────────────────────────
Write-Host ""
Write-Host "${Bold}✅ Claude Code setup completato!${Reset}"
Write-Host ""
Write-Host "Installato in:"
Write-Host "  Skills  : $SKILLS_DIR"
Write-Host "  Monitor : $MONITOR_DIR"
Write-Host "  Log     : $LOG_DIR\monitor.log"
Write-Host "  Task    : 'Claude Code Issue Monitor' (ogni 5 min)"
Write-Host ""
Write-Host "Per aggiornare (senza ricreare task):"
Write-Host "  iwr $REPO_RAW/scripts/install-claude-code.ps1 | iex -Args '-Update'"
Write-Host ""
if ($authOut -notmatch "read:project|project") {
    Write-Host "${Yellow}⚠️  Ricordati: gh auth refresh -s project${Reset}"
}
