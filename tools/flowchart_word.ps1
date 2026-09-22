#MARKER-V2
# =============================================================================
# flowchart_word.ps1 -- draw the flowcharts INTO Word, using Word itself.
#
# The diagrams are built from native Word autoshapes (no images, no hand-written
# OOXML): every box / diamond / line is a real Word shape that can be selected,
# moved and re-typed. Strict monochrome: white fill, black 1pt outline, black
# 8pt text, standard flowchart autoshape types.
#
# ASCII-only source (Windows PowerShell reads BOM-less UTF-8 .ps1 as GBK);
# all Chinese label text comes from the UTF-8 JSON files, read explicitly.
#
# Usage:
#   powershell -NoProfile -ExecutionPolicy Bypass -File tools\flowchart_word.ps1 `
#       -GeoDir docs\figs -SpecDir tools\_flow_spec -Out "docs\程序流程图.docx"
# =============================================================================
param(
    [string]$GeoDir  = 'docs\figs',
    [string]$SpecDir = 'tools\_flow_spec',
    [string]$DocJson = 'tools\_flow_spec\_doc.json',
    [string]$Out     = 'docs\flowchart.docx',
    [double]$MarginL = 90.0,
    [double]$MarginT = 72.0
)

$ErrorActionPreference = 'Stop'

# ---- Word / Office constants (kept as plain numbers, ASCII only) -------------
$MSO_TEXTBOX_H      = 1        # msoTextOrientationHorizontal
$MSO_TRUE           = -1
$MSO_FALSE          = 0
$SH_RECT            = 1        # msoShapeRectangle
$SH_OVAL            = 9        # msoShapeOval
$SH_FC_PROCESS      = 61       # msoShapeFlowchartProcess
$SH_FC_ALT          = 62       # msoShapeFlowchartAlternateProcess
$SH_FC_DECISION     = 63       # msoShapeFlowchartDecision
$SH_FC_DATA         = 64       # msoShapeFlowchartData
$SH_FC_PREDEF       = 65       # msoShapeFlowchartPredefinedProcess
$SH_FC_TERMINATOR   = 69       # msoShapeFlowchartTerminator
$WRAP_NONE          = 3
$REL_PAGE_H         = 1        # wdRelativeHorizontalPositionPage
$REL_PAGE_V         = 1        # wdRelativeVerticalPositionPage
$ANCHOR_MIDDLE      = 3        # msoAnchorMiddle
$ALIGN_LEFT         = 0
$ALIGN_CENTER       = 1
$LS_SINGLE          = 0        # wdLineSpaceSingle
$LS_EXACT           = 4        # wdLineSpaceExactly
$ARROW_TRIANGLE     = 2        # msoArrowheadTriangle
$ARROW_MED          = 2        # msoArrowheadMedium / Width
$ARROW_LONG         = 3        # msoArrowheadLong (length)
$PAGE_BREAK         = 7        # wdPageBreak
$COLOR_BLACK        = 0
$COLOR_WHITE        = 16777215

$SHAPE_TYPE = @{
    'term' = $SH_FC_TERMINATOR
    'proc' = $SH_FC_PROCESS
    'dec'  = $SH_FC_DECISION
    'call' = $SH_FC_PREDEF
    'io'   = $SH_FC_DATA
    'dot'  = $SH_OVAL
}
$NO_FRAME = @('note', 'title', 'label', 'caption')

function Read-Json([string]$path) {
    $txt = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
    return ($txt | ConvertFrom-Json)
}

function Insets {
    param([string]$kind, [double]$w, [double]$h)
    # NOTE: the comma operator binds tighter than '*', so a bare
    # "($w * 0.16, $h * 0.12)" would be parsed as an array multiply --
    # keep the products in locals.
    # A diamond's text is laid out in the INSCRIBED rectangle (about w/2 x h/2),
    # which Word computes itself -- adding insets on top of that shrinks the box
    # to nothing and clips the label.
    if ($kind -eq 'dec') { return @(0.0, 0.0, 0.0, 0.0) }
    if ($kind -eq 'call') { return @(9.0, 3.0, 9.0, 3.0) }
    if ($NO_FRAME -contains $kind) { return @(0.0, 0.0, 0.0, 0.0) }
    return @(5.0, 3.0, 5.0, 3.0)
}

