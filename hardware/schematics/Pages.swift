// Logic schematic, shift-register-to-driver table, models and checks.
import CoreGraphics
import Foundation

func pageLogic() {
	beginPage("Logic schematic", "Pico W, 74HCT245 level shifter, shift-register chain, sensors, status LED. Pin numbers are Pico physical pins.")
	// Pico block
	rect(36, 62, 150, 312, fill: rgb(0.88, 0.96, 0.9), stroke: cBlack, lw: 1.2, r: 4)
	text("Pico W", 111, 78, size: 11, bold: true, align: 1)
	text("(3.3 V logic)", 111, 90, size: 8, color: cGray, align: 1)
	let ledPins: [(String, Int, String)] = [("GP2", 4, "LED row 0"), ("GP3", 5, "LED row 1"), ("GP4", 6, "LED row 2"), ("GP5", 7, "LED row 3"), ("GP6", 9, "LED bar")]
	let ys: [CGFloat] = [108, 130, 152, 174, 196]
	// 74HCT245
	rect(290, 94, 96, 114, fill: cLight, stroke: cBlack, lw: 1.2, r: 3)
	text("74HCT245", 338, 108, size: 9, bold: true, align: 1)
	text("5 V · DIR high", 338, 200, size: 7.5, color: cGray, align: 1)
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
	_ = paragraph("Each line: 330 Ω in series, then a 10 kΩ pull-down to GND at the junction. The pull-down keeps the line quiet while one supply is off.", 646, 112, width: 170, size: 7.5, color: cGray)
	// 245 power
	text("VCC → 5 V logic + 100 nF   ·   DIR → 5 V   ·   OE → GND   ·   A6–A8 → GND", 290, 224, size: 7.5, color: cRed)

	// 595 chain
	text("Shift-register chain: 8 × 74HC595, powered from 3V3 (Pico pin 36). SRCLR → 3V3, 100 nF each.", 232, 246, size: 9, bold: true)
	let cy0: CGFloat = 288
	// Pico side pins and the control bus
	let pinY: [(String, CGFloat, CGFloat)] = [("GP10 pin 14  CLK", 300, 262), ("GP11 pin 15  SER", 316, 0), ("GP12 pin 16  LATCH", 332, 270), ("GP13 pin 17  OE", 348, 278)]
	let vx: [CGFloat] = [196, 0, 204, 212]
	for (i, c) in pinY.enumerated() {
		text(c.0, 182, c.1 + 3, size: 8, align: 2)
		if c.2 == 0 { arrow(186, c.1, 232, c.1, cPurple, w: 1.2) }
		else {
			poly([(186, c.1), (vx[i], c.1), (vx[i], c.2), (232 + 7 * 74 + 62, c.2)], 1.2, cPurple)
			dot(vx[i], c.1, 0.1, fill: nil)
		}
	}
	text("CLK", 806, 265, size: 7.5, bold: true, color: cPurple); text("LATCH", 806, 273, size: 7.5, bold: true, color: cPurple); text("OE", 806, 281, size: 7.5, bold: true, color: cPurple)
	for n in 0 ..< 8 {
		let x = 232 + CGFloat(n) * 74
		rect(x, cy0, 62, 46, fill: cLight, stroke: cBlack, lw: 1.1, r: 3)
		for (i, yy) in [262.0, 270.0, 278.0].enumerated() { let tx = x + 14 + CGFloat(i) * 17; line(tx, yy, tx, cy0, 1, cPurple); dot(tx, yy, 1.8, fill: cPurple) }
		text("595 #\(n)", x + 31, cy0 + 20, size: 9, bold: true, align: 1)
		text("tiles \(2 * n), \(2 * n + 1)", x + 31, cy0 + 32, size: 7.5, align: 1)
		text("BB\(n < 2 ? 1 : 2)", x + 31, cy0 + 43, size: 7, color: cGray, align: 1)
		if n < 7 { arrow(x + 62, cy0 + 28, x + 74, cy0 + 28, cPurple, w: 1.3); text("QH'→SER", x + 68, cy0 + 24, size: 5.5, color: cPurple, align: 1) }
		arrow(x + 31, cy0 + 46, x + 31, cy0 + 62, cBlack, w: 1)
		text("→ drivers", x + 31, cy0 + 74, size: 7.5, color: cGray, align: 1)
	}
	text("CLK, LATCH and OE run to all eight chips in parallel (the three purple buses above the chips). SER goes only to chip #0; each chip's QH' feeds the next SER.", 232, 378, size: 8, color: cPurple)

	// Sensors and power, bottom
	let by0: CGFloat = 410
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
	arrow(380, by0 + 40, 410, by0 + 40, cBlue); text("GP15 pin 20", 346, by0 + 43, size: 7.5, color: cBlue)
	resistor(410, by0 + 40, 36, cBlack); text("4.7 kΩ", 428, by0 + 33, size: 7, align: 1)
	line(446, by0 + 40, 460, by0 + 40, 1.2); diode(460, by0 + 40); line(492, by0 + 40, 500, by0 + 40, 1.2); ground(500, by0 + 40)
	text("red LED, ~0.3 mA (dim on purpose)", 396, by0 + 64, size: 7.5, color: cGray)
	// supply
	text("Pico power", 560, by0 + 10, size: 8, bold: true)
	text("5 V logic rail", 560, by0 + 26, size: 7.5, color: cRed); line(560, by0 + 36, 580, by0 + 36, 1.4, cRed); diode(580, by0 + 36, cRed)
	line(612, by0 + 36, 640, by0 + 36, 1.4, cRed); text("D1 1N5819", 596, by0 + 52, size: 7.5, align: 1); text("→ Pico VSYS (pin 39)", 646, by0 + 39, size: 7.5)
	capacitor(626, by0 + 36); ground(626, by0 + 54); text("100 µF", 640, by0 + 52, size: 7)
	text("VBUS (pin 40): leave unconnected.", 560, by0 + 78, size: 7.5, color: cGray)
	text("3V3(OUT) pin 36 feeds the 595s and the sensors.", 560, by0 + 90, size: 7.5, color: cGray)
	text("GND pins and AGND (pin 33) → star GND.", 560, by0 + 102, size: 7.5, color: cGray)
	endPage()
}

