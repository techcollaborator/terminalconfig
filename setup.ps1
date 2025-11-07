#!/usr/bin/env pwsh
# Dotfiles Setup Script
# Places PowerShell profile and Fastfetch config in their proper locations

param(
    [switch]$Force = $false,
    [switch]$Backup = $true
)

function Write-ColorOutput {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Color
}

function Backup-File {
    param([string]$Path)
    
    if (Test-Path $Path) {
        $backupPath = "$Path.backup.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        Write-ColorOutput "Backing up: $backupPath" "Yellow"
        Copy-Item $Path $backupPath -Force
        return $true
    }
    return $false
}

function Install-Configuration {
    param(
        [string]$Source,
        [string]$Target,
        [string]$Description
    )
    
    Write-ColorOutput "`nSetting up $Description..." "Cyan"
    Write-ColorOutput "Source: $Source" "Gray"
    Write-ColorOutput "Target: $Target" "Gray"
    
    # Create target directory if it doesn't exist
    $targetDir = Split-Path $Target -Parent
    if (!(Test-Path $targetDir)) {
        Write-ColorOutput "Creating directory: $targetDir" "Yellow"
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    }
    
    # Backup existing file if it exists
    if ((Test-Path $Target) -and $Backup) {
        Backup-File $Target
    }
    
    # Remove existing file if force is enabled
    if ((Test-Path $Target) -and $Force) {
        Remove-Item $Target -Force -ErrorAction SilentlyContinue
    }
    
    # Install configuration
    try {
        # Try to create symbolic link (more efficient)
        if (!(Test-Path $Target)) {
            New-Item -ItemType SymbolicLink -Path $Target -Target $Source -Force | Out-Null
            Write-ColorOutput "✓ Created symbolic link" "Green"
        } else {
            Copy-Item $Source $Target -Force
            Write-ColorOutput "✓ Copied file (target already exists)" "Green"
        }
        return $true
    }
    catch {
        Write-ColorOutput "! Symbolic link failed: $($_.Exception.Message)" "Yellow"
        Write-ColorOutput "! Copying file instead..." "Yellow"
        try {
            Copy-Item $Source $Target -Force
            Write-ColorOutput "✓ Copied file" "Green"
            return $true
        }
        catch {
            Write-ColorOutput "✗ Failed to copy: $($_.Exception.Message)" "Red"
            return $false
        }
    }
}

# Main execution
Write-ColorOutput "==========================================" "Cyan"
Write-ColorOutput "    Terminal Configuration Setup" "Cyan"
Write-ColorOutput "==========================================" "Cyan"

# Get script directory (repo root)
$RepoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

# 1. Setup PowerShell Profile
$PowerShellSource = Join-Path $RepoRoot "powershell\Microsoft.PowerShell_profile.ps1"

# Try common PowerShell profile locations
$ProfileLocations = @(
    "$HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1",
    "$HOME\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1",
    "$HOME\Documents\PowerShell\profile.ps1",
    "$HOME\Documents\WindowsPowerShell\profile.ps1"
)

$PowerShellInstalled = $false
foreach ($ProfilePath in $ProfileLocations) {
    $ProfileDir = Split-Path $ProfilePath -Parent
    if (Test-Path $ProfileDir) {
        $PowerShellInstalled = Install-Configuration -Source $PowerShellSource -Target $ProfilePath -Description "PowerShell Profile"
        if ($PowerShellInstalled) { break }
    }
}

# If no profile directory exists, create the most common one
if (!$PowerShellInstalled) {
    $DefaultProfilePath = $ProfileLocations[0]
    $PowerShellInstalled = Install-Configuration -Source $PowerShellSource -Target $DefaultProfilePath -Description "PowerShell Profile"
}

# 2. Setup Fastfetch Configuration
$FastfetchSource = Join-Path $RepoRoot "fastfetch\config.json"

# Try common Fastfetch config locations
$FastfetchLocations = @(
    "$env:APPDATA\fastfetch\config.json",
    "$env:LOCALAPPDATA\fastfetch\config.json",
    "$HOME\.config\fastfetch\config.json"
)

$FastfetchInstalled = $false
foreach ($ConfigPath in $FastfetchLocations) {
    $ConfigDir = Split-Path $ConfigPath -Parent
    if (Test-Path $ConfigDir -or $Force) {
        $FastfetchInstalled = Install-Configuration -Source $FastfetchSource -Target $ConfigPath -Description "Fastfetch Configuration"
        if ($FastfetchInstalled) { break }
    }
}

# If no fastfetch directory exists, create the most common one
if (!$FastfetchInstalled) {
    $DefaultConfigPath = $FastfetchLocations[0]
    $FastfetchInstalled = Install-Configuration -Source $FastfetchSource -Target $DefaultConfigPath -Description "Fastfetch Configuration"
}

# Summary
Write-ColorOutput "`n==========================================" "Cyan"
Write-ColorOutput "           Setup Complete" "Cyan"
Write-ColorOutput "==========================================" "Cyan"

if ($PowerShellInstalled) {
    Write-ColorOutput "✓ PowerShell Profile installed" "Green"
} else {
    Write-ColorOutput "✗ PowerShell Profile installation failed" "Red"
}

if ($FastfetchInstalled) {
    Write-ColorOutput "✓ Fastfetch Configuration installed" "Green"
} else {
    Write-ColorOutput "✗ Fastfetch Configuration installation failed" "Red"
}

Write-ColorOutput "`nNext steps:" "Yellow"
Write-ColorOutput "- Restart PowerShell to load new profile" "White"
Write-ColorOutput "- Run 'fastfetch' to test configuration" "White"
Write-ColorOutput "- Use '-Force' flag to overwrite existing files" "Gray"