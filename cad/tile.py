"""
Dither Board — parametric tile + laser-part generator.

Generates printable STLs and laser-cut SVGs for one tile design.
Change the PARAMETERS block, then run:

    python3 -m venv .venv && .venv/bin/pip install manifold3d numpy trimesh svglib reportlab
    .venv/bin/python cad/tile.py

Outputs go to cad/out/ (STL + PDF only). All units are millimetres.

Status: ROUGH rev 1. The slider/motor interface is a placeholder until the
real 8 mm micro slider stepper is measured.
"""
from pathlib import Path
import math
import numpy as np
import trimesh
from manifold3d import Manifold, CrossSection
import io
from svglib.svglib import svg2rlg
from reportlab.graphics import renderPDF

# ------------------------------------------------------------------ PARAMETERS
N = 5                 # tiles per side
K = 4                 # LEDs per tile side
PITCH = 40.0          # tile centre-to-centre spacing
GAP = 1.2             # gap between neighbouring tile heads (0.6 per side)
HEAD = PITCH - GAP    # tile head outer width

RIM_WALL = 1.2        # outer wall of the head
GRID_WALL = 1.0       # light-grid wall thickness
GRID_H = 8.0          # light-grid cell depth (taller = crisper squares)
DIFFUSER_T = 2.0      # smoked acrylic thickness
PCB_T = 1.6           # tile PCB thickness
FLOOR_T = 2.0         # stem floor plate thickness
FIT = 0.15            # press-fit clearance per side (diffuser / PCB / floor in rim)
CHAMFER = 0.4         # first-layer chamfer (beats elephant's foot)

STEM = 20.0           # square stem outer width
STEM_WALL = 1.6
STEM_LEN = 40.0
STEM_CLEAR = 0.25     # stem <-> guide hole clearance per side
STROKE = 15.0         # tile travel
LEVELS = 10           # detent levels (notch pitch = STROKE / LEVELS)
NOTCH_D = 0.5         # detent notch depth
M2_HOLE = 2.2         # slider screw clearance hole

MARGIN = 10.0         # black border around the grid
PLATE_T = 3.0         # acrylic plate thickness (for reference only)
M3_HOLE = 3.2
# ---------------------------------------------------------------------------

OUT = Path(__file__).parent / "out"
OUT.mkdir(exist_ok=True)

RIM_INNER = HEAD - 2 * RIM_WALL
HEAD_H = GRID_H + PCB_T + FLOOR_T          # printed part (diffuser is glued on the front)
DIFFUSER = HEAD - 0.2                        # smoked acrylic square, glued flush on the front face
CELL = RIM_INNER / K


def box(x, y, z, cx=True):
    m = Manifold.cube([x, y, z])
    return m.translate([-x / 2, -y / 2, 0]) if cx else m


def save_stl(m: Manifold, name: str):
    mesh = m.to_mesh()
    tm = trimesh.Trimesh(vertices=np.asarray(mesh.vert_properties)[:, :3],
                         faces=np.asarray(mesh.tri_verts), process=True)
    assert tm.is_watertight, f"{name} is not watertight"
    tm.export(OUT / name)
    b = tm.bounds
    print(f"  {name:28s} {b[1][0]-b[0][0]:6.1f} x {b[1][1]-b[0][1]:6.1f} x {b[1][2]-b[0][2]:6.1f} mm"
          f"   vol {tm.volume/1000:5.2f} cm³")


# ----------------------------------------------------------------- tile head
def tile_head() -> Manifold:
    """Printed FACE-DOWN: z=0 is the front face (the smoked acrylic is glued onto it).
    Grid walls start on the print bed, so no supports and crisp square cells."""
    # outer shell with a bottom chamfer on the first layer
    sq = CrossSection.square([HEAD - 2 * CHAMFER, HEAD - 2 * CHAMFER], center=True)
    chamfer = Manifold.extrude(sq, CHAMFER, scale_top=[HEAD / (HEAD - 2 * CHAMFER)] * 2)
    body = chamfer + box(HEAD, HEAD, HEAD_H - CHAMFER).translate([0, 0, CHAMFER])
    body = body - box(RIM_INNER, RIM_INNER, HEAD_H + 2).translate([0, 0, -1])
    # light grid (K-1 walls each way) between the diffuser and the PCB
    z0 = 0.0
    for i in range(1, K):
        off = -RIM_INNER / 2 + i * CELL
        body += box(GRID_WALL, RIM_INNER, GRID_H).translate([off, 0, z0])
        body += box(RIM_INNER, GRID_WALL, GRID_H).translate([0, off, z0])
    return body