func pageDrivers() {
	beginPage("Shift registers to motor drivers (64 wires) and tile cables", "Tile t sits at row t ÷ 4, column t mod 4. Each tile has one stepper and one driver. A shift register drives two tiles.")
	var rows: [[String]] = []
	for t in 0 ..< 16 {
		let n = t / 2, bd = chipBoard(n), c0 = chipC0(n)
		let even = t % 2 == 0
		let outs: [(String, Int, Bool, Int)] = even ? [("QA", 15, true, c0 + 1), ("QB", 1, false, c0), ("QC", 2, false, c0 + 1), ("QD", 3, false, c0 + 2)]
			: [("QE", 4, false, c0 + 3), ("QF", 5, false, c0 + 4), ("QG", 6, false, c0 + 5), ("QH", 7, false, c0 + 6)]
		let from = outs.map { "\($0.0) (pin \($0.1), \($0.2 ? "upper" : "lower") col \($0.3))" }.joined(separator: ", ")
		rows.append(["T\(t)", "row \(t / 4), col \(t % 4)", "BB\(bd) 595 #\(n)", from, "IN1, IN2, IN3, IN4"])
	}
	let t = Table(widths: [30, 70, 90, 450, 112], header: ["Tile", "Position", "Chip", "Outputs, in order (breadboard column)", "Driver inputs"], rows: rows, size: 7.5)
	var nx = 0
	var y = drawTable(t, 28, 60, limit: PH - 26, next: &nx) + 12
	let notes = [
		"Each driver: IN1 and IN2 drive coil A (OUT1, OUT2), IN3 and IN4 drive coil B (OUT3, OUT4). On an MX1508 the four inputs are INA1, INA2, INB1, INB2.",
		"The firmware shifts 64 bits per update, tile 15 first, then latches. Outputs stay off until OE goes low.",
		"MX1508 modules (decided driver; the school does not supply L298N): VCC = motor rail (5 V), GND to the star point, IN1 to IN4 from the shift register outputs. No jumpers and almost no voltage drop.",
		"Drivers, their supply and the motor wires are off the breadboards: motor rail (F9, 5 V) to every driver's supply pins, with 100 µF + 100 nF per row of four drivers.",
		"Motor cable, 4 wires: find the two coils with a multimeter (about 15 to 40 Ω between each pair) and wire one coil to OUT1/OUT2, the other to OUT3/OUT4. Swapping a coil's two wires only reverses the motor.",
		"LED cable per tile: +12 V, GND, DIN, DOUT (WS2815). The WS2815 backup-data pins, and so the connector size, are not decided until the LED part is chosen. Each row's DIN comes from the LED output block on breadboard 1 (P3 to P7).",
	]
	for l in notes { y = paragraph("• " + l, 28, y, width: PW - 56, size: 8.5) }
	endPage()
}

