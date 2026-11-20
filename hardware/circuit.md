# Dither Board: Pico W pin map and circuit

_Rev 1, 2026-11-20. Geometry: 4 × 4 moving tiles, 6 × 6 LEDs each (24 × 24 = 576 LEDs), plus a fixed 24-LED status bar under the grid = **600 LEDs**, and 16 stepper motors. Supply: one 5 V brick. See `ingredients.md` for the parts and `docs/context.md` for decisions._

Pin numbers below are **physical pin numbers** (1–40, USB at the top) and GPIO names. Source for the reserved pins: the official Raspberry Pi Pico W datasheet (GP23, GP24, GP25 and GP29 talk to the Wi-Fi/Bluetooth chip and are not available; the on-board LED is on the radio chip, not on a GPIO).

---

## 1. The 3 inputs and 3 outputs (for the brief)

| | What | Pico pin | Automated? |
|---|---|---|---|
| **Input 1** | LDR (room light) | GP26 / ADC0 (pin 31) | Yes. Sets LED brightness, dims at night |
| **Input 2** | NTC thermistor (inside the enclosure) | GP27 / ADC1 (pin 32) | Yes. Too hot → LEDs dim, motors pause |
| **Input 3** | Bluetooth / Wi-Fi commands from the iPhone and Mac apps | Built into the Pico W | No (user) |
| **Output 1** | 600 WS2812B RGB LEDs (grid + status bar) | GP2–GP6 via level shifter | Driven by the LDR and NTC |
| **Output 2** | 16 stepper motors (tile height) | GP10–GP13 via shift registers and drivers | Driven by the NTC |
| **Output 3** | Status LED on the back | GP15 | Shows power / Bluetooth state |

Risk (unchanged): the teacher may count output 3 and output 1 as the same kind (both LEDs).

---

## 2. Pico W pin map

```
                          ┌───── USB ─────┐
   UART0 TX (debug)  GP0  1│●             ●│40  VBUS      leave unconnected
   UART0 RX (debug)  GP1  2│●             ●│39  VSYS  <-- 5 V logic rail via D1
                     GND  3│●             ●│38  GND
   LED data, row 0   GP2  4│●             ●│37  3V3_EN    leave unconnected
   LED data, row 1   GP3  5│●             ●│36  3V3(OUT) --> sensors, 595s
   LED data, row 2   GP4  6│●             ●│35  ADC_VREF  leave unconnected
   LED data, row 3   GP5  7│●             ●│34  GP28 ADC2  5 V monitor (opt.)
                     GND  8│●             ●│33  AGND  --> sensor grounds
   LED data, bar     GP6  9│●             ●│32  GP27 ADC1  NTC
   spare             GP7 10│●             ●│31  GP26 ADC0  LDR
   spare             GP8 11│●             ●│30  RUN       optional reset to GND
   spare             GP9 12│●             ●│29  GP22      spare
                     GND 13│●             ●│28  GND
  595 SRCLK         GP10 14│●             ●│27  GP21      spare
  595 SER           GP11 15│●             ●│26  GP20      spare
  595 RCLK          GP12 16│●             ●│25  GP19      spare
  595 OE (low=on)   GP13 17│●             ●│24  GP18      spare
                     GND 18│●             ●│23  GND
  spare (button)    GP14 19│●             ●│22  GP17      spare
 Status LED         GP15 20│●             ●│21  GP16      spare
                          └───────────────┘
```

| Pin | GPIO | Net | Connects to |
|---|---|---|---|
| 4 | GP2 | `LED0` | 74HCT245 A1 → 330 Ω → tile row 0 DIN |
| 5 | GP3 | `LED1` | 74HCT245 A2 → 330 Ω → tile row 1 DIN |
| 6 | GP4 | `LED2` | 74HCT245 A3 → 330 Ω → tile row 2 DIN |
| 7 | GP5 | `LED3` | 74HCT245 A4 → 330 Ω → tile row 3 DIN |
| 9 | GP6 | `LEDBAR` | 74HCT245 A5 → 330 Ω → status bar DIN |
| 14 | GP10 | `SRCLK` | all 74HC(T)595 pin 11 (SRCLK), in parallel |
| 15 | GP11 | `SER` | first 595 pin 14 (SER) |
| 16 | GP12 | `RCLK` | all 595 pin 12 (RCLK), in parallel |
| 17 | GP13 | `OE` | all 595 pin 13 (OE, active low), plus 10 kΩ pull-up to 3V3 |
| 20 | GP15 | `STATUS` | 4.7 kΩ → status LED anode, cathode to GND |
| 31 | GP26 | `LDR` | LDR/10 kΩ divider midpoint |
| 32 | GP27 | `NTC` | NTC/10 kΩ divider midpoint |
| 34 | GP28 | `V5MON` | optional: 10 kΩ/10 kΩ divider on the 5 V rail (reads 2.5 V) |
| 36 | 3V3(OUT) | `3V3` | dividers, 595 VCC (pin 16) and SRCLR (pin 10) |
| 39 | VSYS | `VLOGIC` | 5 V logic rail through D1 (1N5819) |
| 33 | AGND | | sensor ground (LDR and NTC dividers) |
| 3, 8, 13, 18, 23, 28, 38 | GND | `GND` | main ground |

