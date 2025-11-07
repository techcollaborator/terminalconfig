# --- 1. Local Theme for Oh My Posh (offline, dynamic path) ---
$ompConfig = Join-Path $env:USERPROFILE 'pararussel.omp.json'
if (Test-Path $ompConfig) {
    if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
        oh-my-posh init pwsh --config $ompConfig | Invoke-Expression
    }
} else {
    Write-Host "Oh My Posh theme not found: $ompConfig" -ForegroundColor Yellow
}

# --- 2. Load zoxide (if present) ---
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (& { (zoxide init powershell | Out-String) })
    Set-Alias -Name z -Value __zoxide_z -Option AllScope -Scope Global -Force
    Set-Alias -Name zi -Value __zoxide_zi -Option AllScope -Scope Global -Force
}

# --- 3. Editor Alias/Function ---
$EDITOR = if (Get-Command nvim -ErrorAction SilentlyContinue) { 'nvim' }
          elseif (Get-Command code -ErrorAction SilentlyContinue) { 'code' }
          elseif (Get-Command notepad++ -ErrorAction SilentlyContinue) { 'notepad++' }
          else { 'notepad' }
Set-Alias -Name vim -Value $EDITOR
function ep { & $EDITOR $PROFILE }

# --- 4. System & Security Shortcuts ---
function sysinfo { Get-ComputerInfo }
function flushdns { Clear-DnsClientCache; Write-Host "DNS Flushed." -ForegroundColor Green }
function uptime  {
    $os = Get-CimInstance Win32_OperatingSystem
    $boot = $os.LastBootUpTime
    $up = (Get-Date) - $boot
    Write-Host "Uptime: $($up.Days)d $($up.Hours)h $($up.Minutes)m $($up.Seconds)s" -ForegroundColor Cyan
}

# --- 5. Networking & Cybersecurity: List Interfaces, tshark & nmap w/ Interface ---
function list-interfaces {
    Write-Host "==[ Network Interfaces Detected by tshark ]==" -ForegroundColor Cyan
    if (Get-Command tshark -ErrorAction SilentlyContinue) {
        tshark -D
    } else {
        Write-Host "tshark not found in PATH." -ForegroundColor Red
    }
    Write-Host "`n==[ Network Interfaces Detected by PowerShell ]==" -ForegroundColor Cyan
    Get-NetAdapter | Select-Object -Property ifIndex, Name, Status, MacAddress | Format-Table
}

function sniff { param([int]$interface = 1) tshark -i $interface }
function quickcap { param([int]$packets = 20, [int]$interface = 1) tshark -i $interface -c $packets }
function cap2file { param([string]$outfile = "capture.pcap", [int]$interface = 1) tshark -i $interface -w $outfile; Write-Host "Capture saved to $outfile" -ForegroundColor Green }
function readpcap { param([string]$file) if (-not (Test-Path $file)) { Write-Host "File not found: $file" -ForegroundColor Red; return } tshark -r $file }
function pcapsummary { param([string]$file) if (-not (Test-Path $file)) { Write-Host "File not found: $file" -ForegroundColor Red; return } tshark -r $file -T fields -e frame.number -e ip.src -e ip.dst -e _ws.col.Protocol | Format-Table }
function snifffilter { param([string]$filter, [int]$interface = 1) tshark -i $interface -Y $filter }

function scan-host {
    param(
        [string]$target,
        [int]$interface
    )
    if ($PSBoundParameters.ContainsKey('interface')) {
        $adapter = Get-NetAdapter | Where-Object { $_.ifIndex -eq $interface }
        if ($adapter) {
            nmap -e $adapter.Name -A $target
        } else {
            Write-Host "No adapter with index $interface" -ForegroundColor Red
        }
    } else {
        nmap -A $target
    }
}
function speedtest{
	&"C:\Users\FienD\speedtest.exe"
}
function port-scan {
    param(
        [string]$host="localhost",
        [int]$interface
    )
    if ($PSBoundParameters.ContainsKey('interface')) {
        $adapter = Get-NetAdapter | Where-Object { $_.ifIndex -eq $interface }
        if ($adapter) {
            nmap -e $adapter.Name -p- $host
        } else {
            Write-Host "No adapter with index $interface" -ForegroundColor Red
        }
    } else {
        nmap -p- $host
    }
}

# --- 6. More Cybersecurity Functions ---
function file-hash {
    param(
        [Parameter(Mandatory)] [string]$file,
        [ValidateSet('MD5','SHA1','SHA256')] [string]$algo = 'SHA256'
    )
    if (-not (Test-Path $file)) {
        Write-Host "File not found: $file" -ForegroundColor Red
        return
    }
    Get-FileHash -Path $file -Algorithm $algo
}

function open-ports {
    Get-NetTCPConnection -State Listen | Select-Object LocalAddress,LocalPort,OwningProcess |
        Sort-Object LocalPort | Format-Table -AutoSize
}

