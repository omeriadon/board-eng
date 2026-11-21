"""
Dither Board — parametric tile + laser-part generator.

Generates printable STLs and laser-cut SVGs for one tile design.
Change the PARAMETERS block, then run:

    python3 -m venv .venv && .venv/bin/pip install manifold3d numpy trimesh svglib reportlab
    .venv/bin/python cad/tile.py

Outputs go to cad/out/ (STL + PDF only). All units are millimetres.

Status: rev 27 (2026-11-21). 5 x 5 tiles, one premade 5 x 5 WS2812B module (39 mm,
7.8 mm LED pitch) per tile, one micro servo per tile driving the stem through a
scotch yoke (pin on the servo horn riding in a slot in a printed yoke on the
stem tail). `assembly()` checks the whole stroke for collisions. Servo outline
body 22.2 x 11.8 mm is from the builder-supplied SG90 spec (ears, boss and spline are typical SG90 values).
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
N = 5                 # tiles per side (decided rev 25: 25 tiles, 25 x 25 pixels)
K = 5                 # LEDs per tile side (one 5 x 5 module)
LED_PITCH = 7.8       # module LED pitch = grid cell pitch
MODULE = K * LED_PITCH  # 39.0 mm module (Electropeak lists "3.9" = cm)
PITCH = 43.0          # tile centre-to-centre spacing
GAP = 1.0             # gap between neighbouring tile heads
HEAD = PITCH - GAP    # tile head outer width (42.0)

RIM_WALL = 1.2        # outer wall of the head
GRID_WALL = 1.0       # light-grid wall thickness
GRID_H = 8.0          # light-grid cell depth (taller = crisper squares)
DIFFUSER_T = 0.8      # printed translucent diffuser sheet (was smoked acrylic)
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
M2_HOLE = 2.2         # M2 clearance hole
M2_PILOT = 1.8        # M2 self-tapping pilot in PLA

# ---- servo + scotch yoke (rev 22). Frame: x, y centred on the stem axis; z from the head front face.
TOTAL_ROT = 150.0     # degrees of servo swing used (+-75), of the ~180 available
R_CRANK = (STROKE / 2) / math.sin(math.radians(TOTAL_ROT / 2))   # 7.76 mm
PIN_D = 2.0           # steel pin / M2 screw shank
SLOT_W = PIN_D + 0.3
SERVO_L, SERVO_W, SERVO_H = 22.2, 11.8, 22.7   # body from the builder-supplied SG90 spec (22.2 x 11.8 x 31; the 31 includes the horn hub): along y, along z, along shaft (x)
SERVO_SHAFT_FROM_END = 6.0
EAR_SPAN, EAR_T, EAR_BELOW_TOP = 32.5, 2.5, 3.0 + 2.5          # ears: tip to tip; plane 5.5 below the top face [E]
SERVO_XF = -5.0       # x of the servo's top face (horn side), relative to the stem axis
SPLINE_H, HORN_T = 4.5, 2.0
PIN_LEN = 4.0
BLADE_T = 3.0                                  # yoke blade thickness (x)
BLADE_GAP = 2.0                                # clear space between the horn arm and the blade
WALL_T, FOOT_T = 2.5, 2.5                      # servo bracket thicknesses
BLADE_X0 = SERVO_XF - SPLINE_H - HORN_T - BLADE_GAP - BLADE_T   # yoke blade outer face (-16.5 for a 4.5 mm spline stack)
SERVO_W0 = 12.0       # shaft position along the stem axis, measured back from the stem end cap (w)

MARGIN = 10.0         # black border around the grid
PLATE_T = 3.0         # acrylic plate thickness (for reference only)
M3_HOLE = 3.2
# ---------------------------------------------------------------------------

OUT = Path(__file__).parent / "out"
OUT.mkdir(exist_ok=True)

RIM_INNER = HEAD - 2 * RIM_WALL
HEAD_H = GRID_H + PCB_T + FLOOR_T          # printed part (diffuser is glued on the front)
DIFFUSER = HEAD - 0.2                        # printed sheet, glued flush on the front face
CELL = LED_PITCH
GRID_OFF = (RIM_INNER - K * CELL) / 2        # module is centred in the rim (0.3 mm a side)
TAIL_Z = HEAD_H + STEM_LEN                   # stem end cap back face when retracted (51.6)


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
        off = -K * CELL / 2 + i * CELL
        body += box(GRID_WALL, RIM_INNER, GRID_H).translate([off, 0, z0])
        body += box(RIM_INNER, GRID_WALL, GRID_H).translate([0, off, z0])
    return body


# ----------------------------------------------------------------- tile stem
def tile_stem() -> Manifold:
    """Printed UPRIGHT: z=0 is the floor plate that presses into the head."""
    plate = box(RIM_INNER - 2 * FIT, RIM_INNER - 2 * FIT, FLOOR_T)
    # wire pass-through from the LED module back into the stem
    plate -= box(10, 6, FLOOR_T + 2).translate([0, 0, -1])
    tube = box(STEM, STEM, STEM_LEN).translate([0, 0, FLOOR_T])
    tube -= box(STEM - 2 * STEM_WALL, STEM - 2 * STEM_WALL, STEM_LEN - 2).translate([0, 0, FLOOR_T - 0.01])
    stem = plate + tube
    # two M2 pilot holes in the end cap for the yoke (self-tapping, 6 mm screws)
    for sy in (-5.5, 5.5):
        stem -= Manifold.cylinder(4, M2_PILOT / 2, circular_segments=24).translate([-6.0, sy, FLOOR_T + STEM_LEN - 3])
    # wire exit slot near the bottom on +X face
    stem -= box(4, 8, 8).translate([STEM / 2, 0, FLOOR_T + STEM_LEN - 12])
    return stem



# ------------------------------------------------- servo + scotch yoke (rev 22)
SIN_MAX = math.sin(math.radians(TOTAL_ROT / 2))
Y_S = -R_CRANK * (1 + math.cos(math.radians(TOTAL_ROT / 2))) / 2          # servo shaft y so the pin range is centred on the stem
SLOT_LEN = R_CRANK * (1 - math.cos(math.radians(TOTAL_ROT / 2))) + PIN_D + 1.0
BODY_Y0 = Y_S - SERVO_SHAFT_FROM_END
ZC = TAIL_Z + SERVO_W0                                                     # shaft z when the stem is retracted
GUIDE_Z = [(HEAD_H + 1.0, PLATE_T), (HEAD_H + 18.4, PLATE_T)]              # front plate (behind the pad), rear plate


def bx(x0, x1, y0, y1, z0, z1):
    return Manifold.cube([x1 - x0, y1 - y0, z1 - z0]).translate([x0, y0, z0])


def cylx(x0, x1, y, z, d):
    """Cylinder along x from x0 to x1."""
    return Manifold.cylinder(x1 - x0, d / 2, circular_segments=40).rotate([0, 90, 0]).translate([x0, y, z])


def tile_yoke() -> Manifold:
    """Printed lying on its side. Flange screws to the stem end cap (2 x M2); the blade carries the slot the
    servo's pin rides in. Frame here = world frame, retracted; flange back face of the cap at z = TAIL_Z."""
    fl = bx(BLADE_X0, 1.0, -8, 8, TAIL_Z, TAIL_Z + 2)
    blade = bx(BLADE_X0, BLADE_X0 + BLADE_T, -7.6, 7.6, TAIL_Z, TAIL_Z + SERVO_W0 + SIN_MAX * R_CRANK + SLOT_W / 2 + 2.0)
    y = fl + blade
    zs = TAIL_Z + SERVO_W0 + SIN_MAX * R_CRANK
    y -= bx(BLADE_X0 - 1, BLADE_X0 + BLADE_T + 1, -SLOT_LEN / 2, SLOT_LEN / 2, zs - SLOT_W / 2, zs + SLOT_W / 2)
    for sy in (-5.5, 5.5):
        y -= Manifold.cylinder(6, M2_HOLE / 2, circular_segments=24).translate([-6.0, sy, TAIL_Z - 1])
    return y


