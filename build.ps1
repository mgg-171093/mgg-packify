<#
.SYNOPSIS
    MGG Packify full build pipeline.
    Produces: installer/Output/MGGPackify-3.9.4-Setup.exe

.PREREQUISITES
    - Flutter SDK on PATH
    - PyInstaller installed: pip install pyinstaller==6.19.0
    - Inno Setup 6 installed at default location

.USAGE
    From repo root:
    .\build.ps1
    .\build.ps1 -SkipFlutter   # skip Flutter build (use existing Release build)
    .\build.ps1 -SkipApi       # skip PyInstaller build
#>

param(
    [switch]$SkipFlutter,
    [switch]$SkipApi,
    [switch]$SkipInstaller
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$Version = if ($env:MGG_VERSION -and $env:MGG_VERSION.Trim()) { $env:MGG_VERSION.Trim() } else { "3.9.4" }
$RepoRoot = $PSScriptRoot
$FlutterRelease = Join-Path $RepoRoot "app\build\windows\x64\runner\Release"
$ApiDist = Join-Path $RepoRoot "api\dist"
$StagingDir = Join-Path $RepoRoot "staging"
$InnoSetup = "C:\Program Files (x86)\Inno Setup 6\ISCC.exe"
$PythonExe = $null

function Write-Step($msg) {
    Write-Host "`n==> $msg" -ForegroundColor Cyan
}

function Assert-Exit($msg) {
    if ($LASTEXITCODE -ne 0) {
        Write-Host "FAILED: $msg (exit code $LASTEXITCODE)" -ForegroundColor Red
        exit 1
    }
}

# ─── Step 1: Validate prerequisites ───────────────────────────────────────────
Write-Step "Checking prerequisites..."

if (-not $SkipFlutter) {
    $null = Get-Command flutter -ErrorAction Stop
    Write-Host "  flutter: OK"
}

if (-not $SkipApi) {
    try {
        $PythonExe = (Get-Command python -ErrorAction Stop).Source
    } catch {
        Write-Host "ERROR: Python executable not found in PATH." -ForegroundColor Red
        Write-Host "  Install Python >=3.12 and ensure 'python' is available in PATH." -ForegroundColor Yellow
        exit 1
    }

    & $PythonExe -m PyInstaller --version 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: PyInstaller not installed. Run: pip install pyinstaller==6.19.0" -ForegroundColor Red
        exit 1
    }
    Write-Host "  pyinstaller: OK"
}

if (-not $SkipInstaller) {
    if (-not (Test-Path $InnoSetup)) {
        Write-Host "ERROR: Inno Setup not found at $InnoSetup" -ForegroundColor Red
        Write-Host "  Download from: https://jrsoftware.org/isdl.php" -ForegroundColor Yellow
        exit 1
    }
    Write-Host "  Inno Setup: OK"
}

# ─── Step 2: Flutter release build ────────────────────────────────────────────
if (-not $SkipFlutter) {
    Write-Step "Building Flutter Windows release..."
    Push-Location (Join-Path $RepoRoot "app")
    flutter build windows --release
    Assert-Exit "Flutter build"
    Pop-Location
} else {
    Write-Step "Skipping Flutter build (--SkipFlutter)"
}

# ─── Step 3: PyInstaller — bundle Python API ──────────────────────────────────
if (-not $SkipApi) {
    Write-Step "Bundling Python API with PyInstaller..."
    Push-Location (Join-Path $RepoRoot "api")
    & $PythonExe -m PyInstaller mgg-packify-api.spec --distpath dist --workpath build-pyinstaller --noconfirm
    Assert-Exit "PyInstaller"
    Pop-Location
} else {
    Write-Step "Skipping PyInstaller (--SkipApi)"
}

# ─── Step 4: Assemble staging directory ───────────────────────────────────────
Write-Step "Assembling staging directory..."

if (Test-Path $StagingDir) {
    Remove-Item $StagingDir -Recurse -Force
}
New-Item $StagingDir -ItemType Directory | Out-Null

# Copy Flutter release output
if (-not (Test-Path $FlutterRelease)) {
    Write-Host "ERROR: Flutter release not found at $FlutterRelease" -ForegroundColor Red
    exit 1
}
Copy-Item "$FlutterRelease\*" $StagingDir -Recurse -Force
Write-Host "  Flutter release copied"

# ─── Step 5: Inno Setup ───────────────────────────────────────────────────────
if (-not $SkipInstaller) {
    Write-Step "Running Inno Setup..."
    $IssScript = Join-Path $RepoRoot "installer\mgg-packify.iss"
    & $InnoSetup $IssScript
    Assert-Exit "Inno Setup"
    
    $OutputExe = Join-Path $RepoRoot "installer\Output\MGGPackify-$Version-Setup.exe"
    if (Test-Path $OutputExe) {
        $sizeMB = [math]::Round((Get-Item $OutputExe).Length / 1MB, 1)
        Write-Host "`nBuild complete!" -ForegroundColor Green
        Write-Host "  Output: $OutputExe ($sizeMB MB)" -ForegroundColor Green
    } else {
        Write-Host "WARNING: Expected output not found at $OutputExe" -ForegroundColor Yellow
    }
} else {
    Write-Step "Skipping Inno Setup (--SkipInstaller)"
}

Write-Host "`nDone." -ForegroundColor Green