function live-connections {
    Get-NetTCPConnection | Where-Object { $_.State -eq 'Established' } |
        Select-Object LocalAddress,LocalPort,RemoteAddress,RemotePort,OwningProcess |
        Format-Table -AutoSize
}

function proc-port {
    param([int]$port)
    $con = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue
    if ($con) {
        $proc = Get-Process -Id $con.OwningProcess -ErrorAction SilentlyContinue
        Write-Host "Port ${port}: $($proc.ProcessName) (PID: $($proc.Id))"
    } else {
        Write-Host "No process is using port $port" -ForegroundColor Yellow
    }
}


function whois {
    param([string]$domain)
    try {
        $server = "whois.verisign-grs.com"
        $tcp = New-Object System.Net.Sockets.TcpClient($server,43)
        $stream = $tcp.GetStream()
        $writer = New-Object System.IO.StreamWriter($stream)
        $writer.WriteLine($domain)
        $writer.Flush()
        $reader = New-Object System.IO.StreamReader($stream)
        $response = $reader.ReadToEnd()
        $tcp.Close()
        $response
    } catch {
        Write-Host "WHOIS query failed: $_" -ForegroundColor Red
    }
}

function dns-lookup {
    param(
        [Parameter(Mandatory)] [string]$domain,
        [ValidateSet('A','AAAA','MX','TXT','NS','SOA','CNAME')] [string]$type = 'A'
    )
    try {
        Resolve-DnsName -Name $domain -Type $type
    } catch {
        Write-Host "DNS lookup failed: $_" -ForegroundColor Red
    }
}

function http-get {
    param(
        [Parameter(Mandatory)] [string]$url
    )
    try {
        Invoke-WebRequest -Uri $url -UseBasicParsing | Select-Object StatusCode,StatusDescription,Headers
    } catch {
        Write-Host "HTTP request failed: $_" -ForegroundColor Red
    }
}

function hunt-exe {
    param([string]$path = ".")
    Get-ChildItem -Path $path -Recurse -Include *.exe,*.dll |
        Where-Object { $_.Length -gt 1048576 } |
        Select-Object FullName,Length,LastWriteTime | Sort-Object Length -Descending
}

function scheduled-hunt {
    Get-ScheduledTask | Where-Object { $_.State -eq 'Ready' -or $_.State -eq 'Running' } |
        Select-Object TaskName,State,Actions
}

function list-users {
    Get-LocalUser | Select-Object Name,Enabled,LastLogon
}
function list-admins {
    Get-LocalGroupMember -Group 'Administrators' | Select-Object Name,PrincipalSource
}

function drivers-list {
    Get-WmiObject Win32_SystemDriver | Select-Object Name,State,PathName,StartMode | Format-Table -AutoSize
}

# --- 7. Git Shortcuts ---
function gs    { git status }
function ga    { git add . }
function gc    { param([string]$msg) git commit -m "$msg" }
function gpush { git push }
function gcom  { param([string]$msg) git add .; git commit -m "$msg" }
function lazyg { param([string]$msg) git add .; git commit -m "$msg"; git push }

# --- 8. Clipboard, File, and Process Management ---
function cpy   { Set-Clipboard ($args -join " ") }
function pst   { Get-Clipboard }
function docs  { Set-Location ([Environment]::GetFolderPath("MyDocuments")) }
function dtop  { Set-Location ([Environment]::GetFolderPath("Desktop")) }
function nf    { param($name) New-Item -ItemType "file" -Path . -Name $name }
function mkcd  { param($dir) mkdir $dir -Force; Set-Location $dir }
function head  { param($Path, $n = 10) Get-Content $Path -Head $n }
function tail  { param($Path, $n = 10) Get-Content $Path -Tail $n }
function k9    { param($name) Stop-Process -Name $name }
function pkill { param($name) Get-Process $name -ErrorAction SilentlyContinue | Stop-Process }
function pgrep { param($name) Get-Process $name }

