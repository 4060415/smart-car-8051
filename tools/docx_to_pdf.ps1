# Convert a .docx to .pdf using WPS Office COM automation.
# Usage: powershell -NoProfile -ExecutionPolicy Bypass -File tools\docx_to_pdf.ps1 -In <docx> -Out <pdf>
param(
    [Parameter(Mandatory=$true)][string]$In,
    [Parameter(Mandatory=$true)][string]$Out
)

$ErrorActionPreference = 'Stop'
$In  = (Resolve-Path -LiteralPath $In).Path
$OutDir = Split-Path -Parent $Out
if (-not (Test-Path -LiteralPath $OutDir)) { New-Item -ItemType Directory -Force -Path $OutDir | Out-Null }
$Out = [System.IO.Path]::GetFullPath($Out)
if (Test-Path -LiteralPath $Out) { Remove-Item -LiteralPath $Out -Force }

$progIds = @('KWPS.Application', 'Word.Application')
$app = $null
foreach ($pid_ in $progIds) {
    try {
        $app = New-Object -ComObject $pid_
        Write-Output "COM OK: $pid_"
        break
    } catch {
        Write-Output "COM failed: $pid_ -> $($_.Exception.Message)"
    }
}
if ($null -eq $app) { throw 'No WPS/Word COM automation available' }

try {
    $app.Visible = $false
    try { $app.DisplayAlerts = 0 } catch {}
    $doc = $app.Documents.Open($In, $false, $true)
    # 17 = wdFormatPDF
    $doc.ExportAsFixedFormat($Out, 17)
    $doc.Close(0)
    Write-Output "pdf: $Out"
} finally {
    try { $app.Quit(0) } catch {}
    try { [System.Runtime.InteropServices.Marshal]::ReleaseComObject($app) | Out-Null } catch {}
}
if (Test-Path -LiteralPath $Out) {
    Write-Output ("bytes: " + (Get-Item -LiteralPath $Out).Length)
} else {
    throw 'PDF not produced'
}
