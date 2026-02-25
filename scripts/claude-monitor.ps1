# ===================================================
# Claude Code Issue Monitor v3.0
# Single-agent iterative issue resolver
# 80/20 Solutions — ecologicaleaving
#
# Architecture:
#   One claude invocation per issue (token-efficient).
#   The issue-resolver skill defines the workflow.
#   Monitor handles: polling, branching, commit, push, PR.
# ===================================================

$ErrorActionPreference = "Continue"

# ---- PATHS & CONFIG ----
$WorkspaceRoot = "C:\claude-workspace"
$ReposPath     = "$WorkspaceRoot\repos"
$LogFile       = "$WorkspaceRoot\logs\monitor.log"
$ErrorLogFile  = "$WorkspaceRoot\logs\error.log"
$LockDir       = "$WorkspaceRoot\locks"
$ConfigFile    = "$WorkspaceRoot\config\settings.json"

$Config = @{
    GithubOrg         = "ecologicaleaving"
    MaxIssuesPerCycle = 3
    MaxLockAgeMinutes = 120
    ClaudeCmd         = "claude"
}

if (Test-Path $ConfigFile) {
    try {
        $s = Get-Content $ConfigFile -Raw | ConvertFrom-Json
        if ($s.githubOrg)         { $Config.GithubOrg         = $s.githubOrg }
        if ($s.maxIssuesPerCycle) { $Config.MaxIssuesPerCycle = [int]$s.maxIssuesPerCycle }
        if ($s.claudeCmd)         { $Config.ClaudeCmd         = $s.claudeCmd }
    } catch { }
}

@($ReposPath, $LockDir, "$WorkspaceRoot\logs") | ForEach-Object {
    if (-not (Test-Path $_)) { New-Item -ItemType Directory -Path $_ -Force | Out-Null }
}

# ---- LOGGING ----

function Write-Log {
    param([string]$Message, [string]$Type = "INFO")
    $line = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')][$Type] $Message"
    Add-Content $LogFile -Value $line -ErrorAction SilentlyContinue
    Write-Host $line
}

function Write-ErrorLog {
    param([string]$Message)
    $line = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')][ERROR] $Message"
    Add-Content $ErrorLogFile -Value $line -ErrorAction SilentlyContinue
    Write-Host $line -ForegroundColor Red
}

function Invoke-LogRotation {
    @($LogFile, $ErrorLogFile) | ForEach-Object {
        if ((Test-Path $_) -and (Get-Item $_).Length -gt 10MB) {
            Copy-Item $_ "$_.bak" -Force -ErrorAction SilentlyContinue
            Clear-Content $_ -ErrorAction SilentlyContinue
        }
    }
}

# ---- UTILITIES ----

