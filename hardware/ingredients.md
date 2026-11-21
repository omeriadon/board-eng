# Dither Board: Ingredients List

_Last updated: 2026-11-21 (rev 20). One consolidated list. Prices are **AUD**, ex-GST, from the research in [`components.md`](components.md) (USD figures converted at 0.69 USD per AUD) plus a few fresh lookups. The builder said: ignore the budget, get the cheapest reasonable parts._

**Build:** 4 × 4 tiles, 6 × 6 LEDs per tile (576) + a 24-LED status bar = **600 LEDs**, 16 stepper motors, Pico W. Power is the builder's own three chargers (12 V 4 A, 20 V 3.33 A, 16 V 3.75 A) plus two buck modules. Wiring: [`circuit.md`](circuit.md) and [`schematics/`](schematics/).

Confidence tags: **[P]** page opened and read, **[C]** search-result card only, **[E]** my estimate, nothing checked.

---

## A. BUY LIST (what you must purchase)

| # | Item | Qty | Model / spec | Where | Price (AUD) | Conf. |
|---|---|---|---|---|---|---|
| A1 | **Stepper motor, 8 mm, 2-phase 4-wire, bare lead screw** | 18 (16 + 2 spare). **Order 3 first** as a pilot. | SINONING "Mini 8 mm precision stepper motor 2-phase 4-wire, long linear screw shaft" (2 mm screw, 28 mm, no nut) | sinoning.com (links in `components.md` §1.1) | 18 × 1.58 = **28.40** + postage ~8 | [P] price, [E] postage |
| A2 | **M2 brass nuts** | 100 | Pitch unverified (probably M2 × 0.4); test one on a pilot motor | AliExpress | **2.20** | [E] |
| A3 | **Motor driver module MX1508** (dual H-bridge, 2–10 V, 1.5 A per channel, MOSFET) | 18 (2 packs of 10) | One per motor; 4 inputs IN1–IN4 | AliExpress "MX1508 10 pcs" | **13.80** | [C] |
| A4 | **WS2815-family RGB LED, 5050 SMD, 12 V, addressable** | 630 (600 + 5 % spare) | **Worldsemi WS2815F**, LCSC **C22371533** (SMD5050-6P, 12 V, 800 kbit/s; stock 12,130). Price tiers (USD): 100+ 0.056, **300+ 0.0489**, 1000+ 0.0435. **Fallback: WS2815B-V1, C5446699** (stock 406k; 150+ 0.0738, 1000+ 0.0658). **Check the F datasheet pinout vs the B before drawing the PCB** (pin order may differ; I could not open the F datasheet) | LCSC (full reel is 1000, but partial quantities are sold at the 300+ tier) | 630 × US$0.0489 = US$30.8 = **44.60** + shipping ~25 | [P] price tiers read from LCSC's product API on 2026-11-21, [E] shipping, [C] F pinout |
| A5 | **100 nF capacitor, 0805** (one per LED) | 650 | **Builder may already have SMD 100 nF at school (0805 = 2.0 × 1.25 mm; 0603 also fine; ≥ 16 V, 25 V preferred); if so, drop this line (−AU$6.60).** Decoupling. YAGEO CC0805KRX7R9BB104, LCSC C49678 (US$0.007 at 600+, in the same order as the LEDs) | LCSC | 650 × US$0.007 = US$4.55 = **6.60** | [P] |
| A6 | ~~Tile PCBs (JLCPCB)~~ | | **REMOVED rev 19 at the builder's request** (no custom PCBs; logic stays on the two provided breadboards). **Open consequence:** bare SMD LEDs (A4) and their capacitors (A5) have nothing to sit on. Decide the LED carrier: see §I (soft-sheet concept) | | **0** | |
| A7 | **74HC595N, DIP-16** | 10 (8 + 2 spare), one pack | Powered from 3.3 V, so plain HC is fine | AliExpress 10-pack (AU$1–3) | **2.00** | [C] |
| A8 | **74HCT245, DIP-20** (level shifter for the five LED data lines) | 5 (1 + spares) | Must be **HCT**, not HC or LS (needs 5 V logic with a 3.3 V input threshold) | AliExpress / eBay "SN74HCT245N" | **4.00** | [E] |
| A9 | **Buck module XL4016-class, 8 A, adjustable** ("XH-M404" style) | 3 (2 + 1 spare) | Used at ≤ 5 A with your aluminium heatsink: **12.0 V** from 20 V, **5.0 V** from 16 V | AliExpress / eBay (one eBay sale AU$5.78 + postage) | **18.00** | [E] |
| A10 | **JST-XH 4-pin connector sets** (housing + header) | ~50 pairs | Tile ↔ harness for the LED chain and the motor | AliExpress | **10.00** | [E] |
| | **Subtotal, ex-GST** | | | | **≈ 163** | |
| | **+10 % GST on imports (rough)** | | | | **≈ 16** | |
| | **Total to buy** | | | | **≈ AU$179** (with bare LEDs A4/A5 but no carrier; §I replaces A4/A5) | |

