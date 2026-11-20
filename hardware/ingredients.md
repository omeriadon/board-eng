# Dither Board — Ingredients List

_Last updated: 2026-11-20 (rev 9)_

**CAD / blueprints:** `hardware/cad/tile.py` (parametric) generates `hardware/cad/out/`: tile head + stem STLs, clearance test coupon, laser PDFs (1:1 mm) (diffusers, front bezel, guide plates) and `blueprint_tile.svg`. Repo: github.com/omeriadon/board-eng

**Budget:** brief says ≤ **$80** total component + material cost. The builder will go up to ~**$110**.
**Rough total at N=5, k=4 (25 tiles, 400 LEDs):** ~$95–110, with the Pico W and drivers free. **At N=4:** ~$80–90. Shipping is the main risk.

**Mechanical drive requirement:** met by the **screw drive** (lead screw + slider nut in each micro stepper), which the brief lists by name.

**Rough tile design:** see `tile-design.html` (exploded tile, board section, front view).

This is the full parts list. Grid size is still a variable, so quantities are written in terms of these:

- **N** = moving tiles per side (the grid has N² tiles; candidates are 2, 3, 4, 5 or 6)
- **k** = LEDs per tile side (each tile has k² LEDs; candidates are 3, 4 or 5)
- **P** = total LEDs = N² × k²

Prices are rough estimates for later optimisation. "Free" means the school or home supplies it.


**Specific models, prices and links: see [`components.md`](components.md)** (Sonnet research, 2026-11-20; some prices are estimates marked [E]). Key corrections from it:
- **Motor price:** the ~$1.10 motor price is a one-per-person new-buyer deal. The real price is ~$1.70 (with slider) to ~$3.35. **The bare lead-screw version** (needed if the builder designs the screw drive) is from SINONING at ~$0.60–1.10: 2 mm screw, 28 mm long, **no nut** (buy M2 brass nuts). Order 3 pilots first.
- **Motor thrust:** the slider listing says ~30 gf, not 80 g. Keep tiles light and test early.
- **74HCT595**, not 74HC595 (or power the 595s from 3.3 V). The Pico's 3.3 V signals aren't reliable for 5 V HC logic.
- **Barrel jack:** DC-022D (10 A), not DC-022B (3 A). **PSU:** a fully enclosed plug-in 5 V 10 A brick (~$16), not an open-terminal metal-case unit.
- **Connectors:** JST-XH (perfboard-friendly), not SH/ZH.
- **Totals (USD, before GST/shipping):** N=4 lean ≈ $106 ($96 with free L298Ns); N=5 lean ≈ $136 ($122). **Neither fits $80**; N=4 is near the $110 stretch.

---

## 1. Per tile (multiply by N²)

