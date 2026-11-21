"""Fabrication drawings for the Dither Board (A3 landscape PDF, one part per sheet).

Every number comes from tile.py (the same constants that make the STL and laser files), so the drawings cannot drift
from the models. Run:  /tmp/cadvenv/bin/python drawings.py   ->  out/fabrication-drawings.pdf

Frame used on every sheet: seen from the FRONT of the board, x to the right, y DOWN, z INTO the board (away from you).
The origin of a tile is the centre of its stem axis. Plates are drawn from the front with their top-left corner as the
datum (0, 0).
"""
import math
import numpy as np
import trimesh
import tile as T
from drawing_kit import *

OUT = T.OUT
N, K, PITCH, HEAD, MARGIN = T.N, T.K, T.PITCH, T.HEAD, T.MARGIN
W, H = T.OUTER_W, T.OUTER_H
ST = T.stack()
STEM, STEM_WALL, STEM_LEN = T.STEM, T.STEM_WALL, T.STEM_LEN
HOLE = STEM + 2 * T.STEM_CLEAR                    # square hole in the guide plates
BLADE_LEN = T.SERVO_W0 + T.SIN_MAX * T.R_CRANK + T.SLOT_W / 2 + 2.0
ZS = T.SERVO_W0 + T.SIN_MAX * T.R_CRANK            # slot centre, measured from the stem cap back face
BR_WALL_Y = (-17.5, 18.5)
CUT_Y = (T.BODY_Y0 - 0.25, T.BODY_Y0 + T.SERVO_L + 0.25)
CUT_Z = (T.SERVO_W0 - T.SERVO_W / 2 - 0.25, T.SERVO_W0 + T.SERVO_W / 2 + 0.25)   # relative to TAIL_Z
EAR_HOLE_Y = (T.BODY_Y0 + T.SERVO_L / 2 - 13.9, T.BODY_Y0 + T.SERVO_L / 2 + 13.9)
XW0 = T.SERVO_XF + T.EAR_BELOW_TOP
NEW = "NEW (proposed in rev 27): confirm before cutting"
TOTAL = 12


def check_models():
    """Drawn overall sizes must equal the STL bounding boxes."""
    want = {
        "tile_head.stl": (HEAD, HEAD, T.HEAD_H),
        "tile_stem.stl": (T.RIM_INNER - 2 * T.FIT, T.RIM_INNER - 2 * T.FIT, STEM_LEN + T.FLOOR_T),
        "diffuser_sheet.stl": (T.DIFFUSER, T.DIFFUSER, T.DIFFUSER_T),
        "yoke.stl": (1.0 - T.BLADE_X0, 16.0, BLADE_LEN),
        "servo_bracket.stl": (20.0 - XW0, 36.0, 21 + T.FOOT_T - 3),
    }
    for name, dims in want.items():
        b = trimesh.load(OUT / name).bounds
        got = tuple(float(x) for x in (b[1] - b[0]))
        assert all(abs(g - d) < 0.02 for g, d in zip(got, dims)), (name, got, dims)
    assert abs(MARGIN * 2 + N * PITCH - W) < 1e-9 and abs(W - 235) < 1e-9
    assert abs(sum(ST["spacers"]) + 3 * T.PLATE_T + T.BEZEL_T - ST["total"]) < 1e-9
    assert abs(ST["total"] - 78.9) < 1e-6


# ------------------------------------------------------------------------------------------------ shared drawers
PX, PY = 20, 272          # page position of a plate's top-left corner on the 1:1 plate sheets


def plate_view(pg):
    return View(pg, PX, PY, 1.0)


def plate_outline(v, cs=False):
    v.rect(0, 0, W, H, 0.5)
    for x, y in T.rod_points():
        v.circle(x, y, T.M3_HOLE, 0.4)
        v.centre_cross(x, y, 3.2)
        if cs:
            v.circle(x, y, 6.4, 0.2, GREY, [1, 0.6])


def bolt_dims(v):
    """The 8 bolt holes sit 5 mm from the edges; the mid-edge ones are on the centre lines."""
    v.dh(0, 5, 0, -6, "5")
    v.dh(5, W / 2, 0, -12, f"{W / 2 - 5:g}")
    v.dh(W / 2, W - 5, 0, -12, f"{W / 2 - 5:g}")
    v.dh(W - 5, W, 0, -6, "5")
    v.dv(0, 5, 0, -6, "5")
    v.dv(5, H / 2, 0, -12, f"{H / 2 - 5:g}")
    v.dv(H / 2, H - 5, 0, -12, f"{H / 2 - 5:g}")
    v.dv(H - 5, H, 0, -6, "5")


def overall_dims(v):
    v.dh(0, W, H, 8, f"{W:g}")
    v.dv(0, H, W, 7, f"{H:g}")


def side_notes(pg, x, y, title, lines, width, size=2.7):
    pg.t(x, y, title, 3.4, BOLD)
    return pg.text_block(x, y - 5.5, lines, size, 4.0, width=width)


# ------------------------------------------------------------------------------------------------ sheet 1
def sheet_general(pg):
    pg.new("General arrangement", "1 : 1.5", "Front view and side views of the whole board (retracted, and with some tiles pushed out).",
           1, TOTAL, "GA-01")
    k = 1 / 1.5
    v = View(pg, 24, 262, k)
    pg.t(24, 273, "FRONT VIEW  (looking at the board)", 3.6, BOLD)
    v.rect(0, 0, W, H, 0.5)
    v.rect(MARGIN, MARGIN, MARGIN + N * PITCH, MARGIN + N * PITCH, 0.3, GREY, [2, 1])
    for r in range(N):
        for c in range(N):
            cx, cy = T.cell_centre(r, c)
            v.rect(cx - HEAD / 2, cy - HEAD / 2, cx + HEAD / 2, cy + HEAD / 2, 0.3, INK, None, LIGHT)
            for i in range(1, K):
                o = -K * T.CELL / 2 + i * T.CELL
                v.line(cx + o, cy - T.RIM_INNER / 2, cx + o, cy + T.RIM_INNER / 2, 0.1, GREY)
                v.line(cx - T.RIM_INNER / 2, cy + o, cx + T.RIM_INNER / 2, cy + o, 0.1, GREY)
    bar_x0 = (W - 216) / 2
    bar_y0 = MARGIN + N * PITCH + 5
    v.rect(bar_x0, bar_y0, bar_x0 + 216, bar_y0 + 10, 0.4, INK, None, HexColor("#fff3cc"))
    for x, y in T.rod_points():
        v.circle(x, y, 4.0, 0.4, INK, None, white)
    v.text(W / 2, bar_y0 + 5, "STATUS BAR SLOT", 2.4, BOLD, INK, "c", dy=-0.8)
    v.dh(0, W, H, 8, f"{W:g}")
    v.dv(0, H, W, 8, f"{H:g}")
    v.dh(MARGIN, MARGIN + N * PITCH, H, 16, f"5 tiles × {PITCH:g} = {N * PITCH:g}")
    v.dv(MARGIN, MARGIN + N * PITCH, 0, -8, f"{N * PITCH:g}")
    v.dv(0, MARGIN, 0, -16, f"{MARGIN:g}")
    v.leader(W - 5, 5, -16, 14, "8 bolt holes Ø3.2 (corners + mid-edges)", 2.4)
    v.leader(W / 2 + 60, bar_y0 + 10, 14, -12, f"bar slot 216 × 10 at y = {bar_y0:g}", 2.4)
    for ox, label, offs in ((205, "VIEW FROM THE RIGHT, all tiles retracted", [0] * N),
                            (268, "SAME, rows 2, 3 and 5 pushed out", [0, 15, 7.5, 0, 15])):
        pg.t(ox - 6, 273, label, 2.8, BOLD)
        s = View(pg, ox, 262, k)
        s.rect(ST["bezel"][0], 0, ST["bezel"][1], H, 0.4, INK, None, HexColor("#444444"))
        for g in ("guide1", "guide2", "back"):
            s.rect(ST[g][0], 0, ST[g][1], H, 0.35, INK, None, LIGHT)
        for r in range(N):
            cy = MARGIN + r * PITCH + PITCH / 2
            p = offs[r]
            s.rect(-p - T.DIFFUSER_T, cy - T.DIFFUSER / 2, -p, cy + T.DIFFUSER / 2, 0.3, INK, None, HexColor("#cdb8f0"))
            s.rect(-p, cy - HEAD / 2, -p + T.HEAD_H, cy + HEAD / 2, 0.3, INK, None, HexColor("#555555"))
            s.rect(-p + T.HEAD_H, cy - STEM / 2, -p + T.TAIL_Z, cy + STEM / 2, 0.3, INK, None, white)
            s.rect(ST["guide2"][1], cy - 18, ST["back"][0], cy + 18, 0.2, GREY, [1, 1])
    View(pg, 205, 262, k).dh(ST["bezel"][0], ST["back"][1], H, 8, f"{ST['total']:.1f} deep, retracted")
    s1 = View(pg, 268, 262, k)
    s1.dh(-15 - T.DIFFUSER_T, 0, H, 8, "15 stroke")
    pg.t(262, 84, "(front of the board is on the left in both side views)", 2.4, FONT, GREY)
    pg.text_block(24, 62, [
        "Plates: bezel, two guide plates and back plate, all 3 mm acrylic, 235 × 250, held 78.9 mm apart by 8 bolts and spacer tubes.",
        "Each of the 25 tiles is a printed head carrying one 5 × 5 LED module, a hollow stem sliding through both guide plates, and a yoke on the stem's tail; an SG90 servo on the back plate pushes the yoke 15 mm.",
        "Datum on every plate: top-left corner as seen from the FRONT of the board. x right, y down, z into the board.",
    ], 2.7, 4.0, width=200)