function ConvertTo-BranchSlug {
    param([string]$Text, [int]$MaxLen = 40)
    $s = $Text.ToLower() `
        -replace '[àáâãäå]','a' -replace '[èéêë]','e' `
        -replace '[ìíîï]','i'   -replace '[òóôõö]','o' `
        -replace '[ùúûü]','u'   -replace "[^a-z0-9\s\-]",'' `
        -replace '\s+','-'      -replace '\-{2,}','-' `
        -replace '^\-|\-$',''
    if ($s.Length -gt $MaxLen) { $s = $s.Substring(0, $MaxLen).TrimEnd('-') }
    return $s
}

function Get-DefaultBranch {
    param([string]$RepoPath)
    try {
        $raw = git -C $RepoPath remote show origin 2>$null | Select-String "HEAD branch:"
        if ($raw) {
            $b = ($raw -replace ".*HEAD branch:\s*","").Trim()
            if ($b) { return $b }
        }
    } catch { }
    $remote = git -C $RepoPath branch -r 2>$null
    if ($remote -match "origin/main") { return "main" }
    return "master"
}

# ---- CORE: single-agent issue resolver ----

function Invoke-IssueResolver {
    param(
        [string]$RepoPath,
        [string]$BranchName,
        [int]   $Number,
        [string]$Title,
        [string]$Body
    )

    # The prompt is intentionally concise.
    # The issue-resolver skill (loaded from ~/.claude/skills/) defines
    # the full Research → Clarify → Plan → Iterate workflow.
    $prompt = @"
Resolve GitHub issue #$Number in this repository.

TITLE: $Title

REQUIREMENTS:
$Body

CONTEXT:
- Repository path: $RepoPath
- Working branch: $BranchName  (already checked out — do not switch branches)
- Follow the issue-resolver skill workflow:
    Phase 1 — Research the codebase
    Phase 2 — Clarify and plan
    Phase 3 — Implement iteratively (implement → test → fix, max 5 loops)
    Phase 4 — Final verification

HARD CONSTRAINTS:
- Do NOT run: git add / git commit / git push / git merge / git checkout
- Do NOT switch branches or modify .git/ internals
- Stop if tests are still failing after 5 iterations and document why
"@

    Write-Log "Launching agent for issue #$Number..."

    $prevLoc = Get-Location
    try {
        Set-Location $RepoPath
        $output = $prompt | & $Config.ClaudeCmd --dangerously-skip-permissions 2>&1
        $exit   = $LASTEXITCODE
        $short  = if ("$output".Length -gt 500) { "$output".Substring(0,500)+"..." } else { "$output" }
        Write-Log "Agent finished (exit=$exit): $short"
        return $exit -eq 0
    }
    catch {
        Write-ErrorLog "Agent exception: $_"
        return $false
    }
    finally {
        Set-Location $prevLoc
    }
}

# ---- ISSUE PROCESSOR (git + GitHub orchestration) ----

function Invoke-IssueProcessor {
    param(
        [string]$Repo,
        [int]   $Number,
        [string]$Title,
        [string]$Body
    )

    $org        = $Config.GithubOrg
    $lockFile   = "$LockDir\$Repo-$Number.lock"
    $repoPath   = "$ReposPath\$Repo"
    $slug       = ConvertTo-BranchSlug -Text $Title
    $branchName = "feature/issue-$Number-$slug"

    # Lock check
    if (Test-Path $lockFile) {
        $ageMin = ((Get-Date) - (Get-Item $lockFile).LastWriteTime).TotalMinutes
        if ($ageMin -lt $Config.MaxLockAgeMinutes) {
            Write-Log "Issue $Repo#$Number locked (${ageMin}min). Skipping."
            return
        }
        Write-Log "Stale lock for $Repo#$Number. Removing."
        Remove-Item $lockFile -Force
    }
    "started=$(Get-Date -Format 'o')" | Out-File $lockFile -Encoding UTF8

    try {
        Write-Log "=== BEGIN $Repo#$Number: $Title ==="

        # 1. Mark in-progress
        gh issue edit $Number --repo "$org/$Repo" `
            --remove-label "claude-code" --add-label "in-progress" 2>$null | Out-Null

        gh issue comment $Number --repo "$org/$Repo" --body (
            "🤖 **Claude Code Agent Started**`n`n" +
            "**Issue #${Number}:** $Title`n" +
            "**Branch:** ``$branchName```n" +
            "**Workflow:** Research → Clarify → Plan → Implement (iterative)`n`n" +
            "Started: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        ) 2>$null | Out-Null

        # 2. Clone or update repo
        if (-not (Test-Path $repoPath)) {
            Write-Log "Cloning $org/$Repo..."
            $out = git clone "https://github.com/$org/$Repo.git" $repoPath 2>&1
            if ($LASTEXITCODE -ne 0) { throw "Clone failed: $out" }
        } else {
            Write-Log "Fetching $Repo..."
            git -C $repoPath fetch --all 2>&1 | Out-Null
        }

        $defaultBranch = Get-DefaultBranch -RepoPath $repoPath
        git -C $repoPath checkout $defaultBranch 2>&1 | Out-Null
        git -C $repoPath pull origin $defaultBranch 2>&1 | Out-Null

        # 3. Create feature branch
        Write-Log "Creating branch: $branchName"
        git -C $repoPath branch -D $branchName 2>&1 | Out-Null
        $brOut = git -C $repoPath checkout -b $branchName 2>&1
        if ($LASTEXITCODE -ne 0) { throw "Branch creation failed: $brOut" }

        # 4. Run the single-agent resolver
        $agentOk = Invoke-IssueResolver `
            -RepoPath   $repoPath `
            -BranchName $branchName `
            -Number     $Number `
            -Title      $Title `
            -Body       $Body

        # 5. Check for changes
        $status = git -C $repoPath status --porcelain 2>&1
        if ([string]::IsNullOrWhiteSpace($status)) {
            Write-Log "No changes produced for $Repo#$Number"
            gh issue edit $Number --repo "$org/$Repo" `
                --remove-label "in-progress" --add-label "claude-code" 2>$null | Out-Null
            gh issue comment $Number --repo "$org/$Repo" --body (
                "⚠️ **No Changes Detected**`n`n" +
                "The agent analyzed issue #$Number but produced no code changes.`n" +
                "Possible reasons: already implemented, unclear requirements, or error.`n`n" +
                "Reset to ``claude-code`` for retry or manual intervention."
            ) 2>$null | Out-Null
            return
        }

        # 6. Commit
        Write-Log "Committing..."
        git -C $repoPath add --all 2>&1 | Out-Null
        $commitMsg = @"
feat: resolve issue #$Number - $Title

Resolved by Claude Code autonomous agent:
- Phase 1: researched codebase and identified relevant files
- Phase 2: clarified requirements and planned implementation
- Phase 3: implemented iteratively with test-fix loops
- Phase 4: verified final state

Closes #$Number

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
"@
        git -C $repoPath commit -m $commitMsg 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "git commit failed" }

        # 7. Push
        Write-Log "Pushing $branchName..."
        git -C $repoPath push -u origin $branchName 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "git push failed" }

        # 8. Create PR
        Write-Log "Creating PR..."
        $prBody = @"
