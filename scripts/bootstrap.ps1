# Bootstrap: install this repo's Claude config onto the current Windows machine.
# Idempotent. Run from any directory. Requires no admin.

$ErrorActionPreference = "Stop"
$RepoRoot  = Split-Path -Parent $PSScriptRoot
$DotClaude = Join-Path $RepoRoot "dot-claude"
$HomeClaude = Join-Path $HOME ".claude"
$HomeClaudeJson = Join-Path $HOME ".claude.json"
$HomeClaudeJsonBackup = Join-Path $HOME ".claude.json.backup"
$RepoDotclaudeJson = Join-Path $RepoRoot "dotclaude.json"
$RepoDotclaudeJsonBackup = Join-Path $RepoRoot "dotclaude.json.backup"

Write-Host "Repo: $RepoRoot"
Write-Host "Target ~/.claude: $HomeClaude"

if (-not (Test-Path $DotClaude)) { throw "Missing $DotClaude" }

# 1) Back up existing ~/.claude (if real dir, not already a junction to us)
if (Test-Path $HomeClaude) {
    $item = Get-Item $HomeClaude -Force
    $isJunction = $item.Attributes -band [IO.FileAttributes]::ReparsePoint
    if ($isJunction) {
        Write-Host "~/.claude is already a reparse point — removing link."
        & cmd /c rmdir "$HomeClaude"
    } else {
        $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $backup = "$HomeClaude.backup-$stamp"
        Write-Host "Backing up existing ~/.claude -> $backup"
        Move-Item -LiteralPath $HomeClaude -Destination $backup
    }
}

# 2) Junction ~/.claude -> repo/dot-claude
Write-Host "Creating junction $HomeClaude -> $DotClaude"
& cmd /c mklink /J "$HomeClaude" "$DotClaude" | Out-Null
if ($LASTEXITCODE -ne 0) { throw "mklink failed (exit $LASTEXITCODE)" }

# 3) ~/.claude.json — copy (not junction; single file)
if (Test-Path $RepoDotclaudeJson) {
    if (Test-Path $HomeClaudeJson) {
        $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
        Copy-Item $HomeClaudeJson "$HomeClaudeJson.backup-$stamp"
    }
    Copy-Item $RepoDotclaudeJson $HomeClaudeJson -Force
    Write-Host "Installed ~/.claude.json"
}
if (Test-Path $RepoDotclaudeJsonBackup) {
    Copy-Item $RepoDotclaudeJsonBackup $HomeClaudeJsonBackup -Force
}

Write-Host ""
Write-Host "Bootstrap complete."
Write-Host "Start Claude Code. If auth fails, run 'claude /logout' then log in again."