The LEDs (A4) are now about 22 % of it (rev 17: cheaper part, correct price tier; the earlier AU$88 used a stale 5-piece price). The 12 V part costs the same as the 5 V WS2812B at LCSC (150+ tier: WS2815B 0.0738, WS2812B 0.0741), so the voltage is not a cost lever. The only 5 V part that is meaningfully cheaper is the XINGLIGHT XL-5050RGBC-2812B (C2843785, 300+ 0.0411, 630 = ~AU$37.50), saving only ~AU$7 and forcing a 5 V LED supply (90 W of LEDs at 5 V is ~18 A), so **not recommended**. Each 100 LEDs fewer saves only ~AU$8, so cutting to 5 × 5 per tile would save ~AU$20 and is not worth it.

---

## B. PROVIDED FREE (confirmed by the builder, 2026-11-20)

| Item | Detail from the blueprint |
|---|---|
| **Pico W** | Wi-Fi/BLE version |
| **Basic passives** | 330 Ω × 5, 10 kΩ × 8, 4.7 kΩ × 1, 100 nF × ~15 (decoupling), 100 µF × 5, **1000 µF 25 V × 2**, **470 µF 16 V × 1**, 1N5819 Schottky × 1, LDR (GL5528-type) × 1, NTC 10 kΩ (β 3950) × 1, red LED × 1 |
| **2 breadboards + jumper wires** | Two large (~60 column) boards |
| **Wire and connectors** | Hookup wire, 18–20 AWG power wire, terminal blocks / Wago, Dupont leads, 3–4 core silicone wire for the tile flex |
| **Screws, nuts, threaded rod** | M2 and M3 screws, nuts, standoffs, 4 × M3 rod (~150 mm) |
| **Switch, DC plugs, fuses** | One rocker switch (power board), three DC sockets matching the charger plugs, **10 resettable PTC fuses**: F1 4 A, F2 3 A, F3 3 A, F4 3 A, F5 3 A, F6 3 A, F7 1 A, F8 2 A, F9 5 A, F10 1 A |
| **Black + clear acrylic, laser cut** | 3 mm: front bezel (black), guide plates, motor plate, sides, back (clear) |
| **Diffuser** | A thin **3D-printed sheet** (the school does not supply smoked acrylic) |
| **PLA + 3D printer** | Prusa MK4S, black PLA: tile heads, grids, guides, stand parts |
| **Soldering kit + multimeter** | Plus aluminium for the buck heatsinks |
| **The three chargers** | 12 V 4 A, 20 V 3.33 A, 16 V 3.75 A |
| **Stand timber / paint** | From home |

---

## C. Not bought, dropped, or still open

- **Not bought:** L298N modules (the school does not supply them, so the final driver is the MX1508 in A3), PTFE pen (graphite pencil instead), heat-set inserts (printed bosses or self-tapping), zip ties, level-shifter 74AHCT125 (replaced by A8), 7805 (not used).
- **Open: soldering effort.** The cheapest route is hand-soldering 660 LEDs + 660 capacitors (1,320 tiny parts) on the tile PCBs. If that is too much, **JLCPCB SMT assembly** of the tile boards is the alternative; it was not priced.
- **Open: the tile PCB and CAD.** The PCB (A6) is not drawn yet, and `hardware/cad/tile.py` is still set for K = 4 (9.1 mm cells). With K = 6 the cell is **6.07 mm** (36.4 / 6; rev 17 wrongly said 6.5), so with 1.0 mm grid walls a 5.0 mm 5050 LED has a 5.07 mm opening: **0.035 mm a side, which a printer cannot hold**. Needs walls ≤ 0.77 mm, a thinner rim, or K = 5 (7.3 mm cell). Do not order PCBs until this is settled.
- **Open: mechanical drive.** The bare-screw motor has no nut; the printed nut carrier and the tile stem are not designed.
- **Open: the WS2815 backup-data pins** (BI/BO) and so the tile connector size.
- **Open:** whether the diffuser printed sheet is light enough and even enough (test print before the tile heads).