# ------------------------------------------------------------------------------------------------ sheet 2
def side_tile(v, p, theta_pin):
    """One tile in side view (y down, z right), pushed out by p mm. Fixed parts stay."""
    z = lambda a: a - p
    for g in ("guide1", "guide2"):
        a0, a1 = ST[g]
        v.rect(a0, -21.5, a1, -HOLE / 2, 0.4, INK, None, LIGHT)
        v.rect(a0, HOLE / 2, a1, 21.5, 0.4, INK, None, LIGHT)
    a0, a1 = ST["back"]
    v.rect(a0, -21.5, a1, 21.5, 0.4, INK, None, LIGHT)
    foot0 = T.TAIL_Z + 21
    v.rect(foot0, BR_WALL_Y[0], foot0 + T.FOOT_T, BR_WALL_Y[1], 0.4, INK, None, white)
    v.rect(T.TAIL_Z + 3, BR_WALL_Y[0], foot0, BR_WALL_Y[1], 0.25, GREY, [1.2, 0.8])
    v.rect(T.ZC - T.SERVO_W / 2, T.BODY_Y0, T.ZC + T.SERVO_W / 2, T.BODY_Y0 + T.SERVO_L, 0.45, INK, None, HexColor("#9fc5e8"))
    # moving parts
    v.rect(z(-T.DIFFUSER_T), -T.DIFFUSER / 2, z(0), T.DIFFUSER / 2, 0.35, INK, None, HexColor("#cdb8f0"))
    v.rect(z(0), -HEAD / 2, z(T.HEAD_H), HEAD / 2, 0.4, INK, None, HexColor("#8f8f8f"))
    v.rect(z(T.HEAD_H), -STEM / 2, z(T.TAIL_Z), STEM / 2, 0.4, INK, None, white)
    v.rect(z(T.HEAD_H), -STEM / 2 + STEM_WALL, z(T.TAIL_Z - T.END_CAP), STEM / 2 - STEM_WALL, 0.15, GREY, [1, 1])
    v.rect(z(T.TAIL_Z), -8, z(T.TAIL_Z + 2), 8, 0.4, INK, None, HexColor("#f4b183"))
    v.rect(z(T.TAIL_Z), -7.6, z(T.TAIL_Z + BLADE_LEN), 7.6, 0.4, INK, None, HexColor("#f4b183"), alpha=0.7)
    v.rect(z(T.TAIL_Z + ZS - T.SLOT_W / 2), -T.SLOT_LEN / 2, z(T.TAIL_Z + ZS + T.SLOT_W / 2), T.SLOT_LEN / 2, 0.3, INK, None, white)
    # horn arm and pin on top
    zc, yc = T.ZC, T.Y_S
    th = math.radians(theta_pin)
    pz, py = zc + T.R_CRANK * math.sin(th), yc + T.R_CRANK * math.cos(th)
    v.line(zc, yc, pz, py, 1.6, INK)
    v.circle(zc, yc, 5.0, 0.3, INK, None, white)
    v.circle(pz, py, T.PIN_D, 0.3, INK, None, white)


def sheet_section(pg):
    pg.new("One tile, side view (stack and stroke)", "2 : 1",
           "View from the right. Top: retracted (flush). Bottom: pushed out 15 mm.", 2, TOTAL, "GA-02")
    k = 2.0
    for oy, p in ((205, 0.0), (84, 15.0)):
        v = View(pg, 58, oy, k)
        theta = math.degrees(math.asin((T.SIN_MAX * T.R_CRANK - p) / T.R_CRANK))
        side_tile(v, p, theta)
        if p == 0:
            pg.t(12, 275, "RETRACTED (flush)", 3.6, BOLD)
            pg.t(58 - 2, 281.5, "z from the head front face (0), mm:", 2.4, FONT, BLUE)
            ords = [(0, "0"), (T.HEAD_H, "11.6"), (ST["guide1"][0], "12.6"), (ST["guide1"][1], "15.6"), (ST["guide2"][0], "30"),
                    (ST["guide2"][1], "33"), (T.TAIL_Z, "51.6"), (ST["back"][0], "75.1"), (ST["back"][1], "78.1")]
            for i, (zz, txt) in enumerate(ords):
                lvl = 27 + (i % 2) * 4
                v.line(zz, -21.5, zz, -lvl, 0.12, BLUE)
                v.text(zz, -lvl, txt, 2.2, FONT, BLUE, "c", dy=1.0)
            v.dh(ST["bezel"][0], ST["back"][1], 21.5, 8, f"{ST['total']:.1f} mm total depth (bezel front to back plate rear)")
            v.dh(0, T.HEAD_H, 21.5, 16, "11.6 head")
            v.dh(T.HEAD_H, T.TAIL_Z, 21.5, 16, "40 stem")
            v.dv(-HEAD / 2, HEAD / 2, -T.DIFFUSER_T, -8, "42")
            v.balloon(ST["guide1"][0] + 1.5, 18, 8, -9, 2)
            v.balloon(ST["back"][0] + 1.5, 18, 8, -9, 3)
            v.balloon(T.HEAD_H / 2, -14, 0, 9, 4)
            v.balloon(-0.4, -20.7, -9, 3, 5)
            v.balloon(T.HEAD_H + 18, 9.2, 0, -11, 6)
            v.balloon(T.TAIL_Z + BLADE_LEN - 3, -7.6, 0, 11, 7)
            v.balloon(T.TAIL_Z + 12, 17.8, 0, -9, 8)
        else:
            pg.t(12, 134, "PUSHED OUT 15 mm", 3.6, BOLD)
            v.dh(-p - T.DIFFUSER_T, 0, 21.5, 8, "15 stroke")
    pg.text_block(250, 262, [
        "PARTS  (sheet numbers in brackets)",
        "1 Bezel (4)   2 Guide plate ×2 (5)   3 Back plate (6)",
        "4 Tile head (7)   5 Diffuser sheet (11)   6 Tile stem (8)",
        "7 Yoke (9)   8 Servo bracket (10)",
        "",
        "The thick line is the servo horn, from the servo shaft (circle) to the 2 mm pin. Retracted: the pin is 7.5 mm behind the shaft line and the horn is at +75°. Pushed out: -75°.",
        "",
        "The servo, bracket, plates and horn never move. The head, diffuser, stem and yoke slide 15 mm toward the front.",
        "Head back face to the front guide plate: 1.0 mm gap when retracted. Do not make it smaller.",
        "Yoke blade rear edge to the back plate: 0.85 mm gap when retracted.",
    ], 2.7, 4.0, width=150)