# --- 9. PSReadLine Customization ---
Set-PSReadLineOption -EditMode Windows -HistoryNoDuplicates -HistorySearchCursorMovesToEnd `
    -PredictionSource HistoryAndPlugin -MaximumHistoryCount 10000
Set-PSReadLineOption -BellStyle None
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
Set-PSReadLineKeyHandler -Chord 'Ctrl+d' -Function DeleteChar
Set-PSReadLineKeyHandler -Chord 'Ctrl+w' -Function BackwardDeleteWord
Set-PSReadLineKeyHandler -Chord 'Alt+d' -Function DeleteWord

# --- Win-KeX (WSL Kali) ---
function win-kali {
    [CmdletBinding()]
    param(
        [ValidateSet('win','esm','sl')] [string]$Mode = 'win',          # Window / Enhanced Session / Seamless
        [ValidateSet('start','stop','restart','client')] [string]$Action = 'start',
        [switch]$NoSound,                                               # By default adds -s (sound); use -NoSound to skip
        [string]$Distro = 'kali-linux'                                  # WSL distro name
    )

    if (-not (Get-Command wsl -ErrorAction SilentlyContinue)) {
        Write-Host "WSL not found in PATH." -ForegroundColor Red
        return
    }

    # Build args for the target distro (if installed)
    $availableDistros = @()
    try { $availableDistros = @(wsl -l -q 2>$null) } catch {}
    $dArgs = @()
    if ($availableDistros -and ($availableDistros -contains $Distro)) {
        $dArgs += @('-d', $Distro)
    }

    $modeArg = "--$Mode"

    switch ($Action) {
        'start' {
            $kexArgs = @('kex', $modeArg)
            if (-not $NoSound) { $kexArgs += '-s' }
            wsl @dArgs @kexArgs
        }
        'stop' {
            wsl @dArgs 'kex' $modeArg '--stop'
        }
        'restart' {
            wsl @dArgs 'kex' $modeArg '--stop'
            $kexArgs = @('kex', $modeArg)
            if (-not $NoSound) { $kexArgs += '-s' }
            wsl @dArgs @kexArgs
        }
        'client' {
            wsl @dArgs 'kex' $modeArg '--start-client'
        }
    }
}

# Convenience alias to match the help entry
Set-Alias -Name win-kex -Value win-kali -Option AllScope -Scope Global -Force


# --- 10. Comprehensive Help ---
function Show-Help {
    Write-Host @"
==========[ PowerShell Cybersecurity Profile Help ]==========

Core System & Info:
  sysinfo         - Displays system details (OS, BIOS, hardware)
  flushdns        - Clears DNS cache
  uptime          - Shows time since last boot

Navigation & Files:
  z, zi           - Jump to previous dirs (zoxide)
  docs            - Go to Documents folder
  dtop            - Go to Desktop folder
  nf <name>       - New empty file in current dir
  mkcd <dir>      - Make and cd into new dir
  head <file>     - First 10 lines of file
  tail <file>     - Last 10 lines of file

Clipboard:
  cpy <text>      - Copy text to clipboard
  pst             - Paste clipboard contents

Process:
  k9 <name>       - Kill process by name
  pkill <name>    - Kill all with given name
  pgrep <name>    - List all processes with name

Git Shortcuts:
  gs              - git status
  ga              - git add .
  gc "<msg>"      - git commit -m "<msg>"
  gpush           - git push
  gcom "<msg>"    - git add . & commit
  lazyg "<msg>"   - add, commit, and push all

Cybersecurity / Network:
  list-interfaces             - List all network interfaces (for tshark/nmap usage)
  nmap                        - Nmap scanner (check path if needed)
  scan-host <tgt> [iface]     - Nmap scan with OS/service detection; optionally specify iface index
  port-scan <hst> [iface]     - Full port scan on host; optionally specify iface index
  tshark                      - Wireshark CLI (check path if needed)
  sniff [iface]               - Live packet capture on iface (default 1)
  quickcap <n> [iface]        - Capture next <n> packets on iface (default 1)
  cap2file <file> [iface]     - Save live capture to file on iface
  readpcap <file>             - Display packets from a pcap file
  pcapsummary <file>          - Show src/dst/proto summary from pcap
  snifffilter <expr> [iface]  - Live filter (e.g. "http") on iface
  file-hash <file> [algo]     - Hash a file (SHA256 default, MD5/SHA1 optional)
  open-ports                  - List all open/listening ports and owning process
  live-connections            - Show live TCP connections (with process)
  proc-port <port>            - Show what process owns a port
  whois <domain>              - WHOIS lookup for a domain
  dns-lookup <dom> [type]     - DNS record lookup (A/MX/TXT/NS/etc.)
  http-get <url>              - Quick HTTP(S) GET, show status and headers
  hunt-exe [path]             - Find big/suspicious EXE/DLLs (default: current dir)
  scheduled-hunt              - List suspicious/active scheduled tasks
  list-users                  - Show all users on the system
  list-admins                 - Show all local administrators
  drivers-list                - List loaded system drivers
  win-kex                     - Kehehe

  Use 'list-interfaces' to find the right interface index.
  Example: quickcap 100 2   # Capture 100 packets on interface 2
           scan-host 192.168.1.1 4   # Scan host using interface 4

Editor Shortcuts:
  vim             - Open default editor
  ep              - Edit PowerShell profile

Misc:
  Show-Help       - Show this help message
-------------------------------------------------------------

"@ -ForegroundColor Yellow
}

Write-Host "[$(Get-Date -Format 'HH:mm:ss')] PowerShell loaded. Use 'Show-Help' for commands." -ForegroundColor Cyan

#f45873b3-b655-43a6-b217-97c00aa0db58 PowerToys CommandNotFound module

Import-Module -Name Microsoft.WinGet.CommandNotFound
#f45873b3-b655-43a6-b217-97c00aa0db58
