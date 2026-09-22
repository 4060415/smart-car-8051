# build_c_abs.ps1 -- build the C firmware (main.c) into a flashable Intel HEX.
#
# WHY THIS SCRIPT EXISTS
# ----------------------
# The official Keil flow (C51 -> BL51 -> OH51, see build_c.ps1) CANNOT produce a
# hex for this program: the installed Keil is the Evaluation edition and its
# linker refuses to link more than 0800H = 2048 bytes:
#
#     BL51.EXE -> *** FATAL ERROR L250: CODE SIZE LIMIT ... EXCEEDED
#     LX51.EXE -> RESTRICTED VERSION WITH 0800H BYTE CODE SIZE LIMIT ... L250
#
# (Both linkers were measured; swapping to LX51 does NOT help.)
# The C build is about 2890 bytes, so the official flow stops after C51.
#
# Only the BL51 *linker* is restricted. The C51 *compiler* and the A51
# *assembler* are not. So this script does the linking itself:
#
#     C51 (unlimited)  -> main.src         relocatable assembler source
#     c51_link.py      -> main_abs.asm     one ABSOLUTE module (address assignment)
#     A51 (unlimited)  -> main_abs.LST     final machine code in the listing
#     lst2hex.py       -> main.hex         Intel HEX for STC-ISP
#
#   Output naming: everything is "main" now -- the flashable file is plain
#   "main.hex" (and "main_dbg.hex" for -Debug) because that is the file picked at
#   the bench, and the intermediate files follow the same name (main.src,
#   main_abs.asm, main_abs.LST) so they obviously belong together.
#   (These files used to be named car_c.* / car_c_abs.*; renamed to main.* on
#    2026-09-21. Only the names changed -- the generated hex is byte-identical.)
#
# The address assignment done by c51_link.py is checked by c51_verify.py, which
# compares the per-function byte counts of main.lst (what C51 generated) against
# main_abs.LST (what A51 assembled). They must match exactly.
#
# Every step is FAIL-CLOSED: a non-zero error count from C51 or A51 aborts the
# build. (Learned the hard way: A51 once reported "1 ERROR(S)" and still left a
# truncated .LST behind, which is exactly how a broken hex would get flashed.)
#
# Usage:
#   powershell -NoProfile -ExecutionPolicy Bypass -File build_c_abs.ps1
#   powershell -NoProfile -ExecutionPolicy Bypass -File build_c_abs.ps1 -Debug
#   powershell -NoProfile -ExecutionPolicy Bypass -File build_c_abs.ps1 -Scope
#   powershell -NoProfile -ExecutionPolicy Bypass -File build_c_abs.ps1 -Ir
#   (one variant per run; -Ir / -Scope both keep the UART OFF on purpose)
#
# -Debug builds a DIAGNOSTIC variant with DEBUG_UART=1 (serial prints enabled)
#   and writes main_dbg.hex. Use it only when something misbehaves on the
#   bench: the normal build has no serial output at all, so an IR problem would
#   otherwise be invisible. Do NOT use the debug hex for the demo -- printing
#   during IR reception makes the receiver miss frames (see main.c section 1).
#   The normal main.hex is NOT touched by -Debug.
#
# NOTE: keep this file ASCII-only -- Windows PowerShell reads BOM-less UTF-8 as GBK.

param(
    [switch]$Debug,
    [switch]$Scope,
    [switch]$Ir
)

$ErrorActionPreference = 'Stop'

$c51extra = @()
$hexname  = 'main.hex'
$hexdir   = $null                   # set below, once $here is known
if ($Debug) {
    $c51extra = @('DEFINE(DEBUG_UART=1)')
    $hexname  = 'main_dbg.hex'
}
if ($Scope) {
    # Ultrasonic self-test: runs THIS firmware's own us_read() and shows the result
    # on the 7-segment only:
    #     E = no echo rising edge (module did not respond to the trigger)
    #     H = echo came but is >= US_NEAR (far)
    #     0-9 = the raw tick count the avoidance thresholds are compared against
    # NOTE: serial printing is deliberately NOT enabled here. prt_boot() runs
    # BEFORE the first display write and put_char() busy-waits on TI, so a UART
    # problem would freeze the program with the display still blank -- which is
    # exactly the "us_scope shows nothing" symptom seen on 2026-09-21.
    $c51extra = @('DEFINE(AV_SCOPE=1)')
    $hexname  = 'us_scope.hex'
}
if ($Ir) {
    # IR diagnostic (DIAG_IR=1): shows what the IR decoder did ON THE 7-SEGMENT.
    #     full frame  -> one short beep, then the decoded key byte (high/low nibble
    #                    alternate every 600ms) -- e.g. "4" then "6" for 46H
    #     frame rejected -> two short beeps, then lo / hi / cmd / ~cmd rotate
    # A serial-based IR diagnostic CANNOT be trusted: printing one 40-char line
    # takes 42ms while a whole NEC frame is only 67ms, so the printer itself eats
    # frames (see main.c section 1). This build keeps the UART off on purpose.
    # NOTE: this is the REAL firmware with the display taken over -- the car still
    # drives, so put the wheels in the air.
    $c51extra = @('DEFINE(DIAG_IR=1)')
    $hexname  = 'main_irdiag.hex'
}
$keilBin = $null
foreach ($c in @('D:\keli\C51\BIN', 'C:\Keil\C51\BIN', 'C:\Keil_v5\C51\BIN',
                 'D:\Keil\C51\BIN', 'D:\C51\BIN')) {
    if (Test-Path (Join-Path $c 'C51.EXE')) { $keilBin = $c; break }
}
if (-not $keilBin) { throw "Keil C51 toolchain not found (looked for C51.EXE)." }