# ----------------------------------------------------------------- tile stem
def tile_stem() -> Manifold:
    """Printed UPRIGHT: z=0 is the floor plate that presses into the head."""
    plate = box(RIM_INNER - 2 * FIT, RIM_INNER - 2 * FIT, FLOOR_T)
    # wire pass-through from PCB back into the stem
    plate -= box(10, 6, FLOOR_T + 2).translate([0, 0, -1])
    tube = box(STEM, STEM, STEM_LEN).translate([0, 0, FLOOR_T])
    tube -= box(STEM - 2 * STEM_WALL, STEM - 2 * STEM_WALL, STEM_LEN - 2).translate([0, 0, FLOOR_T - 0.01])
    stem = plate + tube
    # bottom cap M2 hole for the slider nut
    stem -= Manifold.cylinder(10, M2_HOLE / 2, circular_segments=32).translate([0, 0, FLOOR_T + STEM_LEN - 5])
    # wire exit slot near the bottom on +X face
    stem -= box(4, 8, 8).translate([STEM / 2, 0, FLOOR_T + STEM_LEN - 12])
    # detent V-notches on -Y face, one per level
    notch_pitch = STROKE / LEVELS
    s = NOTCH_D * math.sqrt(2)
    for i in range(LEVELS + 1):
        z = FLOOR_T + 8 + i * notch_pitch
        v = box(STEM - 4, s, s).translate([0, 0, -s / 2]).rotate([45, 0, 0]).translate([0, -STEM / 2, z])
        stem -= v
    return stem


# ------------------------------------------------------- clearance test coupon
def clearance_coupon() -> Manifold:
    """Square holes at 4 clearances + a short test stem. Print both, find the best fit."""
    clears = [0.15, 0.20, 0.25, 0.30]
    w = len(clears) * (STEM + 8) + 6
    plate = box(w, STEM + 14, 5, cx=False)
    for i, c in enumerate(clears):
        cx = 3 + 4 + STEM / 2 + i * (STEM + 8)
        plate -= box(STEM + 2 * c, STEM + 2 * c, 7).translate([cx, (STEM + 14) / 2, -1])
        for d in range(i + 1):  # dimples = hole index (1..4)
            plate -= Manifold.cylinder(2, 0.8, circular_segments=16).translate(
                [cx - STEM / 2 + 2 + d * 2.5, 2.5, 4])
    stub = box(STEM, STEM, 15) - box(STEM - 2 * STEM_WALL, STEM - 2 * STEM_WALL, 17).translate([0, 0, -1])
    return plate + stub.translate([w / 2, STEM + 14 + 4 + STEM / 2, 0])


# --------------------------------------------------------------- laser SVGs
def to_pdf(svg_text: str, name: str):
    """Convert SVG text to a true-scale PDF (laser files stay 1:1 in mm)."""
    drawing = svg2rlg(io.BytesIO(svg_text.encode()))
    renderPDF.drawToFile(drawing, str(OUT / name))


def svg(name, w, h, body, pad=3.0):
    """Laser PDF at 1:1 scale, with a small page margin so the outer cut isn't clipped."""
    W, H = w + 2 * pad, h + 2 * pad
    to_pdf(
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{W:.2f}mm" height="{H:.2f}mm" '
        f'viewBox="0 0 {W:.2f} {H:.2f}">\n'
        f'<!-- red hairline = cut. units: mm. Dither Board, rough rev 1 -->\n'
        f'<g fill="none" stroke="#ff0000" stroke-width="0.1" transform="translate({pad},{pad})">\n{body}</g>\n</svg>\n', name)
    print(f"  {name:28s} {w:6.1f} x {h:6.1f} mm")


