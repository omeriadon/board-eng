# Dither Board: Pico W pin map and circuit

_Rev 27, 2026-11-21. Geometry: 5 × 5 moving tiles, each with a premade 5 × 5 WS2812B module (25 × 25 = 625 pixels) plus a fixed 25-LED status bar under the grid = **650 LEDs**, and 25 SG90 servos (scotch-yoke drive, 15 mm stroke) on two PCA9685 boards. Supply: the builder's 20 V and 16 V chargers through three 5 V bucks (the 12 V charger is a spare). See `ingredients.md` for parts and `docs/context.md` for decisions. The drawn versions are `schematics/dither-board-schematics.pdf` and `dither-board-blueprint.pdf`, both redrawn for this design at rev 26._

Pin numbers are **physical pin numbers** (1–40, USB at the top) and GPIO names. GP23, GP24, GP25 and GP29 talk to the Wi-Fi/Bluetooth chip and are not available (official Pico W datasheet).

---

## 1. The 3 inputs and 3 outputs (for the brief)

| | What | Pico pin | Automated? |
|---|---|---|---|
| **Input 1** | LDR (room light) | GP26 / ADC0 (pin 31) | Yes. Sets LED brightness, dims at night |
| **Input 2** | NTC thermistor (inside the enclosure) | GP27 / ADC1 (pin 32) | Yes. Too hot → LEDs dim, servos pause |
| **Input 3** | Bluetooth / Wi-Fi commands from the iPhone and Mac apps | Built into the Pico W | No (user) |
| **Output 1** | 650 WS2812B RGB LEDs (25 modules + status bar) | GP2–GP7 via level shifter | Driven by the LDR and NTC |
| **Output 2** | 25 SG90 servos (tile height) | GP16/GP17 (I2C) + GP13 (OE) via 2 × PCA9685 | Driven by the NTC |
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
   LED data, row 1   GP3  5│●             ●│36  3V3(OUT) --> sensors, I2C, PCA9685 VCC
   LED data, row 2   GP4  6│●             ●│35  ADC_VREF  leave unconnected
   LED data, row 3   GP5  7│●             ●│34  GP28 ADC2  5 V monitor (opt.)
                     GND  8│●             ●│33  AGND  --> sensor grounds
   LED data, row 4   GP6  9│●             ●│32  GP27 ADC1  NTC
   LED data, bar     GP7 10│●             ●│31  GP26 ADC0  LDR
   spare             GP8 11│●             ●│30  RUN       optional reset to GND
   spare             GP9 12│●             ●│29  GP22      spare
                     GND 13│●             ●│28  GND
   spare            GP10 14│●             ●│27  GP21      spare
   spare            GP11 15│●             ●│26  GP20      spare
   spare            GP12 16│●             ●│25  GP19      spare
   PCA9685 OE       GP13 17│●             ●│24  GP18      spare
                     GND 18│●             ●│23  GND
   spare (button)   GP14 19│●             ●│22  GP17  I2C0 SCL
   Status LED       GP15 20│●             ●│21  GP16  I2C0 SDA
                          └───────────────┘