$here  = Split-Path -Parent $MyInvocation.MyCommand.Path
$root  = Split-Path -Parent (Split-Path -Parent $here)     # repo root
$tools = Join-Path $root 'tools'

# Test programs do NOT belong next to the firmware: they go with the other
# diagnostics in firmware\diag\ (usprobe / uscheck / usfollow ...).
if ($Scope) { $hexdir = Join-Path (Split-Path -Parent $here) 'diag' }
if (-not $hexdir) { $hexdir = $here }
$hexout = Join-Path $hexdir $hexname

Set-Location $here
$name = 'main'

# C51 needs a writable scratch directory. On some locked-down setups the TEMP
# handed to the process is not writable and every step dies with
#     C51 FATAL-ERROR - ERROR: CAN'T CREATE FILE
# so pin TMP/TEMP to a folder inside the project instead of trusting the system one.
$scratch = Join-Path $here '_tmp'
New-Item -ItemType Directory -Force $scratch | Out-Null
$env:TMP = $scratch
$env:TEMP = $scratch

if ($Debug) {
    Write-Host ''
    Write-Host '*** DIAGNOSTIC BUILD (DEBUG_UART=1) -- not for the demo ***' -ForegroundColor Yellow
}

function Step($n, $text) {
    Write-Host ''
    Write-Host "[$n] $text" -ForegroundColor Cyan
}

# Run one tool, echo its summary lines, and THROW if it reported any error.
function Invoke-Tool($exe, [string[]]$toolArgs, $mustProduce) {
    $full = Join-Path $keilBin $exe
    $out  = & $full @toolArgs 2>&1
    $text = ($out | Out-String)
    $out | Select-String 'COMPLETE|ERROR|WARNING' | ForEach-Object { $_.Line.TrimEnd() }
    if ($text -match '([1-9][0-9]*)\s+ERROR') {
        throw ("$exe reported $($Matches[1]) error(s) -- build aborted (see the .lst)")
    }
    if ($mustProduce -and -not (Test-Path $mustProduce)) {
        throw "$exe produced no $mustProduce"
    }
}

# ---------------------------------------------------------------------------
Step '1/6' 'C51 compile -> assembler source (main.src)'
# NOTE: with SRC the compiler does NOT emit an object module and the .lst has no
#       generated assembly, so this run and the next one are both required.
Remove-Item "$name.src" -ErrorAction SilentlyContinue
Invoke-Tool 'C51.EXE' (@("$name.c", 'SMALL', 'SRC') + $c51extra) "$name.src"

# ---------------------------------------------------------------------------
Step '2/6' 'C51 compile -> listing with generated machine code (main.lst)'
# This listing is the reference for the size report and for c51_verify.py.
Remove-Item "$name.lst", "$name.obj" -ErrorAction SilentlyContinue
Invoke-Tool 'C51.EXE' (@("$name.c", 'SMALL', 'DEBUG', 'CODE') + $c51extra) "$name.lst"

# ---------------------------------------------------------------------------
Step '3/6' 'c51_link.py -- assign addresses (replaces BL51/LX51)'
python (Join-Path $tools 'c51_link.py') "$name.src" "${name}_abs.asm"
if ($LASTEXITCODE -ne 0) { throw 'c51_link.py failed' }

# ---------------------------------------------------------------------------
Step '4/6' 'A51 assemble the absolute module'
Remove-Item "${name}_abs.lst", "${name}_abs.obj" -ErrorAction SilentlyContinue
Invoke-Tool 'A51.EXE' @("${name}_abs.asm") "${name}_abs.lst"

# ---------------------------------------------------------------------------
Step '5/6' 'lst2hex.py -- A51 listing -> Intel HEX'
python (Join-Path $tools 'lst2hex.py') "${name}_abs.LST" "$hexout"
if ($LASTEXITCODE -ne 0) { throw "lst2hex.py failed (address collisions?) -- no $hexout written" }

# ---------------------------------------------------------------------------
Step '6/6' 'checks: code size + per-function equivalence'
python (Join-Path $tools 'c51_sizes.py') "$name.lst" --top 12
Write-Host ''
python (Join-Path $tools 'c51_verify.py') "$name.lst" "${name}_abs.LST"
if ($LASTEXITCODE -ne 0) { throw 'c51_verify FAILED: address assignment changed the code' }

Write-Host ''
Write-Host 'BUILD OK' -ForegroundColor Green
if ($Debug) {
    Write-Host '*** this is the DIAGNOSTIC build -- re-run without -Debug for the demo hex ***' -ForegroundColor Yellow
}
Get-ChildItem "$name.src", "${name}_abs.asm", "${name}_abs.LST", "$hexout" |
    Select-Object Name, Length, LastWriteTime | Format-Table -AutoSize
Write-Host "hex file : $hexout"
Write-Host 'Flash it: STC-ISP -> STC89C52RC -> COM7 -> open the hex ->'
Write-Host '          Download/Program -> then COLD BOOT (S1 off -> 1~2s -> on).'
