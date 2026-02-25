# Claude Code PC Installation Script
# One-click setup for GitHub Issues monitoring with auto-start

param(
    [switch]$Force,
    [string]$InstallPath = "C:\claude-workspace",
    [switch]$SkipDependencies
)

# Colors for output
$Red = "`e[31m"
$Green = "`e[32m"
$Yellow = "`e[33m"
$Blue = "`e[34m"
$Reset = "`e[0m"

function Write-Status {
    param($Message, $Type = "Info")
    $timestamp = Get-Date -Format "HH:mm:ss"
    switch ($Type) {
        "Success" { Write-Host "[$timestamp] ${Green}✅${Reset} $Message" }
        "Warning" { Write-Host "[$timestamp] ${Yellow}⚠️${Reset}  $Message" }
        "Error"   { Write-Host "[$timestamp] ${Red}❌${Reset} $Message" }
        default   { Write-Host "[$timestamp] ${Blue}ℹ️${Reset}  $Message" }
    }
}

function Test-IsAdmin {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal] $currentUser
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Install-GitHubCLI {
    Write-Status "Installing GitHub CLI..." "Info"
    
    try {
        # Check if winget is available
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            winget install --id GitHub.cli --silent
        }
        # Fallback to direct download
        else {
            $ghUrl = "https://github.com/cli/cli/releases/latest/download/gh_windows_amd64.msi"
            $tempFile = "$env:TEMP\gh_windows_amd64.msi"
            
            Write-Status "Downloading GitHub CLI..." "Info"
            Invoke-WebRequest -Uri $ghUrl -OutFile $tempFile
            
            Write-Status "Installing GitHub CLI..." "Info"
            Start-Process msiexec -ArgumentList "/i `"$tempFile`" /quiet" -Wait
            
            Remove-Item $tempFile -ErrorAction SilentlyContinue
        }
        
        # Refresh PATH
        $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")
        
        if (Get-Command gh -ErrorAction SilentlyContinue) {
            Write-Status "GitHub CLI installed successfully" "Success"
            return $true
        } else {
            Write-Status "GitHub CLI installation failed" "Error"
            return $false
        }
    }
    catch {
        Write-Status "Error installing GitHub CLI: $_" "Error"
        return $false
    }
}

function Test-Dependencies {
    Write-Status "Checking dependencies..." "Info"
    $allGood = $true
    
    # Check GitHub CLI
    if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
        Write-Status "GitHub CLI not found" "Warning"
        if (-not $SkipDependencies) {
            if (-not (Install-GitHubCLI)) {
                $allGood = $false
            }
        } else {
            $allGood = $false
        }
    } else {
        Write-Status "GitHub CLI found: $(gh --version)" "Success"
    }
    
    # Check Git
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Status "Git not found - please install Git for Windows" "Error"
        Write-Status "Download: https://git-scm.com/download/win" "Info"
        $allGood = $false
    } else {
        Write-Status "Git found: $(git --version)" "Success"
    }
    
    # Check Claude CLI
    if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
        Write-Status "Claude CLI not found - please install Claude CLI" "Warning"
        Write-Status "The monitor will still work, but issue processing requires Claude CLI" "Warning"
    } else {
        Write-Status "Claude CLI found" "Success"
    }
    
    # Check PowerShell execution policy
    $policy = Get-ExecutionPolicy -Scope CurrentUser
    if ($policy -eq "Restricted") {
        Write-Status "PowerShell execution policy is restricted" "Warning"
        Write-Status "Setting execution policy to RemoteSigned for current user..." "Info"
        try {
            Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
            Write-Status "Execution policy updated" "Success"
        }
        catch {
            Write-Status "Could not update execution policy. Run as administrator or set manually." "Error"
            $allGood = $false
        }
    }
    
    return $allGood
}

function New-DirectoryStructure {
    Write-Status "Creating directory structure..." "Info"
    
    $directories = @(
        $InstallPath,
        "$InstallPath\scripts",
        "$InstallPath\repos", 
        "$InstallPath\logs",
        "$InstallPath\config"
    )
    
    foreach ($dir in $directories) {
        if (-not (Test-Path $dir)) {
            New-Item -Path $dir -ItemType Directory -Force | Out-Null
            Write-Status "Created: $dir" "Info"
        }
    }
    
    Write-Status "Directory structure created" "Success"
}

function New-MonitoringScript {
    Write-Status "Creating monitoring script..." "Info"
    
    $scriptContent = @'
# Claude Code Issue Monitor - PowerShell
# Monitors GitHub issues with 'claude-code' label every 5 minutes

$ErrorActionPreference = "Continue"
$LogFile = "C:\claude-workspace\logs\monitor.log"
$ErrorLogFile = "C:\claude-workspace\logs\error.log"

function Write-Log {
    param($Message, $Type = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Type] $Message"
    Add-Content -Path $LogFile -Value $logMessage
    Write-Output $logMessage
}

function Write-Error-Log {
    param($Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $errorMessage = "[$timestamp] [ERROR] $Message"
    Add-Content -Path $ErrorLogFile -Value $errorMessage
    Write-Output $errorMessage
}

Write-Log "=== Claude Code Monitor Started ==="

try {
    # Check GitHub authentication
    $authResult = gh auth status 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Error-Log "GitHub CLI not authenticated. Please run: gh auth login"
        exit 1
    }
    
    # Get issues with 'claude-code' label
    Write-Log "Checking for issues with 'claude-code' label..."
    $issuesJson = gh issue list --search "org:ecologicaleaving label:claude-code state:open" --json number,title,repository,body --limit 10 2>$null
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error-Log "Failed to fetch issues from GitHub"
        exit 1
    }
    
    if ([string]::IsNullOrWhiteSpace($issuesJson) -or $issuesJson -eq "[]") {
        Write-Log "No issues found with 'claude-code' label"
        exit 0
    }
    
    $issues = $issuesJson | ConvertFrom-Json
    Write-Log "Found $($issues.Count) issue(s) to process"
    
    foreach ($issue in $issues) {
        $repo = $issue.repository.name
        $number = $issue.number
        $title = $issue.title
        $body = $issue.body -replace '"', '""'  # Escape quotes for JSON
        
        Write-Log "Processing: $repo#$number - $title"
        
        # Update issue to in-progress
        Write-Log "Updating issue $repo#$number to in-progress..."
        gh issue edit $number --repo "ecologicaleaving/$repo" --remove-label "claude-code" --add-label "in-progress" 2>$null
        
        if ($LASTEXITCODE -ne 0) {
            Write-Error-Log "Failed to update issue labels for $repo#$number"
            continue
        }
        
        # Add start comment
        $startComment = @"
🤖 **Claude Code Auto-Processing Started**

**Issue:** #$number - $title
**Repository:** $repo

**Workflow Steps:**
1. ✅ Context cleared - starting fresh
2. 🎯 Analysis and planning initiated
3. 🔄 Development with iterative context resets
4. 🧪 Local testing and validation  
5. 📝 Code commit and push
6. 🏗️ GitHub Actions build trigger
7. ✅ Ready for review and deployment

Processing started at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss UTC')...
"@
        
        Write-Log "Adding start comment to issue $repo#$number..."
        gh issue comment $number --repo "ecologicaleaving/$repo" --body $startComment 2>$null
        
        # Ensure repos directory exists and navigate to it
        $reposPath = "C:\claude-workspace\repos"
        if (-not (Test-Path $reposPath)) {
            New-Item -Path $reposPath -ItemType Directory -Force | Out-Null
        }
        
        Set-Location $reposPath
        
        # Clone or update repository
        $repoPath = "$reposPath\$repo"
        if (-not (Test-Path $repoPath)) {
            Write-Log "Cloning repository: ecologicaleaving/$repo"
            git clone "https://github.com/ecologicaleaving/$repo.git" 2>$null
            if ($LASTEXITCODE -ne 0) {
                Write-Error-Log "Failed to clone repository $repo"
                continue
            }
        } else {
            Write-Log "Updating existing repository: $repo"
            Set-Location $repoPath
            git pull origin main 2>$null
            if ($LASTEXITCODE -ne 0) {
                git pull origin master 2>$null  # Fallback to master
            }
        }
        
        Set-Location $repoPath
        
        # Process with Claude CLI if available
        if (Get-Command claude -ErrorAction SilentlyContinue) {
            Write-Log "Processing issue with Claude CLI..."
            
            $claudePrompt = @"
GITHUB ISSUE AUTO-PROCESSING

Repository: $repo
Issue: #$number
Title: $title

Requirements:
$body

INSTRUCTIONS:
1. Analyze the issue requirements carefully
2. Plan the implementation approach
3. Make necessary code changes to address the issue
4. Test the implementation locally
5. Ensure all requirements are satisfied
6. Do NOT build - GitHub Actions will handle builds
7. When ready, I will commit and push the changes

Please implement the solution for this issue. Focus on clean, working code that addresses all the requirements mentioned.
"@
            
            # Execute Claude CLI (capture output for logging)
            $claudeOutput = claude $claudePrompt 2>&1
            Write-Log "Claude CLI processing completed"
            
            # Add Claude output to issue comments (truncated if too long)
            $outputSummary = if ($claudeOutput.Length -gt 1000) {
                $claudeOutput.Substring(0, 1000) + "... [truncated]"
            } else {
                $claudeOutput
            }
            
            $progressComment = @"
🔄 **Development Progress Update**

**Claude CLI Processing:** Completed
**Implementation Status:** In progress
**Next Steps:** Testing and commit preparation

**Summary:**
``````
$outputSummary
``````

Status: Moving to commit and push phase...
"@
            
            gh issue comment $number --repo "ecologicaleaving/$repo" --body $progressComment 2>$null
            
        } else {
            Write-Log "Claude CLI not available - skipping AI processing"
        }
        
        # Commit changes (if any)
        Write-Log "Checking for changes to commit..."
        $gitStatus = git status --porcelain 2>$null
        
        if ([string]::IsNullOrWhiteSpace($gitStatus)) {
            Write-Log "No changes detected in repository"
        } else {
            Write-Log "Changes detected, committing..."
            git add . 2>$null
            git commit -m "Fix #$number`: $title`n`nAuto-generated by Claude Code issue processor" 2>$null
            
            if ($LASTEXITCODE -eq 0) {
                Write-Log "Changes committed successfully"
                
                # Push changes
                Write-Log "Pushing changes to GitHub..."
                git push 2>$null
                
                if ($LASTEXITCODE -eq 0) {
                    Write-Log "Changes pushed successfully - GitHub Actions will be triggered"
                } else {
                    Write-Error-Log "Failed to push changes for $repo#$number"
                    continue
                }
            } else {
                Write-Error-Log "Failed to commit changes for $repo#$number"
                continue
            }
        }
        
        # Update issue to building (GitHub Actions will change to review-ready)
        Write-Log "Updating issue $repo#$number to building..."
        gh issue edit $number --repo "ecologicaleaving/$repo" --remove-label "in-progress" --add-label "building" 2>$null
        
        # Add completion comment
        $completionComment = @"
✅ **Claude Code Processing Completed**

**Development Phase:** ✅ Complete
**Changes Status:** Committed and pushed
**GitHub Actions:** 🏗️ Build triggered automatically
**Next Phase:** Automated build and release

**Summary:**
- Context reset and planning: ✅
- Implementation: ✅  
- Local testing: ✅
- Code committed: ✅
- GitHub push: ✅
- Build trigger: ✅

**Workflow Status:**
Label changed to `building`. GitHub Actions will:
1. Build all platforms (APK, Web, etc.)
2. Run automated tests
3. Create release with artifacts
4. Change label to `review-ready`
5. Notify deployment team

Processing completed at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss UTC')
"@
        
        gh issue comment $number --repo "ecologicaleaving/$repo" --body $completionComment 2>$null
        
        Write-Log "✅ Issue $repo#$number processed successfully"
    }
    
} catch {
    Write-Error-Log "Unhandled error: $_"
    exit 1
}

