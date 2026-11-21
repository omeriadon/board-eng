# Dither Board — Full Project Context

_Last updated: 2026-11-21 (rev 21)_

**Repo:** https://github.com/omeriadon/board-eng (public), a **monorepo**: `docs/` (this file, `app-plan.md`, `prospectful.md`), `hardware/` (`ingredients.md`, `BUILD-NOTES.md`, `cad/`), `firmware/` (Pico W, Embedded Swift), `server/` (Swift Vapor), `apps/` (SwiftUI iOS + macOS, maybe watchOS), `shared/` (`BoardKit`). The local folder is `~/Documents/Xcode_App_Library/Board`.
**CAD:** `hardware/cad/tile.py`, a parametric Python generator (manifold3d + trimesh) → `cad/out/` STLs, laser PDFs (1:1 mm) and `blueprint_tile.svg`. **Repo rule (from the builder): no HTML or SVG in the repo, only PDF (plus STL and the `cad/*.py` config/generator scripts).** Intermediate files must not be committed (`.gitignore` blocks `*.svg` and `*.html`). The old concept diagram (`tile-design.html`) was removed; a board-layout PDF will replace it.

This file holds the full context of the planning conversation, so another agent or person can pick up the work without the original chat. It is updated as decisions change. The live parts list is in `ingredients.md`, in the same folder, and is also updated every turn.

---

## 1. Who / what

- The builder is a student doing a school engineering project. They're very comfortable with **SwiftUI / Swift** (iOS + macOS apps) and consider the software side (BLE, Wi-Fi, apps, firmware logic) the easy part.
- Their personal projects all use a distinctive **dither aesthetic**: square pixels, dithered gradients. There is an existing Xcode project in this library, `Dither Screen Saver/`, that shows the look.
- The project: a **physical, mechanical, kinetic 3D version of that dither effect**. A wall or desk sculpture made of square pixels that move in and out and light up.

## 2. Assignment requirements (official brief, received 2026-11-20)

- Follow the **engineering design process** to produce a final prototype that fills a need found through research, with all documentation in a **design portfolio**.
- **Microcontroller:** Raspberry Pi Pico, Arduino, ESP32 or another suitable one. **Pico chosen.**
- Must include:
  1. **3 inputs**
  2. **3 outputs**, at least two driven from an automated input
  3. **One form or translation from a mechanical drive system** (listed options include the **screw drive**, which the lead-screw micro steppers satisfy)
- Listed sensors: ultrasonic, IR, LDR, NTC thermistor, colour. Listed outputs: DC motor, servo, stepper, LED, piezo. Anything else must be discussed with the teacher (client).
- **Constraints:**
  - ≤ 250 × 250 × 250 mm. The builder is choosing to ignore this, even though it's a "must".
  - **≤ $80 total component and material cost.** The builder will go up to ~$110.
  - Safe for any high-school student to operate.
  - Aesthetically pleasing and/or meets the client's requirements.

### I/O plan to satisfy the brief
- **Inputs:**
  - LDR: automated, sets LED brightness and night dimming.
  - Presence sensor (IR/PIR/VL53L0X, hidden behind the border): automated, wakes or sleeps the tile motion.
  - Bluetooth app input from the iPhone/Mac apps, including Mac activity and Claude Code status.
  - Optional: colour sensor palette pick.
- **Outputs:**
  - WS2812 LEDs, driven by the LDR (automated)
  - Stepper tiles, driven by presence (automated)
  - **Status LED on the back**: very dim power-on indicator, can also show Bluetooth status. Builder request. **Piezo dropped** (builder said no piezo). The status LED is output #3; risk that the teacher counts it as the same type as the main LEDs.
- **Mechanical drive:** screw drive (rotary → linear) in each tile actuator.
- **Safety:** 5 V only (no mains inside), fused, current-limited, enclosed, low pinch force (~80 g thrust).
- **The "no controls on the device" rule still holds:** sensors aren't controls.

## 2b. Original requirements as first described

- Must **solve a problem**. The engineering-design framing is: identify a problem, then design a solution.
- Must have **multiple inputs and multiple outputs** (motors, actuators, buttons, sounds, lights, screens, knobs, colour sensors, etc.).
- **Size limit ~25 × 25 × 25 cm** (the builder is fine going over, especially in depth).
- Materials: **laser-cut acrylic (preferred: looks, durability, stability)**, thin laser-cut MDF (fallback), 3D-printed PLA, timber, screws.
  - **Clear acrylic is allowed** for the back and structure (guide plates, motor plate, sides, back) so the mechanism shows. The builder says clear isn't a colour, so it doesn't break the all-black rule.
  - The front bezel and tiles stay black.
- **Status: the professor has approved the project.**

## 3. Approved problem statement

> During short, unpredictable waits in focused work, such as waiting for AI tools like Claude Code, builds, renders or exports, people reach for their phones and get pulled into doomscrolling. This project is a screen-free, tactile/visual, calming kinetic dither sculpture that gives idle attention something calm to rest on, so people stay in their work and return to it more easily.

Supporting points:
- The waiting gap is too short to switch tasks but long enough to pick up a phone.
- Sensory and fidget objects are an established category; steady mechanical sound is a known focus and masking aid; slow, predictable motion is calming ("calm technology").
- Wording is "reduces / offers an alternative", **not** "stops", because it has to be testable.
- **Test plan idea:** 8–10 people, a 3–5 minute simulated wait under three conditions (board / phone / nothing). Measure phone pickups, self-rated calm (1–10), and ease of returning to the task.
- **Likely professor objection:** "Everything is controlled from a phone app." Answer: the board itself is screen-free and runs ambiently. You configure it once, and the Mac automations make it fully hands-off.
- Optional extra: a Mac companion app tells the board when a long task (e.g. Claude Code) is running, so it switches to a "waiting" pattern and settles when the task finishes.

## 4. Firm design decisions and preferences