| # | Item | Qty per tile | Notes | Est. unit price |
|---|---|---|---|---|
| 1.1 | **Micro linear slider stepper**: 8 mm, 2-phase, 4-wire, lead screw + slider nut | 1 | 3.3–5 V, ~20 Ω/phase, M2×0.4 screw. Stroke 10 mm (5–10 levels) or 15–20 mm (more levels). Example: VIC-TECH VSM08102-type. Search AliExpress for "8mm stepper motor slider". | ~$1.10–3 |
| 1.2 | **Motor driver, one per tile.** Prototype: school **L298N** (free; bulky ~43 mm, old bipolar-transistor design with a ~2 V drop, so the coils get ~3 V from 5 V). Likely final: **MX1508** (~$0.30–0.50, ~24×21 mm) or **DRV8833** (~$0.50–1, ~18×16 mm) modules, which have MOSFETs with almost no voltage drop. | 1 | Every option drives exactly one bipolar stepper (one channel per coil) via 4 inputs from the shift registers. Swapping L298N → MX1508 costs ~$8–15 for 16–25 tiles. | Free / ~$0.30–1 |
| 1.3 | **WS2812B-5050 addressable RGB LED** (bare SMD, square package) | k² | Square 5×5 mm body with a built-in driver, so no resistor needed. The square pixel look comes from the grid and diffuser (1.6–1.7). | ~$0.03–0.08 |
| 1.4 | **100 nF capacitor** (0603/0805 SMD) | k² | Decoupling, one per LED as in the datasheet. | ~$0.005 |
| 1.5 | **Custom tile PCB**, black soldermask, sized edge-to-edge | 1 | Holds the k² LEDs at exact pitch, with IN/OUT pads for 5 V, GND, DIN/DOUT. JLCPCB (optionally with SMT assembly). | ~$0.20–1 (batch) |
| 1.6 | **Tile head**: black PLA, rim + k×k square light grid in one print (printed face-down) | 1 | ~39×39×13 mm at 40 mm pitch; 1 mm grid walls, 8 mm tall cells; 2 mm lip holds the diffuser. Batch-printed. | Free |
| 1.7 | **Smoked "dead-front" diffuser square**: smoked/tinted black "LED acrylic" (~2–3 mm), laser-cut | 1 | Looks black when off, light shows through when on, so the all-black rule holds. Cut all squares from one sheet in one laser job and glue one per tile. Alternatives: a thin translucent black PETG/PLA print, or a thin white diffuser layer under the smoked one for more even squares. It cuts brightness, so LEDs run brighter. | ~$5–10 per sheet total, or free if the school has it |
| 1.9 | **Guide holes**: 20.6 mm square holes in the front + rear MDF guide plates | — | Keep the stem straight; the motor only pushes. | Free |
| 1.10 | **Detent / click feature** (printed flexure or bumps) | 1 | Optional: gives a soft keyboard-like click at each level. | Free |
| 1.11 | **Flexible tile wiring**: 3–4 core silicone wire, ~26–30 AWG, ~10 cm | 1 set | 5 V, GND, data in/out, with slack for 10–20 mm of travel. | ~$0.10 |
| 1.12 | **Small connectors** (JST-SH/ZH or similar), tile ↔ harness | 1–2 pairs | So tiles can be swapped and repaired. | ~$0.10 |
| 1.13 | **M2 screws** (motor mount) | ~2 | | ~$0.02 |

## 2. Per 2 tiles (multiply by ⌈N²/2⌉)

| # | Item | Qty | Notes | Est. unit price |
|---|---|---|---|---|
| 2.1 | **74HC595 shift register** (DIP-16 or SMD) | 1 per 2 tiles | 8 outputs, enough for 2 steppers × 4 control lines. Chained so the Pico controls all motors with about 3 pins. | ~$0.05–0.20 |

## 3. Fixed / one-off

### Electronics

