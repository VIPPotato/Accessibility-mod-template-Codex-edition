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
Invoke-Git merge "upstream/$UpstreamBranch" --no-edit

Write-Step "Collecting files changed by merge"
$changedPaths = @(
    (& git diff --name-only "$beforeSha..HEAD") |
    ForEach-Object { $_.Trim() } |
    Where-Object { $_ -ne "" }
)

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
