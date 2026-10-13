# build.ps1 -- build the minimal forward/backward demo (fwd_back.c).
#
# Toolchain: Keil C51 command line tools
#   C51 (C compiler) -> BL51 (linker) -> OH51 (hex converter)
# The program is only a few hundred bytes, far below the 2048-byte limit of the
# Evaluation linker, so the plain C51 -> BL51 -> OH51 flow works here (unlike the
# full firmware, which needs tools\c51_link.py + tools\lst2hex.py).
#
# Usage:
#   powershell -NoProfile -ExecutionPolicy Bypass -File build.ps1
#
# NOTE: keep this file ASCII-only -- Windows PowerShell reads BOM-less UTF-8 as GBK.

$ErrorActionPreference = 'Stop'

function Step($title, $exe, $toolArgs) {
    Write-Host "=== $title ===" -ForegroundColor Cyan
    Add-Content $log "=== $title ==="
    & (Join-Path $keilBin $exe) @toolArgs 2>&1 | Tee-Object -FilePath $log -Append
    # BL51 returns exit code 1 for warnings-only runs, so we do not throw on exit
    # code; each step verifies the expected output file exists instead.
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

$name = 'fwd_back'
if (-not (Test-Path "$name.c")) { throw "source not found: $here\$name.c" }

$log = Join-Path $here "$name.build.log"
Remove-Item $log -ErrorAction SilentlyContinue
Remove-Item "$name.obj", "$name.abs", "$name.hex", "$name.lst", "$name.m51" -ErrorAction SilentlyContinue

# [1/3] C51 : C -> object (SMALL memory model; DEBUG adds line info to the .lst)
Step "[1/3] compile (C51)"  'C51.EXE'  @("$name.c", 'SMALL', 'DEBUG')
if (-not (Test-Path "$name.obj")) { throw "C51 produced no $name.obj" }
Write-Host ("object size: {0} bytes" -f (Get-Item "$name.obj").Length)

# [2/3] BL51 : link
Step "[2/3] link (BL51)"    'BL51.EXE' @("$name.obj", 'TO', "$name.abs")
if (-not (Test-Path "$name.abs")) { throw "BL51 produced no $name.abs" }

# [3/3] OH51 : make hex
Step "[3/3] make hex (OH51)" 'OH51.EXE' @("$name.abs")
if (-not (Test-Path "$name.hex")) { throw "OH51 produced no $name.hex" }

Write-Host ''
Write-Host 'BUILD OK' -ForegroundColor Green
Get-ChildItem "$name.hex", "$name.abs", "$name.obj", "$name.lst", "$name.m51" -ErrorAction SilentlyContinue |
    Select-Object Name, Length, LastWriteTime | Format-Table -AutoSize
Write-Host "hex file : $here\$name.hex"
Write-Host 'Flash it: STC-ISP -> MCU type STC89C52RC -> COM7 -> Open the hex -> Download/Program ->'
Write-Host 'then COLD BOOT the board (unplug/replug the USB cable).'
