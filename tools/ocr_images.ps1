# ocr_images.ps1 -- OCR image files with the Windows built-in OCR engine (WinRT).
#
# No external tools needed: uses Windows.Media.Ocr, available on Windows 10+
# with the installed language packs (this machine: en-US, zh-Hans-CN).
# Images larger than the engine's MaxImageDimension are scaled down first.
#
# Usage:
#   powershell -NoProfile -ExecutionPolicy Bypass -File ocr_images.ps1 -Path a.png,b.png [-OutDir DIR]
#   powershell -NoProfile -ExecutionPolicy Bypass -File ocr_images.ps1 -Dir DIR -Filter *.png
#
# NOTE: keep this file ASCII-only (PowerShell reads BOM-less UTF-8 as GBK).

param(
    [string[]]$Path,
    [string]$Dir,
    [string]$Filter = '*.png',
    # NOTE: never put a non-ASCII literal path in this file -- Windows PowerShell
    # reads BOM-less UTF-8 as GBK, which corrupts the literal. Default is derived
    # from the script location at runtime instead.
    [string]$OutDir,
    [string]$Lang = 'zh-Hans-CN'
)

if (-not $OutDir) { $OutDir = Join-Path (Split-Path -Parent $PSScriptRoot) 'refs\_ocr' }

$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Runtime.WindowsRuntime | Out-Null
Add-Type -AssemblyName System.Drawing | Out-Null

[Windows.Storage.StorageFile, Windows.Storage, ContentType = WindowsRuntime] | Out-Null
[Windows.Graphics.Imaging.BitmapDecoder, Windows.Graphics.Imaging, ContentType = WindowsRuntime] | Out-Null
[Windows.Media.Ocr.OcrEngine, Windows.Media.Ocr, ContentType = WindowsRuntime] | Out-Null
[Windows.Globalization.Language, Windows.Globalization, ContentType = WindowsRuntime] | Out-Null
[Windows.Storage.Streams.IRandomAccessStream, Windows.Storage.Streams, ContentType = WindowsRuntime] | Out-Null

# --- WinRT async helper -----------------------------------------------------
$asTaskGeneric = ([System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object {
        $_.Name -eq 'AsTask' -and
        $_.GetParameters().Count -eq 1 -and
        $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1'
    })[0]

function Await($op, $resultType) {
    $task = $asTaskGeneric.MakeGenericMethod($resultType).Invoke($null, @($op))
    $task.Wait(-1) | Out-Null
    $task.Result
}

# --- engine -----------------------------------------------------------------
$engine = $null
try { $engine = [Windows.Media.Ocr.OcrEngine]::TryCreateFromLanguage((New-Object Windows.Globalization.Language $Lang)) } catch { }
if (-not $engine) { $engine = [Windows.Media.Ocr.OcrEngine]::TryCreateFromUserProfileLanguages() }
if (-not $engine) { throw 'no OCR engine available' }
Write-Host ("OCR engine: " + $engine.RecognizerLanguage.LanguageTag)
$maxDim = [Windows.Media.Ocr.OcrEngine]::MaxImageDimension
Write-Host ("MaxImageDimension: " + $maxDim)

# --- collect inputs ---------------------------------------------------------
$files = @()
if ($Path) { $files += $Path }
if ($Dir) { $files += (Get-ChildItem -Path $Dir -Filter $Filter -File | Select-Object -ExpandProperty FullName) }
$files = $files | Where-Object { Test-Path $_ } | Select-Object -Unique
if (-not $files) { throw 'no input images' }

New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
$tmpDir = Join-Path $env:TEMP 'ocr_scale'
New-Item -ItemType Directory -Path $tmpDir -Force | Out-Null

foreach ($img in $files) {
    $name = [System.IO.Path]::GetFileNameWithoutExtension($img)
    $target = $img

    # scale down when larger than the engine limit
    try {
        $src = [System.Drawing.Image]::FromFile($img)
        $w = $src.Width; $h = $src.Height
        if ($maxDim -gt 0 -and ($w -gt $maxDim -or $h -gt $maxDim)) {
            $scale = [Math]::Min($maxDim / $w, $maxDim / $h)
            $nw = [int]($w * $scale); $nh = [int]($h * $scale)
            $bmp = New-Object System.Drawing.Bitmap $nw, $nh
            $g = [System.Drawing.Graphics]::FromImage($bmp)
            $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $g.DrawImage($src, 0, 0, $nw, $nh)
            $g.Dispose()
            $target = Join-Path $tmpDir "$name.png"
            $bmp.Save($target, [System.Drawing.Imaging.ImageFormat]::Png)
            $bmp.Dispose()
        } else {
            $nw = $w; $nh = $h
        }
        $src.Dispose()
    } catch {
        $nw = '?'; $nh = '?'
    }

    try {
        $file = Await ([Windows.Storage.StorageFile]::GetFileFromPathAsync($target)) ([Windows.Storage.StorageFile])
        $stream = Await ($file.OpenAsync([Windows.Storage.FileAccessMode]::Read)) ([Windows.Storage.Streams.IRandomAccessStream])
        $decoder = Await ([Windows.Graphics.Imaging.BitmapDecoder]::CreateAsync($stream)) ([Windows.Graphics.Imaging.BitmapDecoder])
        $bitmap = Await ($decoder.GetSoftwareBitmapAsync()) ([Windows.Graphics.Imaging.SoftwareBitmap])
        $result = Await ($engine.RecognizeAsync($bitmap)) ([Windows.Media.Ocr.OcrResult])
        $text = $result.Text
        $stream.Dispose()
        $outFile = Join-Path $OutDir "$name.txt"
        $text | Out-File -FilePath $outFile -Encoding utf8
        Write-Host ("OK   {0,-16} {1}x{2}  -> {3} chars  {4}" -f $name, $nw, $nh, $text.Length, $outFile)
    } catch {
        Write-Host ("FAIL {0,-16} : {1}" -f $name, $_.Exception.Message) -ForegroundColor Red
    }
}
Write-Host 'done.'