# ------------------------------------------------------------------------------------------------ sheet 3
def sheet_cell(pg):
    pg.new("One tile cell from the front", "3 : 1",
           "Looking toward the back from just behind the rear guide plate. x right, y down; every cell is identical.", 3, TOTAL, "GA-03")
    k = 3.0
    # -------- A: fixed parts
    v = View(pg, 100, 172, k)
    pg.t(30, 273, "A  FIXED PARTS: servo, bracket, back plate", 3.4, BOLD)
    v.rect(-21.5, -21.5, 21.5, 21.5, 0.25, GREY, [3, 1, 0.5, 1])
    v.centre_cross(0, 0, 24)
    for hx, hy in T.FOOT_HOLES:
        v.circle(hx, hy, T.M3_HOLE, 0.45)
        v.centre_cross(hx, hy, 3)
    v.rect(T.CABLE_X0, -17.5, T.CABLE_X1, T.CABLE_Y1, 0.5, RED)
    v.poly([(XW0, -17.5), (T.CABLE_X0, -17.5), (T.CABLE_X0, T.CABLE_Y1), (T.CABLE_X1, T.CABLE_Y1), (T.CABLE_X1, -17.5),
            (20.0, -17.5), (20.0, 18.5), (XW0, 18.5)], 0.4, INK, [2.2, 0.9])
    v.rect(XW0, -17.5, XW0 + T.WALL_T, 18.5, 0.4, INK, None, LIGHT)
    v.rect(T.SERVO_XF, T.BODY_Y0, T.SERVO_XF + T.SERVO_H, T.BODY_Y0 + T.SERVO_L, 0.5, INK, None, None)
    ear_y = (T.EAR_SPAN - T.SERVO_L) / 2
    v.rect(XW0 - T.EAR_T, T.BODY_Y0 - ear_y, XW0, T.BODY_Y0 + T.SERVO_L + ear_y, 0.3, INK, [1.5, 0.8])
    v.line(T.SERVO_XF - 3, T.Y_S, T.SERVO_XF + T.SERVO_H, T.Y_S, 0.15, GREY, [2, 0.6, 0.4, 0.6])
    # dims
    v.dh(XW0, 20.0, -17.5, -8, "19.5 foot")
    v.dh(0, 14.5, 18.5, 8, "14.5")
    v.dh(XW0, T.CABLE_X0, 18.5, 17, "3") if False else None
    v.dh(T.CABLE_X0, T.CABLE_X1, -17.5, -16, "7 notch")
    v.dh(0, T.CABLE_X0, -17.5, -16, "3.5")
    v.dv(0, -13, 20.0, 8, "13")
    v.dv(0, 14, 20.0, 16, "14")
    v.dv(-17.5, T.CABLE_Y1, T.CABLE_X1, 8 + 40, "6")
    v.dv(-17.5, 18.5, T.SERVO_XF, -22, "36 bracket")
    v.dv(T.BODY_Y0, T.BODY_Y0 + T.SERVO_L, T.SERVO_XF, -10, f"{T.SERVO_L:g} servo")
    v.dv(0, T.Y_S, T.SERVO_XF, -16 + 8, "") if False else None
    v.leader(T.SERVO_XF + 6, T.Y_S, -20, 18, f"shaft axis y = {T.Y_S:+.2f}", 2.3, GREY)
    v.leader(14.5, 14, 14, -5, "Ø3.2 foot hole", 2.3)
    v.leader(8, -14.5, 18, 11, "cable notch (NEW)", 2.3, RED)
    # -------- B: moving parts
    m = View(pg, 270, 172, k)
    pg.t(205, 273, "B  MOVING PARTS: stem (cut), yoke", 3.4, BOLD)
    m.rect(-21.5, -21.5, 21.5, 21.5, 0.25, GREY, [3, 1, 0.5, 1])
    m.centre_cross(0, 0, 24)
    m.rect(T.BLADE_X0, -8, 1.0, 8, 0.3, INK, [1.5, 0.8])
    m.rect(T.BLADE_X0, -7.6, T.BLADE_X0 + T.BLADE_T, 7.6, 0.45, INK, None, HexColor("#f4b183"))
    m.rect(-STEM / 2, -STEM / 2, STEM / 2, STEM / 2, 0.5, INK, None, white)
    m.hatch([[(-STEM / 2, -STEM / 2), (STEM / 2, -STEM / 2), (STEM / 2, STEM / 2), (-STEM / 2, STEM / 2)]])
    m.rect(-STEM / 2 + STEM_WALL, -STEM / 2 + STEM_WALL, STEM / 2 - STEM_WALL, STEM / 2 - STEM_WALL, 0.4, INK, None, white)
    m.rect(STEM / 2 - STEM_WALL, -4, STEM / 2, 4, 0.4, RED, [1, 0.6])
    for sy in (-5.5, 5.5):
        m.circle(-6.0, sy, T.M2_PILOT, 0.35, INK, [1, 0.6])
    m.dh(-STEM / 2, STEM / 2, STEM / 2, 9, "20 stem")
    m.dh(T.BLADE_X0, 0, -8, -9, "16.5 to the blade")
    m.dh(T.BLADE_X0, T.BLADE_X0 + T.BLADE_T, 7.6, 17, "3 blade")
    m.dv(-7.6, 7.6, T.BLADE_X0, -9, "15.2")
    m.dv(-5.5, 5.5, -6.0, 0, "") if False else None
    m.dv(-STEM / 2, STEM / 2, STEM / 2, 9, "20")
    m.dv(-4, 4, STEM / 2, 18, "8")
    m.leader(-6.0, -5.5, 6, 18, "2 × Ø1.8 pilot (stem cap) under 2 × Ø2.2 (yoke)", 2.3)
    m.leader(STEM / 2 - 0.5, 0, 14, -14, "wire slot, 8 wide (behind the cut)", 2.3, RED)
    m.leader(T.BLADE_X0 + 1.5, 7.6, -4, 24, "yoke blade (behind the cut)", 2.3)
    pg.text_block(24, 98, [
        "READ THIS FIRST",
        "The cell is 43 × 43 mm and the stem axis is its centre (0, 0). Every one of the 25 tiles has the SAME orientation: servo lying along x, bracket foot to the right, cable notch at the top right.",
        "Foot holes: two Ø3.2 holes through the bracket foot and the back plate at (14.5, -13) and (14.5, +14). Two M3 × 10 screws with nuts behind the back plate fix the bracket. (This is what the '2 foot holes' per cell on the back plate are.)",
        "Cable notch (NEW): the module cable and the servo lead leave the cell through a 7 × 6 notch in the foot and a matching slot in the back plate, at x 3.5 to 10.5 and y -17.5 to -11.5.",
        "The servo shaft is 4.89 mm toward the top of the board from the stem axis, so that the pin's travel is centred on the stem. The servo case is 22.2 long (y) × 11.8 wide (z); it is centred on y = +0.215.",
    ], 2.7, 4.0, width=235)