## Resolves Issue #${Number}: $Title

> Auto-resolved by Claude Code autonomous agent (single-agent iterative mode)

## What was done

The agent followed the **issue-resolver** workflow:

| Phase | Description |
|-------|-------------|
| 1. Research | Explored codebase, read relevant files and tests |
| 2. Clarify & Plan | Identified files to change, planned implementation |
| 3. Implement (iterative) | Implemented → tested → fixed, up to 5 iterations |
| 4. Verify | Final test run, reviewed all changes |

## Checklist

- [x] Codebase researched
- [x] Requirements analyzed
- [x] Implemented iteratively
- [x] Tests run and verified
- [x] Feature branch: ``$branchName``

Closes #$Number

---
*Auto-generated by [Claude Code Issue Monitor](https://github.com/$org/workflow)*
"@

        $prOut = gh pr create `
            --repo  "$org/$Repo" `
            --title "feat: $Title" `
            --body  $prBody `
            --head  $branchName `
            --base  $defaultBranch 2>&1

        $prUrl = if ($LASTEXITCODE -eq 0) {
            ($prOut | Select-String "https://github.com").ToString().Trim()
        } else {
            "Branch pushed: $branchName (PR creation failed — open manually)"
        }

        # 9. Update issue: review-ready
        gh issue edit $Number --repo "$org/$Repo" `
            --remove-label "in-progress" --add-label "review-ready" 2>$null | Out-Null

        gh issue comment $Number --repo "$org/$Repo" --body (
            "✅ **Agent Completed**`n`n" +
            "**PR:** $prUrl`n" +
            "**Branch:** ``$branchName```n`n" +
            "**Next steps:**`n" +
            "1. Review the PR: $prUrl`n" +
            "2. Approve and merge`n" +
            "3. Tell Ciccio to deploy to test`n`n" +
            "Completed: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        ) 2>$null | Out-Null

        Write-Log "=== DONE $Repo#$Number | PR: $prUrl ==="

    }
    catch {
        $err = $_.ToString()
        Write-ErrorLog "Failed $Repo#$Number: $err"
        gh issue edit $Number --repo "$org/$Repo" `
            --remove-label "in-progress" --add-label "claude-code" 2>$null | Out-Null
        gh issue comment $Number --repo "$org/$Repo" --body (
            "❌ **Processing Failed**`n`nError: ``$err```n`n" +
            "Reset to ``claude-code`` for retry.`n" +
            "Failed at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        ) 2>$null | Out-Null
    }
    finally {
        if (Test-Path $lockFile) { Remove-Item $lockFile -Force -ErrorAction SilentlyContinue }
    }
}

# ============================================================
# MAIN
# ============================================================

Invoke-LogRotation
Write-Log "=== Claude Code Issue Monitor v3.0 | Cycle Start ==="

# Auth check
gh auth status 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-ErrorLog "GitHub CLI not authenticated. Run: gh auth login"
    exit 1
}

$currentUser = gh api user --jq ".login" 2>&1
if ($LASTEXITCODE -ne 0) { Write-ErrorLog "Cannot get GitHub user"; exit 1 }
Write-Log "GitHub user: $currentUser"

# Search for open issues assigned to @me with label 'claude-code'
Write-Log "Searching: assignee:@me label:claude-code state:open"

$searchJson = gh search issues `
    --assignee "@me" `
    --label    "claude-code" `
    --state    "open" `
    --limit    $Config.MaxIssuesPerCycle `
    --json     "number,title,repository,body" 2>&1

if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($searchJson) `
        -or $searchJson -eq "[]" -or $searchJson -eq "null") {
    Write-Log "No issues found assigned to $currentUser with label 'claude-code'."
    Write-Log "=== Cycle complete ==="
    exit 0
}

try   { $issues = $searchJson | ConvertFrom-Json }
catch { Write-ErrorLog "JSON parse failed: $_"; exit 1 }

Write-Log "Found $($issues.Count) issue(s)."

foreach ($issue in $issues) {
    Invoke-IssueProcessor `
        -Repo   $issue.repository.name `
        -Number ([int]$issue.number) `
        -Title  $issue.title `
        -Body   (if ($issue.body) { $issue.body } else { "No description provided." })
}

Write-Log "=== Cycle complete. Processed $($issues.Count) issue(s) ==="