def servo_bracket() -> Manifold:
    """Holds the servo by its ears: a wall with a cutout (ears rest on its front face) and a foot that screws to the
    back plate with 2 x M3. Print with the wall flat on the bed."""
    xw0 = SERVO_XF + EAR_BELOW_TOP
    wall = bx(xw0, xw0 + WALL_T, -17.5, 18.5, TAIL_Z + 3, TAIL_Z + 21)
    yc = BODY_Y0 + SERVO_L / 2
    wall -= bx(xw0 - 1, xw0 + WALL_T + 1, BODY_Y0 - 0.25, BODY_Y0 + SERVO_L + 0.25, ZC - SERVO_W / 2 - 0.25, ZC + SERVO_W / 2 + 0.25)
    for dy in (-13.9, 13.9):
        wall -= cylx(xw0 - 1, xw0 + WALL_T + 1, yc + dy, ZC, 1.6)
    foot = bx(xw0, 20.0, -17.5, 18.5, TAIL_Z + 21, TAIL_Z + 21 + FOOT_T)
    for hy in (-13.0, 14.0):
        foot -= Manifold.cylinder(FOOT_T + 2, M3_HOLE / 2, circular_segments=24).translate([14.5, hy, TAIL_Z + 20])
    return wall + foot


def servo_body() -> Manifold:
    """Servo outline (SG90): case 22.2 x 11.8 from the supplied spec, plus typical ears, boss and spline."""
    body = bx(SERVO_XF, SERVO_XF + SERVO_H, BODY_Y0, BODY_Y0 + SERVO_L, ZC - SERVO_W / 2, ZC + SERVO_W / 2)
    ear_y = (EAR_SPAN - SERVO_L) / 2
    ears = bx(SERVO_XF + EAR_BELOW_TOP - EAR_T, SERVO_XF + EAR_BELOW_TOP, BODY_Y0 - ear_y, BODY_Y0 + SERVO_L + ear_y,
              ZC - SERVO_W / 2, ZC + SERVO_W / 2)
    boss = cylx(SERVO_XF - 1.5, SERVO_XF, Y_S, ZC, 11.5) + cylx(SERVO_XF - SPLINE_H, SERVO_XF - 1.5, Y_S, ZC, 4.8)
    return body + ears + boss