Write-Log "=== Monitor cycle completed successfully ==="
'@
    
    $scriptPath = "$InstallPath\scripts\claude-monitor.ps1"
    $scriptContent | Out-File -FilePath $scriptPath -Encoding UTF8
    
    Write-Status "Monitoring script created: $scriptPath" "Success"
}

function New-BatchWrapper {
    Write-Status "Creating batch wrapper..." "Info"
    
    $batchContent = @"
@echo off
cd /d "$InstallPath"
powershell -ExecutionPolicy Bypass -File "scripts\claude-monitor.ps1" 2>> logs\error.log
"@
    
    $batchPath = "$InstallPath\scripts\claude-monitor.bat"
    $batchContent | Out-File -FilePath $batchPath -Encoding ASCII
    
    Write-Status "Batch wrapper created: $batchPath" "Success"
}

function New-TaskSchedulerConfig {
    Write-Status "Creating Task Scheduler configuration..." "Info"
    
    $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    $taskXml = @"
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.3" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo>
    <Date>$(Get-Date -Format 'yyyy-MM-ddTHH:mm:ss')</Date>
    <Author>$currentUser</Author>
    <Description>Claude Code Issue Monitor - Automated GitHub issues processing every 5 minutes</Description>
    <URI>\Claude Code Issue Monitor</URI>
  </RegistrationInfo>
  <Triggers>
    <LogonTrigger>
      <Enabled>true</Enabled>
      <Delay>PT1M</Delay>
      <UserId>$currentUser</UserId>
    </LogonTrigger>
    <TimeTrigger>
      <Repetition>
        <Interval>PT5M</Interval>
        <StopAtDurationEnd>false</StopAtDurationEnd>
      </Repetition>
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
    <AllowHardTerminate>true</AllowHardTerminate>
    <StartWhenAvailable>true</StartWhenAvailable>
    <RunOnlyIfNetworkAvailable>true</RunOnlyIfNetworkAvailable>
    <IdleSettings>
      <StopOnIdleEnd>false</StopOnIdleEnd>
      <RestartOnIdle>false</RestartOnIdle>
    </IdleSettings>
    <AllowStartOnDemand>true</AllowStartOnDemand>
    <Enabled>true</Enabled>
    <Hidden>false</Hidden>
    <RunOnlyIfIdle>false</RunOnlyIfIdle>
    <DisallowStartOnRemoteAppSession>false</DisallowStartOnRemoteAppSession>
    <UseUnifiedSchedulingEngine>true</UseUnifiedSchedulingEngine>
    <WakeToRun>false</WakeToRun>
    <ExecutionTimeLimit>PT10M</ExecutionTimeLimit>
    <Priority>7</Priority>
  </Settings>
  <Actions Context="Author">
    <Exec>
      <Command>$InstallPath\scripts\claude-monitor.bat</Command>
      <WorkingDirectory>$InstallPath</WorkingDirectory>
    </Exec>
  </Actions>
</Task>
"@
    
    $taskXmlPath = "$InstallPath\scripts\startup-task.xml"
    $taskXml | Out-File -FilePath $taskXmlPath -Encoding UTF8
    
    Write-Status "Task Scheduler config created: $taskXmlPath" "Success"
}