```

| Pin | GPIO | Net | Connects to |
|---|---|---|---|
| 4–7, 9 | GP2–GP6 | `LED0`–`LED4` | 74HCT245 A1–A5 → 330 Ω → DIN of the first module in tile row 0–4 |
| 10 | GP7 | `LEDBAR` | 74HCT245 A6 → 330 Ω → status bar DIN |
| 17 | GP13 | `OE` | both PCA9685 OE pins (active low), 1 kΩ pull-up to 3V3 |
| 20 | GP15 | `STATUS` | 4.7 kΩ → status LED anode, cathode to GND |
| 21 | GP16 | `SDA` | both PCA9685 SDA, 4.7 kΩ pull-up to 3V3 (skip if the boards have them) |
| 22 | GP17 | `SCL` | both PCA9685 SCL, 4.7 kΩ pull-up to 3V3 (same) |
| 31 | GP26 | `LDR` | LDR/10 kΩ divider midpoint |
| 32 | GP27 | `NTC` | NTC/10 kΩ divider midpoint |
| 34 | GP28 | `V5MON` | optional: 10 kΩ/10 kΩ divider on the 5 V rail (reads 2.5 V) |
| 36 | 3V3(OUT) | `3V3` | dividers, I2C pull-ups, PCA9685 VCC |
| 39 | VSYS | `VLOGIC` | 5 V logic rail through D1 (1N5819) |
| 33 | AGND | | sensor ground (LDR and NTC dividers) |
| 3, 8, 13, 18, 23, 28, 38 | GND | `GND` | main ground |

Notes:

- GP0/GP1 are kept free for a debug serial header. GP8–GP12, GP14, GP18–GP22 are spare. The old shift-register pins (GP10–GP12) are free again.
- The firmware drives the six LED lines from PIO state machines, 800 kHz each. A row of five modules is 125 LEDs (about 3.8 ms per frame), the bar 25 LEDs.
- **OE is held high by the 1 kΩ pull-up until the firmware has written all 25 start positions to the PCA9685s**, then it goes low. That stops the servos twitching at power-up. The NTC cut-off can also set OE high to cut all servos at once. The 1 kΩ pull-up beats any pull-down your PCA9685 board may carry on OE (check the board).
- I2C0 on GP16/GP17 at 400 kHz. PCA9685 #0 at 0x40, #1 at 0x41 (solder-bridge A0).

---

## 3. Power (FINAL plan: two chargers, three bucks)

The LEDs and servos are all 5 V now. Chargers: **20 V 3.33 A** (66 W) feeds the two LED bucks, **16 V 3.75 A** (60 W) feeds the servo/logic buck; the **12 V 4 A is a spare and is not wired**. Volts × amps = watts, so the limits are each charger's watts and what the wires, fuses and bucks carry.

```
 CHARGER 20 V 3.33 A ─┬─F1 2 A─► BUCK 1 (5.0 V) ─► 5 V LED BUS A ──F3 5 A──► tiles 0-12   (13 modules, 325 LEDs)
 (66 W)               │             1000 µF 10 V
                      └─F2 2 A─► BUCK 2 (5.0 V) ─► 5 V LED BUS B ──F4 5 A──► tiles 13-24 + bar (325 LEDs)

 CHARGER 16 V 3.75 A ──F5 2 A─► BUCK 3 (5.0 V) ─► 5 V SERVO BUS ──F6 5 A──► servo rail: V+ of both PCA9685
 (60 W)                                 470 µF 16 V               └─F7 1 A─► LOGIC RAIL ─ D1 ─► Pico VSYS, 74HCT245

 CHARGER 12 V 4 A: spare, not wired.
 ALL NEGATIVES (both chargers, all three bucks) JOIN AT ONE STAR POINT. NEVER JOIN POSITIVES.
 Both plugs go into one power board with one switch.
```

| Group | Source | Worst-case load | Fuses | Firmware cap |
|---|---|---|---|---|
| LED bus A: tiles 0–12 (325 LEDs) | 20 V charger, buck 1 | capped at 5 A = 25 W at 5 V (full white would be 19.5 A); input 1.4 A at 20 V; buck at its limit: heatsink and fan | F1 2 A (20 V side), F3 5 A | 5 A per bus, about 1 A per module |
| LED bus B: tiles 13–24 + bar (325 LEDs) | 20 V charger, buck 2 | same; both bucks together draw 2.8 A of the charger's 3.33 A (85 %) | F2 2 A, F4 5 A | same |
| Servos, 2 × PCA9685, Pico, 74HCT245 | 16 V charger, buck 3 | 6 servos × 0.25 A typical = 1.5 A (3.9 A if six stall) + Pico 0.3 A + boards 0.1 A = 4.3 A worst; buck 3 at ~86 % of 5 A; input 1.6 A of 3.75 A | F5 2 A (16 V side), F6 5 A, F7 1 A | 6 servos moving at once |

- F1–F7 are resettable PTC fuses (the number is the hold current). LED bus trunks use 18 AWG; each module feed carries up to about 1 A (22 AWG is enough). Servo rail to each PCA9685 board: its own heavy pair (20 AWG), 470 µF across V+ and GND at each board.
- LED power is 10 A at most, about 2,260 nits full-screen white (estimated); each module has its own +5 V and GND from its bus, never through a neighbour. The two buses are split by module count (325 LEDs each) so the firmware limit dims both halves equally.
- **The power limiter must work per bus** (A and B). Not built yet.
- Set all three bucks to exactly 5.0 V with a multimeter **before** connecting any load. Measure each charger's no-load voltage first. Heatsink tabs can be live: insulate them and keep them away from the Pico's antenna end.
- Chargers must be undamaged, regulated and double-insulated. No mains inside the board.
- Pull-downs: 10 kΩ from each LED data line to GND at the level shifter output, so the lines stay quiet if one supply is on before the others.
- Protection layers: firmware cap → fuses → the charger's own overcurrent protection.

---

## 4. Blocks

### 4.1 LED data (6 lines, 3.3 V → 5 V)

```
 GP2 ─► 74HCT245 A1 ─ B1 ─ 330 Ω ─► row 0 DIN       74HCT245:  pin 20 VCC = 5 V logic rail
 GP3 ─► A2 ─ B2 ─ 330 Ω ─► row 1 DIN                           pin 10 GND
 GP4 ─► A3 ─ B3 ─ 330 Ω ─► row 2 DIN                           pin 1 DIR → 5 V (A to B)
 GP5 ─► A4 ─ B4 ─ 330 Ω ─► row 3 DIN                           pin 19 OE → GND (always on)
 GP6 ─► A5 ─ B5 ─ 330 Ω ─► row 4 DIN                           A7, A8 → GND (never leave floating)
 GP7 ─► A6 ─ B6 ─ 330 Ω ─► status bar DIN                      100 nF across pins 20 and 10
