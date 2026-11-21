// Logic schematic, servo channel table, models and checks (rev 26: 5 × 5 tiles, SG90 servos on two PCA9685 boards).
import CoreGraphics
import Foundation

func pageLogic() {
	beginPage("Logic schematic", "Pico W, 74HCT245 level shifter, I2C to the two PCA9685 servo boards, sensors, status LED. Pin numbers are Pico physical pins.")
	// Pico block
	rect(36, 62, 150, 330, fill: rgb(0.88, 0.96, 0.9), stroke: cBlack, lw: 1.2, r: 4)
	text("Pico W", 111, 78, size: 11, bold: true, align: 1)
	text("(3.3 V logic)", 111, 90, size: 8, color: cGray, align: 1)
	let ledPins: [(String, Int, String)] = [("GP2", 4, "LED row 0"), ("GP3", 5, "LED row 1"), ("GP4", 6, "LED row 2"), ("GP5", 7, "LED row 3"), ("GP6", 9, "LED row 4"), ("GP7", 10, "LED bar")]
	let ys: [CGFloat] = [108, 130, 152, 174, 196, 218]
	// 74HCT245
	rect(290, 94, 96, 138, fill: cLight, stroke: cBlack, lw: 1.2, r: 3)
	text("74HCT245", 338, 108, size: 9, bold: true, align: 1)
	text("5 V · DIR high", 338, 226, size: 7.5, color: cGray, align: 1)
	for (i, p) in ledPins.enumerated() {
		let y = ys[i]
		text("\(p.0)  pin \(p.1)", 182, y + 3, size: 8, align: 2)
		arrow(186, y, 290, y, cGreen, w: 1.2)
		text("A\(i + 1)", 294, y + 3, size: 7.5)
		text("B\(i + 1)", 382, y + 3, size: 7.5, align: 2)
		line(386, y, 410, y, 1.2, cGreen)
		resistor(410, y, 36, cBlack)
		text("330 Ω", 428, y - 7, size: 7, align: 1, )
		line(446, y, 500, y, 1.2, cGreen)
		// pull-down
		dot(470, y, 1.8, fill: cBlack)
		line(470, y, 470, y + 3, 1, cBlack); rect(466, y + 3, 8, 10, fill: cWhite, stroke: cBlack); line(470, y + 13, 470, y + 16, 1, cBlack); line(466, y + 16, 474, y + 16, 1.2, cBlack)
		text("10 kΩ", 478, y + 13, size: 6.8, color: cGray)
		rect(500, y - 9, 130, 18, fill: cWhite, stroke: cGreen, lw: 1.2, r: 3)
		text(p.2 + " DIN", 565, y + 3, size: 8, bold: true, align: 1)
	}
	_ = paragraph("Each line: 330 Ω in series, then a 10 kΩ pull-down to GND at the junction. The pull-down keeps the line quiet while one supply is off. Row r = tiles 5r to 5r + 4 (five 5 × 5 modules in a chain); the bar is its own line.", 646, 112, width: 170, size: 7.5, color: cGray)
	// 245 power
	text("VCC → 5 V logic + 100 nF   ·   DIR → 5 V   ·   OE → GND   ·   A7, A8 → GND", 290, 248, size: 7.5, color: cRed)

	// I2C and OE to the PCA9685 boards
	text("Servo drivers: 2 × PCA9685 on one I2C bus (I2C0, 400 kHz), 3V3 chip logic, 5 V servo supply on V+", 232, 272, size: 9, bold: true)
	let busY: [CGFloat] = [296, 332, 368]
	let busPins: [(String, String, CGColor)] = [("GP16 pin 21  SDA", "SDA", cBlue), ("GP17 pin 22  SCL", "SCL", cBlue), ("GP13 pin 17  OE", "OE", cBrown)]
	let pullUps = ["4.7 kΩ", "4.7 kΩ", "1 kΩ"]
	for (i, b) in busPins.enumerated() {
		let y = busY[i]
		text(b.0, 182, y + 3, size: 8, align: 2)
		arrow(186, y, 330, y, b.2, w: 1.3)
		// pull-up to 3V3
		let tx: CGFloat = 232
		dot(tx, y, 1.8, fill: b.2)
		resistor(tx, y, 22, cBlack, vertical: true)
		text(pullUps[i], tx + 8, y + 15, size: 6.8, color: cGray)
		text("3V3", tx, y + 32, size: 7, color: cOrange, align: 1)
	}
	rect(330, 280, 330, 108, fill: rgb(0.93, 0.95, 1), stroke: cBlack, lw: 1.2, r: 4)
	text("2 × PCA9685 (16-channel servo board, I2C)", 495, 294, size: 9, bold: true, align: 1)
	text("SDA · SCL · OE · VCC · GND wired to both boards in parallel (one short cable)", 495, 306, size: 7.5, color: cGray, align: 1)
	rect(340, 314, 148, 58, fill: cWhite, stroke: cBlack, r: 3)
	text("#0 · address 0x40", 414, 328, size: 8.5, bold: true, align: 1)
	text("channels 0 to 15", 414, 340, size: 7.5, align: 1)
	text("servos of tiles 0 to 15", 414, 351, size: 7.5, align: 1)
	text("A0 to A5 open", 414, 363, size: 7, color: cGray, align: 1)
	rect(502, 314, 148, 58, fill: cWhite, stroke: cBlack, r: 3)
	text("#1 · address 0x41", 576, 328, size: 8.5, bold: true, align: 1)
	text("channels 0 to 8", 576, 340, size: 7.5, align: 1)
	text("servos of tiles 16 to 24", 576, 351, size: 7.5, align: 1)
	text("A0 bridged with solder", 576, 363, size: 7, color: cGray, align: 1)
	text("OE is held high by the 1 kΩ pull-up until the firmware has written all 25 start positions, then the Pico pulls it low.", 330, 400, size: 7.5, color: cBrown)
	text("VCC (chip logic) ← 3V3 · V+ (servos) ← +5V·SRV through its own heavy pair of wires, 470 µF across V+ and GND at each board · GND → star.", 330, 410, size: 7.5, color: cRed)
	// servo power note box (right)
	_ = paragraph("Each board's channel header is three pins (GND, V+, PWM), so a servo lead plugs straight in. The 25 servo signals do NOT go through the Pico: they come from the PCA9685 channels.", 676, 296, width: 140, size: 7.5, color: cGray)

	// Sensors and power, bottom
	let by0: CGFloat = 430
	text("Inputs and indicator", 36, by0 - 6, size: 9, bold: true)
	func sensor(_ x: CGFloat, _ title: String, top: String, bottom: String, pin: String) {
		text(title, x + 40, by0 + 10, size: 8, bold: true, align: 1)
		line(x + 40, by0 + 14, x + 40, by0 + 22, 1.4, cOrange); text("3V3", x + 40, by0 + 18, size: 7, color: cOrange, align: 0)
		line(x + 40, by0 + 22, x + 40, by0 + 28, 1.2)
		resistor(x + 40, by0 + 28, 34, cBlack, vertical: true)
		text(top, x + 50, by0 + 42, size: 7.5)
		dot(x + 40, by0 + 62, 2, fill: cBlack)
		line(x + 40, by0 + 62, x + 74, by0 + 62, 1.2, cBlue); text(pin, x + 78, by0 + 65, size: 7.5, color: cBlue)
		resistor(x + 40, by0 + 62, 34, cBlack, vertical: true)
		text(bottom, x + 50, by0 + 78, size: 7.5)
		ground(x + 40, by0 + 96)
		capacitor(x + 22, by0 + 62); line(x + 22, by0 + 62, x + 40, by0 + 62, 1.2); ground(x + 22, by0 + 80)
		text("100 nF", x + 22, by0 + 104, size: 7, align: 1)
	}
	sensor(36, "LDR (light)", top: "LDR", bottom: "10 kΩ", pin: "→ GP26 pin 31")
	sensor(206, "NTC (temperature)", top: "10 kΩ", bottom: "NTC 10 kΩ", pin: "→ GP27 pin 32")
	// status LED
	text("Status LED", 396, by0 + 10, size: 8, bold: true)
	arrow(380, by0 + 40, 410, by0 + 40, cBlue); text("GP15 pin 20", 376, by0 + 43, size: 7.5, color: cBlue, align: 2)
	resistor(410, by0 + 40, 36, cBlack); text("4.7 kΩ", 428, by0 + 33, size: 7, align: 1)
	line(446, by0 + 40, 460, by0 + 40, 1.2); diode(460, by0 + 40); line(492, by0 + 40, 500, by0 + 40, 1.2); ground(500, by0 + 40)
	text("red LED, ~0.3 mA (dim on purpose)", 396, by0 + 64, size: 7.5, color: cGray)
	// supply
	text("Pico power", 560, by0 + 10, size: 8, bold: true)
	text("5 V logic rail", 560, by0 + 26, size: 7.5, color: cRed); line(560, by0 + 36, 580, by0 + 36, 1.4, cRed); diode(580, by0 + 36, cRed)
	line(612, by0 + 36, 640, by0 + 36, 1.4, cRed); text("D1 1N5819", 596, by0 + 52, size: 7.5, align: 1); text("→ Pico VSYS (pin 39)", 646, by0 + 39, size: 7.5)
	capacitor(626, by0 + 36); ground(626, by0 + 54); text("100 µF", 640, by0 + 52, size: 7)
	text("VBUS (pin 40): leave unconnected.", 560, by0 + 78, size: 7.5, color: cGray)
	text("3V3(OUT) pin 36 feeds the sensors, the I2C pull-ups and the PCA9685 chips.", 560, by0 + 90, size: 7.5, color: cGray)
	text("GND pins and AGND (pin 33) → star GND.", 560, by0 + 102, size: 7.5, color: cGray)
	endPage()
}

