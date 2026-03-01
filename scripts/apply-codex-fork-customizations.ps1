[CmdletBinding()]
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,
    [string[]]$OnlyChangedPaths
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host "[customize] $Message"
}

function Write-Utf8NoBom {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Content
    )

    $encoding = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Content, $encoding)
}

function Normalize-RepoRelativePath {
    param([Parameter(Mandatory = $true)][string]$Path)

    $trimmed = $Path.Trim()
    if ([string]::IsNullOrWhiteSpace($trimmed)) {
        return ""
    }

    $normalized = $trimmed -replace '\\', '/'
    while ($normalized.StartsWith("./")) {
        $normalized = $normalized.Substring(2)
    }

    return $normalized
}

function Resolve-RepoPath {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string]$RelativePath
    )

    $normalized = Normalize-RepoRelativePath -Path $RelativePath
    if ([string]::IsNullOrEmpty($normalized)) {
        return $null
    }

    $candidate = [System.IO.Path]::GetFullPath((Join-Path $Root ($normalized -replace '/', [System.IO.Path]::DirectorySeparatorChar)))
    $rootWithSep = [System.IO.Path]::GetFullPath($Root).TrimEnd('\','/') + [System.IO.Path]::DirectorySeparatorChar
    if (-not $candidate.StartsWith($rootWithSep, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $null
    }

    return $candidate
}

function Is-BinaryFile {
    param([Parameter(Mandatory = $true)][string]$Path)

    $stream = [System.IO.File]::OpenRead($Path)
    try {
        $length = [Math]::Min(4096, [int]$stream.Length)
        if ($length -le 0) {
            return $false
        }

        $buffer = New-Object byte[] $length
        $read = $stream.Read($buffer, 0, $length)
        for ($i = 0; $i -lt $read; $i++) {
            if ($buffer[$i] -eq 0) {
                return $true
            }
        }
    }
    finally {
        $stream.Dispose()
    }

    return $false
}

function Is-SkippedPath {
    param([Parameter(Mandatory = $true)][string]$Path)

    # Skip tooling folders to prevent self-mutation of automation files.
    return $Path -match '[\\/](?:\.git|\.github|\.vs|\.vscode|scripts|bin|obj|decompiled|packages|node_modules)[\\/]'
}

function Test-GitAvailable {
    try {
        & git --version *> $null
        return ($LASTEXITCODE -eq 0)
    }
    catch {
        return $false
    }
}

function Replace-InFile {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][array]$Rules
    )

    $original = Get-Content -Raw -LiteralPath $Path
    $updated = $original

    foreach ($rule in $Rules) {
        $updated = [System.Text.RegularExpressions.Regex]::Replace(
            $updated,
            $rule.Pattern,
            $rule.Replacement,
            [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
        )
    }

    if ($updated -ne $original) {
        Write-Utf8NoBom -Path $Path -Content $updated
        Write-Step "Updated text replacements in: $Path"
        return $true
    }

    return $false
}

function Get-ConflictMarkerFiles {
    param([Parameter(Mandatory = $true)][string[]]$Paths)

    $bad = New-Object System.Collections.Generic.List[string]
    foreach ($path in ($Paths | Sort-Object -Unique)) {
        if (-not (Test-Path -LiteralPath $path)) { continue }
        if (Is-BinaryFile -Path $path) { continue }

        $content = Get-Content -Raw -LiteralPath $path
        $hasStart = $content -match '(?m)^<<<<<<< '
        $hasMid = $content -match '(?m)^=======$'
        $hasEnd = $content -match '(?m)^>>>>>>> '
        if ($hasStart -and $hasMid -and $hasEnd) {
            $bad.Add($path)
        }
    }

    return $bad
}

function Get-LegacyAgentFilePaths {
    param([Parameter(Mandatory = $true)][string]$RepoRootFull)

    $legacy = New-Object System.Collections.Generic.List[string]
    Get-ChildItem -LiteralPath $RepoRootFull -Recurse -File |
        Where-Object {
            -not (Is-SkippedPath -Path $_.FullName) -and
            ($_.Name -ieq "CLAUDE.md" -or $_.Name -ieq "AENTS.md")
        } |
        ForEach-Object { $legacy.Add($_.FullName) }

    return $legacy
}

