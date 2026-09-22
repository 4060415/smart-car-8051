# build.ps1 -- assemble the main firmware and produce an Intel HEX for STC-ISP.
#
# Toolchain: Keil C51 command line tools
#   A51 (assembler) -> BL51 (linker) -> OH51 (hex converter)
# No uVision GUI needed. Toolchain path is auto-detected.
# Current install: D:\keli\C51 (V9.00) -- EVAL edition, hard 2048-byte code limit.
#
# Usage:
#   powershell -NoProfile -ExecutionPolicy Bypass -File build.ps1            # builds car_asm.asm
#   powershell -NoProfile -ExecutionPolicy Bypass -File build.ps1 -Name foo  # builds foo.asm
#
# NOTE: keep this file ASCII-only -- Windows PowerShell reads BOM-less UTF-8 as GBK.
#
# ---------------------------------------------------------------------------
# CODE SIZE LIMIT AND THE lst2hex FALLBACK  (added 2026-09-20)
# ---------------------------------------------------------------------------
# BL51 in the Eval edition refuses to link more than 0800H = 2048 bytes of code:
#     *** FATAL ERROR L250: CODE SIZE LIMIT IN RESTRICTED VERSION EXCEEDED
# This is a hard failure (exit code 3, no .abs, no .hex) -- not a warning.
# The innovation feature (blocks 7/8) needs roughly +500 bytes, so the project
# will exceed 2048 and BL51 will stop building it.
#
# The A51 *assembler* has no such limit. car_asm.asm is a single absolute module
# (ORG-based, no EXTRN/PUBLIC), so A51 already resolves every address and the
# .LST listing holds the final object bytes. When BL51 fails, this script
# therefore falls back to tools\lst2hex.py, which rebuilds the Intel HEX from
# the listing.
#
# The fallback is VALIDATED: for any build BL51 can still link, the image from
# lst2hex.py is byte-for-byte identical to the image from BL51+OH51.
#   python tools\compare_hex.py <lst2hex output> <bl51 output>   -> IDENTICAL
# Recorded on build code=2011 (see the design-freeze doc under docs\, section 1.5/append).
# ---------------------------------------------------------------------------

param(
    [string]$Name = 'car_asm'
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

# ---- [2/3] link ----------------------------------------------------------
# Invoked directly (not via Step) so that a non-zero exit is a fallback trigger
# instead of a hard abort. BL51 still prints the "Program Size: ... code=NNNN"
# line before failing, so the size report is preserved either way.
Write-Host "=== [2/3] link (BL51) ===" -ForegroundColor Cyan
Add-Content $log "=== [2/3] link (BL51) ==="
& (Join-Path $keilBin 'BL51.EXE') @("$Name.obj", 'TO', "$Name.abs") 2>&1 | Tee-Object -FilePath $log -Append
$linkOk = ($LASTEXITCODE -eq 0) -and (Test-Path "$Name.abs")

if ($linkOk) {
    Step "[3/3] make hex (OH51)" 'OH51.EXE' @("$Name.abs")
    if (-not (Test-Path "$Name.hex")) { throw "OH51 produced no $Name.hex" }
}
else {
    Write-Host ''
    Write-Host 'BL51 FAILED -- expected when the Eval 2048-byte code limit is exceeded' -ForegroundColor Yellow
    Write-Host '  (*** FATAL ERROR L250: CODE SIZE LIMIT IN RESTRICTED VERSION EXCEEDED)' -ForegroundColor Yellow
    Write-Host 'Falling back to tools\lst2hex.py: A51 listing -> Intel HEX (no size limit).' -ForegroundColor Yellow
    Write-Host 'That path is validated byte-for-byte against BL51+OH51 for linkable builds.' -ForegroundColor Yellow

    if (-not (Test-Path "$Name.lst")) { throw "BL51 failed and there is no $Name.lst to convert" }

    $repoRoot  = Split-Path -Parent (Split-Path -Parent $here)
    $converter = Join-Path $repoRoot 'tools\lst2hex.py'
    if (-not (Test-Path $converter)) { throw "fallback converter not found: $converter" }

    $pyExe = $null
    foreach ($c in @('python', 'py')) {
        $cmd = Get-Command $c -ErrorAction SilentlyContinue
        if ($cmd) { $pyExe = $cmd.Source; break }
    }
    if (-not $pyExe) { throw "python not found on PATH; it is required for the lst2hex.py fallback" }

    Write-Host "=== [3/3] make hex (lst2hex.py fallback) ===" -ForegroundColor Cyan
    Add-Content $log "=== [3/3] make hex (lst2hex.py fallback) ==="
    & $pyExe $converter "$Name.lst" "$Name.hex" 2>&1 | Tee-Object -FilePath $log -Append
    if ($LASTEXITCODE -ne 0) { throw "lst2hex.py failed with exit code $LASTEXITCODE" }
    if (-not (Test-Path "$Name.hex")) { throw "lst2hex.py produced no $Name.hex" }

    Write-Host ''
    Write-Host 'WARNING: this hex came from the lst2hex fallback, NOT from BL51+OH51.' -ForegroundColor Yellow
    Write-Host '         It is validated, but re-check the size and re-run the full on-board regression.' -ForegroundColor Yellow
}

Write-Host ''
Write-Host 'BUILD OK' -ForegroundColor Green
Get-ChildItem "$Name.hex", "$Name.abs", "$Name.obj", "$Name.lst", "$Name.m51" -ErrorAction SilentlyContinue |
    Select-Object Name, Length, LastWriteTime | Format-Table -AutoSize
Write-Host "hex file : $here\$Name.hex"
Write-Host 'Flash it: STC-ISP -> MCU type STC89C52RC -> COM7 -> Open the hex -> Download/Program ->'
Write-Host 'then COLD BOOT the board (unplug/replug the USB cable).'