func pageServos() {
	beginPage("Servo channels (25) and tile cables", "Tile t sits at row t ÷ 5, column t mod 5. Each tile has one SG90 servo (scotch yoke) and one 5 × 5 LED module.")
	func rowFor(_ t: Int) -> [String] {
		let board = t < 16 ? 0 : 1, ch = t < 16 ? t : t - 16
		return ["T\(t)", "row \(t / 5), col \(t % 5)", "#\(board) (0x4\(board))", "\(ch)", t <= 12 ? "A (buck 1)" : "B (buck 2)"]
	}
	let widths: [CGFloat] = [34, 82, 84, 56, 100]
	let left = Table(widths: widths, header: ["Tile", "Position", "PCA9685", "Channel", "LED bus"], rows: (0 ... 12).map(rowFor), size: 8)
	let right = Table(widths: widths, header: ["Tile", "Position", "PCA9685", "Channel", "LED bus"], rows: (13 ... 24).map(rowFor), size: 8)
	var nx = 0
	let y1 = drawTable(left, 28, 60, limit: PH - 26, next: &nx)
	let y2 = drawTable(right, 28 + 356 + 24, 60, limit: PH - 26, next: &nx)
	var y = max(y1, y2) + 12
	let notes = [
		"Servo lead (3 wires): signal (orange or yellow) → the channel's PWM pin, V+ (red) → the channel's V+ pin, ground (brown or black) → GND. On the PCA9685 header the three pins are already in that order. Cut off any extra length and keep a service loop: the tile travels 15 mm.",
		"Servo power: each board's V+ terminal and GND get their own heavy pair (20 AWG) from the servo rail (F6, +5V·SRV), with 470 µF across V+ and GND at each board. The board's V+ pins (one per channel) are all on that terminal.",
		"Firmware: 50 Hz, pulse 1.0 to 2.0 ms = ±90°, only ±75° used (stroke 15 mm, about 170 counts, about 0.12 mm per count). At most 6 servos move at once (typical 0.25 A each, 0.65 A stalled); idle servos stay driven (about 10 to 50 mA each) and the yoke also holds the tile with the power off.",
		"LED cable per tile, JST-XH 4-pin: +5 V, GND, DIN, DOUT. DIN of tile 5r comes from the row's 74HCT245 line (B1 to B5, through 330 Ω); each later module's DIN comes from the previous module's DOUT. Every module's +5 V and GND come from its own LED bus, never through the neighbour. The status bar takes B6 and bus B.",
		"LED bus A (buck 1) feeds tiles 0 to 12 (13 modules, 325 LEDs); bus B (buck 2) feeds tiles 13 to 24 and the status bar (12 modules + 25 LEDs, 325 LEDs). The firmware limits each bus to 5 A and each module to about 1 A (a module at full white would take 1.5 A).",
		"Module pad order (5V, DIN, DOUT, GND) and the module thickness are NOT confirmed until the Alibaba modules arrive; check the pads with a multimeter and the first module on a bench supply before wiring all 26.",
	]
	for l in notes { y = paragraph("• " + l, 28, y, width: PW - 56, size: 8.5) }
	endPage()
}