function Get-ResidualPatternMatches {
    param(
        [Parameter(Mandatory = $true)][string[]]$Paths,
        [Parameter(Mandatory = $true)][array]$Rules
    )

    $hits = New-Object System.Collections.Generic.List[string]
    foreach ($path in ($Paths | Sort-Object -Unique)) {
        if (-not (Test-Path -LiteralPath $path)) { continue }
        if (Is-BinaryFile -Path $path) { continue }

        $content = Get-Content -Raw -LiteralPath $path
        foreach ($rule in $Rules) {
            if ([System.Text.RegularExpressions.Regex]::IsMatch(
                $content,
                $rule.Pattern,
                [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
            )) {
                $hits.Add("$path => /$($rule.Pattern)/")
                break
            }
        }
    }

    return $hits
}

function Ensure-ForkNote {
    param(
        [Parameter(Mandatory = $true)][string]$ReadmePath
    )

    if (-not (Test-Path -LiteralPath $ReadmePath)) {
        return $false
    }

    $startMarker = '<!-- fork-note:start -->'
    $endMarker = '<!-- fork-note:end -->'

    $forkNoteBody = @'
## Fork Note

This repository is a fork of [HappyStarfish/Accessibility-mod-template](https://github.com/HappyStarfish/Accessibility-mod-template).

In this fork, assistant naming was normalized to Codex, and agent-file references were normalized to `AGENTS.md` so Codex can follow the guides more reliably.

I tested this modified template with GPT-5.3 Codex (the latest OpenAI model available at the time of testing), and it worked very well in practice. I hope this helps people who need larger usage limits.

Huge thanks to **Plueschyoda** for creating the original template.
'@

    $forkNote = "$startMarker`r`n$forkNoteBody`r`n$endMarker"
    $noteWithSpacing = "$forkNote`r`n`r`n"

    $original = Get-Content -Raw -LiteralPath $ReadmePath
    $updated = $original
    $legacyPattern = '(?ms)^## Fork Note\s*\r?\n.*?^Huge thanks to \*\*Plueschyoda\*\* for creating the original template\.\s*\r?\n?'

    if ($updated -match '(?ms)<!-- fork-note:start -->.*?<!-- fork-note:end -->') {
        $updated = [System.Text.RegularExpressions.Regex]::Replace(
            $updated,
            '(?ms)<!-- fork-note:start -->.*?<!-- fork-note:end -->(?:\r?\n)*',
            $noteWithSpacing
        )
    }
    elseif ($updated -match $legacyPattern) {
        $updated = [System.Text.RegularExpressions.Regex]::Replace(
            $updated,
            $legacyPattern,
            $noteWithSpacing,
            1
        )
    }
    else {
        $updated = [System.Text.RegularExpressions.Regex]::Replace(
            $updated,
            '(?ms)^(# .+?\r?\n)',
            ('$1' + "`r`n" + $noteWithSpacing),
            1
        )
    }

    if ($updated -ne $original) {
        Write-Utf8NoBom -Path $ReadmePath -Content $updated
        Write-Step "Ensured fork note in: $ReadmePath"
        return $true
    }

    return $false
}

function Assert-TemplateAgentsSafety {
    param(
        [Parameter(Mandatory = $true)][string]$RepoRootFull,
        [Parameter(Mandatory = $true)][string[]]$InspectionPaths,
        [Parameter(Mandatory = $true)][array]$Rules,
        [Parameter(Mandatory = $true)][bool]$ValidateEntireRepo
    )

    $templateAgentsRelative = "Accessibility-Mod-Template/AGENTS.md"
    $templateAgents = Resolve-RepoPath -Root $RepoRootFull -RelativePath $templateAgentsRelative
    if (-not $templateAgents -or -not (Test-Path -LiteralPath $templateAgents)) {
        throw "Safety check failed: missing $templateAgentsRelative"
    }

    $templateClaudeRelative = "Accessibility-Mod-Template/CLAUDE.md"
    $templateClaude = Resolve-RepoPath -Root $RepoRootFull -RelativePath $templateClaudeRelative
    if ($templateClaude -and (Test-Path -LiteralPath $templateClaude)) {
        throw "Safety check failed: $templateClaudeRelative still exists after customization"
    }

    if (Test-GitAvailable) {
        Push-Location -LiteralPath $RepoRootFull
        try {
            & git check-ignore -q -- $templateAgentsRelative
            if ($LASTEXITCODE -eq 0) {
                throw "Safety check failed: $templateAgentsRelative is ignored by .gitignore. Fix ignore rules to allow tracking."
            }
        }
        finally {
            Pop-Location
        }
    }

    $inspection = New-Object System.Collections.Generic.List[string]
    foreach ($path in $InspectionPaths) { $inspection.Add($path) }
    $inspection.Add($templateAgents)
    $conflictFiles = @(Get-ConflictMarkerFiles -Paths ($inspection | Sort-Object -Unique))
    if ($conflictFiles.Count -gt 0) {
        $list = $conflictFiles -join ", "
        throw "Safety check failed: unresolved merge markers detected in $list"
    }

    $legacyAgentFiles = @(Get-LegacyAgentFilePaths -RepoRootFull $RepoRootFull)
    if ($legacyAgentFiles.Count -gt 0) {
        $relativeLegacy = @(
            $legacyAgentFiles |
            ForEach-Object { Normalize-RepoRelativePath -Path ([System.IO.Path]::GetRelativePath($RepoRootFull, $_)) }
        )
        throw "Safety check failed: legacy agent filename(s) remain: $($relativeLegacy -join ', ')"
    }

    $validationTargets = New-Object System.Collections.Generic.List[string]
    if ($ValidateEntireRepo) {
        Get-ChildItem -LiteralPath $RepoRootFull -Recurse -File |
            Where-Object { -not (Is-SkippedPath -Path $_.FullName) } |
            ForEach-Object { $validationTargets.Add($_.FullName) }
    }
    else {
        foreach ($path in $inspection) { $validationTargets.Add($path) }
    }

    $residualHits = @(Get-ResidualPatternMatches -Paths ($validationTargets | Sort-Object -Unique) -Rules $Rules)
    if ($residualHits.Count -gt 0) {
        $preview = $residualHits | Select-Object -First 10
        $suffix = if ($residualHits.Count -gt 10) {
            " (showing first 10 of $($residualHits.Count))"
        }
        else {
            ""
        }
        throw "Safety check failed: residual legacy terms detected$($suffix): $($preview -join '; ')"
    }
}

function Contains-Path {
    param(
        [Parameter(Mandatory = $true)][string[]]$Paths,
        [Parameter(Mandatory = $true)][string]$Target
    )

    $targetNormalized = Normalize-RepoRelativePath -Path $Target
    foreach ($path in $Paths) {
        if ((Normalize-RepoRelativePath -Path $path) -ieq $targetNormalized) {
            return $true
        }
    }

    return $false
}

$repoRootFull = [System.IO.Path]::GetFullPath($RepoRoot)
$rootReadme = Join-Path $repoRootFull "README.md"
$hasChangedFilter = $null -ne $OnlyChangedPaths -and $OnlyChangedPaths.Count -gt 0

$rules = @(
    @{ Pattern = 'CLAUDE\.md'; Replacement = 'AGENTS.md' },
    @{ Pattern = 'AENTS\.md'; Replacement = 'AGENTS.md' },
    @{ Pattern = '\bClaude\s+Code\b'; Replacement = 'Codex' },
    @{ Pattern = '\bClaude\b'; Replacement = 'Codex' }
)

$targets = New-Object System.Collections.Generic.List[string]
$renamedTargets = New-Object System.Collections.Generic.List[string]

# Rename CLAUDE.md -> AGENTS.md. In changed-files mode, only do this for changed paths.
if ($hasChangedFilter) {
    foreach ($relative in ($OnlyChangedPaths | Sort-Object -Unique)) {
        if ([System.IO.Path]::GetFileName($relative) -ieq "CLAUDE.md") {
            $source = Resolve-RepoPath -Root $repoRootFull -RelativePath $relative
            if ($source -and (Test-Path -LiteralPath $source) -and -not (Is-SkippedPath -Path $source)) {
                $destination = Join-Path (Split-Path -Parent $source) "AGENTS.md"
                Copy-Item -LiteralPath $source -Destination $destination -Force
                Remove-Item -LiteralPath $source -Force
                $renamedTargets.Add($destination)
                Write-Step "Replaced CLAUDE.md with AGENTS.md: $source"
            }
        }
    }
}
else {
    Get-ChildItem -LiteralPath $repoRootFull -Recurse -File |
        Where-Object { $_.Name -ieq "CLAUDE.md" -and -not (Is-SkippedPath -Path $_.FullName) } |
        ForEach-Object {
            $destination = Join-Path $_.DirectoryName "AGENTS.md"
            Copy-Item -LiteralPath $_.FullName -Destination $destination -Force
            Remove-Item -LiteralPath $_.FullName -Force
            $renamedTargets.Add($destination)
            Write-Step "Replaced CLAUDE.md with AGENTS.md: $($_.FullName)"
        }
}

if ($hasChangedFilter) {
    foreach ($relative in $OnlyChangedPaths) {
        $resolved = Resolve-RepoPath -Root $repoRootFull -RelativePath $relative
        if (-not $resolved) { continue }
        if (-not (Test-Path -LiteralPath $resolved)) { continue }  # deleted/renamed paths
        if ((Get-Item -LiteralPath $resolved).PSIsContainer) { continue }
        if (Is-SkippedPath -Path $resolved) { continue }
        $targets.Add($resolved)
    }
}
else {
    Get-ChildItem -LiteralPath $repoRootFull -Recurse -File |
        Where-Object { -not (Is-SkippedPath -Path $_.FullName) } |
        ForEach-Object { $targets.Add($_.FullName) }
}

foreach ($path in $renamedTargets) {
    if (-not (Is-SkippedPath -Path $path)) {
        $targets.Add($path)
    }
}

$changed = 0
foreach ($path in ($targets | Sort-Object -Unique)) {
    if (Is-BinaryFile -Path $path) { continue }
    if (Replace-InFile -Path $path -Rules $rules) {
        $changed++
    }
}

if ((-not $hasChangedFilter) -or (Contains-Path -Paths $OnlyChangedPaths -Target "README.md")) {
    if (Ensure-ForkNote -ReadmePath $rootReadme) {
        $changed++
    }
}

Assert-TemplateAgentsSafety `
    -RepoRootFull $repoRootFull `
    -InspectionPaths ($targets | Sort-Object -Unique) `
    -Rules $rules `
    -ValidateEntireRepo (-not $hasChangedFilter)

Write-Step "Customization pass complete. Files changed: $changed"