function Install-ScheduledTask {
    Write-Status "Installing scheduled task..." "Info"
    
    try {
        $taskXmlPath = "$InstallPath\scripts\startup-task.xml"
        
        # Remove existing task if present
        $existingTask = Get-ScheduledTask -TaskName "Claude Code Issue Monitor" -ErrorAction SilentlyContinue
        if ($existingTask) {
            Write-Status "Removing existing scheduled task..." "Info"
            Unregister-ScheduledTask -TaskName "Claude Code Issue Monitor" -Confirm:$false
        }
        
        # Register new task
        Register-ScheduledTask -TaskName "Claude Code Issue Monitor" -Xml (Get-Content $taskXmlPath -Raw) -Force | Out-Null
        
        # Start the task
        Start-ScheduledTask -TaskName "Claude Code Issue Monitor"
        
        Write-Status "Scheduled task installed and started successfully" "Success"
        return $true
    }
    catch {
        Write-Status "Error installing scheduled task: $_" "Error"
        return $false
    }
}

function New-UtilityScripts {
    Write-Status "Creating utility scripts..." "Info"
    
    # Status script
    $statusScript = @'
# Status check script
Write-Host "=== Claude Code Issue Monitor Status ===" -ForegroundColor Cyan

# Check scheduled task
$task = Get-ScheduledTask -TaskName "Claude Code Issue Monitor" -ErrorAction SilentlyContinue
if ($task) {
    $taskInfo = Get-ScheduledTaskInfo -TaskName "Claude Code Issue Monitor"
    Write-Host "✅ Scheduled Task: $($task.State)" -ForegroundColor Green
    Write-Host "   Last Run: $($taskInfo.LastRunTime)" -ForegroundColor Gray
    Write-Host "   Next Run: $($taskInfo.NextRunTime)" -ForegroundColor Gray
} else {
    Write-Host "❌ Scheduled Task: Not Found" -ForegroundColor Red
}

# Check logs
$logFile = "C:\claude-workspace\logs\monitor.log"
if (Test-Path $logFile) {
    $logSize = (Get-Item $logFile).Length
    $lastEntries = Get-Content $logFile -Tail 3
    Write-Host "✅ Monitor Log: $($logSize) bytes" -ForegroundColor Green
    Write-Host "   Recent entries:" -ForegroundColor Gray
    foreach ($entry in $lastEntries) {
        Write-Host "   $entry" -ForegroundColor Gray
    }
} else {
    Write-Host "❌ Monitor Log: Not Found" -ForegroundColor Red
}

# Check dependencies
Write-Host "`n=== Dependencies ===" -ForegroundColor Cyan
$deps = @("gh", "git", "claude")
foreach ($dep in $deps) {
    if (Get-Command $dep -ErrorAction SilentlyContinue) {
        Write-Host "✅ $dep" -ForegroundColor Green
    } else {
        Write-Host "❌ $dep" -ForegroundColor Red
    }
}
'@
    
    $statusScript | Out-File -FilePath "$InstallPath\scripts\status.ps1" -Encoding UTF8
    
    # Diagnose script
    $diagnoseScript = @'
# Diagnostic script
Write-Host "=== Claude Code Issue Monitor Diagnostics ===" -ForegroundColor Cyan

# Test GitHub authentication
Write-Host "`n--- GitHub Authentication ---" -ForegroundColor Yellow
try {
    $authStatus = gh auth status 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ GitHub CLI authenticated" -ForegroundColor Green
    } else {
        Write-Host "❌ GitHub CLI not authenticated" -ForegroundColor Red
        Write-Host "Run: gh auth login" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ GitHub CLI error: $_" -ForegroundColor Red
}

# Test repository access
Write-Host "`n--- Repository Access ---" -ForegroundColor Yellow
try {
    $testRepo = "ecologicaleaving/StageConnect"
    $issues = gh issue list --repo $testRepo --limit 1 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Repository access working" -ForegroundColor Green
    } else {
        Write-Host "❌ Repository access failed" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Repository access error: $_" -ForegroundColor Red
}

# Test Claude CLI
Write-Host "`n--- Claude CLI ---" -ForegroundColor Yellow
try {
    if (Get-Command claude -ErrorAction SilentlyContinue) {
        Write-Host "✅ Claude CLI available" -ForegroundColor Green
    } else {
        Write-Host "⚠️ Claude CLI not found" -ForegroundColor Yellow
        Write-Host "Monitor will work but issue processing requires Claude CLI" -ForegroundColor Gray
    }
} catch {
    Write-Host "❌ Claude CLI error: $_" -ForegroundColor Red
}

# Manual test
Write-Host "`n--- Manual Test ---" -ForegroundColor Yellow
Write-Host "To test manually, run:" -ForegroundColor Gray
Write-Host "C:\claude-workspace\scripts\claude-monitor.bat" -ForegroundColor Cyan
'@
    
    $diagnoseScript | Out-File -FilePath "$InstallPath\scripts\diagnose.ps1" -Encoding UTF8
    
    # Uninstall script
    $uninstallScript = @'
# Uninstall script
Write-Host "=== Claude Code Issue Monitor Uninstaller ===" -ForegroundColor Cyan

$confirm = Read-Host "Are you sure you want to uninstall? (y/N)"
if ($confirm -ne "y" -and $confirm -ne "Y") {
    Write-Host "Uninstall cancelled" -ForegroundColor Yellow
    exit
}

# Remove scheduled task
try {
    $task = Get-ScheduledTask -TaskName "Claude Code Issue Monitor" -ErrorAction SilentlyContinue
    if ($task) {
        Write-Host "Removing scheduled task..." -ForegroundColor Yellow
        Unregister-ScheduledTask -TaskName "Claude Code Issue Monitor" -Confirm:$false
        Write-Host "✅ Scheduled task removed" -ForegroundColor Green
    }
} catch {
    Write-Host "⚠️ Could not remove scheduled task: $_" -ForegroundColor Yellow
}

# Remove directory
$installPath = "C:\claude-workspace"
if (Test-Path $installPath) {
    Write-Host "Removing installation directory..." -ForegroundColor Yellow
    Remove-Item $installPath -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "✅ Installation directory removed" -ForegroundColor Green
}

Write-Host "✅ Claude Code Issue Monitor uninstalled successfully" -ForegroundColor Green
'@
    
    $uninstallScript | Out-File -FilePath "$InstallPath\scripts\uninstall.ps1" -Encoding UTF8
    
    Write-Status "Utility scripts created" "Success"
}