| # | Item | Qty | Notes | Est. price |
|---|---|---|---|---|
| 3.1 | **Raspberry Pi Pico W or Pico 2 W** | 1 | The only computer. **Built-in Wi-Fi (2.4 GHz) + Bluetooth (BLE)** on one chip (Infineon CYW43439), so no extra module is needed. PIO handles LED timing and stepping; runs Embedded Swift. Ask the school for a W. Buying one costs ~$6–7. (Separate modules if stuck with a plain Pico: HM-10 BLE ~$2–4, ESP-01 Wi-Fi ~$2, but a Pico W is simpler.) | Free (ask) / ~$6–7 |
| 3.2 | **5 V power supply** (external brick) | 1 | Size it from N and k. Roughly: LEDs P × 60 mA at full white, capped in firmware to ~20–25%, plus about 0.5 A per stepper moving at once. 5 V 10 A is likely enough for most configs. | ~$10–15 |
| 3.3 | **DC barrel jack** (panel mount) | 1 | | ~$0.50 |
| 3.4 | **Power switch** (rocker or toggle) | 1 | The only control on the device. | ~$0.50 |
| 3.5 | **Inline fuse + holder** | 1 | Safety at 5–10 A. | ~$1 |
| 3.6 | **Bulk capacitor** 1000 µF 6.3–10 V | 1–2 | Across the LED supply. | ~$0.30 |
| 3.7 | **Level shifter for LED data**: 74AHCT125 / 74HCT245 | 1 | Converts the Pico's 3.3 V data to 5 V for the WS2812s. | ~$0.50 |
| 3.8 | **Data line resistor** 330–470 Ω | 1 | In series with the first LED's data in. | ~$0.01 |
| 3.9 | **Main board**: ~5×7 cm perfboard (no custom PCB) | 1 | Pico W, level shifter, sensor headers, status LED, bulk cap, fuse. | ~$1 |
| 3.9b | **Row boards**: perfboard/stripboard, one per tile row (N) | N | ⌈4N/8⌉ 74HC595 + N driver modules each; 5-wire bus to the next row. Breadboards for prototyping only. | ~$1 each |
| 3.10 | **Power wiring**: 18–22 AWG red/black, plus terminal blocks or Wago connectors | — | Bus wiring for 5 V and GND, fed into tile rows from several points. | ~$3 |
| 3.11 | **Hookup wire, headers, Dupont cables** | — | Driver ↔ shift register connections. | ~$2 |
| 3.12 | **Zip ties / cable clips** | — | | ~$1 |

### Structure

| # | Item | Qty | Notes | Est. price |
|---|---|---|---|---|
| 3.13 | **Laser-cut acrylic frame** (preferred over MDF for looks, durability and dimensional stability). **Black** acrylic for the front bezel (`laser_front_bezel_black.svg`). **Clear** acrylic allowed for the guide plates (`laser_guide_plate_x2.svg`), motor plate, sides and back, so the mechanism shows. Clear doesn't break the all-black rule (it's not a colour, and it's not the front). MDF is the fallback. | 1 set | ~22×22 cm plates for 5×5 tiles, ~3 mm thick, ~11 cm deep overall. Check whether school acrylic stock is free. | Free / ~$10–20 if buying sheet |
| 3.14 | **Matte black spray paint / primer** | — | Only needed for any MDF or printed parts that aren't already black. | Free (dad's) |
| 3.15 | **Black PLA filament** | ~0.5–1 kg | Tiles, grids, guides, stand. | Free |
| 3.16 | **Smoked black acrylic sheet** ("LED black acrylic") for diffusers, plus optionally a thin white diffuser film/PLA | 1 sheet | One laser job cuts all N² diffuser squares. | ~$5–10 / free |
| 3.17 | **Stand**: printed/MDF base and arm | 1 | Designed for looks. | Free |
| 3.18 | ~~Camera ball head~~ **dropped** (the builder wants a custom stand: a rotation joint at each side end + wooden supports to the centre, mountable on desk or wall) | — | Design later. | — |
| 3.18-alt | **Stand parts** (TBD): timber (free/cheap), 2× pivot bolts (M5/M6) + nylon washers, printed **worm + worm wheel** tilt mechanism (suggested mechanical drive), wall-mount plate | 1 set | | ~$2–5 |
| 3.18c | **M3 threaded rod** (×4, ~150 mm) + nuts / printed spacers | 1 set | Holds the plate stack at exact spacings. | ~$3 |
| 3.19 | **M3 screws, nuts, standoffs** (assortment) | 1 | Frame and electronics mounting. | ~$3–5 |
| 3.20 | **Heat-set inserts M2/M3** (optional) | ~20 | For printed parts. | ~$2 |
| 3.21 | **Rubber feet** | 4 | Under the stand base. | ~$1 |

## 3b. Sensors and extra outputs (required by the brief: 3 inputs, 3 outputs, ≥2 outputs driven by an automated input)

