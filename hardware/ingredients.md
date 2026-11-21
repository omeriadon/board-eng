# Dither Board: Ingredients List

_Last updated: 2026-11-21 (rev 27). One consolidated list. Prices are **AUD**, ex-GST, from the research in [`components.md`](components.md) (USD figures converted at 0.69 USD per AUD) plus a few fresh lookups. The builder said: ignore the budget, get the cheapest reasonable parts._

**Build (rev 25, DECIDED by the builder):** **5 × 5 tiles**, 5 × 5 LEDs per tile (premade 5 × 5 modules) = **25 × 25 = 625 pixels** + a 25-LED status bar = **650 LEDs**, 25 SG90 servos with scotch-yoke drive, Pico W. Board 235 × 250 mm, depth 78.9 mm retracted. Power is the builder's own 20 V and 16 V chargers through 5 V bucks (12 V charger spare). A new stand is needed (board ≈ 2.1 kg [E]). Wiring: [`circuit.md`](circuit.md) and [`schematics/`](schematics/) (redrawn for this design at rev 26: one breadboard, 2 × PCA9685, two LED bucks).

Confidence tags: **[P]** page opened and read, **[C]** search-result card only, **[E]** my estimate, nothing checked.

---

## A. BUY LIST (rev 25: 5 × 5 tiles, servos + premade 5 × 5 LED modules; supersedes every earlier list)

Source: **Alibaba.com** for the modules (A$1.08 each, free shipping capped at A$30, delivery 30 Nov - 22 Dec, all prices AUD per the builder). The Electropeak cart (A$51.49 for 16 modules + 3 sticks, A$21.53 shipping) is **not needed**: cancel it. Prices marked [E] are not looked up yet; ask the same Alibaba supplier or search the item there (the builder can screenshot the page).

| # | Item | Qty | Model / spec | Where | Price (AUD) | Conf. |
|---|---|---|---|---|---|---|
| A1 | **Micro servo SG90** | 25 (5 provided, **20 to buy**) | 9 g, 22.2 × 11.8 × 31, 1.8 kgf·cm at 4.8 V (spec the builder sent), 1-2 ms = ±90°. Electropeak lists SG90 at A$1.0368 each; Alibaba likely about the same [E]. Builder: surely not more than A$3 each | Alibaba / Electropeak | 20 × 1.0-1.5 = **20-30** (worst case 60) | [E] |
| A2 | **PCA9685 16-channel PWM driver** (I2C) | 2 | **Not owned, to buy.** 25 servos need 2 boards (16 + 9; the Pico has too few free pins to drive 25 servos directly); addresses 0x40 / 0x41; GP16 SDA, GP17 SCL. Electropeak price A$4.032 each | Alibaba / Electropeak | 2 × 4 = **8.06** | [P] |
| A3 | **WS2812B 5 × 5 RGB LED module** (25 LEDs, 5050, 4-7 V, 38.9 mm) | 26 (25 + 1 spare) | Alibaba "WS2812B 5*5 Digit 5050 RGB LED Full-color Driver 25 Bit Color Light Development Board", Shenzhen Jingmaoyuan, 5.0 (2 reviews), 60 sold. A$1.08 each at 2-99 pcs. Pads unconfirmed: ask the seller | Alibaba | 26 × 1.08 = **28.08** | [P] |
| A4 | **Status bar sticks** (8 × WS2812B each, 54 × 10 mm) | 5 (4 + 1 spare) | 4 sticks = 32 LEDs, 216 mm, 25 used. These single LED sticks were only ever found on **Electropeak** (ELC-02-097, A$0.3888 each), not on Alibaba; the builder is unsure where they were from. Shipping makes an Electropeak order pointless, so search Alibaba for an 8-LED WS2812B stick and screenshot it | Alibaba | **≈ 2.5** | [E] |
| A5 | **74HCT245, DIP-20** (level shifter, 6 LED data lines) | 5 | Must be HCT | AliExpress / eBay | **4.00** | [E] |
| A6 | **Buck module XL4016-class 8 A** | 4 (3 + 1 spare) | Two 20 V → 5 V for the LEDs (5 A each, one per half of the board, 10 A total), one 16 V → 5 V for servos + Pico. Builder: "just 8 dollars" each, so budget 6-8 | AliExpress / eBay | **24-32** | [E] |
| A7 | **JST-XH 3/4-pin sets + Dupont leads** | ~75 | Module power + data and servo leads for 25 tiles | AliExpress | **12.00** | [E] |
| | **Total to buy** | | | | **≈ AU$104** (range ≈ 99-125 with servo and buck prices at the high end; GST may add 10 % on some parts) | |