## D. What is not verified

- Nothing has been tested on hardware.
- LED prices were read from LCSC's product API on 2026-11-21 (tiers and stock are exact for that day). **WS2815F pinout and logic threshold are not verified** (datasheet would not load). Untried cheaper source: unbranded clones on AliExpress (chip packs); not found by the search tool. LCSC shipping to Australia is an estimate; JLCPCB can ship parts in the same box as the tile PCBs.
- Motor coil resistance and real current (the bare listing has no tested specs), the M2 thread pitch, the XL4016 module revision and rating, MX1508 availability in packs of 10.

---

## E. Design rules that still apply

- Tiles are located **only by their stems in the guide plates**, never by neighbouring tiles. Gap between heads 1.0–1.5 mm. Stem to guide-hole clearance 0.2–0.3 mm per side; keep the two guide plates as far apart as possible. Print a 2 × 2 test coupon first and tune the clearances (Prusa MK4S gives ±0.1–0.2 mm; chamfer the first-layer edge 0.4 mm).
- Laser-cut the guide-plate holes. Use graphite or dry lube on the stems.
- Firmware safety nets: periodic re-homing, soft limits, at most 6 tiles moving at once (`maxMovingTiles`).

## F. Brief requirement check (3 inputs, 3 outputs, ≥ 2 outputs driven by an automated input)

| Role | Part | Note |
|---|---|---|
| Input (automated) | LDR → room light sets LED brightness | Pico GP26 |
| Input (automated) | NTC → internal temperature dims LEDs or pauses motors | Pico GP27 (a digital sensor such as DS18B20 is possible later; needs teacher approval) |
| Input (user) | Bluetooth / Wi-Fi from the iPhone and Mac apps | Built into the Pico W |
| Output | 600 LEDs (brightness driven by the LDR) | |
| Output | 16 stepper tiles | |
| Output | Status LED on the back | Risk: the teacher may count it as the same type as the LEDs |

## G. Prototype order (before committing)

Order **3 motors** first (A1), plus 1 pack of MX1508 (A3) and the 74HC595 pack (A7): verify the M2 nut pitch, coil resistance and current, and that an MX1508 drives a coil from 5 V. Then order the rest.

_Rev 17 note (diffuser): because the diffuser hides LED shape, smaller packages (3535 / 1010) are allowed but cost more per LED (US$0.055-0.066 vs 0.0489); their only benefit is thicker cell walls. A pre-made 144 LED/m addressable strip (~6.9 mm pitch) could replace hand-soldering 1,320 SMD parts, but is mostly 5 V and unpriced. Open option, not decided._

## H. Price levers (rev 18, 2026-11-21): the mechanism is not where the money is

Mechanism per tile (motor 1.58 + postage share 0.45 + nut 0.14 + driver 0.77 + JST) is about **AU$3.30**, so 16 tiles are ~AU$52 of AU$203 ex-GST (~26 %). LEDs + caps + freight are ~AU$76, tile PCBs ~AU$40, bucks AU$18. Savings below are computed from the LCSC tiers in A4/A5 (AUD ex-GST, [E] where noted). Nothing here is applied to the buy list yet.