Notes:

- GP0/GP1 are kept free for a debug serial header. GP7–GP9, GP14, GP16–GP22 are spare (a button, a second sensor, a fan).
- The firmware drives the five LED lines from PIO state machines, 800 kHz each. Four rows of 144 LEDs take about 4.4 ms per frame, the bar about 0.7 ms.
- The 595 chain uses plain GPIO (or an SPI peripheral on GP10/GP11). 64 bits at a few MHz take well under 0.1 ms.
- **OE is held high by the pull-up until the firmware has shifted zeros into all 595s and latched them**, then it goes low. That stops the motors twitching at power-up. The NTC cut-off can also set OE high to cut all motors at once.

---

## 3. Power

### 3.1 Distribution (one 5 V brick, fused branches)

```
 5 V brick (≥10 A, enclosed plug-in) ──► DC-022D jack (10 A) ──► rocker switch ──► F0 10 A fuse
                                                                                       │
                          ┌── 18 AWG ─────────────────────────────────────────────────┘
                          ▼
              ╔═══════════ 5 V BUS + GND BUS (terminal blocks / Wago / bus wire) ═══════════╗
              ║   2200 µF across the bus                                                    ║
              ╚══╤═══════╤═══════╤═══════╤═══════╤════════════╤══════════════╤═════════════╝
                 │F1     │F2     │F3     │F4     │F5          │F6            │F7
                 │3 A    │3 A    │3 A    │3 A    │2 A         │3 A           │1 A
                 ▼       ▼       ▼       ▼       ▼            ▼              ▼
              LED row 0 row 1  row 2   row 3   status bar   MOTOR rail     LOGIC rail
              (144 LEDs each, 5 V + GND run along the tile row)   (all driver VS+5V pins)   │
                                                                                      D1 1N5819
                                                                                      │
                                                                       Pico VSYS, 74HCT245 VCC
                                                                       (100 µF at the Pico)
```

- F1–F7 are resettable PTC fuses (or small blade fuses): hold current as shown. F0 protects the wiring from the brick.
- **Power injection (your question):** yes, every tile row gets its own feed straight from the bus. A heavy 20 AWG pair runs along each tile row behind the motor plate, and each tile taps 5 V and GND from it with its own thin silicone wire. Nothing is fed through a tile into the next one, so there is no voltage droop along a row and a broken tile wire only loses that tile's power. **Data is the only thing that daisy-chains**: row DIN → tile 0 → tile 1 → tile 2 → tile 3, each tile passing DOUT to the next DIN.
- Run every return (GND) back to the bus GND. Tie the logic ground to the same bus at one point (star ground), so the data lines share the LED ground.
- 100 µF + 100 nF close to each row of motor drivers; 100 nF at every LED (already in the design).
- Moving tiles use 26–28 AWG silicone with a service loop. One tile at the firmware cap is under 1 A, which these wires carry.

### 3.2 Budget (the supply decides the LED cap)

| Load | Worst case |
|---|---|
| LEDs: 600 × 60 mA at full white | 36 A (nowhere near possible) |
| Motors: 4 moving at once (`maxMovingTiles` = 4) × 2 coils × ~0.15–0.3 A | 1.2–2.4 A |
| Pico W (Wi-Fi), 74HCT245, 16 driver logic currents | ~0.4–0.9 A |
| **Left for LEDs on a 10 A brick** (15 % margin: 8.5 A) | **~5–6 A ≈ 15–16 % of full white** |

So the firmware should limit **LED current**, not just brightness: add up the red, green and blue values of the frame (about 20 mA per channel at full) and scale the whole frame down if the total passes the budget (about 5.5 A for a 10 A brick). Dither art averages far below full white, so you will rarely feel the limit. The old "25 % ≈ 9 A" figure would overload a 10 A brick once the motors and logic run.

### 3.3 Fewer amps with a higher voltage (12 V option)