| # | Item | Qty | Role | Est. price |
|---|---|---|---|---|
| 3.22 | **LDR** + 10 kΩ resistor | 1 | **Input (automated):** room light → auto LED brightness, and dims or sleeps at night. Hidden behind a tiny hole in the black border. | ~$0.20 |
| 3.23 | ~~Presence sensor~~ **dropped**. Presence comes from the Mac/iPhone apps. Optional later: HLK-LD2410C 24 GHz mmWave (detects people sitting still, works through acrylic, UART) | 0 (opt. 1) | | ~$0 (opt. $3–5) |
| 3.23b | **NTC thermistor 10 kΩ** + 10 kΩ resistor | 1 | **Input (automated):** internal temperature → dims LEDs / pauses motors if it gets too hot. Thermal safety, and replaces the presence sensor as hardware input #2. | ~$0.20 |
| 3.24 | **Bluetooth app link** (built into the Pico W) | — | **Input (user):** iPhone/Mac apps set pattern, colour, speed and timers, plus Mac activity and Claude Code status. Optional extra: a colour sensor (TCS34725, ~$3) to pick a palette from a real object. | Free |
| 3.25 | **Status LED on the back** (single small LED + 4.7–10 kΩ resistor, or one extra WS2812 at the end of the chain) | 1 | **Output 3:** very dim "it's on" indicator through a small hole in the back plate. Driven from a Pico GPIO so it can also show status, e.g. slow breathing = Bluetooth connected. (No piezo; the builder dropped it.) | ~$0.05 |
| — | Outputs: **LEDs** (driven by the LDR), **stepper tiles** (driven by the presence sensor) and the **status LED** (3.25) | | Covers "3 outputs, ≥2 driven from an automated input". Risk: the teacher may count the status LED and the main LEDs as the same output type. If so, consider a different third output. | |

## 3c. Tile clearance and anti-collision (design rules)

- Tiles are located **only by their stems in the guide plates**, never by neighbouring tiles.
- **Gap between tile heads:** 1.0–1.5 mm (0.5–0.75 mm per side).
- **Stem ↔ guide-hole clearance:** 0.2–0.3 mm per side. Keep the two guide plates as **far apart** as possible: wobble at the head ≈ clearance × (lever ÷ guide span).
- **Prusa MK4S:** expect ±0.1–0.2 mm. Chamfer the head's first-layer edge 0.4 mm to beat elephant's foot. Print a **2×2 test coupon** first and tune the clearances.
- Chamfer or round the top edges of the heads so any brush glides instead of catching. Use PTFE dry lube or graphite on the stems.
- **Laser-cut** the guide-plate holes (accurate pitch). Consider 3 mm acrylic or a printed guide instead of MDF if humidity swelling is a problem.
- **Firmware safety nets:**
  - Micro steppers are too weak (~80 g) to break anything; they skip steps rather than crash.
  - Periodic **re-homing** (retract to the end stop when idle) clears any lost steps.
  - Optional soft limits / max speed.

## 4. Prototype / sample order (before committing to N)

| Item | Qty | Purpose |
|---|---|---|
| 8 mm slider stepper, 10 mm stroke | 3 | Main candidate |
| 8 mm slider stepper, 15–20 mm stroke | 2–3 | Test whether more levels are worth it |
| WS2812B-5050 LEDs | ~20 | One tile's worth (+ spares) |
| School dual H-bridge boards | 2 | Confirm they drive the stepper well |
| 74HC595 | 2 | Shift register test |
| Pico W / 2 W | 1 | |

## 5. Open questions affecting this list

- Can the school give a **Pico W / Pico 2 W**? (Builder will ask.)
- Final driver: keep the free L298N, or buy MX1508/DRV8833 (decide after the prototype).

- Exact **model and quantity of the school's motor drivers** (decides whether 1.2 is free for all N² tiles).
- Whether the school's Pico **has wireless** (plain Pico vs Pico W / 2 W).
- **N and k**: decide after price optimisation.
- **Stroke length**: 10 mm or 15–20 mm, decided after the prototype.
- **Tile PCB**: hand-solder or JLCPCB assembly.
