#!/usr/bin/env pwsh
# Backup current configurations to repository

function Write-ColorOutput {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Color
}

Write-ColorOutput "Backing up current configurations..." "Cyan"

$RepoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

# Backup PowerShell Profile
$ProfilePaths = @(
    $PROFILE.CurrentUserAllHosts,
    "$HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1",
    "$HOME\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
)

foreach ($profilePath in $ProfilePaths) {
    if (Test-Path $profilePath) {
        $target = Join-Path $RepoRoot "powershell\Microsoft.PowerShell_profile.ps1"
        Copy-Item $profilePath $target -Force
        Write-ColorOutput "✓ Backed up PowerShell profile from: $profilePath" "Green"
        break
    }
}

# Backup Fastfetch Config
$FastfetchPaths = @(
    "$env:APPDATA\fastfetch\config.json",
    "$env:LOCALAPPDATA\fastfetch\config.json",
    "$HOME\.config\fastfetch\config.json"
)

foreach ($configPath in $FastfetchPaths) {
    if (Test-Path $configPath) {
        $target = Join-Path $RepoRoot "fastfetch\config.json"
        Copy-Item $configPath $target -Force
        Write-ColorOutput "✓ Backed up Fastfetch config from: $configPath" "Green"
        break
    }
}

Write-ColorOutput "`nBackup complete! Don't forget to commit changes." "Green"
Write-ColorOutput "git add . && git commit -m 'Update configurations' && git push" "Yellow"