def horn_and_pin(theta_deg: float) -> Manifold:
    """Single horn trimmed to 11 mm with an M2 / 2 mm steel pin at R_CRANK, at servo angle theta (0 = pin level with
    the shaft, +theta = pin further back)."""
    hx0, hx1 = SERVO_XF - SPLINE_H - HORN_T, SERVO_XF - SPLINE_H
    hub = cylx(hx0, hx1, Y_S, ZC, 7.0)
    arm = bx(hx0, hx1, 0, R_CRANK + 3.0, -2.5, 2.5).rotate([theta_deg, 0, 0]).translate([0, Y_S, ZC])
    th = math.radians(theta_deg)
    pin = cylx(hx0 - PIN_LEN, hx0, Y_S + R_CRANK * math.cos(th), ZC + R_CRANK * math.sin(th), PIN_D)
    return hub + arm, pin


def guide_plates() -> Manifold:
    hole = STEM + 2 * STEM_CLEAR
    out = None
    for z0, t in GUIDE_Z:
        p = bx(-PITCH / 2, PITCH / 2, -PITCH / 2, PITCH / 2, z0, z0 + t) - bx(-hole / 2, hole / 2, -hole / 2, hole / 2, z0 - 1, z0 + t + 1)
        out = p if out is None else out + p
    return out