Yes, but note what it does: **volts × amps = watts stays the same, so a higher voltage lowers the current, not the power.** What it buys is thinner wire, smaller fuses, less voltage drop, and an easy supply to buy (a 12 V 5 A plug-in brick is a standard item; a 5 V 10 A enclosed one is not).

| | 5 V design (above) | 12 V design |
|---|---|---|
| LED budget (same light) | ~27 W = 5.5 A | 27 W = **2.3 A** |
| Motors + logic (still need 5 V) | ~15 W = 3 A | 12 V → **5 V buck module** (~90 % efficient), ~1.7 A from 12 V |
| Total from the supply | ~8.5 A | **~3.7 A**, so a 12 V 5 A brick (60 W) |
| Per tile-row feed at the cap | ~1.3 A | ~0.55 A (fuses ~1 A hold, main fuse 5 A) |

What changes in the circuit:

- **LEDs:** 12 V WS2815 (6-pin 5050: VDD, DI, DO, GND, plus a backup data pair BI/BO) instead of WS2812B. Per the datasheets each channel is about 10–12 mA, so a pixel can draw ~0.36–0.43 W (a bit more than a WS2812B's 0.3 W). That is why the firmware cap should be in watts, not a percentage.
- **Motors, 74HCT245 and the Pico** run from a 12 V → 5 V **buck module** (an LM2596-type 3 A one is enough). Not the 7805: from 12 V it would turn 58 % of the power into heat.
- Everything in §4 stays the same, but the logic rail and motor rail come from the buck, and the LED rows come straight from the 12 V bus.
- **Unverified, check before ordering:** that bare WS2815 5050 chips are sold in small quantities at a sensible price, what voltage their data input needs (the 74HCT245 outputs 5 V, which should be fine), and how to wire BI/BO (tie BI to the data line, or follow the datasheet). Order ~20 as a test tile first.

**Cost reality:** a new 12 V 5 A brick is about **AU$46** (e.g. Mean Well GST60A12 at Core Electronics, Australian-approved), plus ~AU$5 for the buck. A smaller 12 V 3 A plug-pack costs less and works if the LED cap is lowered to ~15 W. This is on top of the ~AU$93 total, which assumed a free supply.

### 3.4 Chosen supply: the 12 V 4 A charger (48 W)

Candidates found at home: 12 V 4 A (48 W), 16 V 3.75 A (60 W), 20 V 3.33 A (66 W). **The 12 V one is the pick:** the WS2815 LEDs run straight from it, so only one buck module is needed (12 → 5 V for motors, logic and the level shifter). The other two need two bucks and 12 V WS2815 LEDs would still need a buck down to 12 V.

| | Budget |
|---|---|
| Supply (keep 15 % margin) | 48 W → 41 W usable |
| Motors (up to 4 moving), Pico W, 74HCT245, drivers: ~3 A at 5 V | ~15 W |
| Buck loss (~90 %) | ~2 W |
| **LEDs** | **~23–24 W ≈ 1.9–2 A at 12 V** (about 9 % of the 258 W full-white maximum) |

- The firmware caps LED **power** at ~23 W. Real dither pictures average far below full white, so the limit is rarely reached. Lowering `maxMovingTiles` from 4 to 2 frees ~5 W for the LEDs.
- Fuses for this supply: main 5 A; LED rows 2 A each; bar 1 A; the 5 V motor rail 3 A (after the buck); logic 1 A.
- Buck module: 12 → 5 V, rated **5 A** (XL4015/XL4016 type, ~AU$4–8), set to 5.0 V with a multimeter **before** connecting anything. Do not use a 3 A LM2596 at its limit.
- **Check the charger first:** measure the no-load output with a multimeter (should be about 12–12.6 V; an old unregulated transformer type can read 15 V+ and would damage the LEDs), confirm the polarity from the label, and don't use a damaged cable. A switch-mode "laptop-style" brick is regulated; a heavy transformer plug-pack is not.
- **Still to verify before relying on this:** that bare 12 V WS2815 5050 LEDs can be bought in small quantity. If not, WS2812B at 5 V would need a ≥ 8 A buck, which a 48 W supply can only just feed.

### 3.5 Two chargers: one for the LEDs, one for everything else

Works, and is better than one charger. Example: the **12 V 4 A** feeds only the LEDs (WS2815, straight from it), and the **16 V 3.75 A or 20 V 3.33 A** feeds one 5 A buck module (→ 5 V) for the motors, Pico, 74HCT245 and drivers (~15 W, 1 A or less drawn from the charger). A spare 5 V phone charger (2.4 A or more) could replace the second charger and the buck, with `maxMovingTiles` at 2.

- **LED budget rises** to ~41 W (48 W minus 15 % margin) ≈ 3.4 A at 12 V, about 16 % of full white, instead of ~23 W. Motor surges can no longer dim the LEDs or reset the Pico.
- **Join the two negatives (GND) at one point** (the star point). Without it the LED data line has no reference and the LEDs flicker. Do not join the positives.
- **One mains switch for both**: plug both into a power board (or switch both DC outputs with one DPST switch), because a half-powered board misbehaves: LEDs on with the level shifter off leaves the data lines floating (random flicker), and the level shifter on with LEDs off can push a little current into the unpowered LEDs through the data line. Add a 10 kΩ pull-down from each LED data line to GND at the level shifter output as well.
- Fuses: 5 A on the 12 V charger output, 2 A per LED row (F1–F4), 1 A for the bar (F5); 3 A on the 5 V motor rail (F6), 1 A for logic (F7).
- Two mains cords and plugs are an enclosure/tidiness cost, and each charger must be undamaged and double-insulated (no exposed mains).

### 3.6 All three chargers (upgrade path)

| Charger | Job | Conversion | Usable (15 % margin) |
|---|---|---|---|
| 12 V 4 A (48 W) | LED rows 0 and 1 (288 LEDs) | none, WS2815 runs straight from it | ~41 W |
| 20 V 3.33 A (66 W) | LED rows 2 and 3 + status bar (312 LEDs) | one 12 V buck rated 5 A+ (XL4016 type, heatsink), ~88 % efficient | ~49 W |
| 16 V 3.75 A (60 W) | Motors, Pico, level shifter, drivers (~15 W) | one 5 V buck rated 5 A | far more than needed |

- LED budget goes from ~41 W (two chargers) to **~90 W ≈ 35 % of full white**, about twice the light. That matters because the smoked diffuser acrylic absorbs a lot of it.
- The rows already have separate fused branches, so this only changes which charger each branch is wired to. **Start with two chargers (§3.5), test the brightness through the acrylic, and add the third only if it's too dim.**
- The power limiter must work **per supply group** (rows 0–1, rows 2–3 + bar), not just globally, or a bright half overloads its own charger.
- All three negatives join at the one star point; one switch (power board) for all three plugs; pull-downs on every data line; check each charger's no-load voltage first; buck inputs are rated well above 20 V.
- Cost: one more buck (AU$8) and more wiring. Every extra charger and buck is another thing that can fail.

---

## 4. Blocks

### 4.1 LED data (5 lines, 3.3 V → 5 V)

```
 GP2 ─► 74HCT245 A1 ─ B1 ─ 330 Ω ─► row 0 DIN       74HCT245:  pin 20 VCC = 5 V logic rail
 GP3 ─► A2 ─ B2 ─ 330 Ω ─► row 1 DIN                           pin 10 GND
 GP4 ─► A3 ─ B3 ─ 330 Ω ─► row 2 DIN                           pin 1 DIR → 5 V (A to B)
 GP5 ─► A4 ─ B4 ─ 330 Ω ─► row 3 DIN                           pin 19 OE → GND (always on)
 GP6 ─► A5 ─ B5 ─ 330 Ω ─► status bar DIN                      A6, A7, A8 → GND (never leave floating)
                                                               100 nF across pins 20 and 10
```

The 74HCT245 accepts 3.3 V highs and outputs full 5 V, which a WS2812B at 5 V needs (it wants ≥ 3.5 V). One chip covers all five lines. (A 74AHCT125 also works but has only four buffers, so you would need two.)

### 4.2 Motor control (16 motors, 3 + 1 pins)

```
 GP11 SER ─► 595 #1 ─QH'─► 595 #2 ─QH'─► ... ─► 595 #8      595 supply: 3V3(OUT) on pin 16, GND pin 8
 GP10 SRCLK ───────────────► all pin 11                     SRCLR (pin 10) → 3V3
 GP12 RCLK  ───────────────► all pin 12                     OE (pin 13) ← GP13, 10 kΩ pull-up to 3V3
 100 nF across each chip's supply
```

- Chip n drives tiles 2n and 2n+1: outputs QA–QD → tile 2n (IN1, IN2, IN3, IN4), QE–QH → tile 2n+1.
- Each motor driver (one per tile): IN1/IN2 = coil A, IN3/IN4 = coil B, `OUT1/OUT2` to coil A, `OUT3/OUT4` to coil B.
- Powering the 595s from the Pico's 3.3 V means **plain 74HC595 works** (the school's are fine), and the outputs are 3.3 V, which the L298N (needs ≥ 2.3 V) and MX1508 inputs read as high. Use 74HCT595 only if you power the chips from 5 V.
- **School L298N modules (prototype):** take the "5 V-EN" jumper **off**, feed 5 V into the module's **5 V pin** and the motor rail into **VS**, keep the ENA/ENB jumpers on. With only 5 V on VS the module's own regulator would otherwise output ~3 V. The L298N drops ~2 V, so each coil sees ~3 V (about 75–180 mA): weak but enough to test.
- **MX1508 (final):** VCC = motor rail, GND, IN1–IN4. No jumpers and no drop.
- The motor rail and the logic rail are separate fuse branches, so a motor surge cannot brown out the Pico.