- **The board is purely aesthetic as an object.** It is NOT combined with the MacBook-cooling idea. (That idea was only an example of the expected complexity. The builder explicitly rejected merging the two.)
- **Square** board. **Everything is black except the lights**, so it doesn't clash with the colour presets.
- **Square pixels and square LEDs, no round look.** The builder rejected round LEDs and premade boards (resistors, board colour, edge margins).
- **No controls on the device.** One power switch only. Everything else runs from the apps.
- **Power:** plugged in, not batteries.
- **Connectivity:** BLE (and maybe Wi-Fi). No pairing and no security: there's only one device, so the app finds it and connects. A Wi-Fi server is maybe later, cost permitting.
- **Apps:** iPhone + Mac SwiftUI apps for patterns, speed, density, colour, timers, "stop moving when inactive on Mac", Shortcuts-driven colour changes, and more.
- **Mechanical sound** should be like a **mechanical keyboard** (soft, clicky), **not a typewriter** (too loud and bashy). Wanted: a **quiet mode**, through slower motion, eased acceleration, de-synced or staggered actuators, microstepping, and stopping short of hard end stops.
- **Stand:** elegant, mounted at the centre of the back plate. A ball-and-socket joint is suggested; it should be **lockable** because the board may weigh 1–2 kg.
- **Budget:** the brief says ≤ $80; the builder will spend up to ~$110. **All in AUD** (confirmed rev 10), so ≈ US$52 / US$72. `components.md` prices are in USD.
- **Free from school:** Raspberry Pi **Pico** (the builder wants **Pico only, no full Pi**, and will write **Swift** for it, i.e. Embedded Swift), a voltage regulator, "a bunch of" dual motor drivers ("work on the mini servos we have, two motors each"), 3D printing and laser cutting. **Paint is free** (dad's).
- **Also free from school (confirmed rev 10):** Pico W, L298N drivers, acrylic, a power supply, wires, breadboards, resistors, capacitors, screws, buttons, round LEDs (not used: we use square) and other basic parts.

## 5. How the core mechanical design evolved

1. **Original idea:** 4 mm rods with a 1 mm gap (5 mm pitch) in 20 × 20 cm, so 40 × 40 = **1,600 actuators**. Rejected as infeasible on cost, wiring and space.
2. **One micro servo (SG90) per pin with push-rods:** rejected by the builder as too strong, too big and too pricey.
3. **8 mm micro linear slider steppers** (lead screw + slider nut), one per pin: the right actuator type, but 16 × 16 = 256 of them plus drivers cost ~$500–1,000. Too expensive.
4. **Premade pin displays:** none affordable exist. Dot Pad is ~$6,000 and binary; MIT inFORM is research only; flip-dots flip rather than rise.
5. **Lights-only:** kept as a worst-case fallback only. It loses the actuators (an assignment requirement), the sound and the 3D texture.
6. **Scanning head** (shared carriage sets friction-held pins): cheap, but a full update takes 10–60 s. The builder requires a full screen update of **≤ 0.1 s**, so rejected.
7. **CHOSEN: hybrid "super-pixel" tiles.**
   - The board is an **N × N grid of moving tiles**. Each tile carries a **k × k block of square LEDs**.
   - The **lights** give fine, high-resolution dither and update instantly (60 fps).
   - The **tiles** give coarse, slower 3D height movement: roughly 0.3–1 s per full stroke, a "breathing" layer. Firmware can set each tile's height from the mean brightness of its LEDs.
   - **One 8 mm micro slider stepper per tile.**
   - The builder does **not** want a smaller-pixel-count board in general; the hybrid keeps light density high.
   - N (2–6) and k (3–5) are **variables to decide after price optimisation**.

## 6. Current technical architecture

### Actuators
- **8 mm 2-phase 4-wire micro linear stepper** with lead screw + slider (camera-lens / DVD-sled type).
  Reference spec (VIC-TECH VSM08102, from a third-party listing): 8 mm diameter, 10 mm stroke, 18°/step (20 steps/rev), M2×0.4 lead screw (~0.02 mm/step), 3.3–5 V, 20 Ω/phase, ~80 g thrust at 500 pps.
- At 500 pps a full 10 mm stroke takes ~1 s; test whether faster is possible without skipped steps.
- Strokes of 15 / 20 / 34 mm also exist.
- The lead screw **self-locks**, so tiles hold position unpowered. Idle motors can be de-energised: silent, and low power.
- **Homing:** on power-up, drive every tile to its end stop. That gives a satisfying startup routine.
- **Price:** AliExpress ~$1.10–4 each. Fruugo, eBay resellers and Newegg list the same parts at $20–48, so avoid them.
- Sound: a stepper whir whose pitch follows speed, plus optional printed detents for a soft click per level, and soft end-stop pads (TPU / silicone / foam; **not felt**, per the builder).

### Drivers
- The school's driver is the **L298N dual H-bridge module** (red board). One L298N = one stepper, via IN1–IN4 with ENA/ENB jumpered.
  - It has a ~2 V drop, so 5 V in gives the coils ~3 V. Test this; if it's too weak, feed the motor supply 7–7.5 V.
  - Modules are ~43 × 43 mm and sit in the electronics bay.
  - Need N² of them; quantity available is still unknown.
  - The builder dislikes the L298N's inefficiency and bulk. Its bipolar transistors burn ~2 V as heat, ~0.4–0.5 W per energised motor; that's tolerable because idle motors are de-energised.
  - **Plan:** prototype on the free L298N. For the final build, likely buy **MX1508** (~$0.30–0.50) or **DRV8833** (~$0.50–1) modules: small, MOSFET, almost no drop, one stepper each, ~$8–15 total.
  - A later option is one custom driver PCB with shift registers + DRV8833 chips (JLCPCB).
- If buying, the cheap options are the MX1508 (dual H-bridge, ~$0.10–0.40) or the A4988/DRV8825 (step/dir with microstepping, smoother and quieter).
- ULN2003 **won't** work, because it's for unipolar steppers.
- **Control:** 4 lines per motor via chained **74HC595** shift registers (1 chip per 2 motors), so the Pico uses about 3 pins for all motors.

### LEDs
- **Bare WS2812B-5050** addressable RGB LEDs (square 5 × 5 mm package, no resistor needed, 100 nF cap each), on a **custom black-soldermask tile PCB** sized edge-to-edge. The builder rejected premade 4 × 4 WS2812 boards and LED strip (cutting into squares needs too much soldering).
- **Square pixel look:** a **black square-cell grid built into each printed tile body** over the LEDs, topped by a **smoked "dead-front" diffuser** (smoked/tinted black "LED acrylic", laser-cut squares, one per tile).
  - It looks **black when off** (keeps the all-black rule); light shows through when on.
  - The builder's question "shouldn't the diffuser be black?" is resolved this way: fully black blocks the light and white breaks the black look, so smoked is the compromise.
  - Optional thin white diffuser under the smoked layer for evenness.
  - Smoked material cuts brightness, so LEDs run brighter.
  - Every tile needs its own grid + diffuser because tiles move independently. It's one printed part per tile (batch-printed), plus one laser job cutting all the acrylic squares. Fancier option: a single print that changes filament from translucent to black.
- Tiles are daisy-chained with flexible silicone wire with slack for the travel.
- **Level shifter** (74AHCT125) for the 3.3 V → 5 V data line, plus a 330–470 Ω series resistor and a 1000 µF bulk capacitor.

### Controller
- **Raspberry Pi Pico W / Pico 2 W only.** It needs wireless; if the school Pico is plain, buy a W or add a BLE module.
- **Embedded Swift** runs on RP2040 / RP2350. BLE goes through the pico-sdk (BTstack) via C interop.
- **PIO** drives WS2812 timing and can generate step / shift-register clocking.

### Power
- External **5 V brick**, sized from N and k. Probably 5 V 10 A.
- LED brightness capped in firmware (~20–25%).
- Limit how many motors move at once (staggering also helps quiet mode and peak current).
- Barrel jack, one power switch, inline fuse.

### Tile mechanical design (rev 2 — generated by `hardware/cad/tile.py`, drawn in `cad/out/blueprint_tile.pdf`)
- **Rev 2 change:** the light grid now starts at the front face (on the print bed when printed face-down), so no supports are needed. The smoked acrylic diffuser (HEAD − 0.2 mm square) is **glued flush onto the front**, not set into a lip. Head 38.8 × 38.8 × 11.6 mm; stem 20 mm square × 40 mm; guide holes 20.5 mm.

Rev 1 notes (still mostly valid):
Example numbers for N=5, k=4, 40 mm pitch:
- **Tile head:** black PLA, 39 × 39 × 13 mm, printed face-down. Outer rim 1.2 mm; the k×k light grid (1 mm walls, 8 mm tall) is part of it, plus a 2 mm top lip that holds a 37.4 × 37.4 × 2 mm smoked acrylic diffuser.
- **Tile PCB:** 37 × 37 mm, black, with square WS2812B-5050s facing forward and caps on the back. It is sandwiched between the head and the stem's floor plate.
- **Stem:** black PLA, a floor plate (screwed into the head) with a 20 × 20 mm hollow square tube ~40 mm long.
  - The square shape stops rotation; wires run inside and exit through a side slot.
  - V-notches on one side make detents.
  - A tab at the bottom takes an M2 screw into the micro stepper's slider nut.
- **Soft end-stop pad** (TPU / silicone O-ring / foam, not felt) under the head: the head bottoms out on the front guide plate, giving a soft "thock" end stop.
- **Frame, front to back:**
  - Front guide plate (3 mm MDF, 20.6 mm square holes; leaves ~19 mm webs, so it's strong)
  - Rear guide plate (~16 mm behind it; a detent flexure here clicks into the stem notches)
  - Motor plate (micro steppers screw on)
  - Electronics bay (L298Ns, 74HC595s, Pico W)
  - Back plate (ball-joint stand mounts at the centre)
- **Total depth ≈ 11 cm.** Retracted tiles sit flush with the 1 cm black border; extended tiles are +15 mm.
- Tile height can follow the average brightness of its LEDs.

### Structure
- Laser-cut MDF layers (front, guide, motor, back plates and sides) painted matte black, plus black PLA tiles, grids and guides.
- Grid ~20 × 20 cm with ~1 cm margin; depth ~7–12 cm.
- Lockable ball-joint stand.

## 7. Process / next steps

1. **Ingredients list:** done. Kept current in `ingredients.md`, with quantities as functions of N and k.
2. **Price optimisation**, then choose N and k (the builder wants to compare 2² / 3² / 4² / 5² / 6² tiles).
3. **Single-tile prototype** (~$10–15): 2–3 steppers, LEDs for one tile, a school driver, a Pico.
   - Test real motor width, top speed, sound, push force with tile weight, wire flex, and light quality.
4. Then: tile PCB design, frame CAD, firmware (Embedded Swift on Pico), iOS / macOS apps.

### Anti-collision / precision (Prusa MK4S)
- Tiles are guided only by their stems in the guide plates, never by neighbours.
- Head gap 1.0–1.5 mm. Stem clearance 0.2–0.3 mm per side. Guide plates far apart to minimise wobble.
- Chamfer the first layer (elephant's foot). Print a 2×2 test coupon. Round the head edges. Dry lube.
- Weak motors stall rather than crash; periodic re-homing fixes lost steps.

### Pico wireless
- **Decided: Pico W** (the builder will get one). Pico W / Pico 2 W both have Wi-Fi + Bluetooth built in (CYW43439), so no extra module.
- **Range:** BLE is typically ~10 m indoors through a wall or two, and Wi-Fi is fine within a normal room or house. Plenty for a desk object.
  - Keep the Pico's antenna end near an edge of the enclosure and away from the motors, L298N heatsinks and metal; acrylic and PLA don't block the signal.

### Print accuracy (Prusa MK4S)
- The builder plans to raise quality and lower speed. That helps surface finish and consistency, but **dimensional accuracy comes mostly from calibration**:
  - The PrusaSlicer elephant-foot compensation setting (and the 0.4 mm chamfer in the CAD)
  - XY size compensation
  - Correct filament profile / flow
- Print `test_clearance_coupon.stl` first (holes at 0.15 / 0.20 / 0.25 / 0.30 mm per side, with dimples marking 1–4) and pick the best fit before printing the full set.
- Print all tiles in the same orientation with the same filament.
- **Full build-time checklist is in `BUILD-NOTES.md`** (the builder asked for these notes to be kept for build time).
- Laser and blueprint outputs are **PDF** (the builder asked for PDF instead of SVG); `blueprint_tile.svg` is kept only for the README preview.

## 8. Open questions

- How many **L298N** modules the school can provide (need N²).
- Is the school Pico a **W / 2 W** (wireless)?
- N, k and stroke length.
- Hand-solder or JLCPCB-assemble the tile PCBs.

## 9. Housekeeping instructions from the builder

- Keep **`ingredients.md`** updated **every turn** with the current parts list.
- Keep this **`context.md`** updated with all context, so another agent can take over.

## 10. Electronics architecture (planned, rev 1)

- **Main board (small):**
  - Pico W
  - 74AHCT125 level shifter for LED data (+ 330–470 Ω resistor)
  - LDR divider into an ADC pin
  - Presence sensor header (I2C if VL53L0X)
  - Status LED + 4.7–10 kΩ resistor
  - Bulk 1000 µF capacitor, fuse, power input
  - Fits on a ~5×7 cm perfboard. The builder's mini breadboard is fine for testing it.
- **Row boards (one per tile row, N identical):**
  - ⌈4N/8⌉ chained 74HC595 shift registers + N driver modules (MX1508/DRV8833 final; L298N for the prototype)
  - A 5-wire bus daisy-chains row to row (5 V, GND, DATA, CLK, LATCH), plus heavier 5 V/GND power wires.
  - For N=5: 13 × 74HC595 total (3 per row) and 25 drivers.
- **Breadboards:**
  - The builder has a mini breadboard and a ~10 × 22 cm one. Use them **for prototyping only**.
  - The final build should use **soldered perfboard/stripboard**, or later a custom PCB (JLCPCB ~$5–10 + shipping). Breadboard jumpers shake loose with motors and handling, and ~100+ control wires get unmanageable.
- **Pico pins (superseded by §19 and `hardware/circuit.md`):**
  - Shift-register chain: 3 GPIO (SPI/PIO)
  - LED data: 1–2 GPIO via PIO. 400 LEDs ≈ 12 ms per frame (~80 fps); the chain can be split for more.
  - LDR: 1 ADC
  - Presence: I2C (2 pins) or 1 GPIO for PIR
  - Status LED: 1 GPIO
- **Power:**
  - External 5 V ~10 A brick → panel barrel jack (5.5×2.5 mm, rated ≥ 7–10 A) → switch → fuse → star distribution.
  - Inject 5 V into the LED chain at every row.
  - Motor current is limited by de-energising idle motors and capping how many move at once.

## 11. Pico W radio (CYW43439) and placement

- One chip does **2.4 GHz Wi-Fi 4 (802.11n, single stream)** and **Bluetooth 5.2 (BLE + Classic)**, through an onboard PCB antenna.
- **Typical real-world performance:**
  - Wi-Fi: similar to other small IoT boards. Works anywhere in a normal house with decent router signal; throughput is a few Mbps, far more than needed.
  - BLE: reliable at ~10 m indoors, through a wall or two.
  - Wi-Fi and BLE share one radio (time-shared). Using both works but lowers throughput. That's fine for small control messages.
  - These are typical figures, not official specs; Raspberry Pi doesn't publish a range.
- **Placement:**
  - The antenna is the end **opposite** the USB port. Put it at the top edge of the back, near the **clear acrylic back panel**, ≥ 1–2 cm from motors, driver heatsinks, power wires and any metal. Don't put metal behind or around it.
  - Acrylic and PLA are radio-transparent.

## 12. Stand and enclosure (planned)

- **Joint:** buy a **mini camera ball head** (1/4"-20 thread, lockable knob, ~$5–10, holds 1–3 kg) instead of printing one.
  - Mount: a 1/4"-20 threaded insert/nut at the centre of the back panel.
  - Stand: a designed base (printed or acrylic) plus a post up to the ball head.
- **Plate stack:**
  - Black acrylic front bezel → tiles → front guide (clear) → rear guide (clear) → motor plate (clear) → electronics bay → clear back panel
  - Held by **4 M3 threaded rods** through the corner holes, with printed spacers or nuts to set exact gaps.
  - Side walls: acrylic (black or clear) with box joints, or printed corners.
- **Sensors:** LDR and presence sensor behind small holes in the **top-centre of the black bezel border**.
  - Prefer a VL53L0X/L1X time-of-flight sensor (tiny window, I2C) or an AM312 mini PIR (small dome). Avoid the HC-SR04 and big PIR domes.
- **Status LED:** on the main board, visible through the clear back panel.
- **Estimated weight:** ~1–1.5 kg (acrylic plates ~0.7 kg, tiles ~0.3 kg, motors and electronics). Within a mini ball head's rating.

## 13. Remaining planning (to do)

1. **Board layout drawing (PDF):** plate stack, spacings, where every part sits (row boards, main board, Pico W antenna, jack, switch, status LED, sensors, ball-head mount).
2. **Schematic:** main board + row board, Pico pin map, power wiring and fusing.
3. **Enclosure CAD:** side walls, back panel, spacers, sensor window, ball-head mount → add to `cad/` as laser PDFs and STLs.
4. **Stand design.**
5. **Motor plate + slider interface:** needs a real motor measured.
6. **Firmware architecture** (Embedded Swift on the Pico W: PIO LED + stepping, BLE protocol, re-homing) and the app protocol.
7. **Portfolio** (required by the brief): research, design criteria, ideation, decisions log, testing (clearance coupon, single tile, user test), evaluation.
8. **Final costed order list** → choose N and k.

## 14. Decisions from 2026-11-20 (later in the day)

### Timeline
- The school project **starts in ~3 months (≈ Feb 2027)**. The **design portfolio is next year**, not now.
- Hardware and firmware wait. **The apps can start now** to nail the UI/UX; the server also needs setting up.

### Software
- **Monorepo** with three projects plus shared code:
  1. **Pico W firmware** in Embedded Swift
  2. **Server** in Swift Vapor (connected through the Pico's Wi-Fi)
  3. **Swift clients:** iOS + macOS, mostly shared with platform-specific features, maybe watchOS
- The full feature list, navigation and architecture are in **`docs/app-plan.md`**. Ideas for later go in **`docs/prospectful.md`**.
- **Mac-only features:**
  - Presence from keyboard/mouse and other at-desk cues
  - **Music Mirror:** album art on the board, bottom 2 pixel rows show playback progress, optional beat-jumping tiles
  - Long-task detection
- **Other features:**
  - All the dither options (Stipple-style)
  - Timer (top 2 pixel rows: row 1 timer, row 2 margin)
  - Colours
  - On/off schedules
  - Ambient light sensor settings
  - Lots of App Intents (Shortcuts, Siri, automations)
  - Idle "sun through the day" mode
- **Design inspiration:** the **Stipple** app (`Xcode_App_Library/Stipple`), especially its `DitherSettings` model and settings UI.

### CAD
- The builder installed **Shapr3D**; it's the main CAD from now on. `hardware/cad/tile.py` stays as a parametric reference and for quick STL/PDF generation.

### Electronics
- ~~Perfboard for the final build.~~ **Superseded (rev 10): the builder will most likely use a breadboard with cut-to-length wires (~1 cm thick in total).** OK for logic; the 5 V LED/motor current must not go through breadboard rails (see §16). **No custom PCB** (builder said no). The builder wants help drawing the perfboard **schematics** later.

### Presence sensor: hardware sensor dropped (for now)
- The builder thinks a pointed ToF sensor would be unreliable. That's correct: ToF has a narrow cone and needs line of sight, and PIR misses people sitting still.
- **Presence comes from the Mac/iPhone apps** (keyboard/mouse, location, schedules).
- If a hardware sensor is wanted later: an **HLK-LD2410C 24 GHz mmWave sensor** (~$3–5, UART). It detects people sitting still (breathing micro-motion), has a wide ~±60° cone, works **through acrylic** (no hole), and is tunable.
- **Brief impact:** inputs become LDR (automated) + **NTC thermistor** (automated thermal safety: dims LEDs / pauses motors if the enclosure gets hot; also supports the "safe to operate" constraint) + app/network input (including Mac presence).
  - Outputs: LEDs (driven by LDR + NTC), steppers (driven by NTC + presence), status LED.

### Stand
- The builder **does not want a bulky camera ball head**. Idea: their own simple design.
  - A **rotation joint at each of the two side ends** of the board, with a wooden piece running down from each to the centre (a yoke/trunnion).
  - Must mount to **both a desk and a wall** in front of the desk, without sticking out too far or sitting too flat.
  - Details later.

### Mechanical drive system (brief requirement)
- Already met by the **screw drive** (lead screw + slider nut) in every tile actuator: rotary → linear, central to the design.
- **Suggested designed mechanism:** a **worm and worm wheel at a side pivot of the stand**.
  - A hand knob (or optionally a small geared stepper) sets the board's tilt.
  - It's **self-locking**, so it holds the angle without a clamp.
  - It's printable (e.g. module 1, single-start worm, 30-tooth wheel → 30:1).
  - Fits the builder's two-side-joint stand idea and works on desk or wall.
- Status: **suggested, not yet decided.**

## 15. Decisions (2026-11-20, evening)

### Mechanical drive system: still open
- The "screw drive in every tile" meant the lead screw **inside the bought motor**. The builder says, rightly, that **this won't count**: the mechanism has to be their own design.
- The builder **rejected the hand-cranked worm tilt** ("human controlled doesn't make sense").
- **Options now on the table:**
  1. **Design the tile screw drive yourself (recommended).** Buy 8 mm micro steppers with a **bare lead-screw shaft + brass nut** (no slider frame). Then design the rest: the nut carrier captured in the tile stem, anti-rotation from the square stem/guide, end stops, and the motor mount. The screw drive (rotary → linear) is then the builder's own design, central to the project, and in every tile.
  2. **Automated tilt ("sleep posture"):** a small geared stepper (e.g. 28BYJ-48 + ULN2003, ~$2–3) drives a self-locking **worm + worm wheel** at the stand pivot. The board tilts down to "sleep" when you're away or at night, and rises when you're back. It's driven by presence/schedule (automated), not by hand.
- Status: **awaiting the builder's choice.**

### Inputs
- The builder agrees that some inputs must be automated (LDR, NTC thermistor) and is fine with that. The LD2410C mmWave sensor is still being considered.

### Server
- **Runs in the cloud** (builder's decision), deployed with **Docker Compose** (via Dokploy/Traefik), modelled on Ergo's `ErgoServer/compose.yaml`.
- **Single board, single owner:** no accounts, users or device IDs. One board state and one board socket, protected only by a shared bearer token so strangers can't control it.

### Firmware requirement
- **Time sync:** on startup and after any power loss, the Pico W asks the server for the current time (`GET /time?tz=`), with an NTP fallback.

### App navigation (revised by the builder)
- No "Board" home tab. The live preview and dither controls live in **Dither**.
- Sections: Dither, Colours, Timer, Ambient, Music (Mac only), Automations, Device.
- More than 5 tabs → iOS "More" tab is wanted (don't condense unrelated things), which makes a bigger Mac sidebar.
- Colours = global palettes for every mode.
- Details in `docs/app-plan.md` §2.

### Music Mirror
- Now playing via AppleScript to Music.app / Spotify (one-time Automation permission): **accepted.**
- Beat detection: **deferred**; not system-audio capture for now.

### Software scaffolding done
- `shared/BoardKit`: a Swift package (dither engine ported from Stipple; tests pass; written to be Embedded-compatible but not yet verified; no Embedded toolchain installed).
- `apps/`: XcodeGen `project.yml` → `Board.xcodeproj` with iOS + macOS targets. Both build; the Dither section is live with the preview.
- `server/`: Vapor scaffold delegated to a Sonnet subagent (in progress).
- `hardware/components.md`: specific component models and costing delegated to a Sonnet subagent (in progress).

### Component costing (2026-11-20, `hardware/components.md`)
- Neither N=4 nor N=5 fits the $80 brief. **Lean N=4 ≈ US$106** (≈ $96 if the school L298Ns count), roughly $112 with GST. Lean N=5 ≈ $136.
- Corrections: real motor price ~$1.70–3.35 (the $1.10 was a new-buyer deal). The bare lead-screw motor (SINONING, ~$0.60–1.10, no nut) supports designing the screw drive yourself. Thrust is ~30 gf, not 80 g. Use 74HCT595, the DC-022D 10 A jack, an enclosed plug-in PSU, and JST-XH.
- Premade 4×4 WS2812 module (~7.5 mm pitch, $0.96/tile) vs hand-wired bare 5050s at 9.1 mm: **undecided** (the builder previously preferred bare square LEDs; the CAD cell would change to match whichever).
- Open questions from this section were answered in §16.

## 16. Decisions (2026-11-20, night)

### Budget and free parts
- Budget is **AUD**: brief ≤ AU$80, stretch ~AU$110 (≈ US$52 / US$72 at ~1.53 AUD per USD).
- Free from school: Pico W, L298Ns, acrylic, PSU, wires, breadboards, resistors, capacitors, screws, buttons and basic parts.
- Rough re-cost (from `components.md` §3, lean + free L298Ns, minus PSU, wire, caps, resistors/status LED, perfboard, headers, screws): **N=4 ≈ US$61 ≈ AU$93**, **N=5 ≈ US$85 ≈ AU$130**, before GST/shipping. Cuts still needed; the builder said "we'll see, don't overreact".
- PSU **doesn't need testing/tagging** (builder).

### Tile size
- The builder **wants smaller tiles** (more tiles per side, e.g. N=5 or 6), knowing that's more motors. Each extra tile is roughly US$2.50–3 (motor + LED module + driver + connectors).
- Note: with the premade 30 mm 4×4 module, the smallest tile pitch is ~33–34 mm (30 mm block + 1.2 mm rim each side + gap). So N=6 on a 200 mm board (33.3 mm pitch) is too tight for the module; smaller tiles than that would need k=3 or bare LEDs at a smaller pitch.

### Circuit
- Breadboard + cut wires instead of perfboard (see §14 note). Rules: signals (595s, drivers' inputs, LED data) on the breadboard; **5 V power for LEDs and motors on a separate bus** (terminal blocks/Wago or soldered bus wire), never through breadboard rails (~1 A each). Secure the jumpers (hot glue / tape) because the motors vibrate.

### LED power to moving tiles (restated)
- Each tile gets 5 V, GND, DIN (and DOUT back out) over thin, floppy 26–28 AWG silicone wire with a service loop for the travel, plugged in with JST-XH.
- Rows get power injection from an 18–20 AWG bus behind the motor plate. Brightness capped in firmware (16 LEDs ≈ 1 A at full white per tile).
- Wire drag now matters: thrust is only ~30 gf, so the service loop must not pull on the tile. The first test tile checks this.

### Mechanical drive
- Still **open** ("not yet").

### Server deployment (done)
- Mirrors Ergo exactly: workflow `.github/workflows/mirror-server.yml` copies `server/` to the **public** repo `omeriadon/BoardServerDeploy` on every push touching `server/**`, then calls Dokploy's `compose.deploy`.
- Differences from Ergo: pushes with a **write deploy key** (secret `SERVER_MIRROR_KEY`) instead of a PAT; the compose ID is the repo variable `DOKPLOY_COMPOSE_ID` (deploy step skipped until set).
- Secrets set in board-eng: `SERVER_MIRROR_KEY`, `DOKPLOY_API_KEY` (verified against dokploy.jdqc.dev).
- Dokploy app: compose, repo `omeriadon/BoardServerDeploy`, branch `main`, compose path `server/compose.yaml`, env `BOARD_API_TOKEN`, domain → service `board-server` port 8080.
- `BOARD_API_TOKEN` is a password the builder makes up (`openssl rand -hex 32`); the apps and firmware send it as `Authorization: Bearer …`.
- **Live (rev 11):** Dokploy compose app "Board" (id in repo variable `DOKPLOY_COMPOSE_ID`), path `./server/compose.yaml`, auto-deploy off (the GitHub Action triggers it, as for Ergo), domain `https://board-15.235.184.129.sslip.io` → `board-server:8080` with Let's Encrypt. `/health` and `/time` answer; `/v1` needs the bearer token.
- First build failed because `.dockerignore` excluded `Tests/` while `Package.swift` declares the test target (SwiftPM reported overlapping sources). Fixed by keeping `Tests/` in the context. The image builds fine now.
- `BOARD_API_TOKEN` was generated by Claude (`openssl rand -hex 32`), stored in Dokploy's env and in the gitignored `server/.env` on the builder's Mac. It's never committed.

## 17. App design (2026-11-20, night)

### Board size locked: 4 × 4 tiles
- **16 tiles × 16 LEDs = 256 LEDs, a 16 × 16 pixel display.** `BoardGeometry.standard` is now 4 tiles per side.
- Real size (current CAD, 40 mm pitch, 10 mm margin): about **18 cm square, ~7 cm deep**. 5×5 would be ~22 cm, 6×6 ~26 cm. The 250 mm limit is being ignored by the builder anyway.

### One wire format (BoardKit/Wire.swift)
- All three programs encode and decode with the same plain-bytes codec (no Foundation/Codable, so it works in Embedded Swift on the Pico). Same bytes over Bluetooth (GATT write) and Wi-Fi (WebSocket binary frame).
- `BoardMessage`: `.state(Revision, BoardState)`, `.status(BoardStatus)`, `.requestState`, `.time(...)`. State is always sent whole (~150 bytes), so it can't arrive half-applied.
- Decoding rejects truncated/trailing/unknown-version messages and clamps every value (`bounded()`), so corrupt data can't push the board past its limits.
- **Both links at once:** a device sends each change on every connected link. `Revision` = (counter, origin id). `StateSync` applies a message only if its revision is newer, so the duplicate over the second link is dropped and a late stale message is ignored. The board runs the same `StateSync`.
- _Superseded in §18: the server and apps now use BoardKit and have real transports._

### Settings: every Stipple option that makes sense on LEDs
- Kept: wave speed/direction (8-way)/frequency/amplitude/scale/contrast/brightness, pattern, strength, colour levels, wave colour, background (custom/black/white/dimmed), colour goes on (squares/background), square style, palette (≤8) + spread, plus presets (18 ported).
- Reinterpreted for LEDs: **cell size** = LEDs per dither cell (1×1, 2×2, 4×4 = one per tile); **blur** = mixes each LED with its neighbours.
- Dropped (screen/watch only): gap, corner radius, join squares, touch ripples, intro, frame rate, always-on brightness, crown.

### Motion is its own section, independent of the lights
- `MotionSettings` (applies in every mode): master on/off, strength, speed, quiet mode, max tiles moving at once; height source = follow lights / opposite of lights / **own wave** (direction, speed, frequency, scale) / **ripples** (origin on a 3×3 picker, spacing, speed) / still.
- `BoardRenderer.step` (shared by the preview and the firmware) makes the lights, picks target heights, then applies the slew limit, so the preview moves exactly like the real tiles would.
- Quick-controls have a one-tap "tiles move" toggle (silences the board instantly).

### App
- Tabs: Dither, Motion, Colours, Timer, Ambient, Music (Mac), Automations, Device (iOS: More tab after five; Mac: grouped sidebar).
- Pinned live board preview on top of Dither and Motion (like Stipple's pinned watch), with a connection badge and a save-as-preset heart.
- Custom controls ported from Stipple: `DirectionDial` (8-way pixel-arrow compass), `PositionPicker` (3×3, used for ripple origin; later the timer bar/sun position), live mini-board preset grid with touch-and-hold delete, `ValueSlider` with numeric transitions and haptics.
- Both targets build (iOS + macOS). The Mac app was run and looks right.

## 18. Bigger board, all modes, real links (2026-11-20, late night)

### Resolution: 6 LEDs per tile → 24 × 24 pixels
- The builder wants more pixels and/or a bigger board ("even 6×6"). `BoardGeometry.standard` is now **4 × 4 tiles × 6 × 6 LEDs per tile = 24 × 24 px, 576 LEDs**. Not yet confirmed whether the builder meant 6×6 LEDs per tile (what I did) or 6×6 tiles; ask.
- **Consequences to resolve in hardware:** the LED pitch in a 40 mm tile is ~6.7 mm (5 mm 5050 bodies fit, but tightly); each moving tile carries 36 LEDs, and the 30 gf motor thrust limits tile weight (use thin flex/PCB, not a printed block). `hardware/cad/tile.py` still has N=5, K=4 and must be regenerated (K=6, N=4, thinner grid walls ~0.8 mm).
- **Power:** 576 LEDs × 60 mA = **34.6 A at 5 V (173 W) at full white**. With the firmware brightness cap (~25%) and typical dither content (mostly dark) it is a few amps, but the supply and wiring must be sized for the cap, not the average. Power-inject at several points.
- **"Run them in parallel / higher voltage?"** Power per LED is fixed (~0.3 W), so more voltage means less current for the same power, and thinner wire and less voltage drop, but not less energy. Parallel wiring of the same LEDs doesn't reduce the total current. The practical version is **12 V WS2815 LEDs** (same protocol, ~2.4× less current: ~14 A worst case) or just a 5 V supply injected in several places. 5 V stays the simpler, safer default for school.

### New modes (BoardKit `ModeFields.swift`, shared by preview and firmware)
- **Ambient:** sun and moon arc across the board by the hour; sky gradient, twilight, stars, optional time-lapse (a day in N seconds). **Music Mirror:** album art (24×24) with a progress bar on the bottom two rows; art can be dithered with the Dither settings; falls back to dither with no art. **Timer:** bar on the top LED row (second row stays dark), drain or fill, smooth to a fraction of an LED, blinks when done; the end time is absolute (`endsAtMillis`) so devices agree without per-second messages.
- **Automation lives in the state** (`Automation.effective`): schedules (up to 8, can wrap past midnight), auto-brightness from the board's light sensor, and away-from-desk dimming/off/stop-moving. So the board follows them without any app.
- Maximum wave speed is **0.04** (dither and motion own wave).

### Wire format additions
- `BoardMessage` now also has `.artwork` (side 0 = clear) and `.command` (home all, test pattern, stop test, test tile, reboot). `Framing` chunks messages for Bluetooth writes. Full state is ~350 bytes. BLE UUIDs and the socket path are in `BoardBLE`.

### Links (apps)
- `BoardLink` fans every change out to every connected transport (coalesced to ~30/s). On a link coming up, the store re-sends its state and asks for theirs. `WebSocketTransport` (pong-confirmed, 20 s keepalive, backoff, Bearer header) and `BluetoothTransport` (CoreBluetooth central, chunked writes). The server address is stored in UserDefaults, the password in the Keychain.
- The Mac app also watches Music/Spotify (AppleScript, only while in Music Mirror, never launches them) and sets `isAway` from keyboard/mouse idle time. Apple Music streaming tracks don't share their cover with scripts, so the cover is fetched from Apple's public iTunes Search API (only title and artist are sent; there is a switch). The Mac app is no longer sandboxed (Apple Events + Bluetooth entitlements).
- App Intents / Shortcuts: power, brightness, mode, jumping on/off, apply theme, start/pause/reset timer.
- App icon: generated from the real renderer (`apps/Tools/MakeIcon.swift`).

### Server
- Now speaks the BoardKit binary format at `WS /v1/board/socket` (bearer token), relays state/artwork/status/commands between sockets without echo, dedupes by revision, persists the state to `/data/state.bin` (volume `board-data`), and still serves `/health`, `/time` and JSON `GET/PUT /v1/board/state`. Docker builds from the repo root and the mirror workflow copies `server/` and `shared/BoardKit/`.

### Preview scroll lag
- The Dither list's mini boards were all animating while scrolling. They now run at 6 fps and pause while the list scrolls.

### Server redeployed (rev 13)
- The BoardKit-based server is **live** on Dokploy (verified: a WebSocket client receives the time and state frames). The first deploy failed because the Docker build cache from the old layout was keyed to the old path; the cache id is now `board-server-build-v2`. Change the id again if the build path ever changes.
- Apple Music tracks from the streaming catalogue are "shared tracks" and return no artwork to scripts (error -50), hence the online cover lookup.

## 19. Status bar, art dithering removed, Pico circuit (rev 14, 2026-11-20)

The builder said the apps and server are finished ("dont worry about the app or server anymore") and moved on to hardware.

### Status bar (done in BoardKit and the apps)
- The board now has a **separate row of 24 LEDs under the grid with a gap**, holding the timer and the song progress so they no longer cover the picture. `BoardGeometry.barPixelCount` (= pixelsPerSide) and `totalLEDCount` (= 600); `BoardFrame.bar` holds the bar LEDs. The bar is fixed (no motor).
- Timer: grid keeps the dither, the bar is the countdown. Music: the art uses the whole 24 × 24 grid, the bar is the progress. Dither and Ambient leave the bar off (free for later uses).
- The preview draws the gap and the bar; its aspect ratio is no longer 1. Docs in `docs/app-plan.md` updated.
- **Album-art dithering removed** (builder: "remove the option to dither"): art is always true colour. The wire format keeps a reserved byte where `ditherArt` was, so it is byte-compatible with the deployed server and saved `state.bin`.
- Not yet done: CAD for the bar and the longer bezel (`hardware/cad/tile.py` is also still the old N=5, K=4).

### Raspberry Pi: pin map and circuit (`hardware/circuit.md`)
- Full Pico W pin map, 3 inputs / 3 outputs table, power distribution (5 V bus, one PTC fuse per tile row, bar, motors, logic), blocks (LED level shifter, 595 chain, sensors, status LED, VSYS diode), budget and bring-up order.
- Pins: LED data GP2–GP5 (tile rows) and GP6 (bar) through one 74HCT245 + 330 Ω each; 595 chain GP10 (clock), GP11 (data), GP12 (latch), GP13 (OE, pulled high until the firmware has cleared the motors); LDR GP26/ADC0; NTC GP27/ADC1; optional 5 V monitor GP28/ADC2; status LED GP15; GP0/GP1 debug UART; the rest spare. GP23/24/25/29 belong to the radio.
- 595s run from the Pico's 3.3 V (plain 74HC595 works). L298N prototype modules need the 5 V-EN jumper removed and 5 V fed to their 5 V pin.
- **Power-injection answer:** each tile row has its own fused 5 V + GND feed from the bus and each tile taps it with its own wire; only data daisy-chains.
- **Power budget:** 600 LEDs at 25 % (~9 A) plus motors and logic overloads a 10 A brick, so the firmware should cap LED **current** (~5–6 A on a 10 A brick) instead.
- **7805 (teacher's):** logic only, from 9–12 V, ≤ 1 A, hot without a heatsink; cannot run LEDs or motors; not needed from a 5 V brick.
### Own power supply and the 12 V option (rev 14, later)
- The builder asked whether the current can be cut with more voltage, and decided **we buy our own supply**. Answer in `hardware/circuit.md` §3.3: volts × amps = watts is unchanged, but 12 V (WS2815 LEDs + a 12 → 5 V buck for motors and logic) cuts the total from ~8.5 A to ~3.7 A, needs only a standard 12 V 5 A brick (~AU$46) and thinner wires and fuses. WS2815 pixels can draw ~0.36–0.43 W, so cap LED power in watts. Adds ~AU$25–50 to the budget, which was already over; unverified: bare WS2815 5050 supply and data-input level.
- Builder may use an **old laptop charger from home** instead of buying (typically 19–20 V, 65–90 W): enough watts, needs buck modules (see `circuit.md` §5). The real limits are the supply's **watts** (set by the LED power cap) and the **amps** the wires, fuses and rails can carry; higher voltage fixes only the second.
- **Supply chosen (rev 14):** the builder's candidates were 12 V 4 A, 16 V 3.75 A and 20 V 3.33 A chargers. Recommended: **12 V 4 A** with 12 V WS2815 LEDs and one 12 → 5 V 5 A buck (`circuit.md` §3.4); LED power capped at ~23 W. Awaiting the builder's OK; WS2815 sourcing unverified.
- **Two chargers (builder's idea, rev 14):** 12 V 4 A for the LEDs only, a second charger (16 or 20 V) through one 12→5 V buck for everything else. Verdict: works and is better (LED budget ~41 W vs 23 W, no motor interference); needs a common ground, one switch for both, and data-line pull-downs. See `circuit.md` §3.5.
- **Overload is possible by design** (full white = ~258 W vs a 48 W charger; all 16 motors on = ~5–10 A at 5 V), so protection is layered: (1) a **power limiter in BoardKit/firmware** that scales the frame so LED watts stay under the budget (NOT YET IMPLEMENTED; the renderer only has the user brightness slider) and motor limits (`maxMovingTiles`, de-energise idle coils); (2) PTC/blade fuses per branch; (3) the charger's own overcurrent protection as the last line.
- **Third charger (rev 14):** `circuit.md` §3.6. 12 V 4 A → rows 0–1 direct; 20 V 3.33 A → 12 V buck → rows 2–3 + bar; 16 V 3.75 A → 5 V buck → motors/logic. LED budget ~90 W (~35 % of full white) vs ~41 W. Recommended: start with two chargers, add the third only if too dim through the smoked acrylic. Power limiter must be per supply group.
- **Joining bricks / motor limit (rev 14):** not joining (different voltages can't be paralleled; series needs bigger bucks and goes near 50 V). Motors are on their own supply, so `maxMovingTiles` can rise from 4 to ~6 with a 5 A buck (12 with 8 A); set by the buck, not the charger. `circuit.md` §3.7. Default not yet changed in `Settings.swift`.
- **DECIDED (rev 14): all three chargers** (§3.6): 12 V 4 A → LED rows 0–1; 20 V 3.33 A → 12 V buck → rows 2–3 + bar; 16 V 3.75 A → 5 V 5 A buck → motors/logic. LED power budget ~80–90 W: about 35 % of full-white *power* (the builder said "70 %"; that is closer to the *perceived* brightness, about 65 % lightness, but the limiter works in watts). `maxMovingTiles` default raised 4 → 6. Needs 2 bucks (~AU$16). Still unverified: WS2815 5050 sourcing, real motor coil current.
- **LED power by setup (rev 14, WS2815 max 258 W):** one 12 V brick shared with everything ~23 W (9 %); two bricks ~41 W (16 %); all three ~90 W (35 %). The builder will **finalise all models and ingredients before buying**. Buck heatsinks: the builder will make a custom aluminium one; keep it insulated from other metal (the tab can be live) and away from the Pico antenna.
- **`hardware/circuit.md` rewritten (rev 14):** §3 is now the final three-charger power plan with fuse list, §7 has the row-board, driver and tile-cable wiring. Not yet drawn as a real schematic, and the tile connectors wait for the final LED part.
- **Schematics PDF (rev 15):** `hardware/schematics/dither-board-schematics.pdf` (12 pages: cover, power, logic schematic, two breadboard layouts, wire lists, parts, shift-register-to-driver table, models and checks). Generated by `hardware/schematics/make_schematics.swift` + `Lib.swift`, `Breadboard.swift`, `Pages.swift` (compile line in the header comment); one netlist drives both the drawings and the wire lists. The builder added a **second breadboard** because the build needs ~94 columns vs ~60 on one board. Provisional: LED part and tile connectors, 74HCT245/74HC595 pin numbers (from standard datasheets, not checked against the builder's chips), nothing tested on hardware. Open: temperature sensing kept as an NTC for now (a digital sensor such as DS18B20 would need teacher approval; trivial swap); per-group power limiter not built; CAD not updated for the bar.
- **Ingredients consolidated (rev 16, 2026-11-20):** `hardware/ingredients.md` rewritten as one list in **AUD** (budget ignored, cheapest reasonable parts). The builder confirmed **6 × 6 = 36 LEDs per tile (600 LEDs total)**. **Provided free:** Pico W; basic passives; 2 breadboards + jumpers; wire and connectors; screws, nuts, threaded rod; switch, DC plugs, PTC fuses; black + clear acrylic, laser cut; PLA + printer (the diffuser is a thin 3D-printed sheet, NOT smoked acrylic); soldering kit + multimeter; the three chargers. **NOT provided, so bought:** L298N modules (final driver is now the **MX1508**, 18), 74HC595 ×10, 74HCT245 ×5, 18 bare lead-screw motors (SINONING), 660 × WS2815B-V1 LEDs (LCSC, ~AU$88 + shipping) + 700 × 100 nF 0805, tile PCBs (JLCPCB, black, not designed yet), 3 × XL4016 bucks, JST-XH sets. **Estimated total ≈ AU$270** incl. GST; LEDs are ~45 %. Open: hand-solder 1,320 SMD parts vs JLCPCB assembly (not priced); K = 6 CAD update (`tile.py` still K = 4); LED price/stock at LCSC (search snapshots disagree). `components.md` carries a note that `ingredients.md` supersedes it.
- **System blueprint (rev 15):** `hardware/schematics/dither-board-blueprint.pdf`, ONE connected drawing of the whole project (3000 × 1600 pt, vector, zoom in): power (3 chargers, fuses, 2 bucks, rails), Pico with pin numbers, 74HCT245 + 330 Ω/10 kΩ, the eight 595s with CLK/LATCH/OE buses and the QH' chain, LED data daisy-chained through each row, 16 drivers + 16 motors + 16 LED blocks, status bar, sensors, breadboard 1/2 outlines. Power rails are net labels (+12V·R0, +5V·MOT…); the 4-wire 595-to-driver buses are numbered circles T0–T15; cross-board wires are circles a–j (same as the wire list). Generate: `/tmp/mkschem schematics.pdf - blueprint.pdf`. The earlier tiled-pages poster was dropped (not what was asked for).
- **Builder's breadboard (photo, rev 14):** one large breadboard of about 60 columns, with a power rail along the top edge and another along the bottom edge, two bands of 5 rows (A–E, F–J) separated by the centre trench. The rails look split in the middle (break near column 30). Fits roughly: Pico (20 columns) + 74HCT245 (10) + 4 shift registers (8 each), not all 8 shift registers (64 columns) as well. Use only for the logic prototype; the 12 V LED and motor power must not run through the rails (about 1 A each).
- **Open:** 12 V WS2815 sourcing; 6 LEDs per tile vs 6×6 tiles; mechanical drive system.
- **LEDs repriced (rev 17, 2026-11-21):** the builder said AU$88 for LEDs was too much. Real LCSC tiers (product API): WS2815B-V1 150+ = US$0.0738 (the old figure used a stale 5-piece price), so 660 = ~AU$71. **New choice: WS2815F (C22371533, 12 V, 6-pin, 300+ = US$0.0489), 630 pcs = ~AU$44.60**; WS2815B-V1 is the fallback. 5 V parts are not meaningfully cheaper (XINGLIGHT clone saves ~AU$7, needs a 5 V supply). Capacitors C49678 650 pcs = AU$6.60. **Estimated total now ≈ AU$223** incl. GST (was 270). Open: verify WS2815F pinout/logic threshold before the tile PCB.
- **Diffuser LED options (rev 17, 2026-11-21):** with a diffuser the LED need not be square, but smaller packages (3535/1010) are dearer; the 5050 WS2815F stays cheapest. Option noted: a 144 LED/m strip (~6.9 mm pitch) to avoid hand-soldering (5 V, unpriced, undecided). Capacitors (0805 100 nF) may be available free at school.
- **Mechanism explained and design blueprint (rev 18, 2026-11-21):** `hardware/schematics/dither-board-design-blueprint.pdf` (2800 × 1700 pt, blue paper, white ink, SF Pro Text embedded; generator `Mech.swift`) draws the CURRENT design: front elevation, section through a tile column (one tile retracted, one extended 15), exploded view, the 6 × 6 cell, drive chain and force check, dimension-chain checks, open items, system block diagram and a 26-line parts list with status (decided / proposed / not designed). The electrical `dither-board-blueprint.pdf` was re-themed blue/white SF Pro; the A4 schematics stay white. **Current mechanism:** 8 mm 2-phase stepper (20 steps/rev, assumed M2 × 0.4 → 0.02 mm/step) with a bare 28 mm screw; brass nut in a printed carrier at the tip of a 20 mm square hollow stem; the stem slides in two 20.5 mm square holes in two 3 mm acrylic guide plates (anti-rotation, no neighbour contact); stroke 15 mm = 750 steps = 1.5 s at 500 pps; soft pad on the head lands on the front guide plate as the retract stop. **Derived:** depth ≈ 89.8 mm retracted, ≈ 105 mm with a tile out (bay 31.6 mm is [E]); this replaces the 7 cm / 11 cm in older notes. **Checks:** screw engagement, stem-in-plate, end-stop and screw-tip clearances all close. **Risks found:** (1) the LED opening is 5.07 mm for a 5.0 mm LED (0.035 mm a side; cell is 6.07 mm, not 6.5) so K = 6 needs walls ≤ 0.77 mm or a thinner rim; (2) tile ≈ 27 g [E] vs 30 gf thrust borrowed from another motor: marginal face-up, fine on a wall; (3) guide wobble ±1.2 mm at 0.25 mm clearance vs a 1.2 mm head gap (±0.7 at 0.15 mm). Not designed: nut carrier, motor retention, tile PCB, detents, homing, wire loom, stand. `tile.py` is still N = 5, K = 4 (it must be updated to N = 4, K = 6 or the K the builder picks). **Price:** mechanism is ~AU$3.30 per tile (~26 % of AU$203); ranked levers are in `ingredients.md` §H (K = 5 −AU$14, K = 4 −AU$23, 3 × 3 −AU$42, school capacitors −AU$6.60); none applied yet, builder to choose.
- **No custom PCBs; soft-sheet concept (rev 19, 2026-11-21):** the builder objected to "PCBs": they want the provided breadboards used and nothing custom ordered. The JLCPCB tile boards (A6) were removed from `ingredients.md`. Clarified: breadboards only carry the logic (Pico, level shifter, eight 595s); bare 5050 LEDs cannot sit on a breadboard, so with A6 gone the LED carrier is OPEN. The builder proposed **Concept B**: LEDs on a soft rubber/fabric sheet and each motor drives a stick that pushes the sheet up (organic look, far less precision). Assessment written to `ingredients.md` §I: mechanically much easier (no tiles/guide plates/stems; 3 g moving mass vs 27 g; tolerances ±0.5 mm instead of ±0.1), cheaper (≈ AU$120–130 ex-GST vs ≈ 223), but unproven: LEDs on a moving sheet need either a flexible 16 × 16 matrix (gentle shapes only, 16 × 16 pixels, 5 V) or 144 LED/m strips in sleeves (24 × 24), the sheet must push back under ~25 gf, and the stick must be attached to the sheet to retract. The LED plane would become 5 V WS2812B (12 V plan and buck 1 dropped). **Not decided**; recommended next step is a 3-motor, 0.5 m lycra, 1 m strip prototype.
- **Tile design confirmed; LED carrier and servo options (rev 20, 2026-11-21):** the builder chose the TILE design (soft sheet shelved: LED viewing angle changes as the sheet tilts, thin lycra limits height). They also asked whether three chargers at full output would trip the house fuse: no, ~205 W at 230 V ≈ 0.9 A. They called the per-LED custom PCB too expensive and asked about premade modules: `ingredients.md` §J1 recommends **premade 30 × 30 mm 4 × 4 WS2812B modules** (16 × 16 pixels, 5 V, AU$29–55 for 18; removes custom PCB, 1,320 solder joints and the 12 V plan; the apps' pixelsPerSide 24 → 16; builder must confirm K = 4). They proposed a **servo + printed lead screw** instead of bought steppers: §J2 compares them (cost roughly equal; servo ~100 × the force, ~4 × faster, kills the 595/MX1508/64-jumper wiring; but not self-locking, back-drive and servo hum, 180° needs a high-lead screw or a crank). Not decided. The design blueprint's BOM line 3 now reads "LED carrier (open)".
- **Servo route and Electropeak parts (rev 21, 2026-11-21):** the builder accepted servos (their SG90s were strong enough; finger push only just-in-case; wiring complexity irrelevant, only performance and cost matter; a crank / scotch yoke counts as the drive). New buy list in `ingredients.md` §A: 18 × TowerPro MG90S (A$1.80), 2 × PCA9685 (A$4.03), 18 × WS2812B **5 × 5** square modules (A$1.80, Electropeak ELC-02-099; the page says 3.9 mm, must be ~39 mm; pad layout unknown), 3 bucks, 74HCT245, JST. Total ≈ AU$144 incl. GST (was 223). Consequences: tile inner ~39.6 mm (head ≈ 42, pitch ≈ 43, board ≈ 192 mm), pixels 20 × 20 + bar (apps 24 → 20), mechanism = servo scotch yoke (pin 7.5 mm radius in a slot in the stem tail), 5 V LEDs and servos only, steppers / MX1508 / 74HC595 / tile PCBs / 12 V plan dropped. Brightness: with all LEDs white at a 5 A limit ≈ 20 % duty ≈ 1,750 nits [E, untested diffuser]. The design blueprint PDF still shows the stepper/screw and K = 6 and is NOT yet redrawn.
- **Electropeak review, servo fit, pixel count (rev 22, 2026-11-21):** re-read both Electropeak pages. 5 × 5 module: good; "3.9x3.9mm" is certainly 3.9 cm (the 8-LED stick says "5.4x1" = 54 × 10 mm); 7.8 mm LED pitch makes the grid cell 7.8 mm, which removes the 0.035 mm clash of the 6 × 6 design. 8-LED stick (A$0.3888, 5 V) chosen for the status bar: 3 sticks = 24 LEDs, use 20 (A$1.56 for 4). Pixels: 4 × 4 tiles × 5 = **20 × 20 = 400 + 20 bar = 420**; the builder's "6 tiles at 5 = 30 × 30" would be 36 tiles (≈ +A$76, ≈ AU$225 total, 800 nits at 5 A), not chosen. Brightness: the limit is total current (≈ 350 nits per amp full-screen), so bright patches are allowed as long as lit fraction × nits ≤ 1,750 at 5 A (3,000 nits up to ~58 % of the screen); needs a firmware limiter and a ~1 A per-module cap. Shipping: FOB Shenzhen (no customs paid by the seller), DHL base "$35" (≈ A$50 if US$), free over "$100" (≈ A$144 if US$, not reached); total ≈ AU$143, worst case ≈ 170. Servo fit: 23 × 12 mm footprint fits a 43 mm cell but lies behind the stem (+15-25 mm depth, estimate), not beside it; scotch yoke is easy to print (slot in the stem tail, horn + pin at 7.5 mm). Design blueprint and `tile.py` still stale.
- **Checkout, servos provided, CAD model, blueprint, app layout controls (rev 23, 2026-11-21):** the builder's Electropeak checkout is **A$51.49** (16 modules + 3 sticks = A$29.97, Tracked Economy shipping A$21.53 with customs included, 12-15 days). They already have SG90 servos, so servos come off the budget (MG90S stays a fallback). Buy list total ≈ AU$89. Asked that the mechanism use enough of the servo's rotation: chosen ±75° of ±90° at R = 7.76 mm, force margin ≈ 25× (0.047 kg·cm needed vs 1.2 listed). `hardware/cad/tile.py` now models the servo scotch yoke (yoke, bracket, stem, head with 5 × 5 grid, printed diffuser, assembly STLs) with a 9-position collision sweep (0.000 mm³). Depth is 78.1 mm retracted / 94 mm with a tile out, shallower than the stepper design; my earlier "+15-25 mm" was wrong. The design blueprint was redrawn. The app's Device tab gained Board Layout steppers (tiles per side, LEDs per tile side) with presets, counts and a brightness estimate so the builder can choose pixel counts; default geometry is now 4 × 4 × 5. Still open: servo outline measured from the real SG90, module pad layout, wiring PDFs not redrawn, `pixelsPerSide` firmware side.
