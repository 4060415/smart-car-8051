# read_com.ps1 -- open a serial port and print whatever the board sends.
#
# Purpose: read the log printed by firmware\selftest\selftest.asm
# (9600 8N1 on the CH340, COM7 on this machine) so the self-test results can be
# inspected without a GUI serial assistant.
#
# Usage:
#   powershell -NoProfile -ExecutionPolicy Bypass -File read_com.ps1
#   powershell -NoProfile -ExecutionPolicy Bypass -File read_com.ps1 -Port COM7 -Seconds 300
#
# Notes:
#   * STC-ISP must not be holding the port -- close it before running this.
#   * The log is appended to read_com.log next to this script.
# NOTE: keep this file ASCII-only (PowerShell reads BOM-less UTF-8 as GBK).

param(
    [string]$Port = 'COM7',
    [int]$Baud = 9600,
    [int]$Seconds = 240,
    [string]$LogFile
)

$ErrorActionPreference = 'Stop'

if (-not $LogFile) { $LogFile = Join-Path (Split-Path -Parent $PSScriptRoot) 'firmware\_serial_read.log' }

$sp = New-Object System.IO.Ports.SerialPort $Port, $Baud, 'None', 8, 'One'
$sp.ReadTimeout = 1000
$sp.NewLine = "`r`n"

Write-Host "opening $Port @ $Baud 8N1 ..."
try {
    $sp.Open()
} catch {
    Write-Host ("FAILED to open {0}: {1}" -f $Port, $_.Exception.Message) -ForegroundColor Red
    Write-Host 'If STC-ISP is open, close it first (it may hold the port).' -ForegroundColor Yellow
    exit 1
}

Write-Host ("open OK -- capturing for {0}s, log: {1}" -f $Seconds, $LogFile)
$sw = New-Object System.Diagnostics.Stopwatch
$sw.Start()
$buf = New-Object System.Text.StringBuilder

while ($sw.Elapsed.TotalSeconds -lt $Seconds) {
    try {
        $chunk = $sp.ReadExisting()
    } catch {
        $chunk = ''
    }
    if ($chunk) {
        Write-Host -NoNewline $chunk
        [void]$buf.Append($chunk)
    } else {
        Start-Sleep -Milliseconds 50
    }
}

$sp.Close()
$sp.Dispose()
$buf.ToString() | Out-File -FilePath $LogFile -Encoding utf8
Write-Host ''
Write-Host ("closed. {0} chars captured -> {1}" -f $buf.Length, $LogFile)