### 4.3 Sensors

```
 3V3 ─┬─ LDR ──┬── GP26 (ADC0, pin 31)          3V3 ─┬─ 10 kΩ ──┬── GP27 (ADC1, pin 32)
      │        │                                      │          │
      │       10 kΩ ── AGND (pin 33)                  │         NTC 10 kΩ ── AGND
      │        └─ 100 nF ── AGND                      │          └─ 100 nF ── AGND
```

Feed both from 3V3(OUT), never from 5 V (the ADC is 3.3 V only). The NTC sits in the enclosure near the motor drivers; the LDR looks out through a small hole in the bezel border. Read the NTC with the β equation (β ≈ 3950).

Optional 5 V monitor on GP28: 5 V rail → 10 kΩ → GP28 → 10 kΩ → GND. It reads 2.5 V at 5 V and lets the firmware warn about a sagging brick.

### 4.4 Status LED and Pico power

- GP15 → 4.7 kΩ → LED → GND. About 0.3 mA: dim on purpose.
- **Logic rail → D1 (1N5819, stripe toward the Pico) → VSYS (pin 39)**, with 100 µF to GND at the Pico. Leave VBUS (pin 40) unconnected. With D1, you can plug USB in for programming while the brick is on: neither supply feeds the other.

---

## 5. The teacher's 7805

