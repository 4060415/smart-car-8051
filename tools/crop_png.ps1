# crop_png.ps1 -- crop a region out of a PNG and optionally upscale it, so a
# schematic can be zoomed in for visual reading / re-OCR.
#
# Usage:
#   powershell -NoProfile -ExecutionPolicy Bypass -File crop_png.ps1 `
#       -Image refs\_pdf_png\xxx.png -Crop "1900,600,1250,850" -Scale 2 -Out refs\_crop\zoom.png
#
# -Crop is "x,y,w,h" in SOURCE image pixels (same space as refs\schem_words.tsv).
# Keep this file ASCII-only (Windows PowerShell reads BOM-less UTF-8 as GBK).

param(
    [Parameter(Mandatory = $true)][string]$Image,
    [Parameter(Mandatory = $true)][string]$Out,
    [string]$Crop,
    [double]$Scale = 1,
    [int]$Grid = 0
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing | Out-Null

$img = [System.Drawing.Image]::FromFile((Resolve-Path $Image).Path)
try {
    if ($Crop) {
        $p = $Crop -split ','
        $cx = [int]$p[0]; $cy = [int]$p[1]; $cw = [int]$p[2]; $ch = [int]$p[3]
    } else {
        $cx = 0; $cy = 0; $cw = $img.Width; $ch = $img.Height
    }
    if ($cx -lt 0 -or $cy -lt 0 -or ($cx + $cw) -gt $img.Width -or ($cy + $ch) -gt $img.Height) {
        throw "crop $cx,$cy ${cw}x${ch} is outside the ${($img.Width)}x${($img.Height)} source"
    }

    $nw = [int]($cw * $Scale); $nh = [int]($ch * $Scale)
    $bmp = New-Object System.Drawing.Bitmap $nw, $nh
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.DrawImage($img, (New-Object System.Drawing.Rectangle 0, 0, $nw, $nh),
        (New-Object System.Drawing.Rectangle $cx, $cy, $cw, $ch),
        [System.Drawing.GraphicsUnit]::Pixel)

    # Optional coordinate grid every $Grid SOURCE pixels, labelled in source
    # coordinates -- makes it possible to read a pin's y back out of the image.
    if ($Grid -gt 0) {
        $pen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(120, 255, 0, 0)), 1
        $font = New-Object System.Drawing.Font 'Consolas', 10
        $brush = [System.Drawing.Brushes]::Red
        for ($sx = [int]([math]::Ceiling($cx / $Grid) * $Grid); $sx -lt $cx + $cw; $sx += $Grid) {
            $ix = [int](($sx - $cx) * $Scale)
            $g.DrawLine($pen, $ix, 0, $ix, $nh)
            $g.DrawString("$sx", $font, $brush, $ix + 2, 2)
        }
        for ($sy = [int]([math]::Ceiling($cy / $Grid) * $Grid); $sy -lt $cy + $ch; $sy += $Grid) {
            $iy = [int](($sy - $cy) * $Scale)
            $g.DrawLine($pen, 0, $iy, $nw, $iy)
            $g.DrawString("$sy", $font, $brush, 2, $iy + 2)
        }
        $pen.Dispose(); $font.Dispose()
    }

    $g.Dispose()
    $dir = Split-Path -Parent $Out
    if ($dir) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $bmp.Save((Join-Path (Get-Location).Path $Out), [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    Write-Host ("source {0}x{1}  crop {2},{3} {4}x{5}  scale {6}  ->  {7} ({8}x{9})" -f `
            $img.Width, $img.Height, $cx, $cy, $cw, $ch, $Scale, $Out, $nw, $nh)
} finally {
    $img.Dispose()
}
