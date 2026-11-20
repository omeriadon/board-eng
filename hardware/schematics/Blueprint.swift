// One connected drawing of the whole project (not the A4 pages tiled): power, Pico, level shifter,
// shift-register chain, sensors, 16 drivers, 16 motors, 16 LED tile segments and the status bar.
// Signals and chains are drawn as lines; power rails are drawn in the power section and shown by a coloured
// label (flag) at each load; the 4-wire control bus from a shift register to a driver is a numbered circle (T0 to T15).
import CoreGraphics
import Foundation

let BW: CGFloat = 3000, BH: CGFloat = 1600
let cMag = rgb(0.78, 0.1, 0.5), cBrown = rgb(0.6, 0.4, 0.1), cPico = rgb(0.88, 0.96, 0.9)

/// A net label: short stub from (x, y) and a white box with the net name. dir: 0 up, 1 right, 2 left, 3 down.
func flag(_ x: CGFloat, _ y: CGFloat, _ label: String, _ c: CGColor, dir: Int) {
	let w = measure(label, size: 7.5, bold: true) + 10, h: CGFloat = 13
	switch dir {
	case 0:
		line(x, y, x, y - 6, 1.2, c); rect(x - w / 2, y - 6 - h, w, h, fill: cWhite, stroke: c, lw: 1, r: 2); text(label, x, y - 6 - 3.5, size: 7.5, bold: true, color: c, align: 1)
	case 1:
		line(x, y, x + 6, y, 1.2, c); rect(x + 6, y - h / 2, w, h, fill: cWhite, stroke: c, lw: 1, r: 2); text(label, x + 6 + w / 2, y + 3, size: 7.5, bold: true, color: c, align: 1)
	case 2:
		line(x, y, x - 6, y, 1.2, c); rect(x - 6 - w, y - h / 2, w, h, fill: cWhite, stroke: c, lw: 1, r: 2); text(label, x - 6 - w / 2, y + 3, size: 7.5, bold: true, color: c, align: 1)
	default:
		line(x, y, x, y + 6, 1.2, c); rect(x - w / 2, y + 6, w, h, fill: cWhite, stroke: c, lw: 1, r: 2); text(label, x, y + 6 + 10, size: 7.5, bold: true, color: c, align: 1)
	}
}

/// A numbered or lettered circle: one end of a bus or a cross-board wire; the same label is at the other end.
func tag(_ x: CGFloat, _ y: CGFloat, _ label: String, _ c: CGColor, fill: CGColor = cWhite, r: CGFloat = 9, size: CGFloat = 8) {
	dot(x, y, r, fill: fill, stroke: c, lw: 1.4)
	text(label, x, y + size * 0.36, size: size, bold: true, color: cBlack, align: 1)
}

func openBlueprint(_ path: String) {
	var box = CGRect(x: 0, y: 0, width: BW, height: BH)
	ctx = CGContext(URL(fileURLWithPath: path) as CFURL, mediaBox: &box,
	                [kCGPDFContextTitle as String: "Dither Board: system blueprint", kCGPDFContextAuthor as String: "omeriadon/board-eng"] as CFDictionary)!
	ctx.beginPDFPage(nil)
	ctx.translateBy(x: 0, y: BH)
	ctx.scaleBy(x: 1, y: -1)
	ctx.setFillColor(cWhite)
	ctx.fill(CGRect(x: 0, y: 0, width: BW, height: BH))
}

func closeBlueprint() {
	ctx.endPDFPage()
	ctx.closePDF()
}

// Layout constants.
let bandH: CGFloat = 300
func bandTop(_ r: Int) -> CGFloat { 190 + bandH * CGFloat(r) }
func tileX(_ c: Int) -> CGFloat { 1520 + 350 * CGFloat(c) }
let chipX: CGFloat = 1280, chipW: CGFloat = 140, chipH: CGFloat = 120
func chipY(_ n: Int) -> CGFloat { bandTop(n / 2) + (n % 2 == 1 ? 165 : 30) }

