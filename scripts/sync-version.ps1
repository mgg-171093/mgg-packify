param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Read-Text([string]$Path) {
    if (-not (Test-Path $Path)) {
        throw "Required file not found: $Path"
    }
    return [System.IO.File]::ReadAllText($Path)
}

function Write-Text([string]$Path, [string]$Content) {
    [System.IO.File]::WriteAllText($Path, $Content, [System.Text.UTF8Encoding]::new($false))
}

function Replace-OrFail(
    [string]$Content,
    [string]$Pattern,
    [string]$Replacement,
    [string]$TargetLabel
) {
    if (-not [System.Text.RegularExpressions.Regex]::IsMatch($Content, $Pattern, [System.Text.RegularExpressions.RegexOptions]::Multiline)) {
        throw "Pattern '$Pattern' not found while updating $TargetLabel"
    }

    $updated = [System.Text.RegularExpressions.Regex]::Replace(
        $Content,
        $Pattern,
        $Replacement,
        [System.Text.RegularExpressions.RegexOptions]::Multiline
    )

    return $updated
}

$pubspecPath = Join-Path $RepoRoot 'app/pubspec.yaml'
$pubspec = Read-Text -Path $pubspecPath

$versionMatch = [regex]::Match($pubspec, '(?m)^version:\s*(?<semver>\d+\.\d+\.\d+)(?:\+\d+)?\s*$')
if (-not $versionMatch.Success) {
    throw "Unable to parse canonical version from $pubspecPath. Expected format: version: X.Y.Z+N"
}

$version = $versionMatch.Groups['semver'].Value
$tag = "v$version-stable"

$targets = @(
    @{
        Label = 'api/pyproject.toml'
        Path = Join-Path $RepoRoot 'api/pyproject.toml'
        Pattern = '(?m)^version\s*=\s*"[^"]+"\s*$'
        Replacement = "version = `"$version`""
    },
    @{
        Label = 'app/lib/core/constants.dart'
        Path = Join-Path $RepoRoot 'app/lib/core/constants.dart'
        Pattern = "(?m)^const String kAppVersion = '[^']+';\s*$"
        Replacement = "const String kAppVersion = '$version';"
    },
    @{
        Label = 'installer/mgg-packify.iss'
        Path = Join-Path $RepoRoot 'installer/mgg-packify.iss'
        Pattern = '(?m)^#define AppVersion "[^"]+"\s*$'
        Replacement = "#define AppVersion `"$version`""
    },
    @{
        Label = 'build.ps1'
        Path = Join-Path $RepoRoot 'build.ps1'
        Pattern = '(?m)^\$Version\s*=.*$'
        Replacement = "`$Version = if (`$env:MGG_VERSION -and `$env:MGG_VERSION.Trim()) { `$env:MGG_VERSION.Trim() } else { `"$version`" }"
    },
    @{
        Label = 'latest.json (version)'
        Path = Join-Path $RepoRoot 'latest.json'
        Pattern = '"version"\s*:\s*"[^"]+"'
        Replacement = "`"version`": `"$version`""
    },
    @{
        Label = 'latest.json (url)'
        Path = Join-Path $RepoRoot 'latest.json'
        Pattern = '"url"\s*:\s*"[^"]+"'
        Replacement = "`"url`": `"https://github.com/mgg-171093/mgg-packify/releases/download/$tag/MGGPackify-$version-Setup.exe`""
    }
)

$results = @()

foreach ($target in $targets) {
    $path = $target.Path
    $before = Read-Text -Path $path
    $after = Replace-OrFail -Content $before -Pattern $target.Pattern -Replacement $target.Replacement -TargetLabel $target.Label

    if ($after -ne $before) {
        Write-Text -Path $path -Content $after
        $results += "UPDATED: $($target.Label)"
    } else {
        $results += "UNCHANGED: $($target.Label)"
    }
}

Write-Host "CanonicalVersion=$version"
Write-Host "ReleaseTag=$tag"
Write-Host 'Targets:'
$results | ForEach-Object { Write-Host "  - $_" }
