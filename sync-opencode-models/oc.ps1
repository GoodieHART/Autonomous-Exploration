# Stop only for PowerShell errors.
# Native program exit codes are handled manually below.
$ErrorActionPreference = "Stop"


# Configuration

# Override with $env:OMO_SYNC_SCRIPT to use a project-local or custom copy.
# Defaults to the legacy dotfiles location to preserve existing behavior.
$SyncScript = if ($env:OMO_SYNC_SCRIPT) { $env:OMO_SYNC_SCRIPT } else { Join-Path $HOME ".config-dotfiles/sync_omo_models.py" }

# Change this path if your configuration file is somewhere else.
#
# This is the location used by this launcher when calling the
# Python script. The Python script itself accepts --config.
# Override with $env:OMO_CONFIG.
$ConfigFile = if ($env:OMO_CONFIG) { $env:OMO_CONFIG } else { Join-Path $HOME ".config/opencode/oh-my-openagent.json" }


# Parse wrapper-specific arguments

$SkipModelSync = $false
$OpenCodeArguments = New-Object System.Collections.Generic.List[string]

foreach ($Argument in $args) {
    if ($Argument -eq "--skip-model-sync") {
        $SkipModelSync = $true
    }
    else {
        [void]$OpenCodeArguments.Add($Argument)
    }
}


# Locate the Python interpreter

$PythonCommand = $null

$PyLauncher = Get-Command "py.exe" `
    -CommandType Application `
    -ErrorAction SilentlyContinue

if ($null -ne $PyLauncher) {
    $PythonCommand = $PyLauncher.Source
    $PythonArguments = @("-3")
}
else {
    $PythonExecutable = Get-Command "python.exe" `
        -CommandType Application `
        -ErrorAction SilentlyContinue

    if ($null -ne $PythonExecutable) {
        $PythonCommand = $PythonExecutable.Source
        $PythonArguments = @()
    }
}

if ($null -eq $PythonCommand) {
    Write-Host "Error: Python was not found." -ForegroundColor Red
    Write-Host "Install Python or make sure py.exe/python.exe is in PATH."
    exit 1
}


# Validate the synchronization script

if (-not (Test-Path -LiteralPath $SyncScript)) {
    Write-Host "Error: model synchronization script was not found:" `
        -ForegroundColor Red

    Write-Host "  $SyncScript"
    exit 1
}

# Locate OpenCode

$OpenCodeExecutable = $env:OPENCODE_BIN

if ([string]::IsNullOrWhiteSpace($OpenCodeExecutable)) {
    # Get all matching executable commands, then explicitly select
    # only the first one.
    $OpenCodeCommand = Get-Command "opencode" `
        -All `
        -CommandType Application `
        -ErrorAction SilentlyContinue |
        Select-Object -First 1

    if ($null -ne $OpenCodeCommand) {
        # .Path is the complete path to the executable, e.g. C:\path\to\opencode.cmd
        $OpenCodeExecutable = $OpenCodeCommand.Path
    }
}

if ([string]::IsNullOrWhiteSpace($OpenCodeExecutable)) {
    Write-Host "Error: OpenCode was not found." -ForegroundColor Red
    Write-Host ""
    Write-Host "Check that OpenCode is available in PATH."
    Write-Host ""
    Write-Host "You can manually set its path with:"
    Write-Host ""
    Write-Host '  $env:OPENCODE_BIN = "C:\path\to\opencode.cmd"'
    exit 1
}


# Run model synchronization

if (-not $SkipModelSync) {
    Write-Host "Synchronizing OpenCode models..." `
        -ForegroundColor Cyan

    Write-Host ""

    $SyncArguments = @(
        $SyncScript,
        "--config",
        $ConfigFile
    )

    & $PythonCommand @PythonArguments @SyncArguments

    $SyncExitCode = $LASTEXITCODE

    if ($SyncExitCode -ne 0) {
        Write-Host ""
        Write-Host "Model synchronization failed." `
            -ForegroundColor Yellow

        Write-Host ""

        # Non-interactive stdin (piped input, CI, dead console): the
        # [y/N] prompt below cannot be answered reliably, and Read-Host
        # may return $null/empty. Fail safe (default N) instead of
        # prompting.
        if ([Console]::IsInputRedirected) {
            Write-Host "OpenCode was not started."
            exit $SyncExitCode
        }

        $Continue = Read-Host `
            "Start OpenCode anyway? [y/N]"

        if ($Continue -notmatch "^(y|yes)$") {
            Write-Host "OpenCode was not started."
            exit $SyncExitCode
        }
    }
}
else {
    Write-Host "Skipping model synchronization." `
        -ForegroundColor Yellow
}


# Start OpenCode

Write-Host ""
Write-Host "Starting OpenCode..." -ForegroundColor Green
Write-Host "Executable: $OpenCodeExecutable"
Write-Host ""

& $OpenCodeExecutable @OpenCodeArguments

$OpenCodeExitCode = $LASTEXITCODE

exit $OpenCodeExitCode