func drawBlueprint(_ path: String) {
	openBlueprint(path)
	text("Dither Board: system blueprint", 40, 56, size: 40, bold: true)
	text("4 × 4 tiles · 6 × 6 LEDs per tile + 24-LED status bar = 600 LEDs · 16 stepper motors · Raspberry Pi Pico W · three chargers, two buck modules, two breadboards", 40, 86, size: 15, color: cGray)
	text("Read left to right: power, then the Pico, then the shift registers, then the 16 tiles. Rev 1 · 2026-11-20 · prototype, nothing tested on hardware.", 40, 108, size: 12, color: cGray)
	line(40, 120, BW - 40, 120, 1.2, cGray)

	bpPower()
	bpPico()
	bpChain()
	bpTiles()
	bpSensors()
	bpNotes()
	closeBlueprint()
}

// MARK: Power

func bpPower() {
	text("POWER", 40, 142, size: 13, bold: true, color: cGray)
	box(40, 150, 150, 34, "Power board, one switch", ["all three plugs"], fill: rgb(1, 0.95, 0.9))
	func chain(top: CGFloat, height: CGFloat, brick: String, brickLines: [String], fin: String, conv: String, convLines: [String], busTitle: String, busLines: [String], busColor: CGColor, outs: [(String, String, String)]) {
		let mid = top + height / 2
		box(40, mid - 26, 150, 52, brick, brickLines, fill: rgb(0.88, 0.93, 1))
		fuse(194, mid, fin, len: 52)
		box(252, mid - 26, 118, 52, conv, convLines, fill: conv.hasPrefix("BUCK") ? rgb(0.9, 1, 0.9) : cLight)
		line(370, mid, 396, mid, 1.6, busColor)
		box(396, mid - 26, 100, 52, busTitle, busLines, fill: rgb(1, 0.92, 0.95))
		let step = height / CGFloat(outs.count)
		for (i, o) in outs.enumerated() {
			let y = top + step * (CGFloat(i) + 0.5)
			poly([(496, mid), (508, mid), (508, y), (516, y)], 1.6, busColor)
			if y != mid { dot(508, mid, 2, fill: busColor) }
			fuse(516, y, o.0, len: 50)
			if o.1 == "+5V·LOGIC" {
				line(566, y, 650, y, 1.6, cRed)
				text(o.1, 574, y + 14, size: 7.5, bold: true, color: cRed)
			} else {
				flag(566, y, o.1, o.2.hasPrefix("+5V") ? cRed : cMag, dir: 1)
			}
		}
	}
	chain(top: 210, height: 80, brick: "Charger A: 12 V 4 A", brickLines: ["48 W · regulated"], fin: "F1 4 A", conv: "no converter", convLines: ["12 V straight to LEDs"], busTitle: "12 V BUS A", busLines: ["1000 µF 25 V"], busColor: cMag,
	      outs: [("F2 3 A", "+12V·R0", "+12V"), ("F3 3 A", "+12V·R1", "+12V")])
	chain(top: 340, height: 120, brick: "Charger C: 20 V 3.33 A", brickLines: ["66 W · regulated"], fin: "F4 3 A", conv: "BUCK 1 → 12.0 V", convLines: ["XL4016-class, heatsink", "worst case 4.1 of ~5 A"], busTitle: "12 V BUS C", busLines: ["1000 µF 25 V"], busColor: cMag,
	      outs: [("F5 3 A", "+12V·R2", "+12V"), ("F6 3 A", "+12V·R3", "+12V"), ("F7 1 A", "+12V·BAR", "+12V")])
	chain(top: 510, height: 100, brick: "Charger B: 16 V 3.75 A", brickLines: ["60 W · regulated"], fin: "F8 2 A", conv: "BUCK 2 → 5.0 V", convLines: ["XL4016-class, heatsink", "worst case 4.4 of ~5 A"], busTitle: "5 V BUS", busLines: ["470 µF 16 V"], busColor: cRed,
	      outs: [("F9 5 A", "+5V·MOT", "+5V"), ("F10 1 A", "+5V·LOGIC", "+5V")])
	// Mains
	line(28, 167, 40, 167, 1, cBlack, dash: [3, 2]); line(28, 167, 28, 560, 1, cBlack, dash: [3, 2])
	for y: CGFloat in [250, 400, 560] { line(28, y, 40, y, 1, cBlack, dash: [3, 2]) }
	// Star ground
	rect(40, 636, 610, 22, fill: rgb(0.93, 0.93, 0.93), stroke: cBlack, lw: 1.1, r: 4)
	text("STAR GND: the negatives of A, B, C, both bucks, every bus and both breadboards join at ONE point. Never join positives.", 345, 651, size: 8, bold: true, align: 1)
	text("+5V·LOGIC runs up to the Pico's VSYS pin through D1 (1N5819), and to the 74HCT245.", 40, 622, size: 8, color: cGray)
}