def back_plate() -> Manifold:
    """3 mm acrylic back plate (one cell's worth), against the bracket foot."""
    z0 = TAIL_Z + 21 + FOOT_T
    return bx(-PITCH / 2, PITCH / 2, -PITCH / 2, PITCH / 2, z0, z0 + PLATE_T)


def stem_world() -> Manifold:
    """The stem in world frame (retracted): plate at the back of the head, tube behind it."""
    return tile_stem().translate([0, 0, GRID_H + PCB_T])


def diffuser_sheet() -> Manifold:
    return box(DIFFUSER, DIFFUSER, DIFFUSER_T)


def vol(m: Manifold) -> float:
    return m.volume() if hasattr(m, "volume") else m.get_properties().volume


def assembly():
    """Sweeps the stroke and reports any overlap between the moving set (head + stem + yoke) and the fixed set
    (servo, horn, pin, bracket, guide plates). Writes assembly STLs for viewing."""
    head = tile_head()
    stem = stem_world()
    yoke = tile_yoke()
    moving = head + stem + yoke
    servo = servo_body()
    bracket = servo_bracket()
    guides = guide_plates() + back_plate()
    print(f"  crank R {R_CRANK:.2f} mm, swing +-{TOTAL_ROT/2:.0f} deg of ~90, slot {SLOT_LEN:.2f} x {SLOT_W:.1f}, servo shaft y {Y_S:.2f}")
    worst = 0.0
    for k in range(9):
        p = STROKE * k / 8
        sin_t = (SIN_MAX * R_CRANK - p) / R_CRANK
        theta = math.degrees(math.asin(sin_t))
        horn, pin = horn_and_pin(theta)
        fixed = servo + bracket + guides + horn
        mv = moving.translate([0, 0, -p])
        ov = vol(mv ^ fixed) + vol(pin ^ mv)
        slot_margin = SLOT_LEN / 2 - (abs(Y_S + R_CRANK * math.cos(math.radians(theta))) + PIN_D / 2)
        worst = max(worst, ov)
        print(f"  p {p:5.2f} mm  theta {theta:+6.1f} deg  pin y {Y_S + R_CRANK*math.cos(math.radians(theta)):+5.2f}"
              f"  slot end margin {slot_margin:4.2f}  overlap {ov:.4f} mm3")
    assert worst < 1e-3, "COLLISION in stroke sweep"
    xs = [servo.bounding_box(), bracket.bounding_box(), yoke.bounding_box()]
    print(f"  fixed parts x range {min(b[0] for b in xs):.1f} .. {max(b[3] for b in xs):.1f} (cell edge at +-{PITCH/2:.1f})")
    depth_back = TAIL_Z + SERVO_W0 + SERVO_W / 2
    foot_back = TAIL_Z + 21 + FOOT_T
    print(f"  depth to bracket foot {foot_back:.1f} mm + back plate {PLATE_T:g} = {foot_back + PLATE_T:.1f} mm retracted "
          f"(+ {DIFFUSER_T:g} diffuser); tile out: {STROKE + DIFFUSER_T:.1f} mm beyond the rest face")
    for name, p in (("assembly_retracted.stl", 0.0), ("assembly_extended.stl", STROKE)):
        theta = math.degrees(math.asin((SIN_MAX * R_CRANK - p) / R_CRANK))
        horn, pin = horn_and_pin(theta)
        a = (moving + diffuser_sheet().translate([0, 0, -DIFFUSER_T])).translate([0, 0, -p]) + servo + bracket + guides + horn + pin
        save_stl(a, name)


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
        f'<!-- red hairline = cut. units: mm. Dither Board, rev 22 -->\n'
        f'<g fill="none" stroke="#ff0000" stroke-width="0.1" transform="translate({pad},{pad})">\n{body}</g>\n</svg>\n', name)
    print(f"  {name:28s} {w:6.1f} x {h:6.1f} mm")


def rect(x, y, w, h):
    return f'<rect x="{x:.2f}" y="{y:.2f}" width="{w:.2f}" height="{h:.2f}"/>\n'