function Set-ShapeBox($s, [double]$left, [double]$top) {
    $s.RelativeHorizontalPosition = $REL_PAGE_H
    $s.RelativeVerticalPosition = $REL_PAGE_V
    $s.Left = [float]$left
    $s.Top = [float]$top
    $s.WrapFormat.Type = $WRAP_NONE
    try { $s.WrapFormat.AllowOverlap = $MSO_TRUE } catch {}
}

function Set-ShapeText($s, [string]$text, [double]$fs, [bool]$bold, [string]$align, $ins) {
    $tf = $s.TextFrame
    $tf.MarginLeft = [float]$ins[0]
    $tf.MarginRight = [float]$ins[2]
    $tf.MarginTop = [float]$ins[1]
    $tf.MarginBottom = [float]$ins[3]
    $tf.VerticalAnchor = $ANCHOR_MIDDLE
    $tf.WordWrap = $MSO_TRUE
    try { $tf.AutoSize = 0 } catch {}
    if ([string]::IsNullOrEmpty($text)) { return }
    # Set the text first, then RE-FETCH the range (the cached range object goes
    # stale after a text replacement, and the formatting below would be lost).
    $tf.TextRange.Text = $text.Replace("`n", "`r")
    $tr = $tf.TextRange
    $tr.Font.Name = 'SimSun'
    try { $tr.Font.NameFarEast = 'SimSun' } catch {}
    $tr.Font.Size = [float]$fs
    if ($bold) { $tr.Font.Bold = $MSO_TRUE } else { $tr.Font.Bold = $MSO_FALSE }
    $tr.Font.Color = $COLOR_BLACK
    $pf = $tr.ParagraphFormat
    if ($align -eq 'left') { $pf.Alignment = $ALIGN_LEFT } else { $pf.Alignment = $ALIGN_CENTER }
    $pf.SpaceBefore = 0
    $pf.SpaceAfter = 0
    # EXACT line spacing (not "single"): a shape's paragraphs inherit the
    # document style, whose line height is much taller than the 8pt text and
    # would clip the lower lines inside these small boxes.
    $pf.LineSpacingRule = $LS_EXACT
    $pf.LineSpacing = [float]([Math]::Round($fs * 1.32, 1))
}

function Set-CursorEnd($doc) {
    # Writing text into a shape's TextFrame moves Word's Selection INTO that
    # shape's text story -- every shape added afterwards would then be anchored
    # to that story and land on the wrong page. Re-home the cursor to the end of
    # the main text story (which is on the current figure's page) before each
    # shape is added.
    $r = $doc.Content
    [void]$r.Collapse(0)          # 0 = wdCollapseEnd
    $r.Select()
}

function Add-Shape($doc, $sh, [double]$ox, [double]$oy) {
    $kind = [string]$sh.kind
    $left = $ox + [double]$sh.x
    $top  = $oy + [double]$sh.y
    $w = [double]$sh.w
    $h = [double]$sh.h
    $ins = Insets -kind $kind -w $w -h $h
    Set-CursorEnd $doc

    if ($SHAPE_TYPE.ContainsKey($kind)) {
        $type = $SHAPE_TYPE[$kind]
    }
    else {
        $type = -1
    }

    if ($type -lt 0) {
        $s = $doc.Shapes.AddTextbox($MSO_TEXTBOX_H, [float]$left, [float]$top, [float]$w, [float]$h)
        Set-ShapeBox $s $left $top
        if ($kind -eq 'label') {
            $s.Fill.Visible = $MSO_TRUE
            $s.Fill.ForeColor.RGB = $COLOR_WHITE
        }
        else {
            $s.Fill.Visible = $MSO_FALSE
        }
        $s.Line.Visible = $MSO_FALSE
    }
    else {
        $s = $doc.Shapes.AddShape($type, [float]$left, [float]$top, [float]$w, [float]$h)
        Set-ShapeBox $s $left $top
        if ($kind -eq 'dot') {
            $s.Fill.Visible = $MSO_TRUE
            $s.Fill.ForeColor.RGB = $COLOR_BLACK
            $s.Line.Visible = $MSO_FALSE
        }
        else {
            $s.Fill.Visible = $MSO_TRUE
            $s.Fill.ForeColor.RGB = $COLOR_WHITE
            $s.Line.Visible = $MSO_TRUE
            $s.Line.ForeColor.RGB = $COLOR_BLACK
            $s.Line.Weight = 1.0
        }
    }

    if ($null -ne $sh.text) { Set-ShapeText $s ([string]$sh.text) ([double]$sh.fs) ([bool]$sh.bold) ([string]$sh.align) $ins }
    return $s
}

