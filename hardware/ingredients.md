# Dither Board: Ingredients List

_Last updated: 2026-11-21 (rev 21). One consolidated list. Prices are **AUD**, ex-GST, from the research in [`components.md`](components.md) (USD figures converted at 0.69 USD per AUD) plus a few fresh lookups. The builder said: ignore the budget, get the cheapest reasonable parts._

**Build:** 4 × 4 tiles, 6 × 6 LEDs per tile (576) + a 24-LED status bar = **600 LEDs**, 16 stepper motors, Pico W. Power is the builder's own three chargers (12 V 4 A, 20 V 3.33 A, 16 V 3.75 A) plus two buck modules. Wiring: [`circuit.md`](circuit.md) and [`schematics/`](schematics/).

Confidence tags: **[P]** page opened and read, **[C]** search-result card only, **[E]** my estimate, nothing checked.

---

## A. BUY LIST (rev 21: servo actuators + premade 5 × 5 LED modules; supersedes the stepper / bare-LED list in rev 16-20)

Electropeak page prices are shown in AUD; the page's own metadata holds the USD list price and the shop multiplies by 1.44. Shipping is "FOB Shenzhen" (no customs), DHL base cost "$35", free over "$100" (currency not labelled), tracked economy 12-15 days. All A1-A3 can come from one Electropeak order.

| # | Item | Qty | Model / spec | Where | Price (AUD) | Conf. |
|---|---|---|---|---|---|---|
| A1 | **Micro servo, metal gear** | 18 (16 + 2) | TowerPro **MG90S** 9 g, 4.8-6 V, 1.8 kg·cm at 4.8 V / 2.2 at 6 V, 0.1 s per 60°, ~180°, 22.5 × 12 × 22.5 mm (body). Page says gears "metal and plastic (optional)": check on arrival. **Cheaper fallback: SG90** (A$1.0368 each, plastic, 1.2 kg·cm listed) | electropeak.com/towerpro-mg90s-9g-metal-gear-servo | 18 × 1.80 = **32.40** (SG90: 18.66) | [P] |
| A2 | **PCA9685 16-channel PWM driver** (I2C) | 2 (1 + spare) | Drives all 16 servos from 2 Pico pins (GP16 SDA, GP17 SCL) | electropeak.com/16-channel-12-bit-pwm-servo-driver | 2 × 4.032 = **8.06** | [P] |
| A3 | **WS2812B 5 × 5 RGB LED square module** (25 LEDs, 5050, 4-7 V) | 18 (16 + 2) | ELC-02-099. Page says "3.9x3.9mm": almost certainly **39 mm**, since 25 5050 LEDs cannot fit in 3.9 mm. Pad layout and pitch are NOT on the page: ask the seller / check on arrival | electropeak.com/16-bit-square-ws2812-5050-rgb-led (URL says 16-bit; the product shown is the 25-bit one) | 18 × 1.80 = **32.40** | [P] price, [E] size |
| A4 | **Status bar, 20-24 LEDs** | 1 | 3 × "8-Bit straight module" (ELC-02-097, price not on the page) or 14 cm of 144 LED/m strip | Electropeak / any | **~3** | [E] |
| A5 | **74HCT245, DIP-20** (level shifter for the LED data lines) | 5 | Must be HCT | AliExpress / eBay | **4.00** | [E] |
| A6 | **Buck module XL4016-class 8 A** | 3 (2 + 1 spare) | 5 V for LEDs (from the 20 V charger, cap ~5 A) and 5 V for servos + Pico (from the 16 V charger) | AliExpress / eBay | **18.00** | [E] |
| A7 | **JST-XH 3-pin sets** (module power + data) and a few Dupont leads | ~40 | | AliExpress | **8.00** | [E] |
| | Shipping (Electropeak, if under the free threshold) | | | | **~25** | [E] |
| | **Subtotal, ex-GST** | | | | **≈ 131** | |
| | **+10 % GST on imports (rough)** | | | | **≈ 13** | |
| | **Total to buy** | | | | **≈ AU$144** (was ≈ 223 on rev 17) | |

Removed in rev 21: stepper motors, M2 nuts, MX1508 drivers, all eight 74HC595, tile PCBs, bare WS2815 LEDs and capacitors, the 12 V LED plan.

**Consequences to resolve before printing:** the 39 mm module needs a tile inner width of ~39.6 mm (head ≈ 42, pitch ≈ 43, board ≈ 192 mm square, vs 38.8 / 40 / 180 now); pixel count becomes 20 × 20 + bar (apps' `pixelsPerSide` 24 → 20); mechanism changes from screw/nut to a servo scotch-yoke or crank (the stem, guide plates and soft pad stay). Servo supply: six moving at once ≈ 2 A at 5 V.

### Brightness limit (all LEDs full white at the limit; estimates)

WS2812B: ~60 mA per LED at full white; white ≈ 2.15 cd per LED (datasheet typical R 600 + G 1250 + B 300 mcd, recalled, not re-read). 400 + 20 = 420 LEDs → 25 A at 100 %. Pixel pitch 7.8 mm → 6.1e-5 m² → ~35,000 nits at 100 % before the diffuser; assume 25 % through the grid and a thin printed diffuser (untested, range 0.6-1.6x).

| Current limit | Duty | Full-screen white |
|---|---|---|
| 3 A | 12 % | ≈ 1,000 nits |
| **5 A** | **20 %** | **≈ 1,750 nits** |
| 8 A | 32 % | ≈ 2,800 nits |

For reference: a laptop 300-500 nits, a phone maximum 1,000-2,000 nits. Normal room use (100-300 nits) needs only ~1 A.

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

### J3. Rev 21 decisions (2026-11-21)

Builder: servo route accepted ("if it's the same price and gives these benefits, absolutely"), worries are performance and cost only (wiring complexity is irrelevant, so wiring is not an argument), their SG90s were "more than strong enough" and finger push is only a just-in-case, so no slip clutch is needed. A scotch yoke / crank counts as the mechanical drive. Self-locking: a 30 mm-lead, 8 mm screw has a 50° lead angle against a ~11-17° friction angle, so it back-drives; only fine threads (the stepper's 0.4 mm lead = 4°) lock. A 27 g tile needs only ~0.02 kg·cm at the horn, far below a servo's gear friction, so a servo holds it unpowered; a crank also locks at both dead centres. Recommended mechanism: pin on the servo horn at 7.5 mm radius riding in a slot in the stem tail (stroke 15 mm, ~0.3 s).