# ------------------------------------------------------------------------------------------------ plates
def sheet_bezel(pg):
    pg.new("Front bezel", "1 : 1", "Laser cut. 3 mm black acrylic. Seen from the FRONT. Datum: top-left corner (0, 0).", 4, TOTAL, "P-01",
           "acrylic 3 mm, 1 off")
    v = plate_view(pg)
    plate_outline(v, True)
    v.rect(MARGIN, MARGIN, MARGIN + N * PITCH, MARGIN + N * PITCH, 0.5, INK, None, white)
    bar_x0 = (W - 216) / 2
    bar_y0 = MARGIN + N * PITCH + 5
    v.rect(bar_x0, bar_y0, bar_x0 + 216, bar_y0 + 10, 0.5, INK, None, white)
    overall_dims(v)
    bolt_dims(v)
    v.text(MARGIN + 5, MARGIN + 10, f"WINDOW  {N * PITCH:g} × {N * PITCH:g}", 3.4, BOLD)
    v.text(MARGIN + 5, MARGIN + 16, "its top-left corner is at (10, 10)", 2.6, FONT, GREY)
    v.dh(0, MARGIN, 60, 0, "10")
    v.dv(0, MARGIN, 60, 0, "") if False else None
    v.dh(MARGIN, MARGIN + N * PITCH, 100, 0, f"{N * PITCH:g}")
    v.dv(MARGIN, MARGIN + N * PITCH, 100, 0, f"{N * PITCH:g}")
    v.dv(0, MARGIN, 130, 0, "10")
    v.dv(MARGIN + N * PITCH, bar_y0, 20, 0, "5")
    v.dv(bar_y0, bar_y0 + 10, 60, 0, "10")
    v.dh(bar_x0, bar_x0 + 216, bar_y0 + 5, 0, "216")
    v.dh(0, bar_x0, bar_y0 + 5, 0, "9.5")
    v.dv(0, bar_y0, W - 12, 0, f"{bar_y0:g}")
    side_notes(pg, 280, 262, "BEZEL", [
        "Outer 235 × 250.",
        "Window 215 × 215 with its top-left corner at (10, 10): the heads show through it.",
        "Bar slot 216 × 10 with its top-left corner at (9.5, 230).",
        "8 × Ø3.2 bolt holes, 5 mm from the edges: the 4 corners and the 4 edge mid-points (117.5, 5), (5, 125), (230, 125), (117.5, 245).",
        "Countersink the 8 holes from the FRONT (dashed Ø6.4 circle) with a 90° countersink bit so the M3 flat-head bolts sit flush.",
        "",
        NEW + ": the 4 mid-edge holes (the old file had only 4 corners). The bar slot assumes four 54 × 10 mm sticks: check the real stick size.",
        "",
        "The front face of the bezel is flush with the front of the diffuser when the tiles are retracted.",
    ], 125)


def sheet_guide(pg):
    pg.new("Guide plate", "1 : 1  (detail 2.5 : 1)", "Laser cut. 3 mm acrylic. Two identical plates. Seen from the FRONT. Datum: top-left.", 5, TOTAL, "P-02",
           "acrylic 3 mm, 2 off")
    v = plate_view(pg)
    plate_outline(v)
    first = MARGIN + (PITCH - HOLE) / 2
    for r in range(N):
        for c in range(N):
            a0, b0 = first + c * PITCH, first + r * PITCH
            v.rect(a0, b0, a0 + HOLE, b0 + HOLE, 0.45)
            cx, cy = T.cell_centre(r, c)
            v.centre_cross(cx, cy, 3)
    overall_dims(v)
    bolt_dims(v)
    # first row / column
    yy = first + HOLE / 2
    v.dh(0, first, yy, 0, f"{first:g}")
    v.dh(first, first + HOLE, yy, 0, f"{HOLE:g}")
    v.dh(first + HOLE, first + PITCH, yy, 0, f"{PITCH - HOLE:g}")
    xx = first / 2 + 2
    v.dv(0, first, xx, 0, f"{first:g}")
    v.dv(first, first + HOLE, xx, 0, f"{HOLE:g}")
    v.dv(first + HOLE, first + PITCH, xx, 0, f"{PITCH - HOLE:g}")
    v.text(W / 2, H - 14, "25 SQUARE HOLES 20.5 × 20.5, 5 × 5, pitch 43", 3.0, BOLD, INK, "c")
    d = View(pg, 345, 200, 2.5)
    pg.t(284, 272, "DETAIL: ONE HOLE (2.5 : 1)", 3.2, BOLD)
    d.rect(-PITCH / 2, -PITCH / 2, PITCH / 2, PITCH / 2, 0.25, GREY, [2, 1])
    d.rect(-HOLE / 2, -HOLE / 2, HOLE / 2, HOLE / 2, 0.5)
    d.rect(-STEM / 2, -STEM / 2, STEM / 2, STEM / 2, 0.3, GREY, [1.5, 1])
    d.centre_cross(0, 0, 14)
    d.dh(-HOLE / 2, HOLE / 2, HOLE / 2, 8, f"{HOLE:g}")
    d.dv(-HOLE / 2, HOLE / 2, HOLE / 2, 8, f"{HOLE:g}")
    d.dh(-PITCH / 2, PITCH / 2, -PITCH / 2, -8, "43 pitch (cell)")
    pg.t(284, 140, "dashed inner square: the 20 mm stem; clearance 0.25 each side (20 + 2 × 0.25)", 2.4, FONT, GREY)
    side_notes(pg, 284, 128, "GUIDE PLATE", [
        "First hole's top-left corner at (21.25, 21.25). Then every 43 mm in x and y: 5 × 5 = 25 holes.",
        "Holes are SQUARE 20.5 × 20.5. A laser leaves a small corner radius; that is fine.",
        "8 × Ø3.2 bolt holes as on the bezel, no countersink.",
        "Cut two. The front one sits 1.0 mm behind the head, the rear one 14.4 mm behind the front one.",
        "",
        "Fit the stems with test_clearance_coupon.stl first: 0.25 per side is the default; 0.20 if loose, 0.30 if it binds.",
    ], 125)


def sheet_back(pg):
    pg.new("Back plate", "1 : 1  (detail 2.5 : 1)", "Laser cut. 3 mm acrylic. Seen from the FRONT (the side the servos are on). Datum: top-left.", 6, TOTAL, "P-03",
           "acrylic 3 mm, 1 off")
    v = plate_view(pg)
    plate_outline(v)
    for r in range(N):
        for c in range(N):
            cx, cy = T.cell_centre(r, c)
            for hx, hy in T.FOOT_HOLES:
                v.circle(cx + hx, cy + hy, T.M3_HOLE, 0.4)
            v.rect(cx + T.CABLE_X0, cy - 17.5, cx + T.CABLE_X1, cy + T.CABLE_Y1, 0.4, RED)
            v.centre_cross(cx, cy, 2, 0.12)
    overall_dims(v)
    bolt_dims(v)
    c0 = T.cell_centre(0, 0)
    v.dh(0, c0[0], c0[1], 0, f"{c0[0]:g}")
    v.dh(c0[0], c0[0] + PITCH, c0[1], 0, f"{PITCH:g}")
    v.dv(0, c0[1], c0[0], 0, f"{c0[1]:g}")
    v.dv(c0[1], c0[1] + PITCH, c0[0], 0, f"{PITCH:g}")
    v.text(W / 2, H - 14, "25 identical cells: 2 × Ø3.2 + one slot 7 × 6 in each", 3.0, BOLD, INK, "c")
    d = View(pg, 345, 214, 2.5)
    pg.t(284, 272, "DETAIL: ONE CELL (2.5 : 1)", 3.2, BOLD)
    d.rect(-21.5, -21.5, 21.5, 21.5, 0.25, GREY, [3, 1, 0.5, 1])
    d.centre_cross(0, 0, 24)
    for hx, hy in T.FOOT_HOLES:
        d.circle(hx, hy, T.M3_HOLE, 0.5)
        d.centre_cross(hx, hy, 3)
    d.rect(T.CABLE_X0, -17.5, T.CABLE_X1, T.CABLE_Y1, 0.5, RED)
    d.dh(0, 14.5, 21.5, 8, "14.5")
    d.dh(0, T.CABLE_X0, -17.5, -8, "3.5")
    d.dh(T.CABLE_X0, T.CABLE_X1, -17.5, -16, "7")
    d.dv(0, -13, 14.5, 12, "13")
    d.dv(0, 14, 14.5, 20, "14")
    d.dv(-17.5, T.CABLE_Y1, T.CABLE_X0, -8, "6")
    d.text(0, 0, "cell centre = tile axis", 2.3, FONT, GREY, dx=-30, dy=-6) if False else None
    side_notes(pg, 284, 150, "BACK PLATE", [
        "Cell (row r, column c) centre = (31.5 + 43 c, 31.5 + 43 r), counting from 0.",
        "Per cell, relative to its centre: M3 holes at (+14.5, -13) and (+14.5, +14); cable slot x +3.5 to +10.5, y -17.5 to -11.5.",
        "8 × Ø3.2 bolt holes as on the other plates.",
        "",
        "Do not mirror it: this is the view from the FRONT, and the two foot holes are not symmetrical.",
        NEW + ": the cable slots.",
        "3 mm acrylic carries about 0.5 kg of servos on 8 edge bolts. If it sags, use 5 mm: nothing else changes (the bolt just needs to be 2 mm longer).",
    ], 125, 2.6)