function Add-Line($doc, [double]$x1, [double]$y1, [double]$x2, [double]$y2, [bool]$arrow) {
    # AddLine positions the line relative to the column/margin frame, so after
    # switching the frame to "page" the coordinates must be re-applied with the
    # intended absolute page values -- otherwise every line is offset by the
    # page margin and the arrows detach from the boxes.
    Set-CursorEnd $doc
    $ln = $doc.Shapes.AddLine([float]$x1, [float]$y1, [float]$x2, [float]$y2)
    $ln.RelativeHorizontalPosition = $REL_PAGE_H
    $ln.RelativeVerticalPosition = $REL_PAGE_V
    $ln.Left = [float]([Math]::Min($x1, $x2))
    $ln.Top = [float]([Math]::Min($y1, $y2))
    $ln.Width = [float]([Math]::Abs($x2 - $x1))
    $ln.Height = [float]([Math]::Abs($y2 - $y1))
    $ln.WrapFormat.Type = $WRAP_NONE
    try { $ln.WrapFormat.AllowOverlap = $MSO_TRUE } catch {}
    $ln.Line.Visible = $MSO_TRUE
    $ln.Line.ForeColor.RGB = $COLOR_BLACK
    $ln.Line.Weight = 1.0
    if ($arrow) {
        $ln.Line.EndArrowheadStyle = $ARROW_TRIANGLE
        $ln.Line.EndArrowheadLength = $ARROW_LONG
        $ln.Line.EndArrowheadWidth = $ARROW_MED
    }
    return $ln
}

# --------------------------------- main --------------------------------------
$root = (Get-Location).Path
function Abs([string]$p) { if ([System.IO.Path]::IsPathRooted($p)) { return $p } return (Join-Path $root $p) }

$geoDir  = Abs $GeoDir
$specDir = Abs $SpecDir
$docJson = Abs $DocJson
$outPath = Abs $Out
$outDir = Split-Path -Parent $outPath
if (-not (Test-Path $outDir)) { [void](New-Item -ItemType Directory -Path $outDir -Force) }

$meta = Read-Json $docJson
# NOTE: the -Order parameter is deliberately NOT used -- PowerShell turns a
# comma-separated native argument into an array, and `-File` then joins it back
# with spaces, so the figure order is simply the sorted geo file list instead.
$figIds = @(Get-ChildItem -Path $geoDir -Filter '*.geo.json' | Sort-Object Name |
           ForEach-Object { $_.Name -replace '\.geo\.json$', '' })
Write-Output ("[order] " + ($figIds -join ', '))

$app = New-Object -ComObject Word.Application
$app.Visible = $false
try { $app.DisplayAlerts = 0 } catch {}
$doc = $app.Documents.Add()

