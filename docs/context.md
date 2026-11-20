# Dither Board — Full Project Context

_Last updated: 2026-11-20 (rev 10)_

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
- **Pico pins:**
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
- The Docker image has **never been built** yet; the first Dokploy deploy is the first build.
