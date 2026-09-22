# docx_verify.ps1 -- open a .docx with the WPS/Word COM engine and report
# page / word / image statistics, proving the hand-written OOXML package parses.
# Usage: powershell -NoProfile -ExecutionPolicy Bypass -File tools\docx_verify.ps1 -In <docx>
param(
    [Parameter(Mandatory=$true)][string]$In,
    [string]$Pdf
)
$ErrorActionPreference = 'Stop'
$In = (Resolve-Path -LiteralPath $In).Path
$app = New-Object -ComObject Word.Application
try {
    $app.Visible = $false
    try { $app.DisplayAlerts = 0 } catch {}
    $doc = $app.Documents.Open($In, $false, $true)
    $pages = $doc.ComputeStatistics(2)   # wdStatisticPages
    $words = $doc.ComputeStatistics(0)   # wdStatisticWords
    $chars = $doc.ComputeStatistics(3)   # wdStatisticCharacters
    $shapes = $doc.InlineShapes.Count
    $tables = $doc.Tables.Count
    Write-Output ("pages={0} words={1} chars={2} inlineShapes={3} tables={4}" -f $pages, $words, $chars, $shapes, $tables)
    $doc.Close(0)
} finally {
    try { $app.Quit(0) } catch {}
}
if ($Pdf -and (Test-Path -LiteralPath $Pdf)) {
    $bytes = [System.IO.File]::ReadAllBytes((Resolve-Path -LiteralPath $Pdf).Path)
    $text = [System.Text.Encoding]::GetEncoding(28591).GetString($bytes)
    $nPage = ([regex]::Matches($text, '/Type\s*/Page[^s]')).Count
    $nImg = ([regex]::Matches($text, '/Subtype\s*/Image')).Count
    Write-Output ("pdf bytes={0} pageObjs={1} imageObjs={2}" -f $bytes.Length, $nPage, $nImg)
}
