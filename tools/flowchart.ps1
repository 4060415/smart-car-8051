# =============================================================================
# flowchart.ps1 -- flow-chart layout engine.
#
# Outputs, for every JSON spec in -SpecDir:
#   1) <id>.png       raster preview (for eyeballing the layout)
#   2) <id>.geo.json  geometry in POINTS -> consumed by flowchart_docx.py to
#                     emit native, editable Word shapes (no bitmaps in the docx)
#
# Why: this machine has no graphviz / matplotlib / PIL. System.Drawing is the
# only drawing stack, and Windows PowerShell mis-decodes a no-BOM UTF-8 .ps1 as
# GBK -- so this script is PURE ASCII and all Chinese label text lives in the
# UTF-8 JSON specs, read explicitly with Encoding.UTF8.
#
# Usage:
#   powershell -NoProfile -ExecutionPolicy Bypass -File tools\flowchart.ps1 `
#       -SpecDir tools\_flow_spec -OutDir docs\figs -Scale 2
#
# Spec (one JSON file per figure; all coordinates in POINTS, 1 unit = 1 pt):
# {
#   "id": "fig2", "title": "...", "width": 415, "height": 620,
#   "nodes": [ {"id":"a","kind":"proc","x":40,"y":72,"w":210,"h":26,
#               "text":["line1","line2"],"fs":8}, ... ],
#   "edges": [ {"f":"a","t":"b","fs":"b","ts":"t","label":"yes","lx":1,"ly":2},
#              {"pts":[[10,20],[30,40]],"label":"back"}, ... ]
# }
# node kinds: term proc dec call io note dot
# =============================================================================
param(
    [string]$SpecDir = 'tools\_flow_spec',
    [string]$OutDir  = 'docs\figs',
    [double]$Scale   = 2
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$script:FONTNAME = 'Microsoft YaHei'
$script:C_TITLE  = '#000000'
$script:C_LINE   = '#000000'
$script:C_LABEL  = '#000000'
$script:C_NOTE   = '#000000'
$script:C_TEXT   = '#000000'

# Strict monochrome flowchart: white fill, black outline, black text.
$script:STYLE = @{
    'term' = @{ fill = '#FFFFFF'; line = '#000000' }
    'proc' = @{ fill = '#FFFFFF'; line = '#000000' }
    'dec'  = @{ fill = '#FFFFFF'; line = '#000000' }
    'call' = @{ fill = '#FFFFFF'; line = '#000000' }
    'io'   = @{ fill = '#FFFFFF'; line = '#000000' }
    'note' = @{ fill = $null;     line = $null }
    'dot'  = @{ fill = '#000000'; line = '#000000' }
}

$script:GEO = $null
$script:SFM = [System.Drawing.StringFormat]::GenericTypographic

function C([string]$hex) { return [System.Drawing.ColorTranslator]::FromHtml($hex) }

function New-Pen([string]$hex, [double]$w, [bool]$dash) {
    $col = C $hex
    $p = New-Object System.Drawing.Pen -ArgumentList $col, ([float]$w)
    if ($dash) { $p.DashStyle = [System.Drawing.Drawing2D.DashStyle]::Dash }
    return $p
}

function New-BrushSolid([string]$hex) {
    $col = C $hex
    return (New-Object System.Drawing.SolidBrush -ArgumentList $col)
}

function Round-Path([double]$x, [double]$y, [double]$w, [double]$h, [double]$r) {
    if ($r -gt ($h / 2.0)) { $r = $h / 2.0 }
    if ($r -gt ($w / 2.0)) { $r = $w / 2.0 }
    $d = 2.0 * $r
    $fx = [float]$x; $fy = [float]$y; $fw = [float]$w; $fh = [float]$h; $fd = [float]$d
    $p = New-Object System.Drawing.Drawing2D.GraphicsPath
    $p.AddArc($fx, $fy, $fd, $fd, 180, 90)
    $p.AddArc(($fx + $fw - $fd), $fy, $fd, $fd, 270, 90)
    $p.AddArc(($fx + $fw - $fd), ($fy + $fh - $fd), $fd, $fd, 0, 90)
    $p.AddArc($fx, ($fy + $fh - $fd), $fd, $fd, 90, 90)
    $p.CloseFigure()
    return $p
}

function P([double]$x, [double]$y) {
    return (New-Object System.Drawing.PointF -ArgumentList ([float]$x), ([float]$y))
}

function New-Font([double]$size, [bool]$bold) {
    # GraphicsUnit::Pixel => "size" means size world units (1 unit = 1 pt in the
    # Word output), so the PNG preview matches the .docx layout 1:1.
    $style = [System.Drawing.FontStyle]::Regular
    if ($bold) { $style = [System.Drawing.FontStyle]::Bold }
    return (New-Object System.Drawing.Font -ArgumentList $script:FONTNAME, ([float]$size), $style, ([System.Drawing.GraphicsUnit]::Pixel))
}

function Measure-W($g, [string]$s, $font) {
    # GenericTypographic avoids GDI+'s extra per-string padding, which would
    # otherwise make every line wrap far too early.
    return $g.MeasureString($s, $font, 100000, $script:SFM).Width
}

function Split-For-Wrap([string]$cur) {
    # Prefer breaking BEFORE a trailing ASCII run (identifiers like MODE_PLAY
    # must not be cut in half). Returns the index to break at.
    $i = $cur.Length
    while ($i -gt 0) {
        $c = [int][char]$cur[$i - 1]
        if (($c -ge 48 -and $c -le 57) -or ($c -ge 65 -and $c -le 90) -or
            ($c -ge 97 -and $c -le 122) -or $c -eq 95) { $i-- } else { break }
    }
    if ($i -gt 0 -and $i -lt $cur.Length) { return $i }
    return $cur.Length
}

function Wrap-Text($g, [string]$s, [double]$maxw, $font) {
    $out = New-Object System.Collections.ArrayList
    foreach ($ln in ($s -split "`n")) {
        $cur = ''
        foreach ($ch in $ln.ToCharArray()) {
            $try = $cur + [string]$ch
            $mw = Measure-W $g $try $font
            if (($mw -gt $maxw) -and ($cur.Length -gt 0)) {
                $bi = Split-For-Wrap $cur
                if ($bi -lt $cur.Length) {
                    [void]$out.Add($cur.Substring(0, $bi).TrimEnd())
                    $cur = $cur.Substring($bi) + [string]$ch
                }
                else {
                    [void]$out.Add($cur)
                    $cur = [string]$ch
                }
            }
            else { $cur = $try }
        }
        [void]$out.Add($cur)
    }
    return $out
}

# Draws a centred text block; auto-wraps and auto-shrinks so nothing is clipped.
# Returns @{ text = <wrapped text with newlines>; size = <final pt size> }
function Draw-TextBlock($g, [string]$s, [double]$x, [double]$y, [double]$w, [double]$h,
                        [double]$size, [string]$color, [bool]$bold, [string]$align) {
    if ([string]::IsNullOrEmpty($s)) { return @{ text = ''; size = $size } }

    $cur = $size
    $f = New-Font $cur $bold
    $wrapped = Wrap-Text $g $s $w $f
    $lh = $g.MeasureString('Ag', $f, 100000, $script:SFM).Height
    while ((($wrapped.Count * $lh) -gt $h) -and ($cur -gt 6.5)) {
        $f.Dispose()
        $cur = $cur - 0.25
        $f = New-Font $cur $bold
        $wrapped = Wrap-Text $g $s $w $f
        $lh = $g.MeasureString('Ag', $f, 100000, $script:SFM).Height
    }
    $txt = [string]::Join("`n", $wrapped)

    $b = New-BrushSolid $color
    $sf = New-Object System.Drawing.StringFormat
    if ($align -eq 'left')      { $sf.Alignment = [System.Drawing.StringAlignment]::Near }
    elseif ($align -eq 'right') { $sf.Alignment = [System.Drawing.StringAlignment]::Far }
    else                        { $sf.Alignment = [System.Drawing.StringAlignment]::Center }
    $sf.LineAlignment = [System.Drawing.StringAlignment]::Center
    $rect = New-Object System.Drawing.RectangleF -ArgumentList ([float]$x), ([float]$y), ([float]$w), ([float]$h)
    $g.DrawString($txt, $f, $b, $rect, $sf)
    $f.Dispose(); $b.Dispose(); $sf.Dispose()
    return @{ text = $txt; size = $cur }
}

function Node-Text($n) {
    $t = $n.text
    if ($null -eq $t) { return '' }
    return ([string]::Join("`n", @($t)))
}

function Add-GeoShape($kind, $x, $y, $w, $h, $text, $fs, $bold, $align, $fill, $line, $color) {
    $o = [ordered]@{
        kind = $kind; x = [double]$x; y = [double]$y; w = [double]$w; h = [double]$h
        text = $text; fs = [double]$fs; bold = [bool]$bold; align = $align
        fill = $fill; line = $line; color = $color
    }
    $script:GEO.shapes += , ([pscustomobject]$o)
}

function Draw-Node($g, $n) {
    $x = [double]$n.x; $y = [double]$n.y; $w = [double]$n.w; $h = [double]$n.h
    $kind = [string]$n.kind
    $st = $script:STYLE[$kind]
    $fs = 8.0
    if ($null -ne $n.fs) { $fs = [double]$n.fs }
    $text = Node-Text $n
    $bold = $false
    if ($null -ne $n.bold) { $bold = [bool]$n.bold }
    $align = 'center'
    if ($null -ne $n.align) { $align = [string]$n.align }
    $fill = $st.fill; $line = $st.line; $color = $script:C_TEXT
    if ($null -ne $n.fill) { $fill = [string]$n.fill }
    if ($kind -eq 'note') { $color = $script:C_NOTE }

    if ($kind -eq 'dot') {
        $br = New-BrushSolid $st.fill
        $g.FillEllipse($br, ([float]$x), ([float]$y), ([float]$w), ([float]$h))
        $br.Dispose()
        Add-GeoShape 'dot' $x $y $w $h '' $fs $false 'center' $st.fill $st.line $color
        return
    }

    $pen  = New-Pen $line 0.9 $false
    $fillb = $null
    if ($null -ne $fill) { $fillb = New-BrushSolid $fill }
    $padx = 5.0; $pady = 3.0

    switch ($kind) {
        'term' {
            $path = Round-Path $x $y $w $h ($h / 2.0)
            if ($fillb) { $g.FillPath($fillb, $path) }
            $g.DrawPath($pen, $path); $path.Dispose()
        }
        'round' {
            $path = Round-Path $x $y $w $h 5.0
            if ($fillb) { $g.FillPath($fillb, $path) }
            $g.DrawPath($pen, $path); $path.Dispose()
        }
        'proc' {
            $r = New-Object System.Drawing.RectangleF -ArgumentList ([float]$x), ([float]$y), ([float]$w), ([float]$h)
            if ($fillb) { $g.FillRectangle($fillb, $r) }
            $g.DrawRectangle($pen, ([float]$x), ([float]$y), ([float]$w), ([float]$h))
        }
        'call' {
            $r = New-Object System.Drawing.RectangleF -ArgumentList ([float]$x), ([float]$y), ([float]$w), ([float]$h)
            if ($fillb) { $g.FillRectangle($fillb, $r) }
            $g.DrawRectangle($pen, ([float]$x), ([float]$y), ([float]$w), ([float]$h))
            $g.DrawLine($pen, ([float]($x + 5)), ([float]$y), ([float]($x + 5)), ([float]($y + $h)))
            $g.DrawLine($pen, ([float]($x + $w - 5)), ([float]$y), ([float]($x + $w - 5)), ([float]($y + $h)))
            $padx = 9.0
        }
        'io' {
            $sk = [Math]::Min(12.0, $w * 0.14)
            $pts = [System.Drawing.PointF[]]@(
                (P ($x + $sk) $y), (P ($x + $w) $y), (P ($x + $w - $sk) ($y + $h)), (P $x ($y + $h)))
            if ($fillb) { $g.FillPolygon($fillb, $pts) }
            $g.DrawPolygon($pen, $pts)
        }
        'dec' {
            $pts = [System.Drawing.PointF[]]@(
                (P ($x + $w / 2) $y), (P ($x + $w) ($y + $h / 2)),
                (P ($x + $w / 2) ($y + $h)), (P $x ($y + $h / 2)))
            if ($fillb) { $g.FillPolygon($fillb, $pts) }
            $g.DrawPolygon($pen, $pts)
            $padx = $w * 0.16; $pady = $h * 0.12
        }
        default {
            $r = New-Object System.Drawing.RectangleF -ArgumentList ([float]$x), ([float]$y), ([float]$w), ([float]$h)
            if ($fillb) { $g.FillRectangle($fillb, $r) }
            $g.DrawRectangle($pen, ([float]$x), ([float]$y), ([float]$w), ([float]$h))
        }
    }

    $ret = Draw-TextBlock $g $text ($x + $padx) ($y + $pady) ($w - 2 * $padx) ($h - 2 * $pady) $fs $color $bold $align
    Add-GeoShape $kind $x $y $w $h $ret.text $ret.size $bold $align $fill $line $color
    $pen.Dispose()
    if ($fillb) { $fillb.Dispose() }
}

function Anchor($r, [string]$side) {
    switch ($side) {
        't' { return (P ($r.x + $r.w / 2) $r.y) }
        'b' { return (P ($r.x + $r.w / 2) ($r.y + $r.h)) }
        'l' { return (P $r.x ($r.y + $r.h / 2)) }
        'r' { return (P ($r.x + $r.w) ($r.y + $r.h / 2)) }
    }
    return (P ($r.x + $r.w / 2) ($r.y + $r.h))
}

function Auto-Sides($a, $b) {
    if ($b.y -ge ($a.y + $a.h)) { return @('b', 't') }
    if ($a.y -ge ($b.y + $b.h)) { return @('t', 'b') }
    if (($b.x + $b.w / 2) -gt ($a.x + $a.w / 2)) { return @('r', 'l') }
    return @('l', 'r')
}

function Route($a, $b, [string]$fs, [string]$ts) {
    $p1 = Anchor $a $fs
    $p2 = Anchor $b $ts
    $pts = New-Object System.Collections.ArrayList

    if ((($fs -eq 'b') -and ($ts -eq 't')) -or (($fs -eq 't') -and ($ts -eq 'b'))) {
        if ([Math]::Abs($p1.X - $p2.X) -lt 2.0) { [void]$pts.Add($p1); [void]$pts.Add($p2) }
        else {
            $my = ($p1.Y + $p2.Y) / 2.0
            [void]$pts.Add($p1); [void]$pts.Add((P $p1.X $my)); [void]$pts.Add((P $p2.X $my)); [void]$pts.Add($p2)
        }
    }
    elseif ((($fs -eq 'r') -and ($ts -eq 'l')) -or (($fs -eq 'l') -and ($ts -eq 'r'))) {
        if ([Math]::Abs($p1.Y - $p2.Y) -lt 2.0) { [void]$pts.Add($p1); [void]$pts.Add($p2) }
        else {
            $mx = ($p1.X + $p2.X) / 2.0
            [void]$pts.Add($p1); [void]$pts.Add((P $mx $p1.Y)); [void]$pts.Add((P $mx $p2.Y)); [void]$pts.Add($p2)
        }
    }
    elseif ((($fs -eq 'b') -or ($fs -eq 't')) -and (($ts -eq 'l') -or ($ts -eq 'r'))) {
        [void]$pts.Add($p1); [void]$pts.Add((P $p1.X $p2.Y)); [void]$pts.Add($p2)
    }
    elseif ((($fs -eq 'l') -or ($fs -eq 'r')) -and (($ts -eq 't') -or ($ts -eq 'b'))) {
        [void]$pts.Add($p1); [void]$pts.Add((P $p2.X $p1.Y)); [void]$pts.Add($p2)
    }
    else {
        [void]$pts.Add($p1); [void]$pts.Add($p2)
    }
    return $pts
}

function Add-GeoLine($pts, [bool]$dash) {
    $arr = New-Object System.Collections.ArrayList
    foreach ($pt in $pts) { [void]$arr.Add(@([Math]::Round($pt.X, 2), [Math]::Round($pt.Y, 2))) }
    $o = [ordered]@{ pts = $arr; dash = [bool]$dash }
    $script:GEO.lines += , ([pscustomobject]$o)
}

function Draw-Poly($g, $pts, [string]$label, $lx, $ly, [bool]$dash) {
    $n = $pts.Count
    if ($n -lt 2) { return }
    $pen = New-Pen $script:C_LINE 0.9 $dash

    $tip  = $pts[$n - 1]
    $prev = $pts[$n - 2]
    $dx = $tip.X - $prev.X; $dy = $tip.Y - $prev.Y
    $len = [Math]::Sqrt($dx * $dx + $dy * $dy)
    if ($len -lt 0.001) { $len = 1.0 }
    $ux = $dx / $len; $uy = $dy / $len
    $hl = 7.0
    $base = P ($tip.X - $ux * $hl) ($tip.Y - $uy * $hl)
    $px = -$uy; $py = $ux
    $hw = 3.2
    $w1 = P ($base.X + $px * $hw) ($base.Y + $py * $hw)
    $w2 = P ($base.X - $px * $hw) ($base.Y - $py * $hw)

    for ($i = 0; $i -lt ($n - 2); $i++) { $g.DrawLine($pen, $pts[$i], $pts[$i + 1]) }
    $g.DrawLine($pen, $pts[$n - 2], $base)
    $head = [System.Drawing.PointF[]]@($tip, $w1, $w2)
    $hb = New-BrushSolid $script:C_LINE
    $g.FillPolygon($hb, $head)
    $hb.Dispose()
    $pen.Dispose()
    Add-GeoLine $pts $dash

    if (-not [string]::IsNullOrEmpty($label)) {
        $mid_i = [int][Math]::Floor(($n - 1) / 2)
        $mx = ($pts[$mid_i].X + $pts[$mid_i + 1].X) / 2.0
        $my = ($pts[$mid_i].Y + $pts[$mid_i + 1].Y) / 2.0
        if ($null -ne $lx) { $mx = [double]$lx }
        if ($null -ne $ly) { $my = [double]$ly }
        $ret = Draw-TextBlock $g $label ($mx - 14) ($my - 6) 28 12 7.5 $script:C_LABEL $true 'center'
        Add-GeoShape 'label' ($mx - 14) ($my - 6) 28 12 $ret.text $ret.size $true 'center' '#FFFFFF' $null $script:C_LABEL
    }
}

function Render-Figure($spec, [string]$outPng, [string]$outGeo, [double]$scale) {
    # Figure captions belong to the Word document ("图 x ...", below the figure),
    # so by default nothing is drawn inside the drawing area -- that also lets us
    # reclaim the title band by shifting the whole diagram up by topTrim points.
    $drawTitle = $false
    if ($null -ne $spec.renderTitle) { $drawTitle = [bool]$spec.renderTitle }
    $trim = 0.0
    if (-not $drawTitle) {
        $trim = 14.0
        if ($null -ne $spec.topTrim) { $trim = [double]$spec.topTrim }
        foreach ($n in $spec.nodes) { $n.y = [double]$n.y - $trim }
    }

    $W = [double]$spec.width; $H = [double]$spec.height - $trim
    $bw = [int][Math]::Round($W * $scale); $bh = [int][Math]::Round($H * $scale)
    $bmp = New-Object System.Drawing.Bitmap -ArgumentList $bw, $bh
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
    $g.Clear([System.Drawing.Color]::White)
    $g.ScaleTransform([float]$scale, [float]$scale)

    $script:GEO = [pscustomobject]@{ id = [string]$spec.id; title = [string]$spec.title; w = $W; h = $H; shapes = @(); lines = @() }

    $rects = @{}
    foreach ($n in $spec.nodes) {
        $rects[[string]$n.id] = @{ x = [double]$n.x; y = [double]$n.y; w = [double]$n.w; h = [double]$n.h }
    }

    $title = [string]$spec.title
    if ($drawTitle -and (-not [string]::IsNullOrEmpty($title))) {
        $ret = Draw-TextBlock $g $title 0 4 $W 20 11.5 $script:C_TITLE $true 'center'
        Add-GeoShape 'title' 0 4 $W 20 $ret.text $ret.size $true 'center' $null $null $script:C_TITLE
    }

    foreach ($e in $spec.edges) {
        $label = $null; if ($null -ne $e.label) { $label = [string]$e.label }
        $lx = $null; if ($null -ne $e.lx) { $lx = [double]$e.lx }
        $ly = $null; if ($null -ne $e.ly) { $ly = [double]$e.ly - $trim }
        $dash = $false; if ($null -ne $e.dash) { $dash = [bool]$e.dash }

        $pts = New-Object System.Collections.ArrayList
        if ($null -ne $e.pts) {
            foreach ($pair in $e.pts) { [void]$pts.Add((P ([double]$pair[0]) (([double]$pair[1]) - $trim))) }
        }
        else {
            $a = $rects[[string]$e.f]; $b = $rects[[string]$e.t]
            if ($null -eq $a -or $null -eq $b) { throw ("edge refers to unknown node: " + $e.f + " -> " + $e.t) }
            $fs = [string]$e.fs; $ts = [string]$e.ts
            if ([string]::IsNullOrEmpty($fs) -or [string]::IsNullOrEmpty($ts)) {
                $auto = Auto-Sides $a $b
                if ([string]::IsNullOrEmpty($fs)) { $fs = $auto[0] }
                if ([string]::IsNullOrEmpty($ts)) { $ts = $auto[1] }
            }
            $pts = Route $a $b $fs $ts
        }
        Draw-Poly $g $pts $label $lx $ly $dash
    }

    foreach ($n in $spec.nodes) { Draw-Node $g $n }

    $g.Dispose()
    $bmp.Save($outPng, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()

    $json = $script:GEO | ConvertTo-Json -Depth 8
    [System.IO.File]::WriteAllText($outGeo, $json, (New-Object System.Text.UTF8Encoding($false)))
}

# --------------------------------- main -------------------------------------
$root = (Get-Location).Path
if (-not [System.IO.Path]::IsPathRooted($SpecDir)) { $SpecDir = Join-Path $root $SpecDir }
if (-not [System.IO.Path]::IsPathRooted($OutDir))  { $OutDir  = Join-Path $root $OutDir }
if (-not (Test-Path $OutDir)) { [void](New-Item -ItemType Directory -Path $OutDir -Force) }

$files = Get-ChildItem -Path $SpecDir -Filter '*.json' | Sort-Object Name
foreach ($f in $files) {
    if ($f.Name -like '*.geo.json') { continue }
    if ($f.Name.StartsWith('_')) { continue }
    $txt = [System.IO.File]::ReadAllText($f.FullName, [System.Text.Encoding]::UTF8)
    $spec = $txt | ConvertFrom-Json
    if (($null -eq $spec.width) -or ($null -eq $spec.height)) { continue }
    $name = [string]$spec.id
    if ([string]::IsNullOrEmpty($name)) { $name = $f.BaseName }
    $outPng = Join-Path $OutDir ($name + '.png')
    $outGeo = Join-Path $OutDir ($name + '.geo.json')
    Render-Figure $spec $outPng $outGeo $Scale
    Write-Output ("[ok] " + $name + "  " + [int]$spec.width + "x" + [int]$spec.height +
                  " -> " + $outPng + " + " + (Split-Path -Leaf $outGeo))
}
Write-Output ("[done] figures: " + $files.Count)
