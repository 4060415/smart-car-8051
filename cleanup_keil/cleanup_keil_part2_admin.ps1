# cleanup_keil_part2_admin.ps1
# ---------------------------------------------------------------------------
# Removes the ADMINISTRATOR-level leftovers of the broken Keil installation.
# Run this AFTER cleanup_keil_part1_user.ps1.
#
# Must be run as Administrator (right-click -> "Run as administrator").
#
# What it deletes:
#   HKLM\SOFTWARE\WOW6432Node\Keil                     "Products\C51" registration
#   HKLM\SOFTWARE\Keil                                 (if present)
#   HKLM\...\CurrentVersion\Uninstall\<Keil uVision4>  the "Uninstall" entry in
#                                                      Apps & Features
#   C:\ProgramData\...\Start Menu\Programs\Keil uVision4.LNK
#   any leftover Keil install directories (C:\Keil, C:\Keil_v5, D:\Keil, ...)
#   plus everything part 1 handles, in case part 1 was skipped
#
# Usage (elevated PowerShell):
#   powershell -NoProfile -ExecutionPolicy Bypass -File cleanup_keil_part2_admin.ps1
# ---------------------------------------------------------------------------
# Keep this file ASCII-only: Windows PowerShell reads BOM-less UTF-8 as GBK.

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
           ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host 'ERROR: this script needs Administrator rights.' -ForegroundColor Red
    Write-Host 'Right-click the file -> "Run as administrator", or run it from an elevated PowerShell.' -ForegroundColor Red
    exit 1
}

$log = Join-Path $PSScriptRoot 'cleanup_keil_part2.log'
function Log($m) {
    $line = "{0}  {1}" -f (Get-Date -Format 'HH:mm:ss'), $m
    Write-Host $line
    Add-Content -Path $log -Value $line -Encoding utf8
}

Log '=== [1/7] stop any running Keil / setup process ==='
Get-Process -ErrorAction SilentlyContinue |
    Where-Object { $_.ProcessName -match '^(uv4|uvision|uninstall|_iu.*)$' } |
    ForEach-Object {
        Log ("  kill PID {0} ({1})" -f $_.Id, $_.ProcessName)
        Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
    }

Log '=== [2/7] delete install directories and root files ==='
$targets = @(
    'D:\C51', 'D:\UV4', 'D:\Uninstall.exe', 'D:\TOOLS.INI',
    'C:\Keil', 'C:\Keil_v5', 'D:\Keil', 'C:\Keil\UV4'
)
foreach ($t in $targets) {
    if (Test-Path $t) {
        try {
            Remove-Item $t -Recurse -Force -ErrorAction Stop
            Log "  removed: $t"
        } catch {
            Log ("  FAILED: {0} -> {1}" -f $t, $_.Exception.Message)
        }
    } else {
        Log "  not present: $t"
    }
}

Log '=== [3/7] delete HKLM Keil product keys ==='
foreach ($k in 'HKLM:\SOFTWARE\WOW6432Node\Keil', 'HKLM:\SOFTWARE\Keil') {
    if (Test-Path $k) {
        try {
            Remove-Item $k -Recurse -Force -ErrorAction Stop
            Log "  removed: $k"
        } catch {
            Log ("  FAILED: {0} -> {1}" -f $k, $_.Exception.Message)
        }
    } else {
        Log "  not present: $k"
    }
}

Log '=== [4/7] delete the "Keil uVision4" uninstall entry ==='
$bases = @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall',
    'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'
)
foreach ($base in $bases) {
    if (-not (Test-Path $base)) { continue }
    Get-ChildItem $base -ErrorAction SilentlyContinue | ForEach-Object {
        $p = Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue
        if ($p.DisplayName -match 'Keil|uVision') {
            try {
                Remove-Item $_.PSPath -Recurse -Force -ErrorAction Stop
                Log ("  removed entry: {0}  ({1})" -f $p.DisplayName, $_.PSChildName)
            } catch {
                Log ("  FAILED entry {0}: {1}" -f $_.PSChildName, $_.Exception.Message)
            }
        }
    }
}

Log '=== [5/7] delete HKCU\Software\Keil (in case part 1 was skipped) ==='
if (Test-Path 'HKCU:\Software\Keil') {
    try {
        Remove-Item 'HKCU:\Software\Keil' -Recurse -Force -ErrorAction Stop
        Log '  removed HKCU\Software\Keil'
    } catch {
        Log ("  FAILED: " + $_.Exception.Message)
    }
} else {
    Log '  not present'
}

Log '=== [6/7] delete shortcuts ==='
$lnks = @(
    "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Keil uVision4.LNK",
    "$env:USERPROFILE\Desktop\Keil uVision4.LNK",
    "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Keil uVision4.LNK"
)
foreach ($l in $lnks) {
    if (Test-Path $l) {
        try {
            Remove-Item $l -Force -ErrorAction Stop
            Log "  removed: $l"
        } catch {
            Log ("  FAILED: {0} -> {1}" -f $l, $_.Exception.Message)
        }
    } else {
        Log "  not present: $l"
    }
}

Log '=== [7/7] verify ==='
foreach ($t in @('D:\C51', 'D:\UV4', 'D:\Uninstall.exe', 'D:\TOOLS.INI', 'C:\Keil', 'C:\Keil_v5', 'D:\Keil')) {
    Log ("  {0,-20} exists = {1}" -f $t, (Test-Path $t))
}
foreach ($k in 'HKCU:\Software\Keil', 'HKLM:\SOFTWARE\WOW6432Node\Keil', 'HKLM:\SOFTWARE\Keil') {
    Log ("  {0,-45} exists = {1}" -f $k, (Test-Path $k))
}
$left = @()
foreach ($base in $bases) {
    if (-not (Test-Path $base)) { continue }
    Get-ChildItem $base -ErrorAction SilentlyContinue | ForEach-Object {
        $p = Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue
        if ($p.DisplayName -match 'Keil|uVision') { $left += $p.DisplayName }
    }
}
Log ("  remaining Keil uninstall entries = {0}" -f (($left | Measure-Object).Count))
Log 'part 2 finished. Keil is fully removed -- now run C51V900.exe to reinstall.'
