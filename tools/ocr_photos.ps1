# ocr_photos.ps1 -- OCR every photo in a folder and dump a compact summary
# (dimensions, luma stats, recognized words) into refs\_photo_ocr\.
# ASCII-only on purpose (Windows PowerShell reads BOM-less UTF-8 as GBK).
param(
    [Parameter(Mandatory = $true)][string]$Dir
)
$ErrorActionPreference = 'Continue'
$root = Split-Path -Parent $PSScriptRoot
$outDir = Join-Path $root 'refs\_photo_ocr'
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

Add-Type -AssemblyName System.Drawing | Out-Null
$files = Get-ChildItem -LiteralPath $Dir -File | Where-Object { $_.Extension -match '^\.(jpg|jpeg|png)$' } | Sort-Object Name
$i = 0
foreach ($f in $files) {
    $i++
    $tag = 'p{0:D2}' -f $i
    $img = [System.Drawing.Image]::FromFile($f.FullName)
    $w = $img.Width; $h = $img.Height
    $img.Dispose()
    Write-Host ("[$tag] {0}  {1}x{2}  {3} bytes" -f $f.Name, $w, $h, $f.Length)
    $tsv = Join-Path $outDir ($tag + '.tsv')
    try {
        & (Join-Path $PSScriptRoot 'ocr_words.ps1') -Image $f.FullName -Out $tsv | Out-Null
    } catch {
        Write-Host ("   OCR failed: " + $_.Exception.Message)
    }
    if (Test-Path -LiteralPath $tsv) {
        $lines = Get-Content -LiteralPath $tsv -Encoding utf8 | Select-Object -Skip 1
        $words = $lines | ForEach-Object { ($_ -split "`t")[0] }
        Write-Host ("   words: {0}" -f $words.Count)
        if ($words.Count -gt 0) {
            Write-Host ("   text: " + (($words | Select-Object -First 60) -join ' '))
        }
    }
    $sum = Join-Path $outDir ($tag + '.stats.txt')
    & (Join-Path $PSScriptRoot 'img_analyze.ps1') -Image $f.FullName -Mode stats 2>&1 |
        Out-File -FilePath $sum -Encoding utf8
    $l = (Get-Content -LiteralPath $sum -Encoding utf8 | Select-Object -First 2) -join ' | '
    Write-Host ("   " + $l)
}
Write-Host "OCR output dir: $outDir"
