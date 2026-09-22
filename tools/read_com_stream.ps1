# read_com_stream.ps1 -- open the serial port and APPEND every chunk to the log file
# continuously (flushing as it goes), so the log can be inspected WHILE the capture is
# still running -- useful when the person pressing the buttons is not synchronised with
# the capture window.
#
# Usage:
#   powershell -NoProfile -ExecutionPolicy Bypass -File tools\read_com_stream.ps1 -Port COM7 -Seconds 600
#
# Notes:
#   * STC-ISP must not be holding the port -- close it first.
#   * The log is truncated once at start, then appended to.
#   * The script exits by itself after -Seconds (default 600 = 10 minutes).
# NOTE: keep this file ASCII-only (PowerShell reads BOM-less UTF-8 as GBK).

param(
    [string]$Port = 'COM7',
    [int]$Baud = 9600,
    [int]$Seconds = 600,
    [string]$LogFile
)

$ErrorActionPreference = 'Stop'

if (-not $LogFile) { $LogFile = Join-Path (Split-Path -Parent $PSScriptRoot) 'firmware\_serial_read.log' }

# truncate (no BOM!)
[System.IO.File]::WriteAllText($LogFile, '')

$sp = New-Object System.IO.Ports.SerialPort $Port, $Baud, 'None', 8, 'One'
$sp.ReadTimeout = 500

Write-Host ("opening {0} @ {1} 8N1 ..." -f $Port, $Baud)
try {
    $sp.Open()
} catch {
    Write-Host ("FAILED to open {0}: {1}" -f $Port, $_.Exception.Message) -ForegroundColor Red
    Write-Host 'If STC-ISP is open, close it first (it holds the port).' -ForegroundColor Yellow
    exit 1
}

Write-Host ("open OK -- streaming to {0} for {1}s" -f $LogFile, $Seconds)
$sw = [System.Diagnostics.Stopwatch]::StartNew()
$total = 0

while ($sw.Elapsed.TotalSeconds -lt $Seconds) {
    try {
        $chunk = $sp.ReadExisting()
    } catch {
        $chunk = ''
    }
    if ($chunk) {
        [System.IO.File]::AppendAllText($LogFile, $chunk)
        Write-Host -NoNewline $chunk
        $total += $chunk.Length
    } else {
        Start-Sleep -Milliseconds 50
    }
}

$sp.Close()
$sp.Dispose()
Write-Host ''
Write-Host ("closed. {0} chars -> {1}" -f $total, $LogFile)
