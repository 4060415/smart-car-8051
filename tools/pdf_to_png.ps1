# pdf_to_png.ps1 -- rasterize a PDF into PNG images using the Windows built-in
# PDF renderer (WinRT Windows.Data.Pdf). No Ghostscript / poppler needed.
#
# Why: Altium-exported schematics often contain NO text objects at all (every
# label is drawn as vector outlines), so text extraction returns nothing. The
# only way to read them is to rasterize and look at / OCR the pixels.
#
# Usage:
#   powershell -NoProfile -ExecutionPolicy Bypass -File pdf_to_png.ps1 -Pdf file.pdf [-OutDir DIR] [-Width 3000]
#
# NOTE: keep this file ASCII-only (PowerShell reads BOM-less UTF-8 as GBK), and
# never put a non-ASCII literal path in it.

param(
    [Parameter(Mandatory = $true)][string]$Pdf,
    [string]$OutDir,
    [int]$Width = 3000
)

$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Runtime.WindowsRuntime | Out-Null

[Windows.Data.Pdf.PdfDocument, Windows.Data.Pdf, ContentType = WindowsRuntime] | Out-Null
[Windows.Storage.StorageFile, Windows.Storage, ContentType = WindowsRuntime] | Out-Null
[Windows.Storage.Streams.IRandomAccessStream, Windows.Storage.Streams, ContentType = WindowsRuntime] | Out-Null
[Windows.Foundation.IAsyncAction, Windows.Foundation, ContentType = WindowsRuntime] | Out-Null

if (-not $OutDir) { $OutDir = Join-Path (Split-Path -Parent $PSScriptRoot) 'refs\_pdf_png' }
New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
New-Item -ItemType Directory -Path $env:TEMP -Force | Out-Null

# --- WinRT async helpers ----------------------------------------------------
$exts = [System.WindowsRuntimeSystemExtensions].GetMethods()

$asTaskGeneric = ($exts | Where-Object {
        $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and
        $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1'
    })[0]

$asTaskAction = ($exts | Where-Object {
        $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and
        $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncAction'
    })[0]

function Await($op, $resultType) {
    $task = $asTaskGeneric.MakeGenericMethod($resultType).Invoke($null, @($op))
    $task.Wait(-1) | Out-Null
    $task.Result
}

function AwaitAction($op) {
    $task = $asTaskAction.Invoke($null, @($op))
    $task.Wait(-1) | Out-Null
}

# --- render -----------------------------------------------------------------
$full = (Resolve-Path $Pdf).Path
$stem = [System.IO.Path]::GetFileNameWithoutExtension($full)
Write-Host "pdf      : $full"
Write-Host "outdir   : $OutDir"

$file = Await ([Windows.Storage.StorageFile]::GetFileFromPathAsync($full)) ([Windows.Storage.StorageFile])
$doc = Await ([Windows.Data.Pdf.PdfDocument]::LoadFromFileAsync($file)) ([Windows.Data.Pdf.PdfDocument])
Write-Host ("pages    : " + $doc.PageCount)

for ($i = 0; $i -lt $doc.PageCount; $i++) {
    $outPath = Join-Path $OutDir ("{0}_p{1}.png" -f $stem, ($i + 1))
    # WinRT can only open an existing file, so create it with .NET first
    [System.IO.File]::WriteAllBytes($outPath, @())
    $outFile = Await ([Windows.Storage.StorageFile]::GetFileFromPathAsync($outPath)) ([Windows.Storage.StorageFile])
    $stream = Await ($outFile.OpenAsync([Windows.Storage.FileAccessMode]::ReadWrite)) ([Windows.Storage.Streams.IRandomAccessStream])

    $page = $doc.GetPage($i)
    $opts = New-Object Windows.Data.Pdf.PdfPageRenderOptions
    $opts.DestinationWidth = [uint32]$Width
    AwaitAction ($page.RenderToStreamAsync($stream, $opts))
    $stream.Dispose()
    $page.Dispose()

    $size = (Get-Item $outPath).Length
    Write-Host ("OK  page {0} -> {1}  ({2} KB)" -f ($i + 1), $outPath, [math]::Round($size / 1KB))
}
Write-Host 'done.'