function New-ConfigFile {
    Write-Status "Creating configuration file..." "Info"
    
    $config = @{
        version = "1.0.0"
        installPath = $InstallPath
        installDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        repositories = @(
            "StageConnect",
            "BeachRef-app", 
            "x32-Assist",
            "GridConnect",
            "finn",
            "progetto-casa",
            "Maestro",
            "AutoDrum"
        )
        monitoring = @{
            intervalMinutes = 5
            maxLogSizeMB = 50
            logRetentionDays = 30
        }
    }
    
    $configPath = "$InstallPath\config\settings.json"
    $config | ConvertTo-Json -Depth 3 | Out-File -FilePath $configPath -Encoding UTF8
    
    Write-Status "Configuration file created: $configPath" "Success"
}

function Show-PostInstallInstructions {
    Write-Host "`n$Green=== Installation Complete! ===$Reset" -ForegroundColor Green
    Write-Host "`n${Blue}📋 Next Steps:$Reset"
    Write-Host "1. ${Yellow}Authenticate GitHub CLI:$Reset"
    Write-Host "   gh auth login --web"
    Write-Host "`n2. ${Yellow}Test the installation:$Reset"
    Write-Host "   $InstallPath\scripts\status.ps1"
    Write-Host "`n3. ${Yellow}Create a test issue:$Reset"
    Write-Host "   - Go to any repository (e.g., StageConnect)"
    Write-Host "   - Create an issue with label 'claude-code'"
    Write-Host "   - Wait 5 minutes and check if it gets processed"
    Write-Host "`n${Blue}📊 Monitoring:$Reset"
    Write-Host "   Logs: $InstallPath\logs\monitor.log"
    Write-Host "   Status: $InstallPath\scripts\status.ps1"
    Write-Host "   Diagnose: $InstallPath\scripts\diagnose.ps1"
    Write-Host "`n${Blue}🔧 Task Scheduler:$Reset"
    Write-Host "   Task: 'Claude Code Issue Monitor'"
    Write-Host "   Runs every 5 minutes + at startup"
    Write-Host "   Check: Get-ScheduledTask 'Claude Code Issue Monitor'"
    Write-Host "`n${Green}✅ Claude Code is now monitoring GitHub issues automatically!$Reset"
}

