# Manual snapshot: refresh repo from live ~/.claude and push.
# Use this on machines where the junction hasn't been installed, or to push
# ~/.claude.json (which is copied, not junctioned).

$ErrorActionPreference = "Stop"
$RepoRoot  = Split-Path -Parent $PSScriptRoot
$DotClaude = Join-Path $RepoRoot "dot-claude"
$HomeClaude = Join-Path $HOME ".claude"
$HomeClaudeJson = Join-Path $HOME ".claude.json"
$HomeClaudeJsonBackup = Join-Path $HOME ".claude.json.backup"

# Only refresh dot-claude from ~/.claude if they are different directories
# (i.e. junction NOT yet installed). If junctioned, edits are already live.
$needCopy = $true
if (Test-Path $HomeClaude) {
    $item = Get-Item $HomeClaude -Force
    if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
        Write-Host "~/.claude is a junction — dot-claude is already live."
        $needCopy = $false
    }
}
if ($needCopy -and (Test-Path $HomeClaude)) {
    Write-Host "Refreshing dot-claude from ~/.claude ..."
    robocopy "$HomeClaude" "$DotClaude" /MIR /R:1 /W:1 /NFL /NDL /NP | Out-Null
}

# Always refresh top-level json files
if (Test-Path $HomeClaudeJson) {
    Copy-Item $HomeClaudeJson (Join-Path $RepoRoot "dotclaude.json") -Force
}
if (Test-Path $HomeClaudeJsonBackup) {
    Copy-Item $HomeClaudeJsonBackup (Join-Path $RepoRoot "dotclaude.json.backup") -Force
}

Set-Location $RepoRoot
git add -A
$changes = git status --porcelain
if (-not $changes) {
    Write-Host "No changes."
    exit 0
}
$msg = "sync: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
git commit -m $msg | Out-Null
git push
Write-Host "Pushed: $msg"