Free: the 5 servos, PLA, acrylic, chargers, passives, breadboards (section B). Removed earlier: stepper motors, M2 nuts, MX1508 drivers, 74HC595s, tile PCBs, bare WS2815 LEDs, the 12 V LED plan, the Electropeak order.

**Consequences:** tile head 42, pitch 43, board 235 × 250 mm (`tile.py` N = 5, laser files regenerated: bezel and guide plates 235 × 250 with a bar slot); pixels 25 × 25 + bar 25 (apps' default geometry is now 5 × 5 tiles); LED power 650 LEDs = 39 A at full white, limited to 10 A by two 5 A bucks; servo supply (16 V charger → buck) ≈ 2-3 A with a few moving at once; a new stand.

### Brightness limit (all LEDs full white at the limit; estimates)

**Rule:** the limit is on total current, not per pixel. Full-screen nits ≈ 225 × amps (650 LEDs). Lit fraction × pixel nits must stay ≤ the full-screen figure, so at 10 A a patch of 3,000 nits may cover up to ~75 % of the screen (2,250 / 3,000). Needs a firmware limiter (sum of RGB × 20 mA / 255 per frame) and a per-module cap of ~1 A (a 5 × 5 module at full white is 1.5 A through thin board copper). Power wires must not run through the breadboard rails.

WS2812B: ~60 mA per LED at full white; white ≈ 2.15 cd per LED (recalled datasheet values). 625 + 25 = 650 LEDs → 39 A at 100 %. Pixel pitch 7.8 mm → ~35,000 nits at 100 % before the diffuser; assume 25 % through the grid and a printed diffuser (untested, range 0.6-1.6×).

| Current limit | Duty | Full-screen white |
|---|---|---|
| 3 A | 8 % | ≈ 680 nits |
| 5 A (one buck) | 13 % | ≈ 1,130 nits |
| **10 A (two bucks, planned)** | **26 %** | **≈ 2,260 nits** |

For reference: a laptop 300-500 nits, a phone maximum 1,000-2,000 nits. Normal room use (100-300 nits) needs only 1-2 A.

## B. PROVIDED FREE (confirmed by the builder, 2026-11-20)

| Item | Detail from the blueprint |
|---|---|
| **Pico W** | Wi-Fi/BLE version |
| **Basic passives** | 330 Ω × 6, 10 kΩ × 9, 4.7 kΩ × 3, 1 kΩ × 1, 100 nF × ~15 (decoupling), 100 µF × 5, **1000 µF 10 V+ × 2** (LED buses), **470 µF 16 V × 3** (servo bus + one at each PCA9685), 1N5819 Schottky × 1, LDR (GL5528-type) × 1, NTC 10 kΩ (β 3950) × 1, red LED × 1 |
| **Breadboard + jumper wires** | One large (~60 column) board is enough since rev 26 (the 74HC595s are gone); the second is spare |
| **Wire and connectors** | Hookup wire, 18–20 AWG power wire, terminal blocks / Wago, Dupont leads, 3–4 core silicone wire for the tile flex |
| **Screws, nuts, threaded rod** | M2 and M3 screws, nuts, standoffs, 4 × M3 rod (~150 mm) |
| **Switch, DC plugs, fuses** | One rocker switch (power board), two DC sockets matching the 20 V and 16 V charger plugs, **7 resettable PTC fuses** (rev 26): F1 F2 2 A (20 V side of the two LED bucks), F3 F4 5 A (LED buses), F5 2 A (16 V side), F6 5 A (servo rail), F7 1 A (logic) |
| **Black + clear acrylic, laser cut** | 3 mm: front bezel (black), guide plates, motor plate, sides, back (clear) |
| **Diffuser** | A thin **3D-printed sheet** (the school does not supply smoked acrylic) |
| **PLA + 3D printer** | Prusa MK4S, black PLA: tile heads, grids, guides, stand parts |
| **Soldering kit + multimeter** | Plus aluminium for the buck heatsinks |
| **The chargers** | 20 V 3.33 A and 16 V 3.75 A are used; 12 V 4 A is a spare, not wired |
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

### J4. Rev 22 (2026-11-21): Electropeak items reviewed, servo fit, pixel count

**5 × 5 module (ELC-02-099) verdict: good.** A$0.072 per LED, no LED soldering, no PCB. Evidence for 39 mm: the 8-LED stick on the same shop lists "5.4x1", which can only be 54 × 10 mm in cm, so "3.9" is 3.9 cm = 39 mm (7.8 mm LED pitch). Benefit: the printed grid cell is now 7.8 mm for a 5.0 mm LED (6.8 mm opening with 1.0 mm walls), so the 0.035 mm clash of the 6 × 6 design is gone. Costs: head ≈ 42, pitch ≈ 43, board ≈ 192 mm; LEDs sit 7.8 mm apart inside a tile and ~11.8 mm across a tile gap (the image grid is slightly uneven). Unknown: pad layout, board thickness, dead-pixel rate (1 review, 5 stars), whether JSON-LD "price 1.25" (USD) is the real list price (visible A$1.80 = 1.25 × 1.44). Ask the seller for a pad photo before ordering; 2 spares included.

**8-bit stick (ELC-02-097):** A$0.3888 each (USD 0.27 × 1.44), 8 LEDs, 5 V, 96 % of 100 from 11 reviews; "current 18 mA" with no per-LED statement. Bar = 3 sticks (24 LEDs, 162 mm, use 20), joined by short wires. Not suited as the tile LEDs (10 mm wide, 6.75 mm pitch does not tile a 43 mm cell).

**Servo fit (datasheet dimensions from memory, confirm on the listing):** SG90 22.2 × 11.8 × 31, MG90S 22.8 × 12.2 × 28.5, ears 32.5 mm across. The footprint fits a 43 mm cell, but not beside a 20 mm stem (28 mm along the shaft). It lies behind the stem with its shaft sideways, adding an estimated 15-25 mm of depth. Not drawn yet: verify in CAD / on one prototype tile.

**Scotch yoke in print:** the slot is a feature of the stem tail (slot width = pin + 0.3 mm, length = stroke + pin + 0.4 mm, vertical walls), the crank is the servo horn with an M2 screw or 2 mm steel pin at 7.5 mm radius (or a small printed disc), plus a printed servo cradle. Easier than a printed screw (no thread fidelity). Risks: slot wear (steel pin, a dab of grease), 0.3 mm slop. Idle tip: stop the PCA9685 pulse after a move to remove hold hum; the gearbox holds the 27 g tile.

**Pixel count:** 4 × 4 tiles × 5 = **20 × 20 = 400** + 20 bar = 420 (apps' `pixelsPerSide` 24 → 20, bar 20). 6 × 6 tiles (the builder's "6 tiles at 5 = 30 × 30") = 900 + bar: 36 servos + 36 modules, 3 PCA9685, board ≈ 258 mm, ≈ +A$76 ex-GST (total ≈ AU$225), 54 A at full white so 5 A is only ≈ 800 nits full-screen. Not chosen.

### J5. Rev 23 (2026-11-21): checkout, servos provided, CAD model, blueprint redrawn

**Checkout:** Electropeak total A$51.49 (A$29.97 goods + A$21.53 tracked economy shipping with customs included); the buy list above totals ≈ AU$89 with SG90 servos provided. Cart has 16 modules and 3 sticks, no spares. Advised additions: 2 modules (+A$3.60), 1 stick (+0.39), 1 PCA9685 (+4.03) unless one is available free.

**Mechanism model (`hardware/cad/tile.py`, run with `/tmp/cadvenv/bin/python tile.py`, deps manifold3d numpy trimesh svglib reportlab):** crank R = 7.76 mm, swing ±75° of the servo's ±90° (stroke 15.0 = 2 R sin 75°), pin 2.0 mm, slot 8.75 × 2.3. Parts: `yoke.stl` (flange screwed to the end cap with 2 × M2, 3 mm blade), `servo_bracket.stl` (wall with cutout + foot, 2 × M3 to the back plate), `tile_stem.stl` (detents and M2 nut hole removed, 2 yoke pilots added), `tile_head.stl` (5 × 5 grid at 7.8 mm), `diffuser_sheet.stl` (printed 0.8 mm), `assembly_retracted.stl` / `assembly_extended.stl`. `assembly()` sweeps 9 stroke positions and checks the moving set against servo, horn, pin, bracket, guide plates and back plate: 0.000 mm³ overlap (positive controls detect 36-65 mm³ when parts are shifted). Pin end margin in the slot 0.5 mm. Depth 78.1 mm retracted (+0.8 diffuser), 94 mm with a tile out (was 89.8 / 105): the earlier estimate of +15-25 mm depth was wrong, the servo is shorter than the stepper. Servo outline (22.8 × 12.4 case, ears 5.5 below the top, hole spacing 27.8) is from memory: measure the real SG90 before printing 16 brackets.

**Torque:** ≈ 0.6 N (tile ≈ 30 g [E] + 0.3 N friction [E]) × 7.76 mm = 0.047 kg·cm against 1.2 kg·cm listed: ≈ 25×. Servo torque is the same at every angle, so using 150° of 180° costs nothing. Holding unpowered: yoke lever R cos θ gives ≤ 0.02 kg·cm at the horn from the tile's weight.

**Blueprint:** `schematics/dither-board-design-blueprint.pdf` redrawn for rev 22/23 (servo yoke, 5 × 5 module, 43 mm pitch, new BOM, power plan). `dither-board-blueprint.pdf` (wiring) and `dither-board-schematics.pdf` still show the old stepper / 595 / MX1508 wiring.

**App:** Device tab, section "Board Layout": steppers for tiles per side (2-8) and LEDs per tile side (2-8), presets, and live counts (pixels, motors, LEDs, full-white amps, full-screen nits at 5 A). Stored in UserDefaults; `BoardGeometry.standard` is now 4 × 4 × 5 (20 × 20).

### J6. Rev 24 (2026-11-21): Alibaba module source, SG90 spec, 4 or 5 tiles per side

**Cheaper module source (builder's screenshot, Alibaba.com, AUD):** "WS2812B 5*5 Digit 5050 RGB LED Full-color Driver 25 Bit Color Light Development Board", Shenzhen Jingmaoyuan Electronics, 5.0 (2 reviews), 60 sold. **A$1.08 each** for 2-99 pieces (A$1.22 before the 11 % sale, ends Dec 31), A$1.02 at 100+; 17 pieces = **A$18.36, free shipping** (capped at A$30), Alibaba Logistics guaranteed delivery **30 Nov - 22 Dec**. The product photo is dimensioned **38.9 × 38.9 mm** (confirms the 39 mm module) and shows four white holes or pads between LEDs (purpose not confirmed). Versus Electropeak: 16 modules A$28.80 + A$21.53 shipping = A$50.33 against Alibaba A$17.28-18.36 shipped, but slower (up to 31 days against 12-15). Everything on this page is AUD (item subtotal 17 × 1.08 = 18.36). The Electropeak status-bar sticks and PCA9685 are not worth A$21.53 of shipping on their own: source them on Alibaba too (not priced, [E] A$0.4-0.6 per stick, A$2-4 per PCA9685).

**SG90 spec the builder supplied:** 22.2 × 11.8 × 31 mm (31 probably includes the horn hub), 9 g, stall torque **1.8 kgf·cm** at 4.8 V, 0.1 s / 60°, dead band 10 µs, pulse 1-2 ms = ±90° (5.6 µs per degree). Torque margin of the yoke is therefore 25-38× (1.2 on the Electropeak listing, 1.8 here). Resolution: 150° ≈ 830 µs ≈ 170 PCA9685 counts, ≈ 0.12 mm per count, dead band ≈ 0.2 mm, against 1.5 mm per height level. `tile.py` now derives the yoke blade position from the spline stack height and still clears (0.000 mm³ sweep, blade 1.5 mm inside the cell edge) for stacks of 4.5, 6 and 8 mm.

**4 tiles per side or 5 (5 LEDs per tile either way):**

| | 4 × 4 tiles | 5 × 5 tiles |
|---|---|---|
| Pixels | 20 × 20 = 400 (+20 bar) = 420 LEDs | 25 × 25 = 625 (+25 bar) = 650 LEDs |
| Modules (Alibaba, +1 spare) | 17 × 1.08 = 18.36 | 26 × 1.08 = 28.08 |
| Servos (SG90) | 16 | 25 (provided? unknown; A$1.04 each if bought) |
| PCA9685 boards (16 channels each) | 1 | 2 |
| Status-bar sticks (8 LEDs) | 3 (+1) | 4 (+1) |
| Buy list, approx. | ≈ AU$53-60 [E] | ≈ AU$67-75 [E] (+9 for 9 servos if not provided) |
| Board size | 192 mm wide, ≈ 206 tall | 235 wide, ≈ 249 tall |
| Full-white current | 25 A | 39 A |
| Full-screen nits at a 5 A limit | ≈ 1,750 | ≈ 1,130 |
| Moving parts to print | 16 tiles | 25 tiles (≈ +40 h of printing [E]) |
| Estimated mass | ≈ 1.4 kg [E] | ≈ 2.1 kg [E] (above the mini ball head's 1-1.5 kg) |
| Centre pixel / tile | none | yes (symmetric patterns, ripples) |

Money is not the issue (roughly +A$14); print time, mass and the stand are.

### J7. Rev 25 (2026-11-21): 5 × 5 tiles decided

The builder chose **5 × 5 tiles** (25 tiles, 625 pixels): board size is fine, 1,130 nits at 5 A is "still really bright", printing time is not a concern, a new stand is fine, one more buck converter is wanted (so two 5 A LED bucks = 10 A, ≈ 2,260 nits), and servo cost is fine "even if we only get 5 provided" (≤ A$3 each). `tile.py` N = 5 (sweep still 0.000 mm³; laser bezel / plates 235 × 250 with the bar slot), app default geometry 5 × 5 tiles with 10 A as the nits limit, design blueprint redrawn (front view, BOM quantities, system diagram with two LED bucks and two PCA9685). Wiring PDFs (`dither-board-blueprint.pdf`, `dither-board-schematics.pdf`) still show the old stepper plan. The stand is not designed.

## K. Rev 27 notes (2026-11-21)

- **SG90 outline:** the builder's supplied body 22.2 × 11.8 mm is now used in `tile.py` (it was 22.8 × 12.4 from memory) and in the design blueprint; the 9-position collision sweep is still 0.000 mm³. Ear plane, hole spacing and the horn are typical SG90 values, so print one bracket and test-fit a real servo before printing all 25.
- **No resistors for the servos.** A servo plugs straight into a PCA9685 channel (signal, V+, GND). The 330 Ω / 10 kΩ / 4.7 kΩ / 1 kΩ in the passives line belong to the LED data lines, the I2C bus and the OE line.
- **PCA9685 boards are not owned**: they are on the buy list (A2). The Pico cannot drive 25 servos itself (only 26 usable GPIO, six already used for LEDs, I2C, OE and sensors), hence two I2C boards. The 5 servos on hand can be wired straight to the Pico for a first bench test.
- **Power limiter written** (`shared/BoardKit/Sources/BoardKit/PowerLimiter.swift`): input is every LED's absolute current draw (amps, 60 mA at full white); if a bus total is over its budget (5 A per buck, idle draw of 1 mA per LED taken off first) every LED is multiplied by the same factor, so contrast and colours are kept and black LEDs leave their share to the bright ones. The factor is the smaller of the two buses, so both halves dim equally (no step across the board). The firmware that calls it each frame is not written yet.
- **Stand (idea, not designed):** a V-shaped support whose vertex hinges at the middle of the back; for the desk the two legs open and rest on the table, for the wall the legs fold flat against the back and the board hangs from them. Simple and sturdy: nothing complicated or flimsy. Details later.