# ------------------------------------------------------------------------------------------------ head
def sheet_head(pg):
    pg.new("Tile head", "3 : 1", "3D print, black PLA, printed FACE DOWN (front face on the bed). 25 off.", 7, TOTAL, "T-01",
           "black PLA, 25 off")
    k = 3.0
    v = View(pg, 95, 190, k)
    pg.t(30, 273, "FRONT VIEW", 3.6, BOLD)
    v.rect(-HEAD / 2, -HEAD / 2, HEAD / 2, HEAD / 2, 0.5)
    v.rect(-HEAD / 2 + T.CHAMFER, -HEAD / 2 + T.CHAMFER, HEAD / 2 - T.CHAMFER, HEAD / 2 - T.CHAMFER, 0.15, GREY)
    v.rect(-T.RIM_INNER / 2, -T.RIM_INNER / 2, T.RIM_INNER / 2, T.RIM_INNER / 2, 0.5)
    for i in range(1, K):
        o = -K * T.CELL / 2 + i * T.CELL
        v.rect(o - T.GRID_WALL / 2, -T.RIM_INNER / 2, o + T.GRID_WALL / 2, T.RIM_INNER / 2, 0.3, INK, None, LIGHT)
        v.rect(-T.RIM_INNER / 2, o - T.GRID_WALL / 2, T.RIM_INNER / 2, o + T.GRID_WALL / 2, 0.3, INK, None, LIGHT)
    v.centre_cross(0, 0, 25)
    v.dh(-HEAD / 2, HEAD / 2, HEAD / 2, 8, f"{HEAD:g}")
    v.dh(-T.RIM_INNER / 2, T.RIM_INNER / 2, HEAD / 2, 16, f"{T.RIM_INNER:g} inside")
    v.dv(-HEAD / 2, HEAD / 2, -HEAD / 2, -8, f"{HEAD:g}")
    o1 = -K * T.CELL / 2 + T.CELL
    o2 = o1 + T.CELL
    v.dh(-HEAD / 2, -T.RIM_INNER / 2, -HEAD / 2, -8, f"{T.RIM_WALL:g} rim")
    v.dh(o1, o2, -HEAD / 2, -8, f"{T.CELL:g} pitch")
    v.dh(o1 - T.GRID_WALL / 2, o1 + T.GRID_WALL / 2, -HEAD / 2, -17, f"{T.GRID_WALL:g} wall")
    v.dh(o1 + T.GRID_WALL / 2, o2 - T.GRID_WALL / 2, -HEAD / 2, -26, f"{T.CELL - T.GRID_WALL:g} opening")
    v.dv(-T.RIM_INNER / 2, o1 - T.GRID_WALL / 2, HEAD / 2, 8, f"{o1 - T.GRID_WALL / 2 + T.RIM_INNER / 2:.1f}")
    s = View(pg, 225, 190, k)
    pg.t(190, 273, "SECTION A-A  (cut through the centre, looking from the right)", 3.6, BOLD)
    h = T.HEAD_H
    zf = T.GRID_H
    for y0, y1 in ((-HEAD / 2, -T.RIM_INNER / 2), (T.RIM_INNER / 2, HEAD / 2)):
        s.section_rect(0, y0, h, y1)
    for i in range(1, K):
        o = -K * T.CELL / 2 + i * T.CELL
        s.section_rect(0, o - T.GRID_WALL / 2, zf, o + T.GRID_WALL / 2)
    s.line(zf, -T.RIM_INNER / 2, zf, T.RIM_INNER / 2, 0.15, GREY, [1, 1])
    s.line(zf + T.PCB_T, -T.RIM_INNER / 2, zf + T.PCB_T, T.RIM_INNER / 2, 0.15, GREY, [1, 1])
    s.dh(0, h, HEAD / 2, 8, f"{h:g} deep")
    s.dh(0, zf, -HEAD / 2, -8, f"{zf:g} light grid")
    s.dh(zf, h, -HEAD / 2, -17, f"{h - zf:g} pocket")
    s.dh(zf, zf + T.PCB_T, HEAD / 2, 16, f"{T.PCB_T:g}")
    s.dh(zf + T.PCB_T, h, HEAD / 2, 16, f"{T.FLOOR_T:g}")
    s.dv(-HEAD / 2, HEAD / 2, h, 8, f"{HEAD:g}")
    pg.t(188, 112, "dashed lines: module 1.6 thick (CONFIRM) then stem floor plate 2", 2.4, FONT, RED)
    pg.t(188, 108, "front face (z = 0, left): the diffuser is glued here", 2.4, FONT, GREY)
    pg.text_block(24, 98, [
        "TILE HEAD",
        "A 42 × 42 × 11.6 box, open front to back, with a 5 × 5 light grid at the front: 4 walls each way, 1.0 thick, 8 tall.",
        "Cell pitch 7.8 = the LED pitch of the module; opening 6.8 for a 5 mm LED. The first wall's centre is 9.3 from the outer edge.",
        "Behind the grid is a 3.6 deep pocket, 39.6 × 39.6: the 39 × 39 LED module sits in it (0.3 free each side) and the stem's floor plate presses in behind it.",
        "Print face down: the grid starts on the bed, so the cells need no supports. 0.4 × 45° chamfer on the front outer edge (first layer).",
        "Black PLA. Glue the diffuser sheet on the front face.",
    ], 2.7, 4.0, width=165)
    pg.text_block(205, 96, [
        "TO CONFIRM",
        "Module thickness is assumed 1.6 mm (the modules have not arrived). The 3.6 pocket = 1.6 + 2.0 follows from it. If the real module is thicker, make the pocket deeper and keep the 2.0 for the floor plate.",
        "The module's pad layout is not drawn because it is not known yet.",
    ], 2.7, 4.0, width=130)


