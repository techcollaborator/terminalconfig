#!/usr/bin/env pwsh
# Dotfiles Cleanup Script
# Removes PowerShell profile and Fastfetch config

param(
    [switch]$Force = $false,
    [switch]$KeepBackups = $false
)

function Write-ColorOutput {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Color
}

function Remove-Configuration {
    param(
        [string]$Path,
        [string]$Description
    )
    
    Write-ColorOutput "`nRemoving $Description..." "Cyan"
    Write-ColorOutput "Target: $Path" "Gray"
    
    if (Test-Path $Path) {
        try {
            $item = Get-Item $Path
            if ($item.LinkType -eq "SymbolicLink") {
                Remove-Item $Path -Force
                Write-ColorOutput "✓ Removed symbolic link" "Green"
            } else {
                Remove-Item $Path -Force
                Write-ColorOutput "✓ Removed file" "Green"
            }
            return $true
        }
        catch {
            Write-ColorOutput "✗ Failed to remove: $($_.Exception.Message)" "Red"
            return $false
        }
    } else {
        Write-ColorOutput "! File not found, skipping" "Yellow"
        return $true
    }
}

function Remove-Backups {
    param([string]$Directory)
    
    if ($KeepBackups) {
        Write-ColorOutput "! Keeping backup files in $Directory" "Yellow"
        return
    }
    
    if (Test-Path $Directory) {
        $backupFiles = Get-ChildItem $Directory -Filter "*.backup.*" -File
        foreach ($backup in $backupFiles) {
            try {
                Remove-Item $backup.FullName -Force
                Write-ColorOutput "✓ Removed backup: $($backup.Name)" "Green"
            }
            catch {
                Write-ColorOutput "! Failed to remove backup: $($backup.Name)" "Yellow"
            }
        }
    }
}

function Confirm-Removal {
    if ($Force) {
        return $true
    }
    
    $response = Read-Host "`nAre you sure you want to remove all configurations? (y/N)"
    return $response -eq 'y' -or $response -eq 'Y'
}

# Main execution
Write-ColorOutput "==========================================" "Red"
Write-ColorOutput "    Terminal Configuration Cleanup" "Red"
Write-ColorOutput "==========================================" "Red"

if (-not (Confirm-Removal)) {
    Write-ColorOutput "Cleanup cancelled." "Yellow"
    exit 0
}

# Common configuration locations
$PowerShellLocations = @(
    "$HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1",
    "$HOME\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1",
    "$HOME\Documents\PowerShell\profile.ps1",
    "$HOME\Documents\WindowsPowerShell\profile.ps1"
)

$FastfetchLocations = @(
    "$env:APPDATA\fastfetch",
    "$env:LOCALAPPDATA\fastfetch", 
    "$HOME\.config\fastfetch"
)

# Track removal status
$PowerShellRemoved = $false
$FastfetchRemoved = $false
$AsciiArtRemoved = $false

# 1. Remove PowerShell Profiles
Write-ColorOutput "`n=== Removing PowerShell Configurations ===" "Yellow"
foreach ($ProfilePath in $PowerShellLocations) {
    if (Test-Path $ProfilePath) {
        $PowerShellRemoved = Remove-Configuration -Path $ProfilePath -Description "PowerShell Profile"
        if ($PowerShellRemoved) { break }
    }
}

# 2. Remove Fastfetch Configurations
Write-ColorOutput "`n=== Removing Fastfetch Configurations ===" "Yellow"
foreach ($ConfigDir in $FastfetchLocations) {
    $ConfigPath = Join-Path $ConfigDir "config.json"
    $AsciiArtPath = Join-Path $ConfigDir "custom_ascii_art.txt"
    
    # Remove config file
    if (Test-Path $ConfigPath) {
        $FastfetchRemoved = Remove-Configuration -Path $ConfigPath -Description "Fastfetch Configuration"
    }
    
    # Remove ASCII art file
    if (Test-Path $AsciiArtPath) {
        $AsciiArtRemoved = Remove-Configuration -Path $AsciiArtPath -Description "ASCII Art"
    }
    
    # Remove backup files
    Remove-Backups -Directory $ConfigDir
    
    # Remove directory if empty
    if (Test-Path $ConfigDir) {
        $items = Get-ChildItem $ConfigDir
        if ($items.Count -eq 0) {
            try {
                Remove-Item $ConfigDir -Force
                Write-ColorOutput "✓ Removed empty directory: $ConfigDir" "Green"
            }
            catch {
                Write-ColorOutput "! Could not remove directory: $ConfigDir" "Yellow"
            }
        }
    }
}

# Summary
Write-ColorOutput "`n==========================================" "Red"
Write-ColorOutput "           Cleanup Complete" "Red"
Write-ColorOutput "==========================================" "Red"

if ($PowerShellRemoved) {
    Write-ColorOutput "✓ PowerShell Profile removed" "Green"
} else {
    Write-ColorOutput "! No PowerShell Profile found or removal failed" "Yellow"
}

if ($FastfetchRemoved) {
    Write-ColorOutput "✓ Fastfetch Configuration removed" "Green"
} else {
    Write-ColorOutput "! No Fastfetch Configuration found or removal failed" "Yellow"
}

if ($AsciiArtRemoved) {
    Write-ColorOutput "✓ ASCII Art removed" "Green"
} else {
    Write-ColorOutput "! No ASCII Art found or removal failed" "Yellow"
}

if (-not $KeepBackups) {
    Write-ColorOutput "✓ Backup files cleaned up" "Green"
} else {
    Write-ColorOutput "! Backup files preserved" "Yellow"
}

Write-ColorOutput "`nNote:" "Yellow"
Write-ColorOutput "- You may need to restart your terminal for changes to take effect" "White"
Write-ColorOutput "- Original system configurations remain unchanged" "White"
Write-ColorOutput "- Use '-KeepBackups' to preserve backup files" "Gray"