func pageModels() {
	beginPage("Models, checks before power-up, and what is not decided", "Provisional parts are marked. Nothing here has been tested on hardware yet.")
	let rows: [[String]] = [
		["Chargers A, B, C", "12 V 4 A, 16 V 3.75 A, 20 V 3.33 A: the builder's own, regulated switch-mode", "Read each label. Measure the no-load voltage. Check the plug polarity."],
		["Buck 1, buck 2", "XL4016-class adjustable step-down module (the 'XH-M404' style board), two of them", "The XL4016 chip is rated 8 A switching, input 8 to 40 V on the chip datasheet listings; seller listings for the module quote 5 A continuous and an input range from 5 V. Check the revision on YOUR module. Treated here as 5 A continuous with a heatsink."],
		["Microcontroller", "Raspberry Pi Pico W", "GP23, GP24, GP25 and GP29 belong to the radio. Pin map from the Pico W datasheet."],
		["Level shifter", "74HCT245 (DIP-20)", "Pin numbers from the standard datasheet pinout; check yours."],
		["Shift registers", "8 × 74HC595 (DIP-16); 74HCT595 also works", "Powered from 3V3, so plain HC is fine. QA is pin 15, QB to QH are pins 1 to 7."],
		["Diode", "1N5819 Schottky", "Charger-to-Pico VSYS."],
		["Fuses", "Resistive PTC (resettable): F1 4 A, F2 F3 F5 F6 3 A, F4 3 A, F7 1 A, F8 2 A, F9 5 A, F10 1 A", "The number is the hold current."],
		["Sensors", "LDR; 10 kΩ NTC thermistor (β about 3950)", "Both listed sensors in the brief."],
		["Drivers (provisional)", "MX1508 (decided; DRV8833 is the fallback)", "One per motor, 18 bought. Check the module you receive."],
		["Motors (provisional)", "8 mm 2-phase stepper, bare lead-screw version", "Coil resistance and real current not measured yet."],
		["LEDs (provisional)", "12 V WS2815, 5050 SMD", "Small-quantity supply and the data-input level are NOT verified."],
	]
	let t = Table(widths: [120, 290, 372], header: ["Item", "Model", "Notes and what is verified"], rows: rows, size: 8)
	var nx = 0
	var y = drawTable(t, 28, 60, limit: PH - 26, next: &nx) + 14
	y = paragraph("Before first power-up", 28, y, width: 380, size: 10, bold: true) + 2
	let checks = [
		"With NO chips inserted and nothing connected to the chargers: check no short between 3V3, 5 V and GND on both breadboards (multimeter beep).",
		"Charger A, B, C: measure the open-circuit output. Set buck 1 to 12.0 V and buck 2 to 5.0 V with a multimeter, then connect them.",
		"Connect only the 5 V logic rail to breadboard 1 first. Insert the Pico last. Check 3V3 and 5 V at the rails.",
		"Add the shift registers with OE still high (pull-up in place), then the drivers, one motor first. Add LEDs last, one row at a time, at low brightness.",
		"Keep a fuse in every branch. Do not connect LED or motor current to the breadboard rails.",
	]
	for l in checks { y = paragraph("• " + l, 36, y, width: 750, size: 8.5) }
	y += 6
	y = paragraph("Not decided yet", 28, y, width: 380, size: 10, bold: true) + 2
	for l in ["The LED part, and so the tile connectors and the data-input level. The motor model. The mechanical drive system. The firmware power limiter (per group) is not built."] {
		y = paragraph("• " + l, 36, y, width: 750, size: 8.5)
	}
	endPage()
}
