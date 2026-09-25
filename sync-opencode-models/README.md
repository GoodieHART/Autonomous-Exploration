# OpenCode Model Sync Launcher

A Windows PowerShell launcher that updates your OpenCode model configuration before starting OpenCode.

## Requirements

- Windows PowerShell 5.1 or PowerShell 7+
- Python 3
- OpenCode
- The Python model-sync script
- The `oh-my-openagent.json` configuration file

Python 3 must be on `PATH` as `py.exe` or `python.exe`.

OpenCode must be on `PATH` as `opencode`, or set `OPENCODE_BIN` (see Configuration below).

## Installation

Clone the repository:

```powershell
git clone https://github.com/GoodieHART/Autonomous-Exploration.git
cd Autonomous-Exploration
```

The canonical launcher is `sync-opencode-models/oc.ps1`. (An older
duplicate named `sync_omo_models.py` that contained PowerShell instead of
Python was removed; do not recreate it.)

Allow locally created PowerShell scripts to run:

```powershell
Set-ExecutionPolicy `
  -Scope CurrentUser `
  -ExecutionPolicy RemoteSigned
```

## Expected files

The repository should contain:

```text
Autonomous-Exploration/
└── sync-opencode-models/
    ├── README.md
    └── oc.ps1
```

## Configuration

The launcher supports these environment variables:

| Variable | Purpose | Default |
|---|---|---|
| `OPENCODE_BIN` | Full path to the OpenCode executable | Automatically detected from `PATH` |
| `OMO_SYNC_SCRIPT` | Path to the Python model-sync script | `$HOME\.config-dotfiles\sync_omo_models.py` |
| `OMO_CONFIG` | Path to the OpenCode JSON configuration | `$HOME\.config\opencode\oh-my-openagent.json` |

Example:

```powershell
$env:OPENCODE_BIN = "C:\path\to\opencode.cmd"

$env:OMO_SYNC_SCRIPT = `
  "$HOME\.config-dotfiles\sync_omo_models.py"

$env:OMO_CONFIG = `
  "$HOME\.config\opencode\oh-my-openagent.json"
```

For a permanent configuration, add these variables to your PowerShell profile instead of setting them manually each session.

## Running the launcher

From the repository root:

```powershell
powershell -File `
  .\sync-opencode-models\oc.ps1
```

The launcher will:

1. Fetch the available models.
2. Ask you to select models for each agent and category.
3. Show the proposed configuration changes.
4. Create a backup of the existing configuration.
5. Start OpenCode.

## Passing arguments to OpenCode

Arguments after the launcher are passed directly to OpenCode:

```powershell
powershell -File `
  .\sync-opencode-models\oc.ps1 `
  --help
```

```powershell
powershell -File `
  .\sync-opencode-models\oc.ps1 `
  --continue
```

```powershell
powershell -File `
  .\sync-opencode-models\oc.ps1 `
  --agent hephaestus
```

## Skipping synchronization

To start OpenCode without updating models:

```powershell
powershell -File `
  .\sync-opencode-models\oc.ps1 `
  --skip-model-sync
```

## Create a short `oc` command

To avoid typing the full launcher path, add a function to your PowerShell profile.

Open your profile:

```powershell
New-Item -ItemType File -Path $PROFILE -Force
notepad $PROFILE
```

Add this function:

```powershell
$OmoLauncher = `
  "$HOME\codes\Autonomous-Exploration\sync-opencode-models\oc.ps1"

function oc {
    powershell -File $OmoLauncher @args
}
```

Change `$OmoLauncher` if you cloned the repository somewhere else.

Reload the profile:

```powershell
. $PROFILE
```

You can now use:

```powershell
oc
oc --continue
oc --agent hephaestus
oc --skip-model-sync
```

> **Note:** the `oc` function is for interactive use. Piping answers
> into it (e.g. `"1","s" | oc`) does not work — PowerShell drops
> pipeline input in functions that don't consume it, so the sync
> script sees end-of-input and fails. For scripted/non-interactive
> runs, pipe directly to the launcher instead:
>
> ```powershell
> $answers | powershell -File $OmoLauncher --help
> ```

## Troubleshooting

### Python was not found

Install Python 3 and make sure one of these commands works:

```powershell
py -3 --version
```

```powershell
python --version
```

Restart PowerShell after installing Python.

### OpenCode was not found

Check whether OpenCode is available:

```powershell
Get-Command opencode -All
```

If necessary, configure its full path:

```powershell
$env:OPENCODE_BIN = "C:\path\to\opencode.cmd"
```

### The model-sync script was not found

Check the default location:

```powershell
Test-Path "$HOME\.config-dotfiles\sync_omo_models.py"
```

Or configure the correct location:

```powershell
$env:OMO_SYNC_SCRIPT = "C:\path\to\sync_omo_models.py"
```

### The configuration file was not found

Set the correct configuration path:

```powershell
$env:OMO_CONFIG = `
  "C:\path\to\oh-my-openagent.json"
```

### PowerShell says scripts are disabled

Run:

```powershell
Set-ExecutionPolicy `
  -Scope CurrentUser `
  -ExecutionPolicy RemoteSigned
```

Then restart PowerShell.

### `oc` is not recognized

Reload your PowerShell profile:

```powershell
. $PROFILE
```

If that does not work, check the profile path:

```powershell
$PROFILE
```

Make sure the `oc` function was added to that file.

## How it works

The launcher runs in this order:

```text
Python model-sync script
        ↓
Model selection
        ↓
Configuration backup
        ↓
Configuration update
        ↓
OpenCode starts
```

If synchronization fails, the launcher asks whether OpenCode should start anyway.

The launcher does not modify OpenCode itself. It only updates the model values in:

```text
oh-my-openagent.json
```
```

The `.py`/PowerShell mismatch is resolved: the canonical launcher is:

```text
oc.ps1
```

while the actual model synchronization script remains Python:

```text
sync_omo_models.py
```