func pageModels() {
	beginPage("Models, checks before power-up, and what is not decided", "Provisional parts are marked. Nothing here has been tested on hardware yet.")
	let rows: [[String]] = [
		["Chargers", "20 V 3.33 A (LED buses A and B, each through its own buck), 16 V 3.75 A (servos and logic, through buck 3). The 12 V 4 A charger is a spare and is not wired", "The builder's own, regulated switch-mode. Read each label. Measure the no-load voltage. Check the plug polarity."],
		["Buck 1, 2, 3", "XL4016-class adjustable step-down module (the 'XH-M404' style board); 4 to buy (3 + 1 spare)", "The XL4016 chip is rated 8 A switching, input 8 to 40 V on the chip datasheet listings; seller listings for the module quote 5 A continuous and an input range from 5 V. Check the revision on YOUR module. Treated here as 5 A continuous with a heatsink."],
		["Microcontroller", "Raspberry Pi Pico W", "GP23, GP24, GP25 and GP29 belong to the radio. Pin map from the Pico W datasheet."],
		["Level shifter", "74HCT245 (DIP-20)", "Six lines used (A1 to A6). Pin numbers from the standard datasheet pinout; check yours."],
		["Servo drivers", "2 × PCA9685 16-channel PWM board (I2C)", "Addresses 0x40 and 0x41 (solder bridge A0 on the second). Boards to buy (none owned yet). Check whether the ones you get carry SDA/SCL pull-ups and an OE pull-down, and which pin is V+."],
		["Servos", "25 × SG90 micro servo (5 provided, 20 to buy)", "1.2 to 1.8 kgf·cm listed, torque margin 25 to 38×. Real outline and horn not measured yet."],
		["LED modules", "26 × premade WS2812B 5 × 5 module (25 LEDs, 5 V), Alibaba", "Pad order and thickness NOT confirmed. 25 used for tiles, 1 spare; the status bar is a separate 25-LED strip or module."],
		["Diode", "1N5819 Schottky", "Charger-to-Pico VSYS."],
		["Fuses", "Resistive PTC (resettable): F1 F2 2 A (20 V side), F3 F4 5 A (LED buses), F5 2 A (16 V side), F6 5 A (servo rail), F7 1 A (logic)", "The number is the hold current."],
		["Sensors", "LDR; 10 kΩ NTC thermistor (β about 3950)", "Both listed sensors in the brief."],
	]
	let t = Table(widths: [120, 290, 372], header: ["Item", "Model", "Notes and what is verified"], rows: rows, size: 8)
	var nx = 0
	var y = drawTable(t, 28, 60, limit: PH - 26, next: &nx) + 14
	y = paragraph("Before first power-up", 28, y, width: 380, size: 10, bold: true) + 2
	let checks = [
		"With NO chips inserted and nothing connected to the chargers: check no short between 3V3, 5 V and GND on the breadboard (multimeter beep).",
		"Both chargers: measure the open-circuit output. Set buck 1, 2 and 3 to 5.0 V with a multimeter, then connect them.",
		"Connect only the 5 V logic rail to the breadboard first. Insert the Pico last. Check 3V3 and 5 V at the rails.",
		"Add the PCA9685 boards with OE still high (pull-up in place), then ONE servo with its arm off: check the 1 to 2 ms pulse range and the 15 mm stroke on the bench, then the rest. Add the LED modules last, one row at a time at low brightness, measuring the current on each bus.",
		"Keep a fuse in every branch. Do not connect LED or servo current to the breadboard rails.",
	]
	for l in checks { y = paragraph("• " + l, 36, y, width: 750, size: 8.5) }
	y += 6
	y = paragraph("Not decided yet", 28, y, width: 380, size: 10, bold: true) + 2
	for l in ["The module pad layout and thickness (not received yet), the status bar part (Alibaba price not found), the new stand (a folding V, see circuit.md). The power limiter is written (BoardKit PowerLimiter: one scale factor for every LED so each 5 A bus stays in budget) but the firmware that calls it is not."] {
		y = paragraph("• " + l, 36, y, width: 750, size: 8.5)
	}
	endPage()
}