A 7805 is a good regulator for the **logic only**, and only if the supply is **9–12 V**. It is the wrong part for the LEDs and motors, and it is not needed if the supply is already 5 V.

- **Current:** about 1 A at most (1.5 A peak). The LEDs need ~5–9 A and the motors 1–2 A on their own rails.
- **Input:** it needs about 7 V or more to give 5 V. From a 5 V brick it would output only ~3 V.
- **Heat:** it wastes (Vin − 5 V) × current as heat. From 12 V at 0.4 A that is 2.8 W: heatsink needed (bare TO-220 would overheat). From 9 V it is about half that.
- Add 0.33 µF on the input and 0.1 µF on the output, close to the pins.

What to do depends on the supply the school gives you:

| Supply | Plan |
|---|---|
| **5 V, ≥ 10 A** | Circuit above. No 7805. Hard to find as a safe plug-in brick. |
| **9–12 V, a few amps** | Add a 5 V buck module (e.g. LM2596-type for 3 A, or an 8 A one) for the LED/motor rails, and optionally the 7805 for the logic rail only (replacing F7 + D1). |
| **Old laptop charger** (typically 19–20 V, 3.4–4.7 A = 65–90 W; never 5 V 10 A) | Plenty of watts (we need about 45–60 W) but the wrong voltage. Use buck modules: 19 V → 5 V for the motors, logic and (WS2812B design) LEDs, or 19 V → 12 V for WS2815 LEDs plus 19 V → 5 V for the rest. Check the label for output V/A, plug polarity (usually centre positive) and size; a USB-C one needs a PD trigger board. Don't use one with a damaged cable. |
| **5 V, 2–3 A** (phone-charger sized) | LED cap drops to ~1 A, i.e. dim; fine for a desk piece but not 600 LEDs bright. |

The builder has decided the supply will be **bought**, since the school's is unknown and the constraint is heavy. The choice is between a 5 V brick (§3.1) and the 12 V option (§3.3). It changes §3 only, not the pin map.

---

## 6. Bring-up order

1. Pico alone on USB: blink the status LED, read the LDR and NTC.
2. Add 3V3 and the 595s with no motors: check the OE pull-up, shift a pattern, watch outputs with a multimeter or LEDs.
3. One L298N/MX1508 + one motor (from the motor rail, with F6 in place).
4. One tile of LEDs with the 74HCT245 and its 330 Ω, at low brightness.
5. Then add rows one at a time, measuring the supply current at each step.