```

The 74HCT245 accepts 3.3 V highs and outputs full 5 V, which a WS2812B at 5 V needs (it wants ≥ 3.5 V). One chip covers all six lines. Each row is five modules in a chain: DIN of tile 5r from the line, then each module's DOUT → next module's DIN (through the flexible tile cable).

### 4.2 Servo control (25 servos, 3 pins)

```
 GP16 SDA ──┬── PCA9685 #0 (0x40): channels 0-15 → servos of tiles 0-15
 GP17 SCL ──┤                       ← both boards in parallel (one short cable)
 GP13 OE  ──┴── PCA9685 #1 (0x41): channels 0-8  → servos of tiles 16-24
 VCC (chip logic) ← 3V3 · V+ (servo supply) ← +5V·SRV heavy wires · GND → star
```

- Tile t = row t ÷ 5, column t mod 5; tile t uses PCA channel t (board 0) for t < 16, channel t − 16 (board 1) otherwise.
- Servo lead: signal → the channel's PWM pin, V+ → V+ pin, GND → GND (the board's channel header is already in that order).
- Firmware: 50 Hz; 1.0–2.0 ms = ±90°, only ±75° used (stroke 15 mm). 150° ≈ 170 counts of 4.9 µs, about 0.12 mm per count. At most 6 servos move at once. Idle servos stay driven (about 10–50 mA each); the yoke also holds the tile with the power off.

### 4.3 Sensors

```
 3V3 ─┬─ LDR ──┬── GP26 (ADC0, pin 31)          3V3 ─┬─ 10 kΩ ──┬── GP27 (ADC1, pin 32)
      │        │                                      │          │
      │       10 kΩ ── AGND (pin 33)                  │         NTC 10 kΩ ── AGND
      │        └─ 100 nF ── AGND                      │          └─ 100 nF ── AGND
```

Feed both from 3V3(OUT), never from 5 V (the ADC is 3.3 V only). The NTC sits in the enclosure near the buck heatsinks; the LDR looks out through a small hole in the bezel border. Read the NTC with the β equation (β ≈ 3950). Optional 5 V monitor on GP28: 5 V rail → 10 kΩ → GP28 → 10 kΩ → GND.

### 4.4 Status LED and Pico power

- GP15 → 4.7 kΩ → LED → GND. About 0.3 mA: dim on purpose.
- **Logic rail → D1 (1N5819, stripe toward the Pico) → VSYS (pin 39)**, with 100 µF to GND at the Pico. Leave VBUS (pin 40) unconnected. With D1 you can plug USB in for programming while the charger is on: neither supply feeds the other.

---

## 5. Bring-up order

1. Pico alone on USB: blink the status LED, read the LDR and NTC.
2. Add 3V3 and one PCA9685 with OE high (pull-up in place): scan I2C, check 0x40.
3. One servo (arm off), powered from the servo rail with F6 in place: check the 1–2 ms pulse range and the 15 mm stroke on the bench; then the rest, a few at a time.
4. One LED module with the 74HCT245 and its 330 Ω at low brightness, on a bench supply first (pad order is unconfirmed).
5. Then add rows one at a time, measuring the current on each LED bus.

## 6. Tile cables (what moves with the tile, with a service loop)

| Cable | Conductors | Pins |
|---|---|---|
| Servo, 3-wire lead on a header | 3 | signal, V+, GND |
| LED module, JST-XH 4-pin | 4 | +5 V, GND, DIN, DOUT |

Each moving tile has 7 wires in two cables and travels 15 mm; the service loop must not pull on the tile. Test on the first tile.

### Not done yet
- Module pad order and thickness (the Alibaba modules have not arrived); the status-bar part (only seen on Electropeak); the new stand (idea: a V hinged at the middle of the back, legs open for the desk and fold flat for the wall).
- Whether the PCA9685 boards you buy (none owned yet) carry SDA/SCL pull-ups, an OE pull-down, and which pin is V+; the buck module rating. The servos themselves need no resistors.
- The firmware that calls the power limiter each frame (the limiter itself is `BoardKit.PowerLimiter`: one scale factor, 5 A per bus, the tighter bus decides) and the diffuser brightness test.