try {
    $ps = $doc.PageSetup
    $ps.PaperSize = 7                       # wdPaperA4
    $ps.LeftMargin = [float]$MarginL
    $ps.RightMargin = [float]$MarginL
    $ps.TopMargin = [float]$MarginT
    $ps.BottomMargin = [float]$MarginT
    $ps.HeaderDistance = 42
    $ps.FooterDistance = 49

    $sel = $app.Selection
    $psStyle = $sel.ParagraphFormat
    $psStyle.SpaceBefore = 0
    $psStyle.SpaceAfter = 6
    $psStyle.LineSpacingRule = $LS_SINGLE
    $psStyle.FirstLineIndent = 0

    $sel.Font.Name = 'SimHei'
    try { $sel.Font.NameFarEast = 'SimHei' } catch {}
    $sel.Font.Size = 16
    $sel.Font.Bold = $MSO_TRUE
    $sel.ParagraphFormat.Alignment = $ALIGN_CENTER
    $sel.TypeText([string]$meta.title)
    $sel.TypeParagraph()

    $sel.Font.Size = 14
    $sel.TypeText([string]$meta.subtitle)
    $sel.TypeParagraph()

    $sel.Font.Name = 'SimSun'
    try { $sel.Font.NameFarEast = 'SimSun' } catch {}
    $sel.Font.Size = 10.5
    $sel.Font.Bold = $MSO_FALSE
    $sel.ParagraphFormat.Alignment = $ALIGN_LEFT
    foreach ($p in $meta.paragraphs) {
        $sel.ParagraphFormat.FirstLineIndent = 21
        $sel.TypeText([string]$p)
        $sel.TypeParagraph()
    }
    $sel.ParagraphFormat.FirstLineIndent = 0

    $page = 0
    foreach ($fid in $figIds) {
        $geoPath = Join-Path $geoDir ($fid + '.geo.json')
        if (-not (Test-Path $geoPath)) { Write-Output ("[skip] " + $geoPath); continue }
        $geo = Read-Json $geoPath

        $sel.InsertBreak($PAGE_BREAK)

        $n = 0
        foreach ($ln in $geo.lines) {
            $pts = $ln.pts
            for ($i = 0; $i -lt ($pts.Count - 1); $i++) {
                $arrow = ($i -eq ($pts.Count - 2))
                [void](Add-Line $doc ($MarginL + [double]$pts[$i][0]) ($MarginT + [double]$pts[$i][1]) `
                                  ($MarginL + [double]$pts[$i + 1][0]) ($MarginT + [double]$pts[$i + 1][1]) $arrow)
                $n++
            }
        }
        foreach ($sh in $geo.shapes) {
            [void](Add-Shape $doc $sh $MarginL $MarginT)
            $n++
        }

        # figure caption, below the diagram (Chinese reports put the caption under the figure)
        $cap = [string]$geo.title
        if ($cap.Length -gt 0) {
            $cy = $MarginT + [double]$geo.h + 8.0
            Set-CursorEnd $doc
            $cs = $doc.Shapes.AddTextbox($MSO_TEXTBOX_H, [float]$MarginL, [float]$cy, [float]$geo.w, 16.0)
            Set-ShapeBox $cs $MarginL $cy
            $cs.Fill.Visible = $MSO_FALSE
            $cs.Line.Visible = $MSO_FALSE
            Set-ShapeText $cs $cap 9.5 $true 'center' @(0.0, 0.0, 0.0, 0.0)
            $n++
        }

        $page++
        Write-Output ("[ok] page " + $page + ": " + $fid + "  shapes=" + $n + "  (" + $geo.w + "x" + $geo.h + " pt)")
    }

    $doc.SaveAs2($outPath, 16)              # 16 = wdFormatDocumentDefault (.docx)
    $pages = $doc.ComputeStatistics(2)      # 2 = wdStatisticPages
    $shapes = $doc.Shapes.Count
    Write-Output ("[saved] " + $outPath)
    Write-Output ("[check] pages=" + $pages + "  shapes=" + $shapes)
}
finally {
    try { $doc.Close(0) } catch {}
    try { $app.Quit(0) } catch {}
    try { [System.Runtime.InteropServices.Marshal]::ReleaseComObject($app) | Out-Null } catch {}
}