# ------------------------------------------------------------------------------------------------ stem
def sheet_stem(pg):
    pg.new("Tile stem", "2 : 1  (end view 3 : 1)", "3D print, PLA, printed UPRIGHT (floor plate on the bed). 25 off.", 8, TOTAL, "T-02", "PLA, 25 off")
    k = 2.0
    fp = T.RIM_INNER - 2 * T.FIT
    L = STEM_LEN + T.FLOOR_T
    cap = T.END_CAP
    v = View(pg, 24, 228, k)
    pg.t(18, 280, "SECTION B-B  (through the stem axis, from the right)", 3.2, BOLD)
    v.section_rect(0, -fp / 2, T.FLOOR_T, -3)
    v.section_rect(0, 3, T.FLOOR_T, fp / 2)
    v.section_rect(T.FLOOR_T, -STEM / 2, L, -STEM / 2 + STEM_WALL)
    v.section_rect(T.FLOOR_T, STEM / 2 - STEM_WALL, L, STEM / 2)
    v.section_rect(L - cap, -STEM / 2, L, STEM / 2)
    v.dh(0, L, fp / 2, 8, f"{L:g} overall")
    v.dh(0, T.FLOOR_T, -fp / 2, -8, f"{T.FLOOR_T:g}")
    v.dh(T.FLOOR_T, L, -fp / 2, -8, f"{STEM_LEN:g} tube")
    v.dh(L - cap, L, -STEM / 2, -18, f"{cap:g} end cap")
    v.dv(-STEM / 2, STEM / 2, L, 9, f"{STEM:g}")
    v.dv(-fp / 2, fp / 2, 0, -9, f"{fp:g} floor plate")
    v.leader(30, -STEM / 2 + 0.8, 10, 12, f"wall {STEM_WALL:g}", 2.4)
    v.leader(L - 2, 0, 14, 22, "pilot holes are at x = -6 (not in this cut)", 2.4, GREY)
    e = View(pg, 200, 232, 3.0)
    pg.t(172, 280, "END VIEW from the back (cap face)", 3.2, BOLD)
    e.rect(-STEM / 2, -STEM / 2, STEM / 2, STEM / 2, 0.5)
    for sy in (-5.5, 5.5):
        e.circle(-6.0, sy, T.M2_PILOT, 0.5)
        e.centre_cross(-6.0, sy, 2.5)
    e.centre_cross(0, 0, 13)
    e.dh(-STEM / 2, STEM / 2, STEM / 2, 8, f"{STEM:g}")
    e.dv(-STEM / 2, STEM / 2, STEM / 2, 8, f"{STEM:g}")
    e.dh(-STEM / 2, -6.0, -STEM / 2, -8, "4")
    e.dh(-6.0, 0, -STEM / 2, -8, "6")
    e.dv(-5.5, 5.5, -STEM / 2, -9, "11")
    e.dv(0, 5.5, -6.0, 0, "") if False else None
    e.leader(-6.0, 5.5, -28, -9, "2 × Ø1.8 pilot, 3 deep", 2.4)
    f = View(pg, 290, 228, 2.0)
    pg.t(285, 280, "VIEW from the +x side (wire slot)", 3.2, BOLD)
    zs0 = L - cap - 8
    f.rect(0, -STEM / 2, L, STEM / 2, 0.5)
    f.rect(0, -fp / 2, T.FLOOR_T, fp / 2, 0.5)
    f.rect(zs0, -4, zs0 + 8, 4, 0.5, RED)
    f.dh(zs0, zs0 + 8, -STEM / 2, -8, "8")
    f.dv(-4, 4, zs0 + 8, 8, "8")
    f.dh(T.FLOOR_T, zs0, STEM / 2, 8, f"{zs0 - T.FLOOR_T:g}")
    f.dh(zs0 + 8, L, STEM / 2, 8, f"{cap:g}")
    g = View(pg, 80, 105, 2.0)
    pg.t(30, 148, "FLOOR PLATE FROM THE FRONT", 3.2, BOLD)
    g.rect(-fp / 2, -fp / 2, fp / 2, fp / 2, 0.5)
    g.rect(-5, -3, 5, 3, 0.5)
    g.rect(-STEM / 2, -STEM / 2, STEM / 2, STEM / 2, 0.2, GREY, [1.5, 1])
    g.dh(-fp / 2, fp / 2, fp / 2, 8, f"{fp:g}")
    g.dh(-5, 5, -3, -9, "10 wire hole")
    g.dv(-3, 3, 5, 12, "6")
    pg.text_block(160, 140, [
        "TILE STEM",
        "A square tube 20 × 20, wall 1.6, 40 long, with a 39.3 × 39.3 × 2 floor plate at the front end and a 4 thick end cap at the back.",
        "The floor plate presses into the back of the head (0.15 each side) and traps the LED module. Glue it.",
        "10 × 6 hole in the floor plate: the module's wires pass back through it into the hollow stem.",
        "8 × 8 slot in the +x wall (red), just in front of the cap: the wires leave the stem there.",
        "End cap: two Ø1.8 pilot holes, 3 deep, at x = -6, y = ±5.5. The yoke is fixed with two self-tapping M2 × 5 screws.",
        "",
        "NEW (rev 27): the end cap is 4 thick (was 2) so the screws have 3 mm of thread; the outside is unchanged.",
        "The stem slides in the 20.5 square guide plate holes: print the test coupon first.",
    ], 2.7, 4.0, width=235)


# ------------------------------------------------------------------------------------------------ yoke
def sheet_yoke(pg):
    pg.new("Yoke", "3 : 1", "3D print, PLA, printed lying on its side (flat on the large face of the blade). 25 off.", 9, TOTAL, "T-03", "PLA, 25 off")
    k = 3.0
    v = View(pg, 90, 245, k)
    pg.t(30, 273, "VIEW ALONG x (the blade face)", 3.4, BOLD)
    v.rect(-8, 0, 8, 2, 0.45)
    v.rect(-7.6, 2, 7.6, BLADE_LEN, 0.5)
    v.rect(-T.SLOT_LEN / 2, ZS - T.SLOT_W / 2, T.SLOT_LEN / 2, ZS + T.SLOT_W / 2, 0.5, INK, None, white)
    v.line(0, -3, 0, BLADE_LEN + 4, 0.15, GREY, [2, 0.6, 0.4, 0.6])
    v.dh(-8, 8, 0, -8, "16 flange")
    v.dh(-7.6, 7.6, BLADE_LEN, 16, "15.2 blade")
    v.dh(-T.SLOT_LEN / 2, T.SLOT_LEN / 2, ZS - T.SLOT_W / 2, -7, f"{T.SLOT_LEN:.2f} slot")
    v.dv(0, BLADE_LEN, -8, -12, f"{BLADE_LEN:.2f} overall")
    v.dv(0, ZS, -8, -22, f"{ZS:.2f} to the slot centre")
    v.dv(ZS - T.SLOT_W / 2, ZS + T.SLOT_W / 2, T.SLOT_LEN / 2, 12, f"{T.SLOT_W:g} wide")
    v.dv(0, 2, 8, 9, "2")
    pg.t(30, 165, "z = 0 is the flange face that sits on the stem cap.", 2.4, FONT, GREY)
    p = View(pg, 255, 225, k)
    pg.t(190, 273, "VIEW ALONG z (the flange, seen from behind)", 3.4, BOLD)
    p.rect(T.BLADE_X0, -8, 1.0, 8, 0.5)
    p.rect(T.BLADE_X0, -7.6, T.BLADE_X0 + T.BLADE_T, 7.6, 0.3, INK, [1.5, 0.8])
    for sy in (-5.5, 5.5):
        p.circle(-6.0, sy, T.M2_HOLE, 0.5)
        p.centre_cross(-6.0, sy, 2.5)
    p.dh(T.BLADE_X0, 1.0, 8, 8, "17.5 flange")
    p.dh(T.BLADE_X0, T.BLADE_X0 + T.BLADE_T, -8, -8, "3 blade")
    p.dh(T.BLADE_X0, -6.0, -8, -17, "10.5")
    p.dv(-8, 8, 1.0, 8, "16")
    p.dv(-5.5, 5.5, T.BLADE_X0, -9, "11")
    p.leader(-6.0, 5.5, 22, -4, "2 × Ø2.2 (M2 clearance)", 2.4)
    p.text(T.BLADE_X0, 0, "dashed: the blade (3 thick)", 2.3, FONT, GREY, dy=-37)
    pg.text_block(180, 150, [
        "YOKE (the sliding part of the scotch yoke)",
        "A flat flange 17.5 × 16 × 2 with a blade 3 thick standing on one end; the blade has a slot the servo's pin rides in.",
        "Flange: fixed to the stem cap with two self-tapping M2 × 5 screws through the Ø2.2 holes (x = -6, y = ±5.5).",
        f"Slot: {T.SLOT_LEN:.2f} long (along y) × {T.SLOT_W:g} wide, its centre {ZS:.2f} from the flange face. The pin is Ø2.0 so the slot is 0.3 wider.",
        "On the board the blade stands at x = -16.5 to -13.5 from the stem axis (the flange runs from x = -16.5 to +1).",
        "Print lying on its side. Use a steel pin and a dab of grease: the slot wears.",
    ], 2.7, 4.0, width=225)