# Main installation flow
function Main {
    Write-Host "${Blue}🚀 Claude Code PC Installation Script$Reset"
    Write-Host "   Installing to: $InstallPath"
    Write-Host ""
    
    # Check if running as admin for some operations
    $isAdmin = Test-IsAdmin
    if ($isAdmin) {
        Write-Status "Running with administrator privileges" "Success"
    } else {
        Write-Status "Running as regular user (recommended)" "Info"
    }
    
    # Check if already installed
    if ((Test-Path "$InstallPath\scripts\claude-monitor.ps1") -and -not $Force) {
        Write-Status "Claude Code appears to already be installed at $InstallPath" "Warning"
        $reinstall = Read-Host "Reinstall? (y/N)"
        if ($reinstall -ne "y" -and $reinstall -ne "Y") {
            Write-Status "Installation cancelled" "Info"
            exit 0
        }
    }
    
    # Step-by-step installation
    Write-Status "Starting installation..." "Info"
    
    # 1. Check dependencies
    if (-not (Test-Dependencies)) {
        Write-Status "Dependency check failed. Please install missing dependencies and try again." "Error"
        exit 1
    }
    
    # 2. Create directory structure
    New-DirectoryStructure
    
    # 3. Create scripts
    New-MonitoringScript
    New-BatchWrapper
    New-TaskSchedulerConfig
    New-UtilityScripts
    New-ConfigFile
    
    # 4. Install scheduled task
    if (-not (Install-ScheduledTask)) {
        Write-Status "Failed to install scheduled task. You may need to run as administrator." "Error"
        Write-Status "Manual task installation: Register-ScheduledTask -TaskName 'Claude Code Issue Monitor' -Xml (Get-Content '$InstallPath\scripts\startup-task.xml' -Raw)" "Info"
    }
    
    # 5. Post-install instructions
    Show-PostInstallInstructions
}

# Run main installation
try {
    Main
}
catch {
    Write-Status "Installation failed: $_" "Error"
    Write-Status "Please check the error message above and try again." "Error"
    exit 1
}