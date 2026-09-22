# img_analyze.ps1 -- pixel-level analysis of a small raster image, to locate text
# rows/columns before OCR-ing them one cell at a time.
#
# Why: Windows OCR is unreliable on tiny glyphs (a 7x14 px hex digit). Projection
# analysis finds the exact text bands, so each cell can be cropped tightly and
# upscaled before OCR.
#
# Modes:
#   -Mode stats   : luminance histogram + most common quantized colours
#   -Mode bands   : row/column dark-pixel projection -> text bands (default)
#
# Region: -X -Y -W -H (source pixels; default = whole image).
#
# Usage:
#   powershell -NoProfile -ExecutionPolicy Bypass -File img_analyze.ps1 -Image a.jpg -Mode stats
#   powershell -NoProfile -ExecutionPolicy Bypass -File img_analyze.ps1 -Image a.jpg -Mode bands -X 320 -Y 80 -W 200 -H 440
#
# NOTE: keep this file ASCII-only (Windows PowerShell reads BOM-less UTF-8 as GBK).

param(
    [Parameter(Mandatory = $true)][string]$Image,
    [ValidateSet('stats', 'bands')][string]$Mode = 'bands',
    [int]$X = 0, [int]$Y = 0, [int]$W = 0, [int]$H = 0,
    [int]$Threshold = 128,
    [int]$MinRun = 1
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Runtime.InteropServices

$bmp = [System.Drawing.Bitmap]::FromFile($Image)
$iw = $bmp.Width; $ih = $bmp.Height
if ($W -le 0) { $W = $iw - $X }
if ($H -le 0) { $H = $ih - $Y }
Write-Host ("image {0}x{1}   region x={2} y={3} w={4} h={5}   threshold={6}" -f $iw, $ih, $X, $Y, $W, $H, $Threshold)

$rect = New-Object System.Drawing.Rectangle $X, $Y, $W, $H
$data = $bmp.LockBits($rect, [System.Drawing.Imaging.ImageLockMode]::ReadOnly,
    [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$stride = $data.Stride
$buf = New-Object byte[] ($stride * $H)
[System.Runtime.InteropServices.Marshal]::Copy($data.Scan0, $buf, 0, $buf.Length)
$bmp.UnlockBits($data)

# luminance per pixel, packed into a int[] indexed y*W+x  (0..255)
$lum = New-Object 'int[]' ($W * $H)
for ($y = 0; $y -lt $H; $y++) {
    $row = $y * $stride
    $orow = $y * $W
    for ($x = 0; $x -lt $W; $x++) {
        $i = $row + $x * 4
        # BGRA -> luma (integer approx of 0.114B + 0.587G + 0.299R)
        $lum[$orow + $x] = (($buf[$i] * 29 + $buf[$i + 1] * 150 + $buf[$i + 2] * 77) -shr 8)
    }
}

if ($Mode -eq 'stats') {
    $hist = New-Object 'int[]' 16
    $sum = 0; $min = 255; $max = 0
    for ($i = 0; $i -lt $lum.Length; $i++) {
        $v = $lum[$i]
        $hist[$v -shr 4]++
        $sum += $v
        if ($v -lt $min) { $min = $v }
        if ($v -gt $max) { $max = $v }
    }
    Write-Host ("luma min={0} max={1} mean={2:N1}" -f $min, $max, ($sum / $lum.Length))
    Write-Host 'luma histogram (bin of 16):'
    for ($b = 0; $b -lt 16; $b++) {
        $pct = 100.0 * $hist[$b] / $lum.Length
        Write-Host ("  {0,3}-{1,3} : {2,8}  {3,6:N2}%  {4}" -f ($b * 16), ($b * 16 + 15), $hist[$b], $pct, ('#' * [int]($pct / 2)))
    }
    $bmp.Dispose()
    return
}

# --- bands: project "dark" pixels (below threshold) onto each axis -----------
$rowSum = New-Object 'int[]' $H
$colSum = New-Object 'int[]' $W
for ($y = 0; $y -lt $H; $y++) {
    for ($x = 0; $x -lt $W; $x++) {
        if ($lum[$y * $W + $x] -lt $Threshold) { $rowSum[$y]++; $colSum[$x]++ }
    }
}

function Show-Bands($name, $sum, $offset) {
    Write-Host "--- $name bands (dark pixel count > 0, merged runs, min run $MinRun) ---"
    $start = -1
    $n = 0
    for ($i = 0; $i -le $sum.Length; $i++) {
        $dark = ($i -lt $sum.Length -and $sum[$i] -gt 0)
        if ($dark -and $start -lt 0) { $start = $i }
        elseif (-not $dark -and $start -ge 0) {
            $len = $i - $start
            if ($len -ge $MinRun) {
                $peak = 0
                for ($k = $start; $k -lt $i; $k++) { if ($sum[$k] -gt $peak) { $peak = $sum[$k] } }
                Write-Host ("  {0,4} .. {1,4}   len {2,3}  peak {3,4}   (abs {4}..{5})" -f `
                        $start, ($i - 1), $len, $peak, ($start + $offset), ($i - 1 + $offset))
                $n++
            }
            $start = -1
        }
    }
    Write-Host "  total bands: $n"
}

Show-Bands 'ROW' $rowSum $Y
Show-Bands 'COL' $colSum $X

$bmp.Dispose()