# ------------------------------------------------------------------------------------------------ bracket
def sheet_bracket(pg):
    pg.new("Servo bracket", "2.5 : 1", "3D print, PLA. The wall prints FLAT on the bed. 25 off.", 10, TOTAL, "T-04", "PLA, 25 off")
    k = 2.5
    z0, z1, zf1 = 3.0, 21.0, 21.0 + T.FOOT_T
    v = View(pg, 62, 250, k)
    pg.t(18, 277, "VIEW ALONG x (the wall face the ears rest on)", 3.2, BOLD)
    v.rect(BR_WALL_Y[0], z0, BR_WALL_Y[1], z1, 0.5)
    v.rect(CUT_Y[0], CUT_Z[0], CUT_Y[1], CUT_Z[1], 0.5, INK, None, white)
    for ey in EAR_HOLE_Y:
        v.circle(ey, T.SERVO_W0, 1.6, 0.5)
        v.centre_cross(ey, T.SERVO_W0, 2.3, 0.12)
    v.dh(BR_WALL_Y[0], BR_WALL_Y[1], z0, -8, "36 wall")
    v.dv(z0, z1, BR_WALL_Y[0], -8, "18")
    v.dv(CUT_Z[0], CUT_Z[1], BR_WALL_Y[1], 8, f"{CUT_Z[1] - CUT_Z[0]:.1f} window")
    v.dh(BR_WALL_Y[0], CUT_Y[0], z1, 8, f"{CUT_Y[0] - BR_WALL_Y[0]:.2f}")
    v.dh(CUT_Y[0], CUT_Y[1], z1, 8, f"{CUT_Y[1] - CUT_Y[0]:.1f} window")
    v.dh(CUT_Y[1], BR_WALL_Y[1], z1, 8, f"{BR_WALL_Y[1] - CUT_Y[1]:.2f}")
    v.dh(EAR_HOLE_Y[0], EAR_HOLE_Y[1], T.SERVO_W0, 0, "27.8 between ear holes")
    v.leader(EAR_HOLE_Y[1], T.SERVO_W0, 8, -14, "Ø1.6 pilot ×2", 2.4)
    pg.t(18, 168, f"y = 0 is the stem axis; the window is centred on y = {T.BODY_Y0 + T.SERVO_L / 2:+.3f}; z = 0 is the stem cap back face; 2.85 of wall above and below the window.", 2.3, FONT, GREY)
    p = View(pg, 200, 215, k)
    pg.t(180, 277, "VIEW ALONG z (the foot, from behind)", 3.2, BOLD)
    p.poly([(XW0, -17.5), (T.CABLE_X0, -17.5), (T.CABLE_X0, T.CABLE_Y1), (T.CABLE_X1, T.CABLE_Y1), (T.CABLE_X1, -17.5),
            (20.0, -17.5), (20.0, 18.5), (XW0, 18.5)], 0.5)
    for hx, hy in T.FOOT_HOLES:
        p.circle(hx, hy, T.M3_HOLE, 0.5)
        p.centre_cross(hx, hy, 3)
    p.rect(XW0, -17.5, XW0 + T.WALL_T, 18.5, 0.3, INK, [1.5, 0.8])
    p.dh(XW0, 20.0, 18.5, 8, f"{20.0 - XW0:g} foot")
    p.dh(0, 14.5, 18.5, 17, "14.5 (from x = 0)")
    p.dh(T.CABLE_X0, T.CABLE_X1, -17.5, -8, "7 notch")
    p.dh(XW0, T.CABLE_X0, -17.5, -8, "3") if False else None
    p.dv(-17.5, 18.5, 20.0, 8, "36")
    p.dv(-17.5, T.CABLE_Y1, T.CABLE_X1, 8 + 0, "6") if False else None
    p.dv(-17.5, T.CABLE_Y1, 20.0, 17, "6 notch")
    p.dv(-13, 14, XW0, -9, "27")
    p.leader(14.5, 14, 10, 6, "2 × Ø3.2", 2.4)
    s = View(pg, 335, 250, k)
    pg.t(318, 277, "VIEW ALONG y (L shape)", 3.2, BOLD)
    s.rect(XW0, 3.0, XW0 + T.WALL_T, 21.0, 0.5)
    s.rect(XW0, 21.0, 20.0, 21.0 + T.FOOT_T, 0.5)
    s.dh(XW0, 20.0, 23.5, 8, "19.5")
    s.dv(3.0, 21.0, XW0, -8, "18 wall")
    s.dv(21.0, 23.5, 20.0, 8, "2.5 foot")
    s.dh(XW0, XW0 + T.WALL_T, 3.0, -8, "2.5")
    pg.text_block(24, 120, [
        "SERVO BRACKET",
        "An L: a 2.5 thick wall that holds the servo by its ears, and a 2.5 thick foot that screws to the back plate.",
        "Wall: 36 × 18. A 22.7 × 12.3 window lets the servo body through (0.25 free each side). The ears (32.5 tip to tip) rest on the +x face of the wall and the servo's own two screws go into the Ø1.6 pilot holes.",
        "Foot: 19.5 × 36, two Ø3.2 holes. Fix it to the back plate with two M3 × 10 screws and nuts behind the plate.",
        "NEW (rev 27): a 7 × 6 notch on the foot's -y edge (x 3.5 to 10.5) lets the module cable and the servo lead go back through the slot in the back plate.",
        "",
        "Ear hole spacing (27.8) and ear plane (5.5 below the servo top) are typical SG90 values, not measured. Print ONE bracket, try it with a real servo, then print 24 more.",
        "On the board: wall on the left, foot extending to the right, cable notch at the top right (sheet 3). x = 0 is the stem axis; the wall is at x 0.5 to 3.",
    ], 2.7, 4.0, width=235)