// MARK: Pico and level shifter

func bpPico() {
	text("CONTROL", 700, 142, size: 13, bold: true, color: cGray)
	// Breadboard 1 outline
	rect(690, 150, 530, 560, fill: nil, stroke: cTeal, lw: 1.4, r: 8, dash: [8, 4])
	text("BREADBOARD 1: Pico, 74HCT245, LED output block, D1 and C1", 700, 722, size: 8.5, bold: true, color: cTeal)
	rect(700, 160, 140, 540, fill: cPico, stroke: cBlack, lw: 1.4, r: 5)
	text("Pico W", 770, 178, size: 14, bold: true, align: 1)
	text("3.3 V logic", 770, 190, size: 8, color: cGray, align: 1)
	// Right pins
	let rp: [(String, Int, CGFloat, String)] = [("GP2", 4, 200, "LED row 0"), ("GP3", 5, 240, "LED row 1"), ("GP4", 6, 280, "LED row 2"), ("GP5", 7, 320, "LED row 3"), ("GP6", 9, 360, "LED bar"),
	                                            ("GP10", 14, 440, "595 CLK"), ("GP11", 15, 470, "595 SER"), ("GP12", 16, 500, "595 LATCH"), ("GP13", 17, 530, "595 OE"),
	                                            ("GP15", 20, 580, "status LED"), ("GP26", 31, 610, "LDR (ADC0)"), ("GP27", 32, 640, "NTC (ADC1)"), ("GP28", 34, 670, "5 V mon (opt)")]
	for p in rp {
		text("\(p.0) · pin \(p.1)", 836, p.2 + 3, size: 8, bold: true, align: 2)
		if p.2 > 400 { text(p.3, 706, p.2 + 3, size: 7, color: cGray) }
	}
	// Left pins
	line(700, 200, 684, 200, 1.4, cOrange); flag(684, 200, "3V3 → 595s, sensors", cOrange, dir: 2); text("3V3(OUT) · pin 36", 706, 203, size: 8, bold: true)
	text("VSYS · pin 39", 706, 253, size: 8, bold: true)
	text("VBUS · pin 40: leave open", 706, 303, size: 7.5, color: cGray)
	text("GND pins → star GND", 706, 693, size: 7.5, color: cGray)
	line(700, 690, 686, 690, 1.4, cBlack); ground(686, 690)
	// VSYS from the logic rail: D1 + 100 uF
	poly([(650, 585), (650, 250)], 1.6, cRed)
	poly([(650, 250), (660, 250)], 1.6, cRed)
	diode(660, 250, cRed)
	text("D1", 676, 240, size: 8, bold: true, color: cRed)
	line(692, 250, 700, 250, 1.6, cRed)
	dot(696, 250, 2, fill: cRed)
	capacitor(696, 250); ground(696, 268)
	text("100 µF", 704, 268, size: 7, color: cGray)
	// 74HCT245
	rect(960, 180, 90, 200, fill: cLight, stroke: cBlack, lw: 1.2, r: 3)
	text("74HCT245", 1005, 194, size: 9, bold: true, align: 1)
	flag(1005, 180, "+5V·LOGIC", cRed, dir: 0)
	text("DIR → +5V · OE → GND · A6–A8 → GND · 100 nF", 1005, 396, size: 7, color: cGray, align: 1)
	let lanes: [CGFloat] = [bandTop(0) + 12, bandTop(1) + 12, bandTop(2) + 12, bandTop(3) + 12, 1420]
	for i in 0 ..< 5 {
		let y = 200 + 40 * CGFloat(i)
		arrow(840, y, 960, y, cGreen, w: 1.4)
		text("A\(i + 1)", 964, y + 3, size: 7.5); text("B\(i + 1)", 1046, y + 3, size: 7.5, align: 2)
		line(1050, y, 1062, y, 1.4, cGreen)
		resistor(1062, y, 36, cBlack); text("330 Ω", 1080, y - 8, size: 6.5, align: 1)
		line(1098, y, 1108, y, 1.4, cGreen)
		dot(1108, y, 2, fill: cGreen)
		resistor(1108, y, 22, cBlack, vertical: true); ground(1108, y + 22); text("10 kΩ", 1114, y + 16, size: 6.5, color: cGray)
		let xi = 1140 + 8 * CGFloat(4 - i)
		poly([(1108, y), (xi, y), (xi, lanes[i]), (tileX(0), lanes[i])], 1.4, cGreen)
	}
	// Chain control from the Pico
	poly([(840, 440), (1210, 440)], 1.4, cPurple); dot(1210, 440, 2.2, fill: cPurple)
	poly([(840, 500), (1226, 500)], 1.4, cBlue); dot(1226, 500, 2.2, fill: cBlue)
	poly([(840, 530), (1242, 530)], 1.4, cBrown); dot(1242, 530, 2.2, fill: cBrown)
	poly([(840, 470), (1190, 470), (1190, chipY(0) + 12), (chipX, chipY(0) + 12)], 1.4, cTeal)
	// OE pull-up
	dot(930, 530, 2, fill: cBrown)
	resistor(930, 530, 24, cBlack, vertical: true)
	flag(930, 554, "3V3", cOrange, dir: 3)
	text("R11 10 kΩ pull-up", 938, 546, size: 6.5, color: cGray)
	// Sensor lines to BB2 (circles h, i, j are the cross-board wires)
	poly([(840, 640), (870, 640), (870, 770)], 1.4, cBlue)
	poly([(840, 610), (975, 610), (975, 770)], 1.4, cBlue)
	poly([(840, 580), (1070, 580), (1070, 770)], 1.4, cBlue)
	tag(870, 700, "i", cBlue, r: 7, size: 7.5); tag(975, 700, "h", cBlue, r: 7, size: 7.5); tag(1070, 700, "j", cBlue, r: 7, size: 7.5)
}

