# ocr_words.ps1 -- OCR an image with the Windows built-in engine and output every
# recognized word WITH its bounding box, as TSV:
#     text <tab> x <tab> y <tab> w <tab> h <tab> centerX <tab> centerY
#
# Purpose: schematic PDFs are vector graphics, so the only way to recover which
# net label sits on which component pin is to rasterize, OCR, and then reason
# about coordinates (labels are written on the wires).
#
# Optional region crop (pixel coords of the source image) for high-zoom re-OCR:
#   -Crop "x,y,w,h"  and  -Scale 2   (crop first, then upscale before OCR)
#
# Usage:
#   powershell -NoProfile -ExecutionPolicy Bypass -File ocr_words.ps1 -Image a.png [-Out tsv]
# NOTE: keep this file ASCII-only, and never put a non-ASCII literal path in it.

param(
    [Parameter(Mandatory = $true)][string]$Image,
    [string]$Out,
    [string]$Crop,
    [double]$Scale = 1,
    [string]$Lang = 'en-US'
)

$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Runtime.WindowsRuntime | Out-Null
Add-Type -AssemblyName System.Drawing | Out-Null

[Windows.Storage.StorageFile, Windows.Storage, ContentType = WindowsRuntime] | Out-Null
[Windows.Graphics.Imaging.BitmapDecoder, Windows.Graphics.Imaging, ContentType = WindowsRuntime] | Out-Null
[Windows.Media.Ocr.OcrEngine, Windows.Media.Ocr, ContentType = WindowsRuntime] | Out-Null
[Windows.Globalization.Language, Windows.Globalization, ContentType = WindowsRuntime] | Out-Null
[Windows.Storage.Streams.IRandomAccessStream, Windows.Storage.Streams, ContentType = WindowsRuntime] | Out-Null

$asTaskGeneric = ([System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object {
        $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and
        $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1'
    })[0]
function Await($op, $resultType) {
    $task = $asTaskGeneric.MakeGenericMethod($resultType).Invoke($null, @($op))
    $task.Wait(-1) | Out-Null
    $task.Result
}

$engine = [Windows.Media.Ocr.OcrEngine]::TryCreateFromLanguage((New-Object Windows.Globalization.Language $Lang))
if (-not $engine) { $engine = [Windows.Media.Ocr.OcrEngine]::TryCreateFromUserProfileLanguages() }
if (-not $engine) { throw 'no OCR engine' }

$src = $Image
$offX = 0; $offY = 0

# --- optional crop + upscale -------------------------------------------------
if ($Crop -or $Scale -ne 1) {
    $img = [System.Drawing.Image]::FromFile($Image)
    if ($Crop) {
        $p = $Crop -split ','
        $cx = [int]$p[0]; $cy = [int]$p[1]; $cw = [int]$p[2]; $ch = [int]$p[3]
    } else {
        $cx = 0; $cy = 0; $cw = $img.Width; $ch = $img.Height
    }
    $nw = [int]($cw * $Scale); $nh = [int]($ch * $Scale)
    $bmp = New-Object System.Drawing.Bitmap $nw, $nh
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.DrawImage($img, (New-Object System.Drawing.Rectangle 0, 0, $nw, $nh),
        (New-Object System.Drawing.Rectangle $cx, $cy, $cw, $ch),
        [System.Drawing.GraphicsUnit]::Pixel)
    $g.Dispose()
    $src = Join-Path $env:TEMP 'ocr_words_tmp.png'
    $bmp.Save($src, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose(); $img.Dispose()
    $offX = $cx; $offY = $cy
    Write-Host ("crop {0},{1} {2}x{3} scale {4} -> {5}x{6}" -f $cx, $cy, $cw, $ch, $Scale, $nw, $nh)
}

$file = Await ([Windows.Storage.StorageFile]::GetFileFromPathAsync((Resolve-Path $src).Path)) ([Windows.Storage.StorageFile])
$stream = Await ($file.OpenAsync([Windows.Storage.FileAccessMode]::Read)) ([Windows.Storage.Streams.IRandomAccessStream])
$decoder = Await ([Windows.Graphics.Imaging.BitmapDecoder]::CreateAsync($stream)) ([Windows.Graphics.Imaging.BitmapDecoder])
$bitmap = Await ($decoder.GetSoftwareBitmapAsync()) ([Windows.Graphics.Imaging.SoftwareBitmap])
$result = Await ($engine.RecognizeAsync($bitmap)) ([Windows.Media.Ocr.OcrResult])
$stream.Dispose()

$rows = New-Object System.Collections.Generic.List[string]
$rows.Add("text`tx`ty`tw`th`tcx`tcy")
foreach ($line in $result.Lines) {
    foreach ($w in $line.Words) {
        $r = $w.BoundingRect
        # map crop-local coords back to source-image coords
        $x = [int]($r.X / $Scale) + $offX
        $y = [int]($r.Y / $Scale) + $offY
        $ww = [int]($r.Width / $Scale)
        $hh = [int]($r.Height / $Scale)
        $rows.Add(("{0}`t{1}`t{2}`t{3}`t{4}`t{5}`t{6}" -f $w.Text, $x, $y, $ww, $hh,
                [int]($x + $ww / 2), [int]($y + $hh / 2)))
    }
}

if (-not $Out) { $Out = Join-Path (Split-Path -Parent $PSScriptRoot) 'refs\_ocr_words.tsv' }
$rows | Out-File -FilePath $Out -Encoding utf8
Write-Host ("words: {0}  -> {1}" -f ($rows.Count - 1), $Out)