# ------------------------------------------------------------------------------------------------ small parts
def sheet_small(pg):
    pg.new("Diffuser, horn, spacers, fixings", "2 : 1 / 3 : 1 / 5 : 1", "Small parts and how the frame goes together.", 11, TOTAL, "S-01")
    v = View(pg, 62, 232, 2.0)
    pg.t(18, 282, "DIFFUSER SHEET (2 : 1)  25 off, translucent PLA, 0.8 thick", 3.2, BOLD)
    v.rect(-T.DIFFUSER / 2, -T.DIFFUSER / 2, T.DIFFUSER / 2, T.DIFFUSER / 2, 0.5)
    v.dh(-T.DIFFUSER / 2, T.DIFFUSER / 2, T.DIFFUSER / 2, 8, f"{T.DIFFUSER:g}")
    v.dv(-T.DIFFUSER / 2, T.DIFFUSER / 2, T.DIFFUSER / 2, 8, f"{T.DIFFUSER:g}")
    pg.t(18, 176, "Glued flush on the head's front face (the head is 42, so 0.1 each side).", 2.4, FONT, GREY)
    h = View(pg, 300, 220, 5.0)
    pg.t(250, 282, "SERVO HORN, trimmed (5 : 1)", 3.2, BOLD)
    arm = T.R_CRANK + 3.0
    h.circle(0, 0, 7.0, 0.5)
    h.rect(-2.5, -arm, 2.5, 0, 0.5)
    h.circle(0, -T.R_CRANK, T.PIN_D, 0.5)
    h.centre_cross(0, 0, 5)
    h.centre_cross(0, -T.R_CRANK, 2.5)
    h.dv(0, -T.R_CRANK, 2.5, 14, f"{T.R_CRANK:.2f} to the pin hole")
    h.dv(0, -arm, -2.5, -14, f"{arm:.2f} arm length")
    h.dh(-2.5, 2.5, 0, 12, "5")
    h.leader(0, -T.R_CRANK, 24, 6, "Ø2.0 hole for the pin (or an M2 screw)", 2.4)
    pg.text_block(250, 180, ["Cut a single-arm horn to this length and drill the pin hole 7.76 from the spline centre.",
                              "Fit it so that, with the tile fully retracted, the pin is 7.5 mm behind the shaft line (horn at +75°)."], 2.4, 3.6, FONT, GREY, width=150)
    pg.t(18, 160, "SPACER TUBES (3 : 1)   3 lengths × 8", 3.2, BOLD)
    y = 150
    for lab, L in (("A  bezel to front guide plate", ST["spacers"][0]), ("B  between the two guide plates", ST["spacers"][1])):
        s = View(pg, 24, y, 3.0)
        s.rect(0, 0, L, 6, 0.5)
        s.rect(0, 1.3, L, 4.7, 0.2, GREY, [1, 0.6])
        s.dh(0, L, 6, 4, f"{L:.1f}")
        pg.t(24 + 3 * L + 5, y - 10, lab, 2.6)
        y -= 28
    s = View(pg, 24, y, 3.0)
    s.rect(0, 0, 20, 6, 0.5)
    s.line(21, 0, 23, 6, 0.5)
    s.rect(24, 0, 44, 6, 0.5)
    s.dh(0, 44, 6, 4, f"{ST['spacers'][2]:.1f}  (drawn shortened)")
    pg.t(24 + 3 * 44 + 5, y - 10, "C  rear guide plate to back plate", 2.6)
    pg.t(18, y - 40, "Each tube: Ø6 outside, Ø3.4 bore. Print upright, or use M3 standoffs or brass tube cut to length.", 2.4, FONT, GREY)
    pg.text_block(200, 150, [
        "HOW THE FRAME GOES TOGETHER (8 bolt positions)",
        "Along each bolt, front to back: M3 countersunk bolt head in the bezel, 10.4 tube (A), front guide plate, 14.4 tube (B), rear guide plate, 42.1 tube (C), back plate, washer, nut.",
        "Bolt: M3 × 90 flat head; trim it to about 84 after the nut is on (the stack is 78.9 deep, plus washer and nut 81.8 minimum).",
        "Per tile: 2 × M2 × 5 self-tapping (yoke to stem), 2 × M3 × 10 with nuts (bracket foot to back plate), plus the servo's own 2 ear screws.",
        "For 25 tiles: 50 × M2 × 5, 50 × M3 × 10 with 50 nuts; for the frame 8 bolts, 8 nuts, 8 washers.",
    ], 2.7, 4.0, width=205)


# ------------------------------------------------------------------------------------------------ bom + open items
def sheet_bom(pg):
    pg.new("Parts list, fasteners and open items", "-", "Everything needed for the frame, tiles and fixings. Bought parts are not drawn.", 12, TOTAL, "BOM")
    rows = [
        ("No.", "Part", "Qty", "Made how / spec", "Sheet"),
        ("1", "Front bezel", "1", "Laser cut black acrylic 3 mm, 235 × 250, window 215 × 215, bar slot 216 × 10, 8 × Ø3.2 + countersink", "4"),
        ("2", "Guide plate", "2", "Laser cut acrylic 3 mm, 235 × 250, 25 square holes 20.5, 8 × Ø3.2", "5"),
        ("3", "Back plate", "1", "Laser cut acrylic 3 mm, 235 × 250, 8 × Ø3.2, 50 × Ø3.2, 25 slots 7 × 6", "6"),
        ("4", "Tile head", "25", "3D print black PLA, face down", "7"),
        ("5", "Diffuser sheet", "25", "3D print translucent PLA, 0.8 thick, 41.8 × 41.8", "11"),
        ("6", "Tile stem", "25", "3D print PLA, upright", "8"),
        ("7", "Yoke", "25", "3D print PLA, on its side", "9"),
        ("8", "Servo bracket", "25", "3D print PLA, wall flat", "10"),
        ("9", "Spacer tube A / B / C", "8 / 8 / 8", "Ø6 × Ø3.4, lengths 10.4 / 14.4 / 42.1 (print or cut standoffs)", "11"),
        ("", "LED module 5 × 5 WS2812B", "25", "Bought (Alibaba), 38.9 square, LEDs 7.8 pitch", ""),
        ("", "SG90 servo + single horn", "25", "5 provided, 20 to buy; horn trimmed, pin Ø2 steel or M2 screw", "11"),
        ("", "Bolt M3 × 90 countersunk + nut + washer", "8", "Bought; trim to about 84", "11"),
        ("", "Screw M2 × 5 self-tapping", "50", "Yoke to stem cap", ""),
        ("", "Screw M3 × 10 + nut", "50 + 50", "Bracket foot to back plate", ""),
        ("", "Status-bar LED stick (8 × WS2812B)", "4 (+1)", "54 × 10 assumed; behind the bar slot, taped to the bezel back", ""),
    ]
    xs = [22, 36, 110, 140, 300]
    y = 270
    for i, r in enumerate(rows):
        f = BOLD if i == 0 else FONT
        for x, cell in zip(xs, r):
            pg.t(x, y, cell, 2.8, f)
        y -= 5.2
        pg.c.setLineWidth(0.1)
        pg.c.line(20, y + 3.6, 330, y + 3.6)
    y -= 4
    pg.text_block(22, y, ["PROPOSED IN REV 27 (not in the earlier design, confirm before cutting)"], 3.2, 4, BOLD, RED)
    y = pg.text_block(22, y - 5, [
        "• 8 bolts (4 corners + 4 mid-edge) instead of 4 corner holes: the 235 × 250 plates are only supported at their edges. Spacers are printed tubes.",
        "• Bezel front flush with the diffuser; bezel and plates 3 mm, spacer lengths follow the stack: 10.4 + 14.4 + 42.1.",
        "• Cable notch in the bracket foot and a 7 × 6 slot in the back plate per cell: the module cable and servo lead leave through it.",
        "• Stem end cap 4 thick (was 2) so the M2 screws have thread.",
        "• Status bar: the four sticks are taped behind the bezel slot; no printed holder.",
    ], 2.7, 4.2, width=300)
    pg.text_block(22, y - 4, ["STILL UNKNOWN (marked on the sheets)"], 3.2, 4, BOLD, AMBER)
    y = pg.text_block(22, y - 9, [
        "• LED module thickness (1.6 mm assumed) and pad layout. • Ear screw hole spacing and ear plane of the SG90 (typical values used). • Real size of the status-bar sticks.",
        "• Diffuser translucency (print one and test). • Back plate stiffness at 3 mm. • The stand (a folding V on the back: not designed yet).",
    ], 2.7, 4.2, width=300)


def main():
    check_models()
    pg = Page(OUT / "fabrication-drawings.pdf")
    for f in (sheet_general, sheet_section, sheet_cell, sheet_bezel, sheet_guide, sheet_back, sheet_head, sheet_stem, sheet_yoke,
              sheet_bracket, sheet_small, sheet_bom):
        f(pg)
    pg.save()
    assert len(pg.sheets) == TOTAL
    print("wrote", OUT / "fabrication-drawings.pdf", len(pg.sheets), "sheets")


if __name__ == "__main__":
    main()