// MARK: Shift-register chain

func bpChain() {
	text("SHIFT REGISTERS", 1210, 142, size: 13, bold: true, color: cGray)
	let lastTap = chipY(7)
	// Control buses
	line(1210, chipY(0) + 32, 1210, lastTap + 32, 1.4, cPurple)
	line(1226, chipY(0) + 52, 1226, lastTap + 52, 1.4, cBlue)
	line(1242, chipY(0) + 72, 1242, lastTap + 72, 1.4, cBrown)
	text("CLK", 1210, chipY(0) + 24, size: 6.5, bold: true, color: cPurple, align: 1)
	text("LATCH", 1228, chipY(0) + 44, size: 6.5, bold: true, color: cBlue, align: 1)
	text("OE", 1242, chipY(0) + 64, size: 6.5, bold: true, color: cBrown, align: 1)
	// Breadboard outlines for the chips
	for r in 0 ..< 4 {
		let y = bandTop(r) + 22
		let col = r == 0 ? cTeal : cPurple
		rect(chipX - 14, y, chipW + 80, 290, fill: nil, stroke: col, lw: 1.3, r: 8, dash: [8, 4])
		text(r == 0 ? "BREADBOARD 1" : "BREADBOARD 2", chipX - 8, y + 282, size: 7.5, bold: true, color: col)
	}
	for n in 0 ..< 8 {
		let y = chipY(n)
		rect(chipX, y, chipW, chipH, fill: cLight, stroke: cBlack, lw: 1.2, r: 3)
		text("74HC595 #\(n)", chipX + chipW / 2, y + 46, size: 9, bold: true, align: 1)
		text("tiles \(2 * n), \(2 * n + 1)", chipX + chipW / 2, y + 58, size: 7.5, align: 1)
		text("VCC · SRCLR → 3V3", chipX + chipW / 2, y + 90, size: 6.5, color: cOrange, align: 1)
		text("GND · 100 nF", chipX + chipW / 2, y + 100, size: 6.5, color: cGray, align: 1)
		// control pins
		text("SER", chipX + 4, y + 15, size: 6.5); text("SRCLK", chipX + 4, y + 35, size: 6.5); text("RCLK", chipX + 4, y + 55, size: 6.5); text("OE", chipX + 4, y + 75, size: 6.5)
		line(1210, y + 32, chipX, y + 32, 1.4, cPurple); dot(1210, y + 32, 2, fill: cPurple)
		line(1226, y + 52, chipX, y + 52, 1.4, cBlue); dot(1226, y + 52, 2, fill: cBlue)
		line(1242, y + 72, chipX, y + 72, 1.4, cBrown); dot(1242, y + 72, 2, fill: cBrown)
		// outputs
		let names = ["QA", "QB", "QC", "QD", "QE", "QF", "QG", "QH"]
		for i in 0 ..< 8 {
			let oy = y + 12 + 13 * CGFloat(i)
			text(names[i], chipX + chipW - 4, oy + 2.5, size: 6.5, align: 2)
			line(chipX + chipW, oy, chipX + chipW + 8, oy, 1, cBlack)
		}
		for g in 0 ..< 2 {
			let y0 = y + 12 + 13 * CGFloat(4 * g), y1 = y0 + 39
			line(chipX + chipW + 8, y0, chipX + chipW + 8, y1, 1.2, cBlack)
			line(chipX + chipW + 8, (y0 + y1) / 2, chipX + chipW + 18, (y0 + y1) / 2, 1.2, cBlack)
			tag(chipX + chipW + 29, (y0 + y1) / 2, "T\(2 * n + g)", cBlack, fill: cYellow, r: 11, size: 7.5)
		}
		// chain: QH' to the next SER
		if n < 7 {
			let bx = chipX + chipW - 20, by = y + chipH
			let next = chipY(n + 1) + 12
			poly([(bx, by), (bx, by + 7), (1260, by + 7), (1260, next), (chipX, next)], 1.4, cTeal)
			text("QH'", bx + 3, by - 3, size: 6.5, color: cTeal)
		}
	}
	// Cross-board wires between BB1 and BB2 (same letters as the wire list)
	let yb = bandTop(1) - 3
	tag(1210, yb, "e", cPurple, r: 6.5, size: 7); tag(1226, yb, "f", cBlue, r: 6.5, size: 7); tag(1242, yb, "g", cBrown, r: 6.5, size: 7); tag(1260, yb, "d", cTeal, r: 6.5, size: 7)
}

