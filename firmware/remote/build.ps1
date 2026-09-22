# build.ps1 -- assemble an 8051 program and produce an Intel HEX for STC-ISP.
#
# Toolchain: Keil C51 command line tools
#   A51 (assembler) -> BL51 (linker) -> OH51 (hex converter)
# No uVision GUI needed. Toolchain path is auto-detected.
# Current install: D:\keli\C51  (V9.00) -- registered? see docs\开发环境与工具链.md
#
# Usage:
#   powershell -NoProfile -ExecutionPolicy Bypass -File build.ps1            # builds remote.asm
#   powershell -NoProfile -ExecutionPolicy Bypass -File build.ps1 -Name foo  # builds foo.asm
#
# NOTE: keep this file ASCII-only -- Windows PowerShell reads BOM-less UTF-8 as GBK.

param(
    [string]$Name = 'remote'
)

$ErrorActionPreference = 'Stop'

# NOTE: the helper parameter below must NOT be named $args -- that is a
# PowerShell automatic variable, and using it collides with the @splat operator
# (the tool would then be launched with no arguments at all).
function Step($title, $exe, $toolArgs) {
    Write-Host "=== $title ===" -ForegroundColor Cyan
    Add-Content $log "=== $title ==="
    & (Join-Path $keilBin $exe) @toolArgs 2>&1 | Tee-Object -FilePath $log -Append
    if ($LASTEXITCODE -ne 0) { throw "$exe failed with exit code $LASTEXITCODE" }
}

$candidates = @(
    'D:\keli\C51\BIN',
    'C:\Keil\C51\BIN',
    'C:\Keil_v5\C51\BIN',
    'D:\Keil\C51\BIN',
    'D:\C51\BIN',
    'C:\Keil\UV4\C51\BIN'
)
$keilBin = $candidates | Where-Object { Test-Path (Join-Path $_ 'C51.EXE') } | Select-Object -First 1
if (-not $keilBin) {
    throw "Keil C51 toolchain not found. Looked in:`n  " + ($candidates -join "`n  ")
}
Write-Host "toolchain: $keilBin"

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $here

if (-not (Test-Path "$Name.asm")) { throw "source not found: $here\$Name.asm" }

$log = Join-Path $here "$Name.build.log"
Remove-Item $log -ErrorAction SilentlyContinue
Remove-Item "$Name.obj", "$Name.abs", "$Name.hex", "$Name.lst", "$Name.m51" -ErrorAction SilentlyContinue

Step "[1/3] assemble (A51)"  'A51.EXE'  @("$Name.asm")
if (-not (Test-Path "$Name.obj")) { throw "A51 produced no $Name.obj" }

Step "[2/3] link (BL51)"     'BL51.EXE' @("$Name.obj", 'TO', "$Name.abs")
if (-not (Test-Path "$Name.abs")) { throw "BL51 produced no $Name.abs" }

Step "[3/3] make hex (OH51)" 'OH51.EXE' @("$Name.abs")
if (-not (Test-Path "$Name.hex")) { throw "OH51 produced no $Name.hex" }

Write-Host ''
Write-Host 'BUILD OK' -ForegroundColor Green
Get-ChildItem "$Name.hex", "$Name.abs", "$Name.obj", "$Name.lst", "$Name.m51" -ErrorAction SilentlyContinue |
    Select-Object Name, Length, LastWriteTime | Format-Table -AutoSize
Write-Host "hex file : $here\$Name.hex"
Write-Host 'Flash it: STC-ISP -> MCU type STC89C52RC -> COM7 -> Open the hex -> Download/Program ->'
Write-Host 'then COLD BOOT the board (unplug/replug the USB cable).'
