# cleanup_keil_part1_user.ps1
# ---------------------------------------------------------------------------
# Removes the broken Keil C51 / uVision4 installation -- user-level parts.
# (The matching administrator-level script is cleanup_keil_part2_admin.ps1.)
#
# What it deletes:
#   D:\C51            broken C51 toolchain (C51.exe missing, A51/BL51/OH51 corrupt)
#   D:\UV4            uVision4 IDE shell (15.6 MB, no working tools inside)
#   D:\Uninstall.exe  Keil's own uninstaller, left at the install root (D:\)
#   D:\TOOLS.INI      Keil tool registration file at the install root (D:\)
#   HKCU\Software\Keil                       uVision4 user settings / recent lists
#   Desktop shortcut  "Keil uVision4.LNK"
#
# A backup of TOOLS.INI, the registry keys and the deleted file lists is in
# .\backup\ (created before the removal).
#
# Usage:
#   powershell -NoProfile -ExecutionPolicy Bypass -File cleanup_keil_part1_user.ps1
# ---------------------------------------------------------------------------
# Keep this file ASCII-only: Windows PowerShell reads BOM-less UTF-8 as GBK.

$log = Join-Path $PSScriptRoot 'cleanup_keil_part1.log'
function Log($m) {
    $line = "{0}  {1}" -f (Get-Date -Format 'HH:mm:ss'), $m
    Write-Host $line
    Add-Content -Path $log -Value $line -Encoding utf8
}

Log '=== [1/5] stop any running Keil / setup process ==='
Get-Process -ErrorAction SilentlyContinue |
    Where-Object { $_.ProcessName -match '^(uv4|uvision|uninstall|_iu.*)$' } |
    ForEach-Object {
        Log ("  kill PID {0} ({1})" -f $_.Id, $_.ProcessName)
        Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
    }

Log '=== [2/5] delete Keil directories and root files ==='
$targets = @('D:\C51', 'D:\UV4', 'D:\Uninstall.exe', 'D:\TOOLS.INI')
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

Log '=== [3/5] delete HKCU\Software\Keil ==='
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

Log '=== [4/5] delete user shortcuts ==='
$lnks = @(
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

Log '=== [5/5] verify ==='
foreach ($t in $targets) { Log ("  {0,-20} exists = {1}" -f $t, (Test-Path $t)) }
Log ("  HKCU\Software\Keil   exists = {0}" -f (Test-Path 'HKCU:\Software\Keil'))
Log 'part 1 finished. Now run cleanup_keil_part2_admin.ps1 as Administrator.'
