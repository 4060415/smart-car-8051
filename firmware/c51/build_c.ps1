# build_c.ps1 -- compile the C firmware (main.c).
#
# !! THIS SCRIPT CANNOT PRODUCE A FLASHABLE HEX FOR THIS PROGRAM -- see below. !!
# For the working build use:   build_c_abs.ps1
#
# Toolchain: Keil C51 command line tools
#   C51 (C compiler) -> BL51 (linker) -> OH51 (hex converter)
# NOTE: the C51 COMPILER has no size limit; only the BL51 LINKER enforces the
#       2048-byte limit in the Evaluation edition. So this script can be used to
#       syntax-check / measure the object size even with an Eval install.
#
# WHY THE HEX IS MISSING:
#   main.c is about 2939 bytes, over the Eval limit of 0800H = 2048 bytes, so BL51
#   stops with "*** FATAL ERROR L250: CODE SIZE LIMIT ... EXCEEDED" and produces
#   no .abs -> OH51 has nothing to convert.
#   LX51 (the extended linker) was measured too: same restricted message, same
#   L250. Swapping linkers does NOT help.
#   => The address assignment is done by tools\c51_link.py instead (that step is
#      all a linker does), and the hex comes from the A51 listing via
#      tools\lst2hex.py. See build_c_abs.ps1 and docs\C版移植方案.md section 11.
#
# Usage:
#   powershell -NoProfile -ExecutionPolicy Bypass -File build_c.ps1
#   powershell -NoProfile -ExecutionPolicy Bypass -File build_c.ps1 -Name foo
#
# NOTE: keep this file ASCII-only -- Windows PowerShell reads BOM-less UTF-8 as GBK.

param(
    [string]$Name = 'main'
)

$ErrorActionPreference = 'Stop'

function Step($title, $exe, $toolArgs) {
    Write-Host "=== $title ===" -ForegroundColor Cyan
    Add-Content $log "=== $title ==="
    & (Join-Path $keilBin $exe) @toolArgs 2>&1 | Tee-Object -FilePath $log -Append
    # NOTE: BL51 returns exit code 1 when it only has WARNINGS (e.g. L16 uncalled
    # segment) even though linking succeeded -- so we do NOT throw on exit code.
    # Each caller verifies the expected output file exists instead.
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

if (-not (Test-Path "$Name.c")) { throw "source not found: $here\$Name.c" }

$log = Join-Path $here "$Name.build_c.log"
Remove-Item $log -ErrorAction SilentlyContinue
Remove-Item "$Name.obj", "$Name.abs", "$Name.hex", "$Name.lst", "$Name.m51" -ErrorAction SilentlyContinue

# [1/3] C51 : C -> object.  (SMALL memory model; DEBUG adds line info to the .lst)
Step "[1/3] compile (C51)"  'C51.EXE'  @("$Name.c", 'SMALL', 'DEBUG')
if (-not (Test-Path "$Name.obj")) { throw "C51 produced no $Name.obj" }

# report the object size (this is what matters for the 2KB linker limit)
$objSize = (Get-Item "$Name.obj").Length
Write-Host ("object size: {0} bytes" -f $objSize)

# [2/3] BL51 : link
Step "[2/3] link (BL51)"    'BL51.EXE' @("$Name.obj", 'TO', "$Name.abs")
if (-not (Test-Path "$Name.abs")) { throw "BL51 produced no $Name.abs" }

# [3/3] OH51 : make hex
Step "[3/3] make hex (OH51)" 'OH51.EXE' @("$Name.abs")
if (-not (Test-Path "$Name.hex")) { throw "OH51 produced no $Name.hex" }

Write-Host ''
Write-Host 'BUILD OK' -ForegroundColor Green
Get-ChildItem "$Name.hex", "$Name.abs", "$Name.obj", "$Name.lst", "$Name.m51" -ErrorAction SilentlyContinue |
    Select-Object Name, Length, LastWriteTime | Format-Table -AutoSize
Write-Host "hex file : $here\$Name.hex"
Write-Host 'Flash it: STC-ISP -> MCU type STC89C52RC -> COM7 -> Open the hex -> Download/Program ->'
Write-Host 'then COLD BOOT the board (unplug/replug the USB cable).'
