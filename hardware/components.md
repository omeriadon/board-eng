# Dither Board — Component Research and Costing

> **Rev 16 note:** the current, consolidated list is [`ingredients.md`](ingredients.md). Where this research conflicts with it (LED module, 5 V PSU, barrel jack, fuse holder, N = 5, USD totals), `ingredients.md` wins: the design is now 600 WS2815 LEDs on custom tile PCBs, three chargers + two bucks, MX1508 drivers, prices in AUD. This file is kept for the research and source links. **Rev 26:** the stepper, MX1508, 74HC595, WS2815 and per-tile-board material below is superseded by the servo / PCA9685 / 5 × 5 module design.

_Researched 2026-11-20. Companion to `ingredients.md` (parts list) and `docs/context.md` (decisions)._
_Scope: concrete models, real listings, honest prices, N = 4 vs N = 5 with k = 4._

## 0. Read this first (headline findings)

1. **Honest totals are above the brief.** With real (non-promo) prices, the full N=4 build is about **US$125** and N=5 about **US$155**, before GST and shipping. The lean versions are in §6. Only N=4 with several things supplied free gets near the **US$110** stretch. Nothing gets near US$80.
2. **AliExpress "AU$1.49" prices are not real unit prices.** Almost every card showing it carries "New shoppers save…", and the 8 mm motor page says **"Max. 1 pcs/shopper at this price"**. Its regular price is AU$4.86. I used regular or pack prices throughout.
3. **Bare-screw motor found.** SINONING sells the 8 mm 2-phase 4-wire micro stepper with a bare 2 mm screw and no slider frame, at **US$1.09**. I could not find any AliExpress listing that sells it that way. Every AliExpress listing I opened shows the stamped slider frame. See §1.1.
4. **LED mounting: no off-the-shelf option hits your 9.1 mm cell pitch.** `tile.py` has `CELL = RIM_INNER / K = 36.4 / 4 = 9.1 mm`. Details and recommendation are in §2.
5. **The power path needs care.** A 10 A rail is too much for the usual DC-022B barrel jack (listed at 3 A) and for the cheap 5 V 10 A "LED driver" bricks (mains screw terminals in a metal case, not a student-safe plug-in). See §1.6.
6. **Logic-level trap:** 74HC595 on 5 V needs ≥ 3.5 V logic-high, but the Pico gives 3.3 V. Power the 595s from 3.3 V, or use 74HCT595. See §1.4.

**Conventions.** Prices are USD, converted from AliExpress AU storefront AUD at **0.69 USD/AUD** (FRED 2026-11-06: 0.6875; sources in §8). AliExpress AU prices are **ex-GST**; checkout adds 10 % GST. Confidence tags:

- **[P]** = I opened the item page and read it.
- **[C]** = search-result card only (pack size or variant not fully verified).
- **[E]** = my estimate, no listing checked.

---

## 1. Components

### 1.1 Stepper motor (per tile)

**Recommended: bare lead-screw version** (the builder designs their own drive).

| Item | Detail |
|---|---|
| Model | SINONING "Mini 8mm Precison Stepper Motor 2-phase 4-wire … long Linear Screw shaft" (SKU 4000386995771). Sister listing SKU 4000370468991 shows **$0.61** with "Shaft Diameter: 8mm". |
| Specs (seller) | 8 mm body, 8.3 mm tall, **2 mm screw, 28 mm screw length**, 3 g, 2-phase 4-wire. No slider, no frame. Seller says "we can not test". |
| Price / stock | **US$1.09** each [P], 489 in stock; the other listing is $0.61 [P], 984 in stock. Shipping not checked, so I allow $4 [E]. |
| Source | https://www.sinoning.com/product/mini-8mm-precison-stepper-motor-2-phase-4-wire-precision-long-linear-screw-shaft-stepping-motor/ and https://www.sinoning.com/product/micro-precision-linear-screw-stepper-motor-mini-8mm-2-phase-4-wire-stepping-motor-2mm-dia-shaft-26-5mm-screw-length/ |

Caveats:

