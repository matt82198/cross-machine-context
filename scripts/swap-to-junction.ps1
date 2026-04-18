# Run AFTER closing all Claude Code processes on this machine.
# Replaces the live ~/.claude dir with a junction to ~/cross-machine-context/dot-claude.
# Any local changes in ~/.claude since the last push will be merged in first.

$ErrorActionPreference = "Stop"
$RepoRoot  = Split-Path -Parent $PSScriptRoot
$DotClaude = Join-Path $RepoRoot "dot-claude"
$HomeClaude = Join-Path $HOME ".claude"

if (-not (Test-Path $HomeClaude)) { throw "No ~/.claude to swap." }
$item = Get-Item $HomeClaude -Force
if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
    Write-Host "~/.claude is already a junction. Nothing to do."
    exit 0
}

# Check no Claude process is running
$procs = Get-Process -Name "claude","Claude","node" -ErrorAction SilentlyContinue |
         Where-Object { $_.Path -and $_.Path -match "claude" }
if ($procs) {
    Write-Warning "Claude processes may still be running. Close them and retry:"
    $procs | Format-Table Id,ProcessName,Path -AutoSize
    exit 1
}

# Merge live state -> repo (use /E to copy all subdirs including empty ones)
Write-Host "Merging live ~/.claude into repo copy..."
robocopy "$HomeClaude" "$DotClaude" /E /R:1 /W:1 /NFL /NDL /NP | Out-Null

# Backup the live dir
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backup = "$HomeClaude.backup-$stamp"
Write-Host "Moving ~/.claude -> $backup"
Move-Item -LiteralPath $HomeClaude -Destination $backup

# Create junction
Write-Host "Creating junction $HomeClaude -> $DotClaude"
& cmd /c mklink /J "$HomeClaude" "$DotClaude" | Out-Null
if ($LASTEXITCODE -ne 0) { throw "mklink failed (exit $LASTEXITCODE)" }

Write-Host ""
Write-Host "Done. ~/.claude is now a junction to $DotClaude."
Write-Host "Original preserved at $backup (delete after you verify Claude works)."