| Lever | Saves | Cost of the change |
|---|---|---|
| Fewer LEDs per tile: **K = 5** (25/tile, 424 LEDs) | ≈ AU$14 | Also fixes the 0.035 mm cell clash (7.28 mm cell); ~890 solder joints instead of 1,320 |
| **K = 4** (16/tile, 280 LEDs; the original CAD) | ≈ AU$23 | 9.1 mm cell, the CAD already fits; coarser image (16 × 16 pixels) |
| **3 × 3 tiles** (9 tiles, 348 LEDs) | ≈ AU$42 (LEDs and caps 20.5, 7 fewer motors 11, one fewer driver pack 6.9, JST 4) | Board 140 mm square; fewer tiles than planned |
| Capacitors from school (0805/0603, ≥ 16 V) | AU$6.60 | Footprint must match what they have |
| Cheaper bucks (LM2596-class) | ≈ AU$8–10 [E] | 3 A modules are too small for the 12 V rows (~3.9 A at full white) unless brightness is capped |
| No spares (16 motors, 600 LEDs) | ≈ AU$5 | No margin for a dead part or a failed print |
| LCSC freight folded into the JLCPCB order | up to AU$25 [E] | Only works if JLCPCB assembly or parts-with-board shipping is used; not verified |

Not a lever: switching the actuator (servo + crank is no cheaper), 5 V LEDs (clone saves ~AU$7 and breaks the power plan), smaller LED packages (dearer).

## I. Concept B (rev 19, 2026-11-21, not decided): LEDs on a soft sheet, motors push sticks

Builder's idea: put the LEDs on a soft, fabric-like sheet; each motor drives a stick that pushes the sheet up at that point. No tiles, heads, guide plates, stems or tile PCBs. Prices AUD ex-GST, [E] unless stated.

| Part | Qty | Price | Note |
|---|---|---|---|
| Motors (A1), MX1508 (A3), nuts (A2), 595/245 (A7/A8), JST, bucks: unchanged | | ≈ 86 | The same AU$86 that remains of the current list once A4, A5 and A6 are removed |
| Stretch fabric (lycra / spandex, thin, black or white) | ~0.5 m | 5–10 | Hardware shop / Spotlight |
| LED option 1: **flexible 16 × 16 WS2812B matrix** (160 × 160 mm, 10 mm pitch, 256 LEDs, 5 V) | 1 | 25–40 | Listings seen: EUR 12.90 to 22.99; confirm the chip (some say SK6812). Fits the 4 × 4 pin grid exactly. 16 × 16 pixels, not 24 × 24 (the apps use 24: `BoardGeometry`) |
| LED option 2: **WS2812B 144 LED/m strip** in 24 rows of 24 LEDs (≈ 3.5 m) | 3.5 m | 40–105 | AU retail A$29.82/m ex-GST (Core Electronics); AliExpress is far cheaper (≈ AU$12/m, [E]); rows run in sewn sleeves so they can slide as the sheet bulges |
| Printed sticks + nut carriers + one guide board | 16 | ~0 | The 20 mm tolerance-critical stem is replaced by a ~3 mm square stick in a loose guide |
| **Estimated total** | | **≈ AU$120–130 ex-GST (≈ AU$135–145 with GST)** | vs ≈ 223 for the current tile design |

**Power consequence:** the LED plane becomes 5 V (WS2812B), so the 12 V WS2815 plan, buck 1 and the 12 V rails go; the LED supply must be 5 V (cap brightness in firmware; 256 LEDs is ~15 A at full white, 576 is ~35 A).

**Mechanics (numbers [E]):** stick + nut ≈ 3 g instead of a 27 g tile, so thrust margin improves from ~3 gf to ~20 gf provided the sheet pushes back under ~25 gf (a lycra membrane at ≤ 8 N/m tension). Neighbouring pins 15 mm apart over 40 mm stretch the surface ~7 %: lycra can, a flat flexible PCB cannot (it wrinkles; keep neighbour height differences ≤ 5 mm), strips in sleeves can slide. Retraction needs the stick tip attached to the sheet (glued button) or a tensioned sheet. Unproven; prototype with 3 motors, 0.5 m lycra and 1 m of strip before choosing.

## J. Rev 20 (2026-11-21): tile design confirmed; LED carrier and actuator options

**Decided by the builder:** the tile design stays (the soft-sheet concept in §I is shelved: LED viewing angle changes on a tilting sheet, thin lycra limits the height range). **No custom PCBs** (rev 19).

### J1. LED carrier: premade 4 × 4 WS2812B modules (recommended, not yet confirmed by the builder)