// MARK: Tiles

func bpTiles() {
	text("TILES: row r = tiles 4r to 4r+3; each tile has one LED block, one motor driver and one stepper", 1520, 142, size: 13, bold: true, color: cGray)
	for r in 0 ..< 4 {
		let b = bandTop(r)
		let flagName = "+12V·R\(r)"
		for c in 0 ..< 4 {
			let t = 4 * r + c
			let x = tileX(c)
			// LED block: DIN at the left, DOUT at the right (lane y = b + 12)
			rect(x, b - 6, 250, 36, fill: rgb(0.96, 1, 0.96), stroke: cGreen, lw: 1.2, r: 4)
			text("Tile \(t) LED block · 36 LEDs (6 × 6)", x + 125, b + 9, size: 8.5, bold: true, align: 1)
			text("DIN →  row \(r), column \(c)  → DOUT", x + 125, b + 22, size: 7, color: cGray, align: 1)
			flag(x + 125, b - 6, flagName, cMag, dir: 0)
			ground(x + 125, b + 30)
			if c < 3 { line(x + 250, b + 12, tileX(c + 1), b + 12, 1.4, cGreen) } else { text("end of chain", x + 256, b + 15, size: 7, color: cGray) }
			// Driver
			let dy = b + 90
			rect(x, dy, 170, 96, fill: rgb(0.93, 0.95, 1), stroke: cBlack, lw: 1.2, r: 4)
			text("Driver \(t)", x + 85, dy + 14, size: 9, bold: true, align: 1)
			text("L298N / MX1508", x + 85, dy + 25, size: 7, color: cGray, align: 1)
			flag(x + 85, dy, "+5V·MOT", cRed, dir: 0)
			ground(x + 85, dy + 96)
			let pinY = (0 ..< 4).map { dy + 40 + 14 * CGFloat($0) }
			for k in 0 ..< 4 {
				text("IN\(k + 1)", x + 4, pinY[k] + 2.5, size: 6.5)
				text("OUT\(k + 1)", x + 166, pinY[k] + 2.5, size: 6.5, align: 2)
				line(x - 12, pinY[k], x, pinY[k], 1.2, cBlack)
				line(x + 170, pinY[k], x + 190, pinY[k], 1.2, cBlack)
			}
			line(x - 12, pinY[0], x - 12, pinY[3], 1.2, cBlack)
			line(x - 12, (pinY[0] + pinY[3]) / 2, x - 18, (pinY[0] + pinY[3]) / 2, 1.2, cBlack)
			tag(x - 29, (pinY[0] + pinY[3]) / 2, "T\(t)", cBlack, fill: cYellow, r: 11, size: 7.5)
			// Motor
			let mc = CGPoint(x: x + 250, y: (pinY[0] + pinY[3]) / 2)
			dot(mc.x, mc.y, 40, fill: rgb(1, 0.97, 0.9), stroke: cBlack, lw: 1.2)
			text("M\(t)", mc.x, mc.y - 4, size: 10, bold: true, align: 1)
			text("stepper", mc.x, mc.y + 8, size: 7, color: cGray, align: 1)
			for k in 0 ..< 4 {
				let dyk = pinY[k] - mc.y
				let xe = mc.x - sqrt(40 * 40 - dyk * dyk)
				line(x + 190, pinY[k], xe, pinY[k], 1.2, cBlack)
			}
		}
		text("Row \(r): LED data from 74HCT245 output B\(r + 1) (through 330 Ω) · tiles \(4 * r) to \(4 * r + 3) driven by 595 #\(2 * r) and #\(2 * r + 1) · 100 µF + 100 nF across the row's drivers' +5V·MOT", tileX(0), b + 240, size: 8, color: cGray)
	}
	// Status bar
	let by: CGFloat = 1420
	rect(tileX(0), by - 20, 560, 40, fill: rgb(0.96, 1, 0.96), stroke: cGreen, lw: 1.2, r: 4)
	text("Status bar: 24 LEDs under the grid (timer, song progress)", tileX(0) + 280, by - 4, size: 9, bold: true, align: 1)
	text("DIN ← 74HCT245 B5 through 330 Ω · fixed, does not move · 100 nF per LED", tileX(0) + 280, by + 9, size: 7, color: cGray, align: 1)
	flag(tileX(0) + 280, by - 20, "+12V·BAR", cMag, dir: 0)
	ground(tileX(0) + 280, by + 20)
}

