# -*- coding: utf-8 -*-
"""docx_kit.py -- minimal dependency-free .docx (WordprocessingML) writer.

Why: this machine has no python-docx / lxml / reportlab, and the .ps1 toolchain
cannot install wheels offline. Writing the OOXML package by hand with the stdlib
zipfile module is proven to work here (an earlier report in this workspace was
produced this way and opens/converts cleanly in WPS/Word).

Features
    * A4 page, Chinese fonts (SimSun body / SimHei headings), no external deps
    * headings with outline levels (so Word's navigation pane works)
    * body paragraphs with first-line indent, centred captions
    * data tables (header fill, banded rows, borders)
    * inline JPEG/PNG images sized in cm, aspect preserved
    * page breaks, cover page helper

Usage
    d = Docx()
    d.h1("标题"); d.body("正文……")
    d.table(["a", "b"], [["1", "2"]], [4, 10], caption="表 1 示例")
    d.image("photo.jpg", width_cm=7.6, caption="图 1-1 现场照片")
    d.save("out.docx")
"""
import struct
import zipfile

# --- units ------------------------------------------------------------------
CM = 567               # twips per cm
EMU_PER_CM = 360000    # EMU per cm
PT = 20                # twips per pt

PAGE_W, PAGE_H = 11906, 16838          # A4 portrait (twips)
MARGIN_T = MARGIN_B = 1440
MARGIN_L = MARGIN_R = 1800
BODY_W = PAGE_W - MARGIN_L - MARGIN_R  # 8306 twips ~ 14.65 cm

F_BODY = "SimSun"
F_HEAD = "SimHei"
F_LAT = "Times New Roman"

HEADER_FILL = "1F4E78"
BAND_FILL = "F3F7FA"

_ns_doc = (
    '<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" '
    'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" '
    'xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing" '
    'xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" '
    'xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture">'
)


def esc(t):
    return (str(t).replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;"))


def jpeg_size(path):
    """Return (width, height) of a JPEG by walking its SOF marker."""
    with open(path, "rb") as fh:
        data = fh.read()
    i = 2
    while i < len(data) - 9:
        if data[i] != 0xFF:
            i += 1
            continue
        marker = data[i + 1]
        if marker in (0xD8, 0x01) or 0xD0 <= marker <= 0xD7:
            i += 2
            continue
        if marker == 0xD9:
            break
        seglen = struct.unpack(">H", data[i + 2:i + 4])[0]
        if 0xC0 <= marker <= 0xCF and marker not in (0xC4, 0xC8, 0xCC):
            h, w = struct.unpack(">HH", data[i + 5:i + 9])
            return w, h
        i += 2 + seglen
    raise ValueError("no SOF marker in %s" % path)


def image_size(path):
    lower = str(path).lower()
    if lower.endswith((".jpg", ".jpeg")):
        return jpeg_size(path)
    if lower.endswith(".png"):
        with open(path, "rb") as fh:
            head = fh.read(24)
        return struct.unpack(">II", head[16:24])
    raise ValueError("unsupported image type: %s" % path)


# --- inline runs / paragraphs ----------------------------------------------
def _rpr(font=F_BODY, size=24, bold=False, italic=False, color=None):
    parts = ['<w:rFonts w:ascii="%s" w:hAnsi="%s" w:eastAsia="%s"/>' % (F_LAT, F_LAT, font)]
    if bold:
        parts.append("<w:b/>")
    if italic:
        parts.append("<w:i/>")
    parts.append('<w:sz w:val="%d"/><w:szCs w:val="%d"/>' % (size, size))
    if color:
        parts.append('<w:color w:val="%s"/>' % color)
    return "<w:rPr>%s</w:rPr>" % "".join(parts)


def run(text, font=F_BODY, size=24, bold=False, italic=False, color=None):
    text = esc(text)
    return ('<w:r>' + _rpr(font, size, bold, italic, color)
            + '<w:t xml:space="preserve">' + text + '</w:t></w:r>')


def runs(segments):
    """segments: [(text, kwargs), ...]"""
    return "".join(run(s, **kw) for s, kw in segments)


def para(segments, align=None, indent_chars=None, line=360, before=0, after=0,
         keep_next=False, style=None):
    if isinstance(segments, str):
        segments = [(segments, {})]
    ppr = []
    if style:
        ppr.append('<w:pStyle w:val="%s"/>' % style)
    if keep_next:
        ppr.append("<w:keepNext/>")
    ppr.append('<w:spacing w:before="%d" w:after="%d" w:line="%d" w:lineRule="auto"/>'
               % (before, after, line))
    if align:
        ppr.append('<w:jc w:val="%s"/>' % align)
    if indent_chars:
        ppr.append('<w:ind w:firstLineChars="%d"/>' % indent_chars)
    return "<w:p><w:pPr>%s</w:pPr>%s</w:p>" % ("".join(ppr), runs(segments))


# --- tables -----------------------------------------------------------------
def _borders(color="808080", sz="4"):
    b = lambda e: '<%s w:val="single" w:sz="%s" w:space="0" w:color="%s"/>' % (e, sz, color)
    return "<w:tcBorders>%s</w:tcBorders>" % (b("top") + b("left") + b("bottom") + b("right"))


def _cell(text, width_tw, fill=None, font=9.5, bold=False, color=None,
          center=True, valign="center", grid_span=1):
    tcpr = ['<w:tcW w:w="%d" w:type="dxa"/>' % width_tw,
            '<w:vAlign w:val="%s"/>' % valign,
            '<w:tcMar><w:top w:w="40" w:type="dxa"/><w:bottom w:w="40" w:type="dxa"/>'
            '<w:start w:w="70" w:type="dxa"/><w:end w:w="70" w:type="dxa"/></w:tcMar>']
    if grid_span > 1:
        tcpr.insert(0, '<w:gridSpan w:val="%d"/>' % grid_span)
    tcpr.append(_borders())
    if fill:
        tcpr.append('<w:shd w:val="clear" w:color="auto" w:fill="%s"/>' % fill)
    ppr = '<w:spacing w:before="0" w:after="0" w:line="240" w:lineRule="auto"/><w:jc w:val="%s"/>' % (
        "center" if center else "left")
    sz = int(font * 2)
    txt = text if isinstance(text, str) else "\n".join(str(x) for x in text)
    inner = "".join(
        "<w:p><w:pPr>%s</w:pPr>%s</w:p>" % (ppr, run(line, font=F_BODY, size=sz, bold=bold, color=color))
        for line in txt.split("\n"))
    return "<w:tc><w:tcPr>%s</w:tcPr>%s</w:tc>" % ("".join(tcpr), inner)


class Docx(object):
    def __init__(self, title="", subject=""):
        self.parts = []
        self.media = []          # (rid, part_name, bytes)
        self._next_rid = 2       # rId1 = styles.xml
        self._next_pic = 1
        self.title = title
        self.subject = subject

    # -- text --------------------------------------------------------------
    def raw(self, xml):
        self.parts.append(xml)
        return self

    def h1(self, text):
        return self.raw(para([(text, {"font": F_HEAD, "size": 32, "bold": True})],
                             align="center", before=320, after=180, keep_next=True,
                             style="Heading1"))

    def h2(self, text):
        return self.raw(para([(text, {"font": F_HEAD, "size": 28, "bold": True})],
                             before=220, after=120, keep_next=True, style="Heading2"))

    def h3(self, text):
        return self.raw(para([(text, {"font": F_HEAD, "size": 24, "bold": True})],
                             before=160, after=100, keep_next=True, style="Heading3"))

    def body(self, text, after=0):
        return self.raw(para(text, indent_chars=200, line=360, after=after))

    def body_segments(self, segments, after=0):
        return self.raw(para(segments, indent_chars=200, line=360, after=after))

    def plain(self, text, align=None, size=24, bold=False, after=0):
        return self.raw(para([(text, {"size": size, "bold": bold})], align=align, after=after))

    def bullet(self, text, level=0):
        seg = ("　" * level) + "● " + text
        return self.raw(para(seg, line=340, after=0, indent_chars=200))

    def numbering(self, idx, text):
        return self.raw(para("%s %s" % (idx, text), line=340, after=0, indent_chars=200))

    def caption(self, text):
        return self.raw(para([(text, {"size": 20, "bold": True})], align="center",
                             before=60, after=160, line=280))

    def blank(self):
        return self.raw("<w:p/>")

    def page_break(self):
        return self.raw('<w:p><w:r><w:br w:type="page"/></w:r></w:p>')

    # -- table -------------------------------------------------------------
    def table(self, headers, rows, widths_cm, font=9.5, first_col_left=False,
              caption=None, header_font=None):
        widths = [int(w * CM) for w in widths_cm]
        grid = "".join('<w:gridCol w:w="%d"/>' % w for w in widths)
        hf = header_font or font
        head = "".join(_cell(h, widths[i], fill=HEADER_FILL, font=hf, bold=True, color="FFFFFF")
                       for i, h in enumerate(headers))
        trs = ['<w:tr><w:trPr><w:tblHeader/><w:cantSplit/></w:trPr>' + head + "</w:tr>"]
        for ri, row in enumerate(rows):
            fill = BAND_FILL if ri % 2 == 1 else None
            cells = "".join(
                _cell(str(v), widths[i], fill=fill, font=font,
                      center=(not first_col_left or i > 0))
                for i, v in enumerate(row))
            trs.append("<w:tr><w:trPr><w:cantSplit/></w:trPr>" + cells + "</w:tr>")
        tbl = ('<w:tbl><w:tblPr><w:tblStyle w:val="TableGrid"/>'
               '<w:tblW w:w="%d" w:type="dxa"/><w:jc w:val="center"/>'
               '<w:tblBorders>'
               '<w:top w:val="single" w:sz="4" w:color="808080"/>'
               '<w:left w:val="single" w:sz="4" w:color="808080"/>'
               '<w:bottom w:val="single" w:sz="4" w:color="808080"/>'
               '<w:right w:val="single" w:sz="4" w:color="808080"/>'
               '<w:insideH w:val="single" w:sz="4" w:color="808080"/>'
               '<w:insideV w:val="single" w:sz="4" w:color="808080"/>'
               '</w:tblBorders>'
               '<w:tblLayout w:type="fixed"/></w:tblPr>'
               '<w:tblGrid>%s</w:tblGrid>%s</w:tbl>' % (sum(widths), grid, "".join(trs)))
        self.raw(tbl)
        if caption:
            self.caption(caption)
        return self

    # -- image -------------------------------------------------------------
    def image(self, path, width_cm=7.6, caption=None, max_height_cm=10.5):
        with open(path, "rb") as fh:
            blob = fh.read()
        ext = "jpeg" if str(path).lower().endswith((".jpg", ".jpeg")) else "png"
        w_px, h_px = image_size(path)
        width_cm = min(width_cm, BODY_W / CM)
        height_cm = width_cm * h_px / float(w_px)
        if height_cm > max_height_cm:
            height_cm = max_height_cm
            width_cm = height_cm * w_px / float(h_px)
        cx, cy = int(width_cm * EMU_PER_CM), int(height_cm * EMU_PER_CM)

        rid = "rId%d" % self._next_rid
        self._next_rid += 1
        part = "word/media/image%d.%s" % (len(self.media) + 1, ext)
        self.media.append((rid, part, blob))
        pid = self._next_pic
        self._next_pic += 1

        drawing = (
            '<w:r><w:drawing><wp:inline distT="0" distB="0" distL="0" distR="0">'
            '<wp:extent cx="%d" cy="%d"/>'
            '<wp:effectExtent l="0" t="0" r="0" b="0"/>'
            '<wp:docPr id="%d" name="Picture %d"/>'
            '<wp:cNvGraphicFramePr><a:graphicFrameLocks noChangeAspect="1"/></wp:cNvGraphicFramePr>'
            '<a:graphic><a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/picture">'
            '<pic:pic><pic:nvPicPr><pic:cNvPr id="%d" name="image%d.%s"/><pic:cNvPicPr/></pic:nvPicPr>'
            '<pic:blipFill><a:blip r:embed="%s"/><a:stretch><a:fillRect/></a:stretch></pic:blipFill>'
            '<pic:spPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="%d" cy="%d"/></a:xfrm>'
            '<a:prstGeom prst="rect"><a:avLst/></a:prstGeom></pic:spPr>'
            '</pic:pic></a:graphicData></a:graphic>'
            '</wp:inline></w:drawing></w:r>' % (cx, cy, pid, pid, pid, len(self.media), ext, rid, cx, cy))
        self.raw('<w:p><w:pPr><w:jc w:val="center"/>'
                 '<w:spacing w:before="80" w:after="40" w:line="240" w:lineRule="auto"/></w:pPr>'
                 + drawing + '</w:p>')
        if caption:
            self.caption(caption)
        return self

    def image_row(self, items, width_cm=6.6, caption=None):
        """items: [(path, sub_label), ...] side by side in one row."""
        cells = []
        n = len(items)
        for path, label in items:
            with open(path, "rb") as fh:
                blob = fh.read()
            ext = "jpeg" if str(path).lower().endswith((".jpg", ".jpeg")) else "png"
            w_px, h_px = image_size(path)
            h_cm = width_cm * h_px / float(w_px)
            if h_cm > 8.6:
                h_cm = 8.6
                width_cm_eff = h_cm * w_px / float(h_px)
            else:
                width_cm_eff = width_cm
            cx, cy = int(width_cm_eff * EMU_PER_CM), int(h_cm * EMU_PER_CM)
            rid = "rId%d" % self._next_rid
            self._next_rid += 1
            part = "word/media/image%d.%s" % (len(self.media) + 1, ext)
            self.media.append((rid, part, blob))
            pid = self._next_pic
            self._next_pic += 1
            drawing = (
                '<w:r><w:drawing><wp:inline distT="0" distB="0" distL="0" distR="0">'
                '<wp:extent cx="%d" cy="%d"/><wp:effectExtent l="0" t="0" r="0" b="0"/>'
                '<wp:docPr id="%d" name="Picture %d"/>'
                '<wp:cNvGraphicFramePr><a:graphicFrameLocks noChangeAspect="1"/></wp:cNvGraphicFramePr>'
                '<a:graphic><a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/picture">'
                '<pic:pic><pic:nvPicPr><pic:cNvPr id="%d" name="image%d.%s"/><pic:cNvPicPr/></pic:nvPicPr>'
                '<pic:blipFill><a:blip r:embed="%s"/><a:stretch><a:fillRect/></a:stretch></pic:blipFill>'
                '<pic:spPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="%d" cy="%d"/></a:xfrm>'
                '<a:prstGeom prst="rect"><a:avLst/></a:prstGeom></pic:spPr>'
                '</pic:pic></a:graphicData></a:graphic></wp:inline></w:drawing></w:r>'
                % (cx, cy, pid, pid, pid, len(self.media), ext, rid, cx, cy))
            label_p = ('<w:p><w:pPr><w:jc w:val="center"/>'
                       '<w:spacing w:before="20" w:after="0" w:line="240" w:lineRule="auto"/></w:pPr>'
                       + run(label, size=18) + '</w:p>')
            cells.append('<w:tc><w:tcPr><w:tcW w:w="%d" w:type="dxa"/>'
                         '<w:vAlign w:val="center"/></w:tcPr><w:p><w:pPr><w:jc w:val="center"/>'
                         '<w:spacing w:before="0" w:after="0" w:line="240" w:lineRule="auto"/></w:pPr>'
                         '%s</w:p>%s</w:tc>' % (int(BODY_W / n), drawing, label_p))
        tbl = ('<w:tbl><w:tblPr><w:tblW w:w="%d" w:type="dxa"/><w:jc w:val="center"/>'
               '<w:tblLayout w:type="fixed"/></w:tblPr>'
               '<w:tblGrid>%s</w:tblGrid><w:tr>%s</w:tr></w:tbl>'
               % (BODY_W, "".join('<w:gridCol w:w="%d"/>' % int(BODY_W / n) for _ in items),
                  "".join(cells)))
        self.raw(tbl)
        if caption:
            self.caption(caption)
        return self

    # -- package -----------------------------------------------------------
    def _content_types(self):
        overrides = [
            '<Override PartName="/word/document.xml" ContentType="application/vnd.'
            'openxmlformats-officedocument.wordprocessingml.document.main+xml"/>',
            '<Override PartName="/word/styles.xml" ContentType="application/vnd.'
            'openxmlformats-officedocument.wordprocessingml.styles+xml"/>',
            '<Override PartName="/docProps/core.xml" ContentType="application/vnd.'
            'openxmlformats-package.core-properties+xml"/>',
        ]
        defaults = [
            '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>',
            '<Default Extension="xml" ContentType="application/xml"/>',
        ]
        exts = set(p.rsplit(".", 1)[-1] for _, p, _ in self.media)
        if "jpeg" in exts:
            defaults.append('<Default Extension="jpeg" ContentType="image/jpeg"/>')
        if "png" in exts:
            defaults.append('<Default Extension="png" ContentType="image/png"/>')
        return ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
                '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
                + "".join(defaults) + "".join(overrides) + "</Types>")

    def _doc_rels(self):
        rels = ['<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/'
                'officeDocument/2006/relationships/styles" Target="styles.xml"/>']
        for rid, part, _ in self.media:
            rels.append('<Relationship Id="%s" Type="http://schemas.openxmlformats.org/'
                        'officeDocument/2006/relationships/image" Target="%s"/>'
                        % (rid, part.replace("word/", "")))
        return ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
                '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
                + "".join(rels) + "</Relationships>")

    def _styles(self):
        head = ('<w:rFonts w:ascii="%s" w:hAnsi="%s" w:eastAsia="%s" w:cs="%s"/>'
                % (F_LAT, F_LAT, F_HEAD, F_LAT))
        return ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
                '<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">'
                '<w:docDefaults><w:rPrDefault><w:rPr>'
                '<w:rFonts w:ascii="Times New Roman" w:hAnsi="Times New Roman" '
                'w:eastAsia="SimSun" w:cs="Times New Roman"/><w:sz w:val="24"/>'
                '<w:szCs w:val="24"/></w:rPr></w:rPrDefault>'
                '<w:pPrDefault><w:pPr><w:spacing w:after="0" w:line="360" w:lineRule="auto"/>'
                '</w:pPr></w:pPrDefault></w:docDefaults>'
                '<w:style w:type="paragraph" w:default="1" w:styleId="Normal">'
                '<w:name w:val="Normal"/></w:style>'
                '<w:style w:type="paragraph" w:styleId="Heading1"><w:name w:val="heading 1"/>'
                '<w:basedOn w:val="Normal"/><w:next w:val="Normal"/>'
                '<w:pPr><w:outlineLvl w:val="0"/><w:keepNext/><w:jc w:val="center"/></w:pPr>'
                '<w:rPr>' + head + '<w:b/><w:sz w:val="32"/><w:szCs w:val="32"/></w:rPr></w:style>'
                '<w:style w:type="paragraph" w:styleId="Heading2"><w:name w:val="heading 2"/>'
                '<w:basedOn w:val="Normal"/><w:next w:val="Normal"/>'
                '<w:pPr><w:outlineLvl w:val="1"/><w:keepNext/></w:pPr>'
                '<w:rPr>' + head + '<w:b/><w:sz w:val="28"/><w:szCs w:val="28"/></w:rPr></w:style>'
                '<w:style w:type="paragraph" w:styleId="Heading3"><w:name w:val="heading 3"/>'
                '<w:basedOn w:val="Normal"/><w:next w:val="Normal"/>'
                '<w:pPr><w:outlineLvl w:val="2"/><w:keepNext/></w:pPr>'
                '<w:rPr>' + head + '<w:b/><w:sz w:val="24"/><w:szCs w:val="24"/></w:rPr></w:style>'
                '<w:style w:type="table" w:styleId="TableGrid"><w:name w:val="Table Grid"/>'
                '<w:tblPr><w:tblBorders>'
                '<w:top w:val="single" w:sz="4" w:color="808080"/>'
                '<w:left w:val="single" w:sz="4" w:color="808080"/>'
                '<w:bottom w:val="single" w:sz="4" w:color="808080"/>'
                '<w:right w:val="single" w:sz="4" w:color="808080"/>'
                '<w:insideH w:val="single" w:sz="4" w:color="808080"/>'
                '<w:insideV w:val="single" w:sz="4" w:color="808080"/>'
                '</w:tblBorders></w:tblPr></w:style>'
                "</w:styles>")

    def _core(self):
        return ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
                '<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/'
                'metadata/core-properties" xmlns:dc="http://purl.org/dc/elements/1.1/" '
                'xmlns:dcterms="http://purl.org/dc/terms/" '
                'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">'
                "<dc:title>%s</dc:title><dc:subject>%s</dc:subject>"
                "<dc:creator>03231312 李家乐</dc:creator>"
                '<dcterms:created xsi:type="dcterms:W3CDTF">2026-09-20T00:00:00Z</dcterms:created>'
                '<dcterms:modified xsi:type="dcterms:W3CDTF">2026-09-20T00:00:00Z</dcterms:modified>'
                "</cp:coreProperties>" % (esc(self.title), esc(self.subject)))

    def save(self, path):
        sectpr = ("<w:sectPr>"
                  '<w:pgSz w:w="%d" w:h="%d"/>' % (PAGE_W, PAGE_H)
                  + '<w:pgMar w:top="%d" w:right="%d" w:bottom="%d" w:left="%d" '
                    'w:header="851" w:footer="992" w:gutter="0"/>'
                    % (MARGIN_T, MARGIN_R, MARGIN_B, MARGIN_L)
                  + '<w:cols w:space="708"/><w:docGrid w:linePitch="312"/></w:sectPr>')
        doc = ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' + _ns_doc
               + "<w:body>" + "".join(self.parts) + sectpr + "</w:body></w:document>")
        rels_root = ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
                     '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
                     '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/'
                     'officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>'
                     '<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/'
                     'relationships/metadata/core-properties" Target="docProps/core.xml"/>'
                     "</Relationships>")
        with zipfile.ZipFile(path, "w", zipfile.ZIP_DEFLATED) as z:
            z.writestr("[Content_Types].xml", self._content_types())
            z.writestr("_rels/.rels", rels_root)
            z.writestr("docProps/core.xml", self._core())
            z.writestr("word/document.xml", doc)
            z.writestr("word/styles.xml", self._styles())
            z.writestr("word/_rels/document.xml.rels", self._doc_rels())
            for _, part, blob in self.media:
                z.writestr(part, blob)
        return path