def rect(x, y, w, h):
    return f'<rect x="{x:.2f}" y="{y:.2f}" width="{w:.2f}" height="{h:.2f}"/>\n'


def circ(x, y, d):
    return f'<circle cx="{x:.2f}" cy="{y:.2f}" r="{d/2:.2f}"/>\n'


def laser_parts():
    # diffusers: N*N squares, 3 mm apart
    d = DIFFUSER
    sp = 3.0
    cols = N
    rows = math.ceil(N * N / cols)
    body = "".join(rect(sp + (i % cols) * (d + sp), sp + (i // cols) * (d + sp), d, d) for i in range(N * N))
    svg("laser_diffusers_smoked.pdf", sp + cols * (d + sp), sp + rows * (d + sp), body)

    outer = N * PITCH + 2 * MARGIN
    corners = [(MARGIN / 2, MARGIN / 2), (outer - MARGIN / 2, MARGIN / 2),
               (MARGIN / 2, outer - MARGIN / 2), (outer - MARGIN / 2, outer - MARGIN / 2)]
    mount = "".join(circ(x, y, M3_HOLE) for x, y in corners)

    # front bezel: opening = full grid (each tile already has GAP/2 each side)
    body = rect(0, 0, outer, outer) + rect(MARGIN, MARGIN, N * PITCH, N * PITCH) + mount
    svg("laser_front_bezel_black.pdf", outer, outer, body)

    # guide plates (front + rear identical): square holes for the stems
    hole = STEM + 2 * STEM_CLEAR
    holes = "".join(
        rect(MARGIN + c * PITCH + (PITCH - hole) / 2, MARGIN + r * PITCH + (PITCH - hole) / 2, hole, hole)
        for r in range(N) for c in range(N))
    body = rect(0, 0, outer, outer) + holes + mount
    svg("laser_guide_plate_x2.pdf", outer, outer, body)


# --------------------------------------------------------- blueprint drawing
def blueprint():
    S = 4.0  # px per mm
    o = []
    def R(x, y, w, h, c="part"): o.append(f'<rect x="{x:.1f}" y="{y:.1f}" width="{w:.1f}" height="{h:.1f}" class="{c}"/>')
    def T(x, y, t, a="middle", c="t"): o.append(f'<text x="{x:.1f}" y="{y:.1f}" text-anchor="{a}" class="{c}">{t}</text>')
    def DH(x1, x2, y, label):  # horizontal dimension
        o.append(f'<line x1="{x1:.1f}" y1="{y:.1f}" x2="{x2:.1f}" y2="{y:.1f}" class="dim" marker-start="url(#a)" marker-end="url(#a)"/>')
        T((x1 + x2) / 2, y - 4, label, c="d")
    def DV(y1, y2, x, label):
        o.append(f'<line x1="{x:.1f}" y1="{y1:.1f}" x2="{x:.1f}" y2="{y2:.1f}" class="dim" marker-start="url(#a)" marker-end="url(#a)"/>')
        o.append(f'<text x="{x-5:.1f}" y="{(y1+y2)/2:.1f}" class="d" text-anchor="middle" transform="rotate(-90 {x-5:.1f} {(y1+y2)/2:.1f})">{label}</text>')

    # A: head, front view
    ax, ay = 40, 60
    T(ax + HEAD * S / 2, 24, "A · TILE HEAD — FRONT VIEW", c="h")
    R(ax, ay, HEAD * S, HEAD * S)
    R(ax + RIM_WALL * S, ay + RIM_WALL * S, RIM_INNER * S, RIM_INNER * S, "hole")
    for i in range(1, K):
        off = (RIM_WALL + i * CELL - GRID_WALL / 2) * S
        R(ax + off, ay + RIM_WALL * S, GRID_WALL * S, RIM_INNER * S)
        R(ax + RIM_WALL * S, ay + off, RIM_INNER * S, GRID_WALL * S)
    for i in range(K):
        for j in range(K):
            cx = ax + (RIM_WALL + (i + 0.5) * CELL) * S; cy = ay + (RIM_WALL + (j + 0.5) * CELL) * S
            R(cx - 2.5 * S, cy - 2.5 * S, 5 * S, 5 * S, "led")
    DH(ax, ax + HEAD * S, ay - 10, f"{HEAD:.1f}")
    DV(ay, ay + HEAD * S, ax - 12, f"{HEAD:.1f}")
    DH(ax + RIM_WALL * S, ax + (RIM_WALL + CELL) * S, ay + HEAD * S + 16, f"cell {CELL:.2f}")
    T(ax - 20, ay + HEAD * S + 40, f"rim {RIM_WALL} · grid walls {GRID_WALL}", "start", "n")
    T(ax - 20, ay + HEAD * S + 56, f"{K}×{K} square WS2812B-5050 LEDs (5×5)", "start", "n")

    # B: section of head + stem (side)
    bx, by = 300, 60
    T(bx + HEAD * S / 2, 24, "B · TILE SECTION — SIDE", c="h")
    R(bx + (HEAD - DIFFUSER) / 2 * S, by, DIFFUSER * S, DIFFUSER_T * S, "acr")
    y = by + DIFFUSER_T * S
    R(bx, y, RIM_WALL * S, HEAD_H * S); R(bx + (HEAD - RIM_WALL) * S, y, RIM_WALL * S, HEAD_H * S)
    for i in range(1, K):
        R(bx + (RIM_WALL + i * CELL - GRID_WALL / 2) * S, y, GRID_WALL * S, GRID_H * S)
    R(bx + RIM_WALL * S, y + GRID_H * S, RIM_INNER * S, PCB_T * S, "pcb")
    R(bx + (RIM_WALL + FIT) * S, y + (GRID_H + PCB_T) * S, (RIM_INNER - 2 * FIT) * S, FLOOR_T * S)
    sx = bx + (HEAD - STEM) / 2 * S; sy = y + HEAD_H * S
    R(sx, sy, STEM_WALL * S, STEM_LEN * S); R(sx + (STEM - STEM_WALL) * S, sy, STEM_WALL * S, STEM_LEN * S)
    R(sx, sy + (STEM_LEN - 2) * S, STEM * S, 2 * S)
    DV(by, by + DIFFUSER_T * S, bx - 10, f"{DIFFUSER_T:g}")
    DV(y, y + GRID_H * S, bx - 10, f"{GRID_H:g}")
    DV(y + GRID_H * S, y + HEAD_H * S, bx - 26, f"{PCB_T+FLOOR_T:g}")
    DV(sy, sy + STEM_LEN * S, bx - 10, f"{STEM_LEN:g}")
    DH(sx, sx + STEM * S, sy + STEM_LEN * S + 16, f"stem {STEM:g} sq")
    lx = bx + HEAD * S + 30
    for ty, py, txt in [(by - 2, by + DIFFUSER_T * S / 2, "smoked acrylic, glued on"),
                        (by + 18, y + GRID_H * S / 2, "black PLA head + light grid (face-down)"),
                        (by + 38, y + (GRID_H + PCB_T / 2) * S, "tile PCB (LEDs face front)"),
                        (by + 58, y + (GRID_H + PCB_T + FLOOR_T / 2) * S, "stem floor plate (press fit)")]:
        o.append(f'<polyline points="{bx + HEAD*S + 2:.1f},{py:.1f} {lx - 4:.1f},{ty - 4:.1f}" class="dim" fill="none" opacity=".5"/>')
        T(lx, ty, txt, "start", "n")
    T(bx + HEAD * S + 8, sy + 60, "hollow stem: wires", "start", "n")
    T(bx + HEAD * S + 8, sy + 74, f"detents every {STROKE/LEVELS:g}", "start", "n")
    T(bx + HEAD * S + 8, sy + (STEM_LEN - 1) * S, f"M2 → slider nut", "start", "n")

    # C: guide plate detail (2x2 corner)
    cx0, cy0 = 40, 420
    T(cx0 - 20, cy0 - 14, "C · GUIDE PLATE — CORNER DETAIL (×2 plates, acrylic)", "start", "h")
    s2 = 2.4
    R(cx0, cy0, (MARGIN + 2 * PITCH) * s2, (MARGIN + 2 * PITCH) * s2)
    hole = STEM + 2 * STEM_CLEAR
    for r in range(2):
        for c in range(2):
            R(cx0 + (MARGIN + c * PITCH + (PITCH - hole) / 2) * s2, cy0 + (MARGIN + r * PITCH + (PITCH - hole) / 2) * s2, hole * s2, hole * s2, "hole")
    o.append(f'<circle cx="{cx0 + MARGIN/2*s2:.1f}" cy="{cy0 + MARGIN/2*s2:.1f}" r="{M3_HOLE/2*s2:.1f}" class="hole"/>')
    DH(cx0 + MARGIN * s2, cx0 + (MARGIN + PITCH) * s2, cy0 + (MARGIN + 2 * PITCH) * s2 + 16, f"pitch {PITCH:g}")
    T(cx0 + (MARGIN + 2 * PITCH) * s2 + 16, cy0 + 30, f"holes {hole:.1f} sq (stem {STEM:g} + {STEM_CLEAR}/side)", "start", "n")
    T(cx0 + (MARGIN + 2 * PITCH) * s2 + 16, cy0 + 48, f"border {MARGIN:g} · M3 corner holes", "start", "n")
    T(cx0 + (MARGIN + 2 * PITCH) * s2 + 16, cy0 + 66, f"overall {N*PITCH+2*MARGIN:g} × {N*PITCH+2*MARGIN:g} for {N}×{N} tiles", "start", "n")
    T(cx0 + (MARGIN + 2 * PITCH) * s2 + 16, cy0 + 84, f"head gap {GAP} between tiles · stroke {STROKE:g}", "start", "n")
    T(cx0 + (MARGIN + 2 * PITCH) * s2 + 16, cy0 + 112, "ROUGH REV 2 · units mm · motor interface TBD", "start", "w")

    W, H = 720, 680
    css = """.part{fill:#2b2b30;stroke:#9aa0aa;stroke-width:1}.hole{fill:#0e1a2b;stroke:#9aa0aa;stroke-width:1}
.led{fill:#e8e8e8;opacity:.25;stroke:#ccc;stroke-width:.5}.acr{fill:#4a3d5c;stroke:#b9a3d6}.pcb{fill:#111;stroke:#888}
.dim{stroke:#7fb7ff;stroke-width:1}.t{fill:#ddd;font:12px sans-serif}.h{fill:#fff;font:bold 13px sans-serif}
.d{fill:#7fb7ff;font:11px monospace}.n{fill:#bbb;font:11px sans-serif}.w{fill:#ffb347;font:bold 11px sans-serif}"""
    svg_text = (
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">'
        f'<defs><marker id="a" viewBox="0 0 10 10" refX="5" refY="5" markerWidth="5" markerHeight="5" orient="auto-start-reverse">'
        f'<path d="M0,0 L10,5 L0,10 z" fill="#7fb7ff"/></marker><style>{css}</style></defs>'
        f'<rect width="100%" height="100%" fill="#0b1220"/>{"".join(o)}</svg>')
    to_pdf(svg_text, "blueprint_tile.pdf")
    print("  blueprint_tile.pdf")


if __name__ == "__main__":
    print(f"Grid {N}x{N} tiles, {K}x{K} LEDs each = {N*K}x{N*K} pixels, pitch {PITCH} mm")
    print(f"Head {HEAD:.1f} mm, cell {CELL:.2f} mm, head height {HEAD_H:.1f} mm")
    save_stl(tile_head(), "tile_head.stl")
    save_stl(tile_stem(), "tile_stem.stl")
    save_stl(clearance_coupon(), "test_clearance_coupon.stl")
    laser_parts()
    blueprint()