// MARK: Sensors (breadboard 2)

func bpSensors() {
	rect(850, 735, 290, 170, fill: nil, stroke: cPurple, lw: 1.3, r: 8, dash: [8, 4])
	text("BREADBOARD 2: sensors and status LED", 858, 898, size: 8.5, bold: true, color: cPurple)
	let y0: CGFloat = 770
	func divider(xl: CGFloat, xd: CGFloat, title: String, top: String, bottom: String) {
		text(title, xd, y0 - 8, size: 8, bold: true, align: 1)
		flag(xd, y0 + 13, "3V3", cOrange, dir: 0)
		line(xd, y0 + 13, xd, y0 + 20, 1.2, cBlack)
		resistor(xd, y0 + 20, 36, cBlack, vertical: true)
		text(top, xd - 8, y0 + 33, size: 7, align: 2)
		let ny = y0 + 56
		dot(xd, ny, 2, fill: cBlack)
		line(xl, ny, xd, ny, 1.4, cBlue)
		resistor(xd, ny, 36, cBlack, vertical: true)
		text(bottom, xd - 8, ny + 22, size: 7, align: 2)
		ground(xd, ny + 36)
		line(xd, ny, xd + 22, ny, 1.2); capacitor(xd + 22, ny); ground(xd + 22, ny + 18)
		// make the vertical from the Pico meet the node line
		line(xl, y0, xl, ny, 1.4, cBlue)
	}
	divider(xl: 870, xd: 915, title: "NTC (temperature)", top: "10 kΩ", bottom: "NTC 10 kΩ")
	divider(xl: 975, xd: 1020, title: "LDR (light)", top: "LDR", bottom: "10 kΩ")
	// Status LED
	text("Status LED", 1070, y0 - 8, size: 8, bold: true)
	let ly = y0 + 28
	line(1070, y0, 1070, ly, 1.4, cBlue)
	resistor(1070, ly, 24, cBlack); text("4.7 kΩ", 1082, ly - 7, size: 7, align: 1)
	diode(1094, ly); ground(1126, ly)
	text("red LED, ~0.3 mA", 1070, ly + 26, size: 7, color: cGray)
	text("Each sensor node has 100 nF to GND.", 858, 880, size: 7, color: cGray)
}

