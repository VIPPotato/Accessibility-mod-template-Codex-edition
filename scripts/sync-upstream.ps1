[CmdletBinding()]
param(
    [string]$UpstreamUrl = "https://github.com/HappyStarfish/Accessibility-mod-template.git",
    [string]$UpstreamBranch = "master",
    [string]$Branch = "master",
    [switch]$Commit,
    [switch]$Push
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host "[sync] $Message"
}

function Invoke-Git {
    param(
        [Parameter(Mandatory = $true, ValueFromRemainingArguments = $true)]
        [string[]]$Args
    )

    & git @Args
    if ($LASTEXITCODE -ne 0) {
        throw "git $($Args -join ' ') failed"
    }
}

function Get-ChangedPathsFromWorkingTree {
    $paths = New-Object System.Collections.Generic.List[string]

    @(
        (& git diff --name-only --cached),
        (& git diff --name-only)
    ) | ForEach-Object {
        foreach ($line in $_) {
            $trimmed = $line.Trim()
            if ($trimmed -ne "") {
                $paths.Add($trimmed)
            }
        }
    }

    return ($paths | Sort-Object -Unique)
}

function Resolve-KnownMergeConflicts {
    $unmerged = @(
        (& git diff --name-only --diff-filter=U) |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ -ne "" }
    )

    if ($unmerged.Count -eq 0) {
        return
    }

    $unsupported = @($unmerged | Where-Object { $_ -notmatch '(?i)CLAUDE\.md$' })
    if ($unsupported.Count -gt 0) {
        $list = $unsupported -join ", "
        throw "Merge conflict requires manual resolution: $list"
    }

    Write-Step "Auto-resolving CLAUDE.md conflict(s) by taking upstream file, then reapplying customizations."
    foreach ($path in $unmerged) {
        Invoke-Git checkout --theirs -- $path
        Invoke-Git add -- $path
    }
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
Set-Location -LiteralPath $repoRoot

Write-Step "Checking current branch"
$currentBranch = (& git rev-parse --abbrev-ref HEAD).Trim()
if ($currentBranch -ne $Branch) {
    throw "Current branch is '$currentBranch'. Checkout '$Branch' first."
}

Write-Step "Checking for a clean working tree"
$status = & git status --porcelain
if ($status) {
    throw "Working tree is not clean. Commit or stash changes first."
}

Write-Step "Ensuring upstream remote exists"
$remotes = @(& git remote)
if (-not ($remotes -contains "upstream")) {
    Invoke-Git remote add upstream $UpstreamUrl
    Write-Step "Added remote 'upstream' -> $UpstreamUrl"
}
else {
    $currentUpstream = (& git remote get-url upstream).Trim()
    if ($currentUpstream -ne $UpstreamUrl) {
        Invoke-Git remote set-url upstream $UpstreamUrl
        Write-Step "Updated remote 'upstream' URL"
    }
}

Write-Step "Fetching upstream"
Invoke-Git fetch upstream

Write-Step "Capturing pre-merge commit"
$beforeSha = (& git rev-parse HEAD).Trim()

Write-Step "Merging upstream/$UpstreamBranch into $Branch"
$mergeOutput = & git merge "upstream/$UpstreamBranch" --no-edit 2>&1
$mergeExit = $LASTEXITCODE
if ($mergeExit -ne 0) {
    Write-Step "Merge reported conflicts. Attempting known auto-resolution paths."
    Resolve-KnownMergeConflicts

    $remainingUnmerged = @(
        (& git diff --name-only --diff-filter=U) |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ -ne "" }
    )
    if ($remainingUnmerged.Count -gt 0) {
        $list = $remainingUnmerged -join ", "
        throw "Unresolved merge conflicts remain: $list"
    }

    & git rev-parse -q --verify MERGE_HEAD *> $null
    if ($LASTEXITCODE -ne 0) {
        throw "git merge failed before conflict resolution could proceed. Output: $mergeOutput"
    }
}

Write-Step "Collecting files changed by merge"
$currentHead = (& git rev-parse HEAD).Trim()
if ($currentHead -ne $beforeSha) {
    $changedPaths = @(
        (& git diff --name-only "$beforeSha..HEAD") |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ -ne "" }
    )
}
else {
    $changedPaths = @(Get-ChangedPathsFromWorkingTree)
}

if ($changedPaths.Count -eq 0) {
    Write-Step "No upstream file changes detected. Skipping customization pass."
}
else {
    Write-Step "Files changed by upstream merge: $($changedPaths.Count)"
    Write-Step "Applying codex fork customizations to changed files"
    $customizeScript = Join-Path $PSScriptRoot "apply-codex-fork-customizations.ps1"
    & $customizeScript -RepoRoot $repoRoot -OnlyChangedPaths $changedPaths
    if ($LASTEXITCODE -ne 0) {
        throw "Customization script failed."
    }
}

$postStatus = & git status --porcelain
if (-not $postStatus) {
    Write-Step "No additional customization changes detected."
    Write-Step "Sync complete."
    exit 0
}

Write-Step "Customization changes detected. Review with: git status && git diff"

if ($Commit) {
    Invoke-Git add -A
    Invoke-Git commit -m "Apply Codex fork customizations"
    Write-Step "Committed customization changes."
}

if ($Push) {
    Invoke-Git push origin $Branch
    Write-Step "Pushed to origin/$Branch"
}

Write-Step "Sync complete."