The earlier research (`components.md` §2) found premade modules: 30 × 30 mm, 16 × SMD 5050 WS2812B, 7.5 mm pitch, 5 V. They were rejected early for board colour, edge margins and the 7.5 mm pitch, but the margins and colour hide behind the printed rim and diffuser, and with a 7.5 mm pitch a 1.0 mm wall leaves a 6.5 mm opening for a 5.0 mm LED (0.75 mm a side, so the K = 6 clash disappears). No premade 5 × 5 or 6 × 6 module was found.

| | Bare 5050 on custom PCB (old A4 + A5 + A6) | Premade 4 × 4 modules |
|---|---|---|
| Pixels | 24 × 24 = 576 (+24 bar) | **16 × 16 = 256 (+16 bar)**; the apps' `pixelsPerSide` (24) must become 16 |
| LED parts | 630 LEDs + 650 caps ≈ AU$51 + LCSC freight 25 | 18 modules ≈ **AU$29–55** (Core Electronics GlowBit 4×4 AU$1.59 ex-GST each, size unchecked; 30 × 30 mm module listings 1.5–4.95 EUR; earlier AliExpress estimate US$0.96 each) |
| Custom PCB | AU$40 | none |
| Soldering | 1,320 SMD joints | 3 wires per module (5 V, GND, DIN; DOUT to the next) |
| Supply | 12 V WS2815 | **5 V** WS2812B: 272 LEDs is ~16 A at full white; cap brightness (~5 A) |
| Status bar | 24 LEDs | 16 LEDs, e.g. 11 cm of 144 LED/m strip (AU$3–5) |
| Tile pitch | 40 mm | 40 mm still fine (module 30 mm inside a 36.4 mm opening); could shrink to ~34 mm |

Buying the modules instead of A4, A5 and A6 would put the total near **AU$125–150 ex-GST** (86 for the rest + 29–55 modules + ~4 bar), versus ≈ 223 for the old LED path. It changes the pixel count, so the builder must confirm K = 4.

### J2. Actuator: servo + printed screw instead of the bare stepper (assessment, not decided)

The earlier SG90-per-pin rejection (`context.md` §6) was for 5 mm-pitch rods. At 40 mm pitch a 23 × 12 mm micro servo fits.

| Per tile | Bare stepper + MX1508 (now) | MG90S/SG90 servo + printed screw or crank |
|---|---|---|
| Parts | motor 1.58 + postage 0.45 + nut 0.14 + MX1508 0.77 + share of 595/JST ≈ **AU$3.3** | servo **≈ AU$2–4 [E, unverified]** (AU retail AU$13 each; pack prices not found) + PCA9685 share (AU$6–8 for all 16) ≈ **AU$2.5–4.5** |
| Wiring | 4 wires per motor: 8 × 74HC595, 16 × MX1508, 64 jumpers | 3 wires per servo to one PCA9685 (I2C, 2 Pico pins): no 595s, no drivers, no jumpers |
| Force | ~0.3 N (30 gf, borrowed) | ~2 kg·cm = 0.2 N·m: ≈ 29 N through a 30 mm-lead screw, ≈ 26 N through a 7.5 mm crank (100 × the stepper) |
| Stroke time | 1.5 s at 500 pps | ≈ 0.3–0.5 s |
| Hold | self-locking, 0 W | powered hold (servo hum, ~10–50 mA each) or friction / crank dead-centre at the ends |
| Finger push | strips the 2 mm nut | back-drives the servo gears (plastic SG90 strips; metal MG90S survives better); needs a slip clutch or compliant link |
| Travel | screw 28 mm, firmware-limited to 15 | set by crank radius or screw lead: any stroke |

A positional servo turns only 180°, so a conventional fine screw is out. Two ways: a **high-lead printed screw** (4-start, ~30 mm lead: 180° = 15 mm, a true screw drive, efficiency ~70 %, not self-locking) or a **crank / scotch yoke** (simpler, dead-centre self-locks at both ends; whether it counts as the brief's mechanical drive must be checked). Servo supply: 5–6 V; six moving at once ≈ 2–3 A.

**Power:** three chargers draw at most ~205 W / 230 V ≈ 0.9 A from the wall (the sum of output amps at different voltages is meaningless); nowhere near a 10 A circuit. With 5 V LEDs and servos only two chargers (20 V and 16 V, each through a buck) are needed.