// MARK: Notes, legend, pin table, title block

func bpNotes() {
	var y: CGFloat = 700
	text("HOW TO READ THIS DRAWING", 40, y, size: 12, bold: true); y += 16
	for l in ["Lines are drawn for signals and chains. A line that crosses another without a dot is NOT connected to it.",
	          "Power rails are drawn in the POWER section and shown elsewhere by a coloured label (e.g. +12V·R0). The same label is the same wire, so +12V·R0 at a tile block comes from fuse F2.",
	          "Circles T0 to T15 are the 4-wire control buses from a shift register's outputs (QA to QD or QE to QH) to a driver's IN1 to IN4. The same T-number is at both ends.",
	          "Circles a to j are the wires that run between the two breadboards (same letters as on the breadboard pages): a, b, c = 3V3 and the two GND rails, d = chain data, e f g = CLK, LATCH, OE, h i j = LDR, NTC and status LED.",
	          "Dashed boxes show which breadboard each part sits on. The 16 drivers, 16 motors and all LED blocks are off the breadboards; the 12 V rails and all motor current never touch the breadboards.",
	          "Every chip has its notch to the left on the real board; this drawing shows logical connections, not hole positions. For hole positions use the breadboard pages."] {
		y = paragraph("• " + l, 48, y, width: 590, size: 8.5)
	}
	y += 6
	text("COLOURS", 40, y, size: 12, bold: true); y += 14
	var x: CGFloat = 48
	for (c, n) in [(cOrange, "3.3 V"), (cRed, "5 V"), (cMag, "12 V"), (cBlack, "GND / signal wire"), (cGreen, "LED data"), (cPurple, "CLK"), (cBlue, "LATCH, sensors"), (cBrown, "OE"), (cTeal, "chain (SER, QH')")] {
		dot(x, y - 3, 5, fill: c); text(n, x + 9, y, size: 8.5)
		x += 22 + measure(n, size: 8.5, bold: false)
		if x > 560 { x = 48; y += 14 }
	}
	y += 22
	text("WHAT IS VERIFIED AND WHAT IS NOT", 40, y, size: 12, bold: true); y += 16
	for l in ["Verified by arithmetic only: the power budget and fuse values. Nothing has been tested on hardware.",
	          "From the standard datasheets, not checked against your chips: the 74HCT245 and 74HC595 pin numbers.",
	          "Provisional: the LED part (WS2815 5050), the tile connectors, the motor and driver models (L298N prototype or MX1508/DRV8833), the XL4016 buck module rating.",
	          "Not decided: the mechanical drive system, 6 LEDs per tile versus 6 × 6 tiles, and the firmware power limiter (per group) is not built.",
	          "On the school L298N modules remove the 5 V-EN jumper and feed 5 V into the module's 5 V pin as well as VS."] {
		y = paragraph("• " + l, 48, y, width: 590, size: 8.5)
	}

	// Pin table
	let rows: [[String]] = [["4–7", "GP2–GP5", "LED data rows 0–3, to 74HCT245 A1–A4"], ["9", "GP6", "LED bar data, to 74HCT245 A5"], ["14", "GP10", "595 SRCLK (CLK), all eight chips"], ["15", "GP11", "595 SER, chip #0 only"],
	                        ["16", "GP12", "595 RCLK (LATCH), all eight chips"], ["17", "GP13", "595 OE, all eight chips, 10 kΩ pull-up to 3V3"], ["20", "GP15", "status LED through 4.7 kΩ"], ["31", "GP26 / ADC0", "LDR divider"],
	                        ["32", "GP27 / ADC1", "NTC divider"], ["34", "GP28 / ADC2", "5 V monitor (optional, not wired)"], ["36", "3V3(OUT)", "595 VCC and SRCLR, both sensor dividers"], ["39", "VSYS", "from +5V·LOGIC through D1"], ["40", "VBUS", "leave open"]]
	text("PICO PIN MAP (physical pins)", 700, 940, size: 12, bold: true)
	var nx = 0
	_ = drawTable(Table(widths: [40, 80, 300], header: ["Pin", "GPIO", "Use"], rows: rows, size: 8), 700, 950, limit: 5000, next: &nx)
	text("GP23, GP24, GP25 and GP29 belong to the Wi-Fi radio and are not used.", 700, 1172, size: 8, color: cGray)

	// Power budget
	text("POWER BUDGET AND FUSES (worst case)", 40, 1010, size: 12, bold: true)
	let prow: [[String]] = [
		["LED rows 0–1 (288 LEDs)", "Charger A, direct", "41 W = 3.4 A at 12 V (charger A gives 4 A)", "F1 4 A; rows F2, F3 3 A"],
		["LED rows 2–3 + bar (312 LEDs)", "Charger C via buck 1", "49 W = 4.1 A at 12 V; buck 1 at ~82 % of 5 A; input 2.8 A of 3.33 A", "F4 3 A (20 V side); F5, F6 3 A; F7 1 A"],
		["Motors, drivers, Pico, 74HCT245", "Charger B via buck 2", "6 × 0.6 A + 0.5 A + 0.3 A = 4.4 A; buck 2 at ~88 % of 5 A; input 1.6 A of 3.75 A", "F8 2 A (16 V side); F9 5 A; F10 1 A"]]
	_ = drawTable(Table(widths: [140, 100, 230, 120], header: ["Group", "Source", "Worst-case load", "Fuses (PTC hold current)"], rows: prow, size: 8), 40, 1020, limit: 5000, next: &nx)
	_ = paragraph("Both bucks run near their limit: heatsink each (insulate the tab from other metal) and set them with a multimeter BEFORE connecting any load. The firmware limits at most 6 tiles moving at once; the per-group LED power limiter is not built yet, so keep the brightness low.", 40, 1112, width: 590, size: 8.5, color: cGray)

	// Title block
	rect(2330, 1410, 630, 150, fill: cWhite, stroke: cBlack, lw: 1.6)
	text("Dither Board", 2346, 1442, size: 24, bold: true)
	text("System blueprint: power, control, 16 tiles", 2346, 1462, size: 11)
	text("Rev 1 · 2026-11-20 · 106 × 56 cm, vector (zoom in)", 2346, 1482, size: 9, color: cGray)
	text("Prototype wiring: verify against the datasheets and with a multimeter before applying power.", 2346, 1502, size: 8, color: cGray)
	text("Repo: omeriadon/board-eng · hardware/schematics", 2346, 1520, size: 8, color: cGray)
	text("Generated by make_schematics.swift", 2346, 1538, size: 8, color: cGray)
}