- **The nut is not included.** Buy M2 brass nuts (~100 for ~$1.50 [E]). Thread pitch is **unverified**. Context says M2×0.4 (0.4 mm ÷ 20 steps = 0.02 mm/step). Buy 2–3 motors first and try a nut and calipers.
- **Usable stroke is under 28 mm.** The screw must clear the motor face and an end bearing or guide, so the usable stroke is likely ~15–20 mm.
- **Coil resistance is unknown for the bare listing.** Related PM08-2 data sheet: 3.3 V rated, 40 Ω ±7 % (https://temperosystems.com.au/?p=28605, an AU stockist for the PM08-2 with the same 8 mm body; price not checked). The slider listing below says 16.8 Ω.
- **A listing with no tested specs is a risk.** Order 3 as a pilot before ordering the rest.

**Alternative: with-slider version** (framed, brass slider, guide rod).

| Listing | Price | Notes |
|---|---|---|
| AliExpress "Micro 8mm 2-phase 4-wire Precision Stepper Motor DC 5V 14mm … Slider Nut", https://www.aliexpress.com/item/1005009294269843.html | **AU$2.50 = US$1.73** each [P], no per-shopper cap, 440 sold | The honest bulk price for the slider type. |
| AliExpress "Mini Tiny 8MM … Metal Slider Nut Moving Block", https://www.aliexpress.com/item/1005007632197678.html | AU$1.49 promo (**max 1 per shopper**), regular **AU$4.86 = US$3.35** [P] | 163 sold. |
| AliExpress "Stroke 29mm … Screw Slider Nut", https://www.aliexpress.com/item/1005009130510952.html | A Motor / B Motor with board; AU$1.49 promo vs about AU$5–7 regular [P] | Description [P]: 8 mm body, **16.8 Ω**, ~0.25 A at 5 V short-circuit, 18°/step, **29.5 mm stroke**, 5.2 g, thrust "about 30 gf". The photo shows a 31 mm stamped frame with brass nut on a guide rod. |

Note the thrust figure: **~30 gf**, versus the 80 g assumed in `context.md`. Lighter heads or a lighter guide-plate fit are worth planning for.

AU stockist alternative: Tempero Systems lists the PM08-2 (no price checked).

### 1.2 Motor driver (per tile)

| Item | Model | Specs | Price / pack | Source | Conf. |
|---|---|---|---|---|---|
| Prototype | School L298N | ~2 V drop, ~43 mm | Free | | |
| **Final (recommended)** | **MX1508** (TC1508 clone) dual H-bridge module | 2–10 V, 1.5 A/channel, MOSFET, ~24×21 mm; 4 inputs, no enable pins, one stepper per module | AliExpress "1/5/10PCS Mini L298N DC Motor Driver, MX1508" AU$6.91 at 10 pcs = AU$0.69/pc = **US$0.48/pc** (pack size not fully verified) | https://www.aliexpress.com/w/wholesale-MX1508-motor-driver-module-10pcs.html | [C] |
| Alternative | DRV8833 module | 2.7–10.8 V, 1.5 A/channel, smaller, nSLEEP pin | ~AU$3.52 per listing variant; **est. US$0.50–0.80/pc** | https://www.aliexpress.com/w/wholesale-DRV8833-motor-driver-module.html | [C] |

Quantity: N² + spares.

### 1.3 Controller

| Item | Model | Price | Source | Conf. |
|---|---|---|---|---|
| Raspberry Pi Pico W (or Pico 2 W) | Official board, CYW43439 Wi-Fi + BLE | School: free. Buying: **~US$7** official list price [E]. Core Electronics AU: **AU$9.50 inc GST ≈ US$6.55** (search snippet, undated). Pico WH (headers): AU$11.90 | https://core-electronics.com.au/raspberry-pi-pico-w-wireless-wifi.html | [C] |

### 1.4 Logic

| Item | Model | Price | Notes | Conf. |
|---|---|---|---|---|
| Shift registers | **SN74HC595N** DIP-16, 10 pcs | AliExpress cards range AU$1.00–3.11 per 10; I used AU$2.00 = **US$1.38 / 10** | N=4: 8 chips needed (1 per 2 motors); N=5: 13. Buy 1 pack for N=4 and 2 packs for N=5. **Power them from 3.3 V** (so outputs match MX1508/DRV8833 3.3 V logic and the Pico) or use **74HCT595** at 5 V. At 5 V, V_IH is 3.5 V, which the Pico's 3.3 V data/clock can't guarantee. | [C] |
| Level shifter | **SN74AHCT125N** DIP-14, 5 pcs | AU$3.45 per 5 = **US$2.38** per pack | 1 needed. LCSC cheaper per chip but adds shipping. | [C] |
| Series resistor | 330–470 Ω | in resistor kit | | [E] |

### 1.5 LEDs (per tile, k²=16) — see §2 for the mounting decision

| Option | Part | Price | Conf. |
|---|---|---|---|
| **Recommended: 4×4 WS2812B-5050 module**, 30×30 mm, 16 LEDs (~7.5 mm pitch), 5 V/GND/DIN/DOUT pads | AliExpress "5/10PCS 16Bit RGB 4x4 LED WS2812B 5050 Matrix Module", https://www.aliexpress.com/item/1005010216139423.html : AU$6.95 for 5 = **US$0.96/module** (77 sold) | **[P]** |
| Single pieces | https://www.aliexpress.com/item/1005007020942337.html : AU$2.14 each = US$1.48 (396 sold) | [P] |
| Alternative: bare WS2812B-5050 | AliExpress 100 pcs "WS2812B RGB LED Chip 5050SMD White PCB" AU$6.68 = **US$0.046 each**. LCSC C114586 (Worldsemi WS2812B-B/W): ~US$0.047–0.056 each at 1000+, reel of 1000, cached prices inconsistent. https://www.lcsc.com/product-detail/C114586.html | [C] |
| 100 nF 0805 caps (bare option only) | ~US$0.01 each | [E] |
| Module dimensions | 30×30 mm, 5×5 mm diodes (stockist pages: makerlab-electronics, gleanntronics). **Pitch ≈ 7.5 mm is my inference (30 ÷ 4), not a stated spec.** Measure on arrival. | [C] |

### 1.6 Power

| Item | Recommendation | Price | Notes | Conf. |
|---|---|---|---|---|
| **5 V PSU** | A **plug-in 5 V 6–10 A adapter with a barrel plug** (mains-isolated, enclosed). | **~US$12–20** [E] | The cheap AliExpress "5V 10A 50W LED power supply" (AU$9.31 = US$6.4, AU$15.19 = US$10.5 [C]) is an open mains-terminal metal-case driver. Not recommended for a classroom object. Check **RCM/AU compliance** of any imported supply; a test-and-tagged or locally bought plugpack is safest. I budgeted **US$16**. | [E] |
| Current reality check | Cap LEDs at ~20–25 % (≈4–5 A for 400 LEDs). Motors draw ~0.3–0.6 A each when both coils are on (16.8 Ω → 0.3 A/coil), so stagger to ≤ 8 energised at once. A 5 V 5–6 A supply may be enough; **decide after the prototype**. | | | |
| **Barrel jack** | **DC-022D 10 A** panel jack with 15 cm wire (AliExpress AU$2.19 per pack = **US$1.51**) | $1.51 | The standard DC-022B is listed at 3 A: don't use it at 5–10 A. | [C] |
| Rocker switch | KCD1 15×21 mm, 2-pin, 6 A/250 V (10 A/125 V), AU$0.30/pc = **~US$1.00 per 5** | | AC-rated; fine at 5 V DC for this duty. | [C] |
| Fuse + holder | 5×20 mm inline holder **with 16 AWG leads** + 100 assorted fuses kit, AU$8.62 = **US$5.95** | | Cheaper 5-pack holders (AU$1.49, 22 AWG leads) are too thin for 10 A. You could rewire them yourself. | [C] |
| 1000 µF 10 V electrolytic | AliExpress 10 pcs ≈ AU$2.99 = **US$2.06** | | Need 1–2. | [C] |

### 1.7 Sensors and indicators

| Item | Model | Price | Conf. |
|---|---|---|---|
| LDR | GL5528, 10 pcs AU$1.32 = **US$0.91** | | [C] |
| NTC 10 kΩ | MF52 B3950, 10 pcs AU$0.96 = **US$0.66** | | [C] |
| Status LED + resistor kit | assorted | **~US$3** (with 10k/330/4.7k resistors) | [E] |
| Optional: HLK-LD2410C mmWave | AU$5.19 = **US$3.58** (416 sold) | Not in totals | [C] |

### 1.8 Boards, wiring, connectors

| Item | Model | Price | Notes | Conf. |
|---|---|---|---|---|
| Main board | 5×7 cm double-sided perfboard, 10 pcs AU$4.52 = **US$3.12** | | | [C] |
| Row boards | 9×15 cm perfboard × N | ~US$0.80 each (N=4 $3.2, N=5 $4.0) | 5×7 is too small for 5 drivers plus 3 shift registers per row. | [E] |
| Headers | male + female strips | ~US$3 | | [E] |
| **Tile connectors** | **JST-XH 2.54 mm 4-pin** sets (housing + header), 2 per tile | ~US$0.10/pair (N=4 $3.2, N=5 $5.0) | **I recommend XH, not SH/ZH.** JST-SH (1.0 mm) only fits perfboard through breakout adapters. Pre-crimped 10 cm SH 4-pin cables are AU$2.80 per 10 = US$1.93 [C] if you want SH. | [E] |
| Silicone hookup wire | 26–28 AWG, 4 colours | ~US$3 | Tile flex harness. | [E] |
| Power wire | 18–20 AWG red/black + Wago/terminal blocks | N=4 ~$3.5, N=5 ~$4.5 | | [E] |
| Zip ties | | ~US$1 | | [E] |

### 1.9 Acrylic and fixings

| Item | Model | Price | Notes | Conf. |
|---|---|---|---|---|
| **Smoked "LED" diffuser acrylic, 2 mm** | AliExpress "Translucent Black … Acrylic Board … LED Screen Cover 2/3/5/8 mm", AU$13.29 = **US$9.17** (700 sold); a cheaper listing is AU$7.40 = $5.1 | Sheet size and variant **not verified**: need ≥ 170×170 mm (N=4) or ≥ 205×205 mm (N=5) for the diffuser squares. Check dimensions before ordering. | https://www.aliexpress.com/w/wholesale-smoked-black-translucent-acrylic-sheet-2mm.html | [C] |
| Black + clear 3 mm acrylic (bezel, guides, motor plate, back, sides) | | **Likely free at school (ask).** If bought: **~US$25–35** [E] for ~0.35 m². | Excluded from the main totals. | [E] |
| M3 threaded rod (4 × 150 mm) | 304 stainless full-thread, AU$1.61 card | **~US$2.50** | M3 nuts come from the screw kit. | [E] |
| Screws + nuts kit (M2, M3 …) | "1 Box M1.6–M8 … Hex Socket Screw Kit", AU$3.29 = **US$2.27** | | Covers M2 motor screws and M3 hardware. | [C] |
| Heat-set inserts | Brass M2/M3 kit, AU$4.23 = **US$2.92** | | Optional. | [C] |
| PTFE dry lube | "3D printer PTFE lubrication pen", AU$4.91 = **US$3.39** | | **Free alternative:** graphite pencil on the stems. | [C] |
| PLA, paint, laser cutting, L298N, Pico (maybe) | School/home | Free | | |
| Stand parts | TBD (not costed) | | | |

---

## 2. LED mounting without a custom PCB

**Constraint from the CAD:** `hardware/cad/tile.py` has `PITCH = 40`, `HEAD = 38.8`, `RIM_WALL = 1.2`, `K = 4`, so each light cell is **9.1 mm**. Anything else needs a CAD tweak to the cell pitch.

| Option | LED pitch | Fits 9.1 mm cell? | Effort per tile | Cost per tile (16 LEDs) | Verdict |
|---|---|---|---|---|---|
| **A. Premade 4×4 WS2812B module** | ~7.5 mm | No; **block is 30 mm**, so the printed grid needs a 7.5 mm cell (change one parameter) | ~4 solder joints | **$0.96** | **Recommended** |
| B. Bare 5050 chips on a cut perfboard | 7.62 mm or 10.16 mm only (3 or 4 holes) | 10.16 mm × 4 = 40.6 mm exceeds the 38.8 mm head. 7.62 mm × 4 = 30.5 mm fits with the same CAD change as A. | 16 LEDs + 16 caps, ≥ 64 joints. Pads of a 5050 don't land on the 2.54 mm grid, so you bridge with wire. Over 1,600 joints at N=5. | $0.74 LEDs + $0.16 caps + perfboard ≈ $1.1 | Fallback only |
| C. Bare chips glued in printed pockets at exactly 9.1 mm, hand-wired | 9.1 mm | Yes | 16 LEDs × 4 wires each by hand | ~$0.9 | Exact pitch but heavy labour |
| D. 10 mm round pixel boards ("Dia 10 mm WS2812B board") or 10 × 3 mm heatsink-board chips | 10 mm | Round boards at 10 mm pitch give 40 mm, wider than 38.8 mm | Each board still needs wiring | ~$0.05–0.10 each | Not verified, dimensions unclear |
| E. 16×16 flexible WS2812B panel cut into 4×4 blocks | 10 mm | No (40 mm vs 38.8 mm) | Cutting breaks the serpentine data chain, so about 16 jumpers per block | ~$17–30 per 256 LEDs [E] | Not recommended; **not priced or opened** |

**Recommendation: A (premade module).** Cost is about the same as bare LEDs plus caps plus perfboard, and it avoids soldering 16 chips per tile. The module's pads and board margins sit behind the black printed rim and smoked diffuser.

**Conflict to resolve:** `context.md` §6 records that the builder rejected premade 4×4 boards (resistors, board colour, edge margins, and 9.1 mm pitch). The margins and board colour are hidden by the head and diffuser. The pitch is the real cost: ~7.5 mm instead of 9.1 mm. If 9.1 mm is non-negotiable, use C. If the builder is happy with a 30 mm LED block, use A and change the CAD cell.

Check the module's PCB colour and corner pads before committing; AliExpress photos show black or blue boards.

---

## 3. Quantities and costs

**Ordering model:** spares included (N=4: +2 motors, drivers, modules; N=5: +3 motors/drivers, +2 modules). Packs rounded up. Prices are USD ex-GST.

| # | Item | Unit / pack | N=4 qty | N=4 cost | N=5 qty | N=5 cost |
|---|---|---|---|---|---|---|
| 1 | Bare-screw 8 mm stepper (SINONING) | $1.09 ea | 18 | $19.62 | 28 | $30.52 |
| 2 | M2 brass nuts | $1.50 / 100 [E] | 100 | $1.50 | 100 | $1.50 |
| 3 | 4×4 WS2812B modules | $4.80 / 5 | 20 (4 packs) | $19.18 | 30 (6 packs) | $28.78 |
| 4 | MX1508 drivers | $0.48 ea (pack 10) | 18 → 2 packs | $9.54 | 28 → 3 packs | $14.31 |
| 5 | 74HC595N | $1.38 / 10 | 8 → 1 pack | $1.38 | 13 → 2 packs | $2.76 |
| 6 | 74AHCT125N | $2.38 / 5 | 1 pack | $2.38 | 1 pack | $2.38 |
| 7 | Pico W | $0 school / $7 | 1 | $0 | 1 | $0 |
| 8 | 5 V plug-in PSU | ~$16 [E] | 1 | $16.00 | 1 | $16.00 |
| 9 | DC-022D 10 A jack | $1.51 / 5 | 1 pack | $1.51 | 1 pack | $1.51 |
| 10 | KCD1 rocker | $1.00 / 5 | 1 pack | $1.00 | 1 pack | $1.00 |
| 11 | Fuse holder 16 AWG + fuse kit | $5.95 | 1 | $5.95 | 1 | $5.95 |
| 12 | 1000 µF 10 V | $2.06 / 10 | 1 pack | $2.06 | 1 pack | $2.06 |
| 13 | LDR GL5528 | $0.91 / 10 | 1 | $0.91 | 1 | $0.91 |
| 14 | NTC 10 k MF52 | $0.66 / 10 | 1 | $0.66 | 1 | $0.66 |
| 15 | Status LED + resistor kit | ~$3 [E] | 1 | $3.00 | 1 | $3.00 |
| 16 | Perfboard (main 5×7 pack + N row boards) | $3.12 + $0.80 × N | | $6.32 | | $7.12 |
| 17 | Headers | ~$3 [E] | | $3.00 | | $3.00 |
| 18 | JST-XH sets (2/tile) | ~$0.10/pair [E] | 32 | $3.20 | 50 | $5.00 |
| 19 | Wire (hookup + power + terminals) | [E] | | $6.50 | | $7.50 |
| 20 | Zip ties | [E] | | $1.00 | | $1.00 |
| 21 | Smoked 2 mm acrylic | $9.17 | 1 sheet | $9.17 | 1 sheet | $9.17 |
| 22 | M3 threaded rod | ~$2.50 [E] | 4 | $2.50 | 4 | $2.50 |
| 23 | Screw/nut kit | $2.27 | 1 | $2.27 | 1 | $2.27 |
| 24 | Heat-set inserts | $2.92 | 1 | $2.92 | 1 | $2.92 |
| 25 | PTFE pen | $3.39 | 1 | $3.39 | 1 | $3.39 |
| | **Subtotal, ex-GST, ex-shipping** | | | **$124.96** | | **$155.21** |

Not included: black/clear 3 mm acrylic (free at school; ~$25–35 if bought), Pico W if bought (+$7), optional LD2410C (+$3.58), stand parts (TBD).

---

## 4. Totals against the budget

| Scenario | N=4 (16 tiles, 256 LEDs) | N=5 (25 tiles, 400 LEDs) |
|---|---|---|
| **Full list, ex-GST** (§3) | **$124.96** | **$155.21** |
| **Lean** (drop PTFE pen, inserts, zip ties; cheap fuse $2 and smaller diffuser sheet $5.10; PSU $12) | **$105.63** | **$135.88** |
| **Lean + school supplies L298N drivers** (prototype only; see warning) | **$96.09** | **$121.57** |
| Lean + free drivers, **+10 % GST + ~$6 shipping** | **~$112** | **~$140** |

Against the limits:

| | ≤ $80 | ≤ $110 |
|---|---|---|
| N=4 lean | Over by ~$26 | Under by ~$4 ex-GST, over by ~$12 with GST and shipping (~$122) |
| N=4 lean + free drivers | Over by ~$16 | Under by ~$14 ex-GST, over by ~$2 with GST and shipping (~$112) |
| N=5 lean | Over by ~$56 | Over by ~$26 |
| N=5 lean + free drivers | Over by ~$42 | Over by ~$12 ex-GST, ~$30 with GST and shipping |

**Warning on free L298N:** at 43 mm each, 25 of them will not fit the electronics bay. The free-drivers row is a budget view only; the final build should use MX1508 or DRV8833.

If the brief's "$80" is **AUD**, it is ~US$55, which none of these meet. Ask the teacher which currency.

---

## 5. Biggest cost drivers (N=5 full list)

| Rank | Item | $ | Share |
|---|---|---|---|
| 1 | Stepper motors (28) | $30.52 | 20 % |
| 2 | LED modules (30) | $28.78 | 19 % |
| 3 | PSU | $16.00 | 10 % |
| 4 | MX1508 drivers (28) | $14.31 | 9 % |
| 5 | Smoked acrylic | $9.17 | 6 % |
| 6 | Wire, connectors, perfboard, headers (combined) | ~$23 | 15 % |

Motors, LEDs and drivers are about 47 % of the total, and all three scale with N².

---

## 6. Ways to cut cost

1. **Choose N=4.** Saves about $30 (full list); roughly $25 of that is motors, drivers and LED modules.
2. **Order motors from SINONING at $0.61–1.09** and skip the with-slider alternative ($1.73–3.35 each). The difference at N=5 is 25 × $1–2.
3. **Get the PSU free or cheap.** Ask the school (they supply a regulator), or reuse a 5 V 5–6 A plugpack. Cap LEDs at 15–20 % to match. That is worth $10–16.
4. **Cut the optional extras:** PTFE pen (use graphite pencil), heat-set inserts (print bosses or use self-tapping M2), zip ties. Total $7.3.
5. **Use the cheaper diffuser acrylic** (AU$7.40, $5.10) once you confirm the sheet size. Or ask whether the school has smoked acrylic offcuts.
6. **Fewer spares** once the pilot of 3 motors works. Each spare motor + driver + module is about $2.50.
7. **Smaller k.** With bare chips, k=3 is 225 LEDs at N=5 instead of 400. The premade-module route doesn't offer 3×3, so this saves ~$16 only if you hand-solder.
8. **One order for AliExpress items** to avoid separate shipping and to share GST handling.
9. **Local AU stockists** (e.g. Core Electronics for the Pico W at AU$9.50 inc GST) cost more per part but remove the 2–4 week wait and the import-GST step.

---

## 7. Decisions the builder must make

1. **LED mounting:** premade 4×4 module with a 7.5 mm cell (recommended), or exact 9.1 mm pitch with hand-wired bare chips (§2). This overrides the earlier "premade boards rejected" note.
2. **Budget currency:** is "$80 / $110" USD or AUD?
3. **Motor order:** buy 3 bare-screw pilots first; verify the M2 thread pitch and coil resistance, then order the rest.
4. **PSU:** which supply, and does the school or teacher require a tested/tagged one? Choose between 5–6 A and 10 A after the prototype.
5. **Which items are really free:** Pico W, L298N (and how many), acrylic, smoked sheet, PSU.
6. **N=4 or N=5**, given the totals in §4.

---

## 8. Sources

- SINONING bare-screw motor: https://www.sinoning.com/product/mini-8mm-precison-stepper-motor-2-phase-4-wire-precision-long-linear-screw-shaft-stepping-motor/ ; https://www.sinoning.com/product/micro-precision-linear-screw-stepper-motor-mini-8mm-2-phase-4-wire-stepping-motor-2mm-dia-shaft-26-5mm-screw-length/
- AliExpress slider motors: https://www.aliexpress.com/item/1005009294269843.html ; https://www.aliexpress.com/item/1005007632197678.html ; https://www.aliexpress.com/item/1005009130510952.html
- PM08-2 8 mm micro stepper (AU stockist, spec data): https://temperosystems.com.au/?p=28605
- 4×4 WS2812B modules: https://www.aliexpress.com/item/1005010216139423.html ; https://www.aliexpress.com/item/1005007020942337.html ; module dimensions: https://www.makerlab-electronics.com/products/4x4-rgb-module-ws2812b , https://gleanntronics.ie/en/products/4x4-bits-square-rgb-led-matrix-ws2812b-5050-leds-4732.html
- LCSC WS2812B-B/W: https://www.lcsc.com/product-detail/C114586.html
- Core Electronics Pico W: https://core-electronics.com.au/raspberry-pi-pico-w-wireless-wifi.html
- AliExpress search pages used for card prices (AU storefront, 2026-11-20): MX1508, DRV8833, 74HC595, 74AHCT125, barrel jacks, KCD1 switch, fuse holders, 1000 µF caps, GL5528, MF52, perfboard, acrylic, threaded rod, inserts, PTFE, LD2410C, JST-SH. Each is `https://www.aliexpress.com/w/wholesale-<query>.html`.
- AUD/USD: FRED DEXUSAL, 2026-11-06 = 0.6875; other sources 0.68–0.70 (Wise, xe, exchangerate.guru). Check a live rate before ordering.
