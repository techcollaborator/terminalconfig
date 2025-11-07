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

function Install-AsciiArt {
    param(
        [string]$RepoRoot,
        [string]$ConfigDir
    )
    
    Write-ColorOutput "`nSetting up ASCII Art..." "Cyan"
    
    $AsciiArtSource = Join-Path $RepoRoot "fastfetch\custom_ascii_art.txt"
    $AsciiArtTarget = Join-Path $ConfigDir "custom_ascii_art.txt"
    
    Write-ColorOutput "Source: $AsciiArtSource" "Gray"
    Write-ColorOutput "Target: $AsciiArtTarget" "Gray"
    
    if (!(Test-Path $AsciiArtSource)) {
        Write-ColorOutput "! ASCII art source file not found: $AsciiArtSource" "Yellow"
        Write-ColorOutput "! Please ensure custom_ascii_art.txt exists in fastfetch folder" "Yellow"
        return $false
    }
    
    # Backup existing file if it exists
    if ((Test-Path $AsciiArtTarget) -and $Backup) {
        Backup-File $AsciiArtTarget
    }
    
    # Remove existing file if force is enabled
    if ((Test-Path $AsciiArtTarget) -and $Force) {
        Remove-Item $AsciiArtTarget -Force -ErrorAction SilentlyContinue
    }
    
    try {
        if (!(Test-Path $AsciiArtTarget)) {
            New-Item -ItemType SymbolicLink -Path $AsciiArtTarget -Target $AsciiArtSource -Force | Out-Null
            Write-ColorOutput "✓ Created ASCII art symbolic link" "Green"
        } else {
            Copy-Item $AsciiArtSource $AsciiArtTarget -Force
            Write-ColorOutput "✓ Copied ASCII art file (target already exists)" "Green"
        }
        return $true
    }
    catch {
        Write-ColorOutput "! ASCII art symbolic link failed: $($_.Exception.Message)" "Yellow"
        Write-ColorOutput "! Copying ASCII art file instead..." "Yellow"
        try {
            Copy-Item $AsciiArtSource $AsciiArtTarget -Force
            Write-ColorOutput "✓ Copied ASCII art file" "Green"
            return $true
        }
        catch {
            Write-ColorOutput "✗ Failed to copy ASCII art: $($_.Exception.Message)" "Red"
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
$FastfetchConfigDir = $null

foreach ($ConfigPath in $FastfetchLocations) {
    $ConfigDir = Split-Path $ConfigPath -Parent
    if (Test-Path $ConfigDir -or $Force) {
        $FastfetchInstalled = Install-Configuration -Source $FastfetchSource -Target $ConfigPath -Description "Fastfetch Configuration"
        if ($FastfetchInstalled) { 
            $FastfetchConfigDir = $ConfigDir
            break 
        }
    }
}

# If no fastfetch directory exists, create the most common one
if (!$FastfetchInstalled) {
    $DefaultConfigPath = $FastfetchLocations[0]
    $FastfetchInstalled = Install-Configuration -Source $FastfetchSource -Target $DefaultConfigPath -Description "Fastfetch Configuration"
    if ($FastfetchInstalled) {
        $FastfetchConfigDir = Split-Path $DefaultConfigPath -Parent
    }
}

# 3. Setup ASCII Art for Fastfetch
$AsciiArtInstalled = $false
if ($FastfetchInstalled -and $FastfetchConfigDir) {
    $AsciiArtInstalled = Install-AsciiArt -RepoRoot $RepoRoot -ConfigDir $FastfetchConfigDir
} elseif ($FastfetchInstalled) {
    Write-ColorOutput "! Could not determine Fastfetch config directory for ASCII art" "Yellow"
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

if ($AsciiArtInstalled) {
    Write-ColorOutput "✓ ASCII Art installed" "Green"
} else {
    Write-ColorOutput "✗ ASCII Art installation failed" "Red"
}

Write-ColorOutput "`nNext steps:" "Yellow"
Write-ColorOutput "- Restart PowerShell to load new profile" "White"
Write-ColorOutput "- Run 'fastfetch' to test configuration" "White"
Write-ColorOutput "- Use '-Force' flag to overwrite existing files" "Gray"