def circ(x, y, d):
    return f'<circle cx="{x:.2f}" cy="{y:.2f}" r="{d/2:.2f}"/>\n'


def laser_parts():
    outer = N * PITCH + 2 * MARGIN
    bar_zone = 15.0                      # 5 mm gap + 10 mm status-bar window under the grid
    tall = outer + bar_zone
    corners = [(MARGIN / 2, MARGIN / 2), (outer - MARGIN / 2, MARGIN / 2),
               (MARGIN / 2, tall - MARGIN / 2), (outer - MARGIN / 2, tall - MARGIN / 2)]
    mount = "".join(circ(x, y, M3_HOLE) for x, y in corners)

    # front bezel: opening = full grid (each tile already has GAP/2 each side) + a slot for the 4 x 8-LED sticks (216 mm)
    bar = rect((outer - 216) / 2, MARGIN + N * PITCH + 5, 216, 10)
    body = rect(0, 0, outer, tall) + rect(MARGIN, MARGIN, N * PITCH, N * PITCH) + bar + mount
    svg("laser_front_bezel_black.pdf", outer, tall, body)

    # guide plates (front + rear identical): square holes for the stems
    hole = STEM + 2 * STEM_CLEAR
    holes = "".join(
        rect(MARGIN + c * PITCH + (PITCH - hole) / 2, MARGIN + r * PITCH + (PITCH - hole) / 2, hole, hole)
        for r in range(N) for c in range(N))
    body = rect(0, 0, outer, tall) + holes + mount
    svg("laser_guide_plate_x2.pdf", outer, tall, body)


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
    T(ax - 20, ay + HEAD * S + 56, f"{K}×{K} WS2812B-5050 LEDs, {LED_PITCH} mm pitch (premade module)", "start", "n")

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
    for ty, py, txt in [(by - 2, by + DIFFUSER_T * S / 2, "printed diffuser sheet, glued on"),
                        (by + 18, y + GRID_H * S / 2, "black PLA head + light grid (face-down)"),
                        (by + 38, y + (GRID_H + PCB_T / 2) * S, "5x5 LED module (LEDs face front)"),
                        (by + 58, y + (GRID_H + PCB_T + FLOOR_T / 2) * S, "stem floor plate (press fit)")]:
        o.append(f'<polyline points="{bx + HEAD*S + 2:.1f},{py:.1f} {lx - 4:.1f},{ty - 4:.1f}" class="dim" fill="none" opacity=".5"/>')
        T(lx, ty, txt, "start", "n")
    T(bx + HEAD * S + 8, sy + 60, "hollow stem: wires", "start", "n")
    T(bx + HEAD * S + 8, sy + 74, f"servo yoke on the tail", "start", "n")
    T(bx + HEAD * S + 8, sy + (STEM_LEN - 1) * S, f"M2 → yoke", "start", "n")

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
    T(cx0 + (MARGIN + 2 * PITCH) * s2 + 16, cy0 + 112, "REV 22 · units mm · servo scotch yoke, see assembly()", "start", "w")

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
    print(f"Grid {N}x{N} tiles, {K}x{K} LEDs each = {N*K}x{N*K} pixels, pitch {PITCH} mm, board {N*PITCH+2*MARGIN:g} mm")
    print(f"Head {HEAD:.1f} mm, cell {CELL:.2f} mm (opening {CELL-GRID_WALL:.2f} for a 5.0 mm LED), head height {HEAD_H:.1f} mm")
    save_stl(tile_head(), "tile_head.stl")
    save_stl(tile_stem(), "tile_stem.stl")
    save_stl(diffuser_sheet(), "diffuser_sheet.stl")
    save_stl(tile_yoke(), "yoke.stl")
    save_stl(servo_bracket(), "servo_bracket.stl")
    save_stl(clearance_coupon(), "test_clearance_coupon.stl")
    assembly()
    laser_parts()
    blueprint()
