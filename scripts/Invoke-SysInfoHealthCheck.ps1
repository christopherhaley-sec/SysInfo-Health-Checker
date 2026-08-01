<#
.SYNOPSIS
    Windows Endpoint System Health Checker
.DESCRIPTION
    Collects key diagnostic details including OS specs, CPU usage, RAM utilization,
    disk storage, network IP configuration, and critical running service states.
    Outputs results to terminal and appends to a local log file.
.AUTHOR
    Christopher Haley
#>

$ErrorActionPreference = "SilentlyContinue"
$LogPath = "$PSScriptRoot\..\HealthCheck_Log.txt"
$Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

function Write-Diagnostics {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Color
    Add-Content -Path $LogPath -Value $Message
}

# Clear previous session log header
Add-Content -Path $LogPath -Value "`n=========================================="
Add-Content -Path $LogPath -Value " System Health Check - $Timestamp"
Add-Content -Path $LogPath -Value "=========================================="

Write-Diagnostics "==========================================" "Cyan"
Write-Diagnostics "   SYSTEM HEALTH DIAGNOSTIC REPORT        " "Cyan"
Write-Diagnostics "   Executed: $Timestamp                   " "Cyan"
Write-Diagnostics "==========================================" "Cyan"

# 1. System Overview
$OS = Get-CimInstance Win32_OperatingSystem
$ComputerSystem = Get-CimInstance Win32_ComputerSystem
$Uptime = (Get-Date) - $OS.LastBootUpTime

Write-Diagnostics "`n[+] SYSTEM OVERVIEW" "Yellow"
Write-Diagnostics "  Hostname      : $env:COMPUTERNAME"
Write-Diagnostics "  OS Name       : $($OS.Caption)"
Write-Diagnostics "  OS Version    : $($OS.Version)"
Write-Diagnostics "  System Uptime : $($Uptime.Days) Days, $($Uptime.Hours) Hours, $($Uptime.Minutes) Mins"

# 2. Hardware Resources
$TotalRAM = [math]::Round($ComputerSystem.TotalPhysicalMemory / 1GB, 2)
$FreeRAM = [math]::Round($OS.FreePhysicalMemory / 1MB / 1024, 2)
$UsedRAM = [math]::Round($TotalRAM - $FreeRAM, 2)
$RAMPercent = [math]::Round(($UsedRAM / $TotalRAM) * 100, 1)

$CPU = Get-CimInstance Win32_Processor | Select-Object -First 1

Write-Diagnostics "`n[+] HARDWARE RESOURCE UTILIZATION" "Yellow"
Write-Diagnostics "  CPU Model     : $($CPU.Name)"
Write-Diagnostics "  RAM Installed : $TotalRAM GB"
Write-Diagnostics "  RAM Usage     : $UsedRAM GB / $TotalRAM GB ($RAMPercent%)"

# 3. Disk Storage
Write-Diagnostics "`n[+] DISK STORAGE" "Yellow"
$Disks = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3"
foreach ($Disk in $Disks) {
    $Size = [math]::Round($Disk.Size / 1GB, 2)
    $Free = [math]::Round($Disk.FreeSpace / 1GB, 2)
    $Used = [math]::Round($Size - $Free, 2)
    $PercentFree = [math]::Round(($Free / $Size) * 100, 1)
    
    $StatusColor = if ($PercentFree -lt 15) { "Red" } else { "Green" }
    Write-Diagnostics "  Drive $($Disk.DeviceID) :: Free: $Free GB / $Size GB ($PercentFree% Available)" $StatusColor
}

# 4. Network Configuration
Write-Diagnostics "`n[+] NETWORK CONFIGURATION" "Yellow"
$NetAdapters = Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -notlike "*Loopback*" }
foreach ($Adapter in $NetAdapters) {
    Write-Diagnostics "  Adapter Alias : $($Adapter.InterfaceAlias)"
    Write-Diagnostics "  IPv4 Address  : $($Adapter.IPAddress)"
    Write-Diagnostics "  Subnet Prefix : /$($Adapter.PrefixLength)"
}

# 5. Critical Services Check
Write-Diagnostics "`n[+] CRITICAL SERVICES STATUS" "Yellow"
$ServicesToMonitor = @("Spooler", "wuauserv", "Dhcp", "Dnscache", "EventLog")
foreach ($SvcName in $ServicesToMonitor) {
    $Svc = Get-Service -Name $SvcName -ErrorAction SilentlyContinue
    if ($Svc) {
        $StateColor = if ($Svc.Status -eq "Running") { "Green" } else { "Red" }
        Write-Diagnostics "  Service: $($Svc.DisplayName) ($SvcName) -> State: $($Svc.Status)" $StateColor
    }
}

Write-Diagnostics "`n==========================================" "Cyan"
Write-Diagnostics " Diagnostic report saved to: $LogPath" "Green"
Write-Diagnostics "==========================================" "Cyan"