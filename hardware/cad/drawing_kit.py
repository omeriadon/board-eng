"""Small 2D drafting toolkit on top of reportlab for the fabrication drawings (sheet size A3 landscape, all page units
are millimetres, so a drawn 10 mm is 10 mm on paper when printed at 100 %).

A View maps part coordinates (a to the right, b DOWN the page) to the page: page_x = ox + k a, page_y = oy - k b.
"""
import math
from reportlab.pdfgen import canvas
from reportlab.lib.colors import black, white, HexColor

MM = 72 / 25.4
PW, PH = 420.0, 297.0
INK = black
GREY = HexColor("#8a8f98")
LIGHT = HexColor("#d9dce1")
BLUE = HexColor("#1f4fd8")
RED = HexColor("#c0392b")
AMBER = HexColor("#b36b00")
HATCH = HexColor("#7b8088")
FONT, BOLD = "Helvetica", "Helvetica-Bold"


class Page:
    def __init__(self, path):
        self.c = canvas.Canvas(str(path), pagesize=(PW * MM, PH * MM))
        self.c.setTitle("Dither Board: fabrication drawings")
        self.c.setAuthor("Dither Board project")
        self.sheets = []

    def new(self, title, scale, sub="", n=None, total=None, part="", material=""):
        c = self.c
        if self.sheets:
            c.showPage()
        self.sheets.append(title)
        c.scale(MM, MM)
        c.setLineWidth(0.5)
        c.setStrokeColor(INK)
        c.rect(5, 5, PW - 10, PH - 10)
        # title block (150 x 30, bottom right)
        bx, by, bw, bh = PW - 5 - 150, 5, 150, 30
        c.rect(bx, by, bw, bh)
        c.line(bx + 105, by, bx + 105, by + bh)
        c.line(bx + 105, by + 15, bx + bw, by + 15)
        c.line(bx, by + 21, bx + 105, by + 21)
        self.t(bx + 2.5, by + 24.2, f"DITHER BOARD  ·  Rev 27  ·  2026-11-21  ·  {part}", 2.6, BOLD)
        self.t(bx + 2.5, by + 14.2, title, 4.0, BOLD)
        self.text_block(bx + 2.5, by + 10.2, [sub], 2.1, 3.0, FONT, GREY, width=100)
        self.t(bx + 2.5, by + 2.2, ("Material: " + material + "   " if material else "") + "Print at 100 % to read the scale.", 2.0, FONT, GREY)
        self.t(bx + 107.5, by + 26.5, "SCALE", 2.0, FONT, GREY)
        self.t(bx + 107.5, by + 18.6, scale, 3.4, BOLD)
        self.t(bx + 107.5, by + 11.5, "SHEET", 2.0, FONT, GREY)
        self.t(bx + 107.5, by + 4.0, f"{n} / {total}" if n else "", 3.4, BOLD)
        return c

    def t(self, x, y, s, size=2.8, font=FONT, color=INK, anchor="l", rot=0):
        c = self.c
        c.saveState()
        c.setFillColor(color)
        c.setFont(font, size)
        if rot:
            c.translate(x, y)
            c.rotate(rot)
            x = y = 0
        if anchor == "l":
            c.drawString(x, y, s)
        elif anchor == "r":
            c.drawRightString(x, y, s)
        else:
            c.drawCentredString(x, y, s)
        c.restoreState()

    def text_block(self, x, y, lines, size=2.8, lead=4.2, font=FONT, color=INK, width=None):
        """Left-aligned lines going down the page; wraps to `width` mm if given."""
        c = self.c
        out = []
        for ln in lines:
            if width is None:
                out.append(ln)
                continue
            words, cur = ln.split(" "), ""
            for w in words:
                trial = (cur + " " + w).strip()
                if c.stringWidth(trial, font, size) > width and cur:
                    out.append(cur)
                    cur = w
                else:
                    cur = trial
            out.append(cur)
        for i, ln in enumerate(out):
            self.t(x, y - i * lead, ln, size, font, color)
        return y - len(out) * lead

    def save(self):
        self.c.showPage()
        self.c.save()


class View:
    def __init__(self, page, ox, oy, k):
        self.p, self.c, self.ox, self.oy, self.k = page, page.c, ox, oy, k

    def X(self, a): return self.ox + self.k * a
    def Y(self, b): return self.oy - self.k * b

    def _style(self, lw, color, dash):
        c = self.c
        c.setLineWidth(lw)
        c.setStrokeColor(color)
        c.setDash(dash if dash else [])

    def line(self, a0, b0, a1, b1, lw=0.35, color=INK, dash=None):
        self.c.saveState()
        self._style(lw, color, dash)
        self.c.line(self.X(a0), self.Y(b0), self.X(a1), self.Y(b1))
        self.c.restoreState()

    def rect(self, a0, b0, a1, b1, lw=0.35, color=INK, dash=None, fill=None, alpha=None):
        self.c.saveState()
        self._style(lw, color, dash)
        if fill is not None:
            self.c.setFillColor(fill)
        if alpha is not None:
            self.c.setFillAlpha(alpha)
        x0, x1 = sorted((self.X(a0), self.X(a1)))
        y0, y1 = sorted((self.Y(b0), self.Y(b1)))
        self.c.rect(x0, y0, x1 - x0, y1 - y0, stroke=1, fill=1 if fill is not None else 0)
        self.c.restoreState()

    def poly(self, pts, lw=0.35, color=INK, dash=None, fill=None, close=True):
        self.c.saveState()
        self._style(lw, color, dash)
        pth = self.c.beginPath()
        pth.moveTo(self.X(pts[0][0]), self.Y(pts[0][1]))
        for a, b in pts[1:]:
            pth.lineTo(self.X(a), self.Y(b))
        if close:
            pth.close()
        if fill is not None:
            self.c.setFillColor(fill)
        self.c.drawPath(pth, stroke=1, fill=1 if fill is not None else 0)
        self.c.restoreState()

    def circle(self, a, b, d, lw=0.35, color=INK, dash=None, fill=None):
        self.c.saveState()
        self._style(lw, color, dash)
        if fill is not None:
            self.c.setFillColor(fill)
        self.c.circle(self.X(a), self.Y(b), d * self.k / 2, stroke=1, fill=1 if fill is not None else 0)
        self.c.restoreState()

    def centre_cross(self, a, b, r, lw=0.15):
        self.line(a - r, b, a + r, b, lw, GREY, [2, 0.6, 0.4, 0.6])
        self.line(a, b - r, a, b + r, lw, GREY, [2, 0.6, 0.4, 0.6])

    def hatch(self, polys, step=1.3):
        """Section hatching (45 degrees) clipped to the union of polygons given in part coordinates."""
        c = self.c
        c.saveState()
        pth = c.beginPath()
        xs, ys = [], []
        for pts in polys:
            pth.moveTo(self.X(pts[0][0]), self.Y(pts[0][1]))
            for a, b in pts[1:]:
                pth.lineTo(self.X(a), self.Y(b))
            pth.close()
            xs += [self.X(a) for a, b in pts]
            ys += [self.Y(b) for a, b in pts]
        c.clipPath(pth, stroke=0, fill=0, fillMode=0)
        c.setLineWidth(0.12)
        c.setStrokeColor(HATCH)
        x0, x1, y0, y1 = min(xs), max(xs), min(ys), max(ys)
        t = x0 - (y1 - y0)
        while t < x1:
            c.line(t, y0, t + (y1 - y0), y1)
            t += step
        c.restoreState()

    def section_rect(self, a0, b0, a1, b1, lw=0.4):
        pts = [(a0, b0), (a1, b0), (a1, b1), (a0, b1)]
        self.hatch([pts])
        self.rect(a0, b0, a1, b1, lw)

    def text(self, a, b, s, size=2.8, font=FONT, color=INK, anchor="l", dx=0, dy=0, rot=0):
        self.p.t(self.X(a) + dx, self.Y(b) + dy, s, size, font, color, anchor, rot)

    # ---------------------------------------------------------------- dimensions
    def _arrow(self, x, y, dx, dy, color):
        c = self.c
        L, W = 2.0, 0.7
        ang = math.atan2(dy, dx)
        c.saveState()
        c.setFillColor(color)
        c.setStrokeColor(color)
        c.setLineWidth(0.05)
        p = c.beginPath()
        p.moveTo(x, y)
        p.lineTo(x - L * math.cos(ang) + W * math.sin(ang), y - L * math.sin(ang) - W * math.cos(ang))
        p.lineTo(x - L * math.cos(ang) - W * math.sin(ang), y - L * math.sin(ang) + W * math.cos(ang))
        p.close()
        c.drawPath(p, stroke=0, fill=1)
        c.restoreState()

    def dh(self, a0, a1, b, off, label, color=BLUE, size=2.7, ext_from=None):
        """Horizontal dimension between a0 and a1 measured at part row b; the line sits `off` mm below (off > 0)
        or above (off < 0) that row on the page."""
        c = self.c
        y0 = self.Y(b)
        yd = y0 - off
        x0, x1 = self.X(a0), self.X(a1)
        if x0 > x1:
            x0, x1 = x1, x0
        c.saveState()
        c.setStrokeColor(color)
        c.setLineWidth(0.15)
        for x in (x0, x1):
            c.line(x, y0 - (1.0 if off > 0 else -1.0), x, yd - (1.5 if off > 0 else -1.5))
        tw = c.stringWidth(label, FONT, size)
        span = x1 - x0
        c.setLineWidth(0.2)
        if span >= tw + 5.5:
            c.line(x0, yd, x1, yd)
            self._arrow(x0, yd, -1, 0, color)
            self._arrow(x1, yd, 1, 0, color)
            self.p.t((x0 + x1) / 2, yd + 0.9, label, size, FONT, color, "c")
        else:
            c.line(x0 - 5, yd, x1 + 5, yd)
            self._arrow(x0, yd, 1, 0, color)
            self._arrow(x1, yd, -1, 0, color)
            self.p.t(x1 + 6, yd - 0.9, label, size, FONT, color, "l")
        c.restoreState()

    def dv(self, b0, b1, a, off, label, color=BLUE, size=2.7):
        """Vertical dimension between rows b0 and b1 at column a; the line sits `off` mm right (off > 0) or left."""
        c = self.c
        x0 = self.X(a)
        xd = x0 + off
        y0, y1 = self.Y(b0), self.Y(b1)
        if y0 < y1:
            y0, y1 = y1, y0
        c.saveState()
        c.setStrokeColor(color)
        c.setLineWidth(0.15)
        for y in (y0, y1):
            c.line(x0 + (1.0 if off > 0 else -1.0), y, xd + (1.5 if off > 0 else -1.5), y)
        tw = c.stringWidth(label, FONT, size)
        span = y0 - y1
        c.setLineWidth(0.2)
        if span >= tw + 5.5:
            c.line(xd, y0, xd, y1)
            self._arrow(xd, y0, 0, -1, color)
            self._arrow(xd, y1, 0, 1, color)
            self.p.t(xd - 0.9, (y0 + y1) / 2, label, size, FONT, color, "c", rot=90)
        else:
            c.line(xd, y0 + 5, xd, y1 - 5)
            self._arrow(xd, y0, 0, 1, color)
            self._arrow(xd, y1, 0, -1, color)
            self.p.t(xd - 0.9, y1 - 6 - tw, label, size, FONT, color, "l", rot=90)
        c.restoreState()

    def leader(self, a, b, dx, dy, label, size=2.7, color=INK, anchor="l"):
        """Leader line from part point (a, b) to a point dx, dy mm away on the page (dy up) with text at the end."""
        x, y = self.X(a), self.Y(b)
        c = self.c
        c.saveState()
        c.setStrokeColor(color)
        c.setLineWidth(0.18)
        c.line(x, y, x + dx, y + dy)
        c.restoreState()
        self._arrow(x, y, -dx, -dy, color) if (dx or dy) else None
        self.p.t(x + dx + (0.8 if dx >= 0 else -0.8), y + dy - 0.9, label, size, FONT, color, "l" if dx >= 0 else "r")

    def balloon(self, a, b, dx, dy, n):
        x, y = self.X(a), self.Y(b)
        c = self.c
        c.saveState()
        c.setStrokeColor(INK)
        c.setLineWidth(0.2)
        c.line(x, y, x + dx, y + dy)
        c.setFillColor(white)
        c.circle(x + dx, y + dy, 2.6, stroke=1, fill=1)
        c.restoreState()
        self.p.t(x + dx, y + dy - 1.0, str(n), 2.8, BOLD, INK, "c")

    def title(self, a, b, s, size=3.6):
        self.p.t(self.X(a), self.Y(b), s, size, BOLD)
