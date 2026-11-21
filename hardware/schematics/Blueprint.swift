// One connected drawing of the whole project (not the A4 pages tiled): power, Pico, level shifter,
// two PCA9685 servo boards, sensors, 25 servos, 25 LED modules and the status bar (rev 26: 5 × 5 tiles).
// Signals and chains are drawn as lines; power rails are drawn in the power section and shown by a coloured
// label (flag) at each load; the servo signal from a PCA9685 channel to its servo is a numbered circle (0 to 24).
import CoreGraphics
import Foundation

let BW: CGFloat = 3000, BH: CGFloat = 1600
var cMag = rgb(0.78, 0.1, 0.5), cBrown = rgb(0.6, 0.4, 0.1), cPico = rgb(0.88, 0.96, 0.9)
func applyBlueprintThemeExtras() { cMag = rgb(1, 0.58, 0.82); cBrown = rgb(0.92, 0.74, 0.46) }

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
	text(label, x, y + size * 0.36, size: size, bold: true, color: fill === cYellow ? rgb(0.05, 0.08, 0.2) : cBlack, align: 1)
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
	if themed { blueprintGrid(BW, BH) }
}

func closeBlueprint() {
	ctx.endPDFPage()
	ctx.closePDF()
}

// Layout constants.
let bandH: CGFloat = 260
func bandTop(_ r: Int) -> CGFloat { 190 + bandH * CGFloat(r) }
func tileX(_ c: Int) -> CGFloat { 1520 + 290 * CGFloat(c) }
let modW: CGFloat = 220
let pcaX: CGFloat = 1290, pcaW: CGFloat = 130
let pca0Y: CGFloat = 218, pca1Y: CGFloat = 482
func ledBus(_ t: Int) -> String { t <= 12 ? "+5V·LA" : "+5V·LB" }

func drawBlueprint(_ path: String) {
	openBlueprint(path)
	text("Dither Board: system blueprint", 40, 56, size: 40, bold: true)
	text("5 × 5 tiles · 5 × 5 LEDs per module + 25-LED status bar = 650 LEDs · 25 SG90 servos on 2 × PCA9685 · Raspberry Pi Pico W · two chargers, three buck modules, one breadboard", 40, 86, size: 15, color: cGray)
	text("Read left to right: power, then the Pico, then the servo drivers, then the 25 tiles. Rev 26 · 2026-11-21 · prototype, nothing tested on hardware.", 40, 108, size: 12, color: cGray)
	line(40, 120, BW - 40, 120, 1.2, cGray)

	bpPower()
	bpPico()
	bpServos()
	bpTiles()
	bpSensors()
	bpNotes()
	closeBlueprint()
}

// MARK: Power

func bpPower() {
	text("POWER", 40, 142, size: 13, bold: true, color: cGray)
	box(40, 150, 150, 34, "Power board, one switch", ["both plugs"], fill: rgb(1, 0.95, 0.9))
	/// One branch: fuse, buck, bus, then the output fuses with their flags (name, colour, y offset from the branch line).
	func branch(fuseX: CGFloat, mid: CGFloat, fin: String, conv: String, convLines: [String], busTitle: String, busLines: [String], color: CGColor, outs: [(fuse: String, flag: String, color: CGColor, dy: CGFloat)]) {
		fuse(fuseX, mid, fin, len: 52)
		line(fuseX + 52, mid, 252, mid, 1.6, color)
		box(252, mid - 26, 118, 52, conv, convLines, fill: rgb(0.9, 1, 0.9))
		line(370, mid, 396, mid, 1.6, color)
		box(396, mid - 26, 100, 52, busTitle, busLines, fill: rgb(1, 0.92, 0.95))
		for o in outs {
			let y = mid + o.dy
			poly([(496, mid), (508, mid), (508, y), (516, y)], 1.6, color)
			if y != mid { dot(508, mid, 2, fill: color) }
			fuse(516, y, o.fuse, len: 50)
			if o.flag == "+5V·LOGIC" {
				line(566, y, 650, y, 1.6, cRed)
				text(o.flag, 574, y + 14, size: 7.5, bold: true, color: cRed)
			} else {
				flag(566, y, o.flag, o.color, dir: 1)
			}
		}
	}
	// 20 V charger: two LED buses
	let midA: CGFloat = 230, midB: CGFloat = 338
	box(40, 258, 150, 52, "Charger 20 V 3.33 A", ["66 W · regulated"], fill: rgb(0.88, 0.93, 1))
	line(190, 284, 194, 284, 1.6, cMag); line(194, midA, 194, midB, 1.6, cMag); dot(194, 284, 2, fill: cMag)
	line(194, midA, 198, midA, 1.6, cMag); line(194, midB, 198, midB, 1.6, cMag)
	branch(fuseX: 198, mid: midA, fin: "F1 2 A", conv: "BUCK 1 → 5.0 V", convLines: ["XL4016-class, heatsink", "5 A max · 1.4 A in"], busTitle: "5 V LED BUS A", busLines: ["1000 µF 10 V"], color: cMag,
	       outs: [("F3 5 A", "+5V·LA", cMag, 0)])
	branch(fuseX: 198, mid: midB, fin: "F2 2 A", conv: "BUCK 2 → 5.0 V", convLines: ["XL4016-class, heatsink", "5 A max · 1.4 A in"], busTitle: "5 V LED BUS B", busLines: ["1000 µF 10 V"], color: cMag,
	       outs: [("F4 5 A", "+5V·LB", cMag, 0)])
	text("LED bus A: tiles 0–12 (325 LEDs)", 252, midA + 40, size: 7.5, color: cGray)
	text("LED bus B: tiles 13–24 + bar (325 LEDs)", 252, midB + 40, size: 7.5, color: cGray)
	// 16 V charger: servos and logic
	let midC: CGFloat = 480
	box(40, midC - 26, 150, 52, "Charger 16 V 3.75 A", ["60 W · regulated"], fill: rgb(0.88, 0.93, 1))
	branch(fuseX: 194, mid: midC, fin: "F5 2 A", conv: "BUCK 3 → 5.0 V", convLines: ["XL4016-class, heatsink", "worst case 4.3 of ~5 A"], busTitle: "5 V SERVO BUS", busLines: ["470 µF 16 V"], color: cRed,
	       outs: [("F6 5 A", "+5V·SRV", cRed, -25), ("F7 1 A", "+5V·LOGIC", cRed, 25)])
	// Spare charger
	box(40, 556, 150, 36, "Charger 12 V 4 A", ["spare, not wired"], fill: rgb(0.93, 0.93, 0.93))
	// Mains
	line(28, 167, 40, 167, 1, cBlack, dash: [3, 2]); line(28, 167, 28, 574, 1, cBlack, dash: [3, 2])
	for y: CGFloat in [284, midC] { line(28, y, 40, y, 1, cBlack, dash: [3, 2]) }
	line(28, 574, 40, 574, 1, cBlack, dash: [3, 2])
	// Star ground
	rect(40, 636, 610, 22, fill: rgb(0.93, 0.93, 0.93), stroke: cBlack, lw: 1.1, r: 4)
	text("STAR GND: the negatives of both chargers, all three bucks, every bus and the breadboard join at ONE point. Never join positives.", 345, 651, size: 8, bold: true, align: 1)
	text("+5V·LOGIC runs up to the Pico's VSYS pin through D1 (1N5819), and to the 74HCT245.", 40, 622, size: 8, color: cGray)
}

// MARK: Pico and level shifter

func bpPico() {
	text("CONTROL", 700, 142, size: 13, bold: true, color: cGray)
	// Breadboard outline
	rect(690, 150, 530, 560, fill: nil, stroke: cTeal, lw: 1.4, r: 8, dash: [8, 4])
	text("THE BREADBOARD: Pico, 74HCT245, LED output block, D1, C1, pull-ups (sensors below)", 700, 722, size: 8.5, bold: true, color: cTeal)
	rect(700, 160, 140, 540, fill: cPico, stroke: cBlack, lw: 1.4, r: 5)
	text("Pico W", 770, 178, size: 14, bold: true, align: 1)
	text("3.3 V logic", 770, 190, size: 8, color: cGray, align: 1)
	// Right pins
	let rp: [(String, Int, CGFloat, String)] = [("GP2", 4, 200, "LED row 0"), ("GP3", 5, 240, "LED row 1"), ("GP4", 6, 280, "LED row 2"), ("GP5", 7, 320, "LED row 3"), ("GP6", 9, 360, "LED row 4"), ("GP7", 10, 400, "LED bar"),
	                                            ("GP13", 17, 440, "PCA OE"), ("GP15", 20, 490, "status LED"), ("GP16", 21, 530, "I2C SDA"), ("GP17", 22, 570, "I2C SCL"),
	                                            ("GP26", 31, 610, "LDR (ADC0)"), ("GP27", 32, 640, "NTC (ADC1)"), ("GP28", 34, 670, "5 V mon (opt)")]
	for p in rp {
		text("\(p.0) · pin \(p.1)", 836, p.2 + 3, size: 8, bold: true, align: 2)
		if p.2 > 420 { text(p.3, 706, p.2 + 3, size: 7, color: cGray) }
	}
	// Left pins
	line(700, 200, 684, 200, 1.4, cOrange); flag(684, 200, "3V3 → sensors, I2C, PCA9685", cOrange, dir: 2); text("3V3(OUT) · pin 36", 706, 203, size: 8, bold: true)
	text("VSYS · pin 39", 706, 253, size: 8, bold: true)
	text("VBUS · pin 40: leave open", 706, 303, size: 7.5, color: cGray)
	text("GND pins → star GND", 706, 693, size: 7.5, color: cGray)
	line(700, 690, 686, 690, 1.4, cBlack); ground(686, 690)
	// VSYS from the logic rail: D1 + 100 uF
	poly([(650, 505), (650, 250)], 1.6, cRed)
	poly([(650, 250), (660, 250)], 1.6, cRed)
	diode(660, 250, cRed)
	text("D1", 676, 240, size: 8, bold: true, color: cRed)
	line(692, 250, 700, 250, 1.6, cRed)
	dot(696, 250, 2, fill: cRed)
	capacitor(696, 250); ground(696, 268)
	text("100 µF", 704, 268, size: 7, color: cGray)
	// 74HCT245
	rect(960, 180, 90, 240, fill: cLight, stroke: cBlack, lw: 1.2, r: 3)
	text("74HCT245", 1005, 194, size: 9, bold: true, align: 1)
	flag(1005, 180, "+5V·LOGIC", cRed, dir: 0)
	text("DIR → +5V · OE → GND · A7, A8 → GND · 100 nF", 1005, 432, size: 7, color: cGray, align: 1)
	let lanes: [CGFloat] = [bandTop(0) + 12, bandTop(1) + 12, bandTop(2) + 12, bandTop(3) + 12, bandTop(4) + 12, 1480]
	for i in 0 ..< 6 {
		let y = 200 + 40 * CGFloat(i)
		arrow(840, y, 960, y, cGreen, w: 1.4)
		text("A\(i + 1)", 964, y + 3, size: 7.5); text("B\(i + 1)", 1046, y + 3, size: 7.5, align: 2)
		line(1050, y, 1062, y, 1.4, cGreen)
		resistor(1062, y, 36, cBlack); text("330 Ω", 1080, y - 8, size: 6.5, align: 1)
		line(1098, y, 1108, y, 1.4, cGreen)
		dot(1108, y, 2, fill: cGreen)
		resistor(1108, y, 22, cBlack, vertical: true); ground(1108, y + 22); text("10 kΩ", 1114, y + 16, size: 6.5, color: cGray)
		let xi = 1140 + 8 * CGFloat(5 - i)
		poly([(1108, y), (xi, y), (xi, lanes[i]), (tileX(0), lanes[i])], 1.4, cGreen)
	}
	// I2C and OE from the Pico to the two PCA9685 boards (buses at x = 1210, 1226, 1242)
	poly([(840, 490 + 40), (1210, 490 + 40)], 1.4, cBlue); dot(1210, 530, 2.2, fill: cBlue)
	poly([(840, 570), (1226, 570)], 1.4, cBlue); dot(1226, 570, 2.2, fill: cBlue)
	poly([(840, 440), (1242, 440)], 1.4, cBrown); dot(1242, 440, 2.2, fill: cBrown)
	// Pull-ups to 3V3 (compact: resistor, then the 3V3 label)
	func pullup(_ x: CGFloat, _ y: CGFloat, _ label: String) {
		dot(x, y, 2, fill: cBlack)
		resistor(x, y, 16, cBlack, vertical: true)
		line(x, y + 16, x, y + 22, 1.2, cOrange)
		text("3V3", x + 5, y + 28, size: 6.5, bold: true, color: cOrange)
		text(label, x + 7, y + 11, size: 6.5, color: cGray)
	}
	pullup(930, 440, "1 kΩ OE")
	pullup(900, 530, "4.7 kΩ")
	pullup(870, 570, "4.7 kΩ")
	// Status LED line to the sensors area
	poly([(840, 490), (1070, 490), (1070, 770)], 1.4, cBlue)
	// Sensor lines
	poly([(840, 640), (870, 640), (870, 770)], 1.4, cBlue)
	poly([(840, 610), (975, 610), (975, 770)], 1.4, cBlue)
}

// MARK: PCA9685 servo boards

func bpServos() {
	text("SERVO DRIVERS", 1250, 142, size: 13, bold: true, color: cGray)
	text("2 × PCA9685, off the breadboard", 1250, 156, size: 8, color: cGray)
	struct Board { var n: Int; var y0: CGFloat; var channels: Int; var first: Int; var addr: String; var order: [Int] }
	// order: which bus is on the first, second, third tap (0 SDA, 1 SCL, 2 OE)
	let boards = [Board(n: 0, y0: pca0Y, channels: 16, first: 0, addr: "0x40", order: [0, 1, 2]), Board(n: 1, y0: pca1Y, channels: 9, first: 16, addr: "0x41 (A0 bridged)", order: [2, 1, 0])]
	let busX: [CGFloat] = [1210, 1226, 1242]
	let busName = ["SDA", "SCL", "OE"], busCol = [cBlue, cBlue, cBrown]
	let tapY: [[CGFloat]] = [[278, 298, 318], [534, 554, 574]]
	for (bi, b) in boards.enumerated() {
		let h = bi == 0 ? CGFloat(230) : CGFloat(136)
		rect(pcaX, b.y0, pcaW, h, fill: cLight, stroke: cBlack, lw: 1.2, r: 3)
		text("PCA9685 #\(b.n)", pcaX + 8, b.y0 + 14, size: 9, bold: true)
		text("I2C \(b.addr)", pcaX + 8, b.y0 + 26, size: 7, color: cGray)
		text("tiles \(b.first) to \(b.first + b.channels - 1)", pcaX + 8, b.y0 + 38, size: 7, color: cGray)
		for k in 0 ..< 3 {
			let y = tapY[bi][k], bus = b.order[k]
			line(busX[bus], y, pcaX, y, 1.4, busCol[bus]); dot(busX[bus], y, 2.2, fill: busCol[bus])
			text(busName[bus], pcaX + 4, y + 2.5, size: 6.5, bold: true)
		}
		let vy = bi == 0 ? b.y0 + 130 : b.y0 + 108
		text("VCC ← 3V3", pcaX + 6, vy, size: 6.5, color: cOrange)
		text("GND ← star", pcaX + 6, vy + 10, size: 6.5, color: cGray)
		text("V+ ← +5V·SRV", pcaX + 6, vy + 20, size: 6.5, color: cRed)
		for i in 0 ..< b.channels {
			let oy = b.y0 + 14 + 13.5 * CGFloat(i)
			text("CH\(i)", pcaX + pcaW - 4, oy + 2.5, size: 6, align: 2)
			line(pcaX + pcaW, oy, pcaX + pcaW + 8, oy, 1, cBlack)
			tag(pcaX + pcaW + 16, oy, "\(b.first + i)", cBlue, r: 6.2, size: 5.8)
		}
	}
	// Buses
	line(busX[0], tapY[0][0], busX[0], tapY[1][2], 1.4, cBlue)
	line(busX[1], tapY[0][1], busX[1], tapY[1][1], 1.4, cBlue)
	line(busX[2], tapY[0][2], busX[2], tapY[1][0], 1.4, cBrown)
	text("SDA", busX[0], tapY[0][0] - 8, size: 6.5, bold: true, color: cBlue, align: 1)
	text("SCL", busX[1], tapY[0][1] - 20, size: 6.5, bold: true, color: cBlue, align: 1)
	text("OE", busX[2], tapY[0][2] - 32, size: 6.5, bold: true, color: cBrown, align: 1)
	text("V+ of both boards ← +5V·SRV", pcaX, pca1Y + 150, size: 7, color: cRed)
	text("(heavy wires, 470 µF each)", pcaX, pca1Y + 160, size: 7, color: cGray)
	text("Servo signal circles 0 to 24 = tile numbers.", pcaX, pca1Y + 176, size: 7, color: cGray)
}

// MARK: Tiles

func bpTiles() {
	text("TILES: row r = tiles 5r to 5r+4; each tile has one 5 × 5 LED module and one SG90 servo (scotch yoke)", 1520, 142, size: 13, bold: true, color: cGray)
	let rowBus = ["bus A", "bus A", "bus A for tiles 10–12, bus B for 13–14", "bus B", "bus B"]
	for r in 0 ..< 5 {
		let b = bandTop(r)
		for c in 0 ..< 5 {
			let t = 5 * r + c
			let x = tileX(c)
			// LED module: DIN at the left, DOUT at the right (lane y = b + 12)
			rect(x, b - 6, modW, 36, fill: rgb(0.96, 1, 0.96), stroke: cGreen, lw: 1.2, r: 4)
			text("Tile \(t) LED module · 25 LEDs (5 × 5)", x + modW / 2, b + 9, size: 8.5, bold: true, align: 1)
			text("DIN →  row \(r), column \(c)  → DOUT", x + modW / 2, b + 22, size: 7, color: cGray, align: 1)
			flag(x + modW / 2, b - 6, ledBus(t), cMag, dir: 0)
			ground(x + modW / 2, b + 30)
			if c < 4 { line(x + modW, b + 12, tileX(c + 1), b + 12, 1.4, cGreen) } else { text("end of chain", x + modW + 6, b + 15, size: 7, color: cGray) }
			// Servo
			let sy = b + 70
			rect(x, sy, 170, 70, fill: rgb(0.93, 0.95, 1), stroke: cBlack, lw: 1.2, r: 4)
			text("Servo \(t) · SG90", x + 85, sy + 14, size: 9, bold: true, align: 1)
			text("PCA9685 #\(t < 16 ? 0 : 1) · channel \(t < 16 ? t : t - 16)", x + 85, sy + 26, size: 7, color: cGray, align: 1)
			text("SIG", x + 4, sy + 47, size: 6.5)
			text("tile row \(r), column \(c)", x + 166, sy + 47, size: 6.5, color: cGray, align: 2)
			flag(x + 85, sy, "+5V·SRV", cRed, dir: 0)
			ground(x + 85, sy + 70)
			line(x - 12, sy + 44, x, sy + 44, 1.2, cBlue)
			tag(x - 24, sy + 44, "\(t)", cBlue, fill: cYellow, r: 11, size: 7.5)
		}
		text("Row \(r): LED data from 74HCT245 B\(r + 1) (through 330 Ω) · modules powered from \(rowBus[r]) · servo signal circles \(5 * r) to \(5 * r + 4)", tileX(0), b + 185, size: 8, color: cGray)
	}
	// Status bar
	let by: CGFloat = 1480
	rect(tileX(0), by - 20, 560, 40, fill: rgb(0.96, 1, 0.96), stroke: cGreen, lw: 1.2, r: 4)
	text("Status bar: 25 LEDs under the grid (timer, song progress)", tileX(0) + 280, by - 4, size: 9, bold: true, align: 1)
	text("DIN ← 74HCT245 B6 through 330 Ω · fixed, does not move · powered from bus B", tileX(0) + 280, by + 9, size: 7, color: cGray, align: 1)
	flag(tileX(0) + 280, by - 20, "+5V·LB", cMag, dir: 0)
	ground(tileX(0) + 280, by + 20)
}

// MARK: Sensors (on the breadboard)

func bpSensors() {
	rect(850, 735, 290, 170, fill: nil, stroke: cTeal, lw: 1.3, r: 8, dash: [8, 4])
	text("THE BREADBOARD: sensors and status LED", 858, 898, size: 8.5, bold: true, color: cTeal)
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
	          "Power rails are drawn in the POWER section and shown elsewhere by a coloured label (e.g. +5V·LA). The same label is the same wire, so +5V·LA at a tile block comes from fuse F3.",
	          "Circles 0 to 24 are the servo signal wires from a PCA9685 channel to its servo. The circle number is the tile number; the same number is at both ends.",
	          "Dashed boxes show what sits on the one breadboard. The two PCA9685 boards, the 25 servos, the 25 LED modules, the status bar and the buck modules are off the breadboard; LED and servo current never touch it.",
	          "Every chip has its notch to the left on the real board; this drawing shows logical connections, not hole positions. For hole positions use the breadboard page."] {
		y = paragraph("• " + l, 48, y, width: 590, size: 8.5)
	}
	y += 6
	text("COLOURS", 40, y, size: 12, bold: true); y += 14
	var x: CGFloat = 48
	for (c, n) in [(cOrange, "3.3 V"), (cRed, "5 V servo and logic"), (cMag, "5 V LED buses"), (cBlack, "GND / signal wire"), (cGreen, "LED data"), (cBlue, "I2C, servo signal, sensors"), (cBrown, "OE (servo outputs)"), (cTeal, "breadboard outline")] {
		dot(x, y - 3, 5, fill: c); text(n, x + 9, y, size: 8.5)
		x += 22 + measure(n, size: 8.5, bold: false)
		if x > 560 { x = 48; y += 14 }
	}
	y += 22
	text("WHAT IS VERIFIED AND WHAT IS NOT", 40, y, size: 12, bold: true); y += 16
	for l in ["Verified by arithmetic only: the power budget and fuse values. Nothing has been tested on hardware.",
	          "From the standard datasheets, not checked against your parts: the 74HCT245 pin numbers and the PCA9685 board pinout.",
	          "Provisional: the LED module pad order and thickness (not received), the XL4016 buck module rating, whether the PCA9685 boards you buy already have SDA/SCL pull-ups.",
	          "Not decided: the new stand. The firmware power limiter (per bus, 5 A each, about 1 A per module) is not built.",
	          "Servos: 50 Hz, 1 to 2 ms = ±90°, only ±75° used (stroke 15 mm); at most 6 moving at once."] {
		y = paragraph("• " + l, 48, y, width: 590, size: 8.5)
	}

	// Pin table
	let rows: [[String]] = [["4–7, 9", "GP2–GP6", "LED data rows 0–4, to 74HCT245 A1–A5"], ["10", "GP7", "LED bar data, to 74HCT245 A6"], ["17", "GP13", "PCA9685 OE, both boards, 1 kΩ pull-up to 3V3"], ["20", "GP15", "status LED through 4.7 kΩ"],
	                        ["21", "GP16 / I2C0 SDA", "PCA9685 SDA, both boards, 4.7 kΩ pull-up"], ["22", "GP17 / I2C0 SCL", "PCA9685 SCL, both boards, 4.7 kΩ pull-up"], ["31", "GP26 / ADC0", "LDR divider"],
	                        ["32", "GP27 / ADC1", "NTC divider"], ["34", "GP28 / ADC2", "5 V monitor (optional, not wired)"], ["36", "3V3(OUT)", "sensors, I2C pull-ups, PCA9685 VCC"], ["39", "VSYS", "from +5V·LOGIC through D1"], ["40", "VBUS", "leave open"]]
	text("PICO PIN MAP (physical pins)", 700, 940, size: 12, bold: true)
	var nx = 0
	_ = drawTable(Table(widths: [40, 100, 300], header: ["Pin", "GPIO", "Use"], rows: rows, size: 8), 700, 950, limit: 5000, next: &nx)
	text("GP23, GP24, GP25 and GP29 belong to the Wi-Fi radio and are not used. GP10–GP12 are free again (the old shift-register pins).", 700, 1172, size: 8, color: cGray)

	// Power budget
	text("POWER BUDGET AND FUSES (worst case)", 40, 1010, size: 12, bold: true)
	let prow: [[String]] = [
		["LED bus A: tiles 0–12 (325 LEDs)", "20 V charger, buck 1", "Capped at 5 A = 25 W at 5 V (full white would be 19.5 A); input 1.4 A at 20 V; buck 1 at its limit: heatsink and fan", "F1 2 A (20 V side); F3 5 A"],
		["LED bus B: tiles 13–24 + bar (325 LEDs)", "20 V charger, buck 2", "Same as bus A. Both bucks together draw 2.8 A of the charger's 3.33 A (85 %)", "F2 2 A (20 V side); F4 5 A"],
		["Servos, 2 × PCA9685, Pico, 74HCT245", "16 V charger, buck 3", "6 servos × 0.25 A = 1.5 A typical (3.9 A if all six stall) + Pico 0.3 A + boards 0.1 A = 4.3 A worst; buck 3 at ~86 % of 5 A; input 1.6 A of 3.75 A", "F5 2 A (16 V side); F6 5 A servo rail; F7 1 A logic"]]
	let ty = drawTable(Table(widths: [140, 100, 250, 110], header: ["Group", "Source", "Worst-case load", "Fuses (PTC hold current)"], rows: prow, size: 8), 40, 1020, limit: 5000, next: &nx)
	_ = paragraph("All LED power is 10 A at most (about 2,260 nits full-screen white, estimated). The firmware limits at most 6 servos moving at once; the per-bus LED power limiter is not built yet, so keep the brightness low. Heatsink every buck (insulate the tab from other metal) and set each on a multimeter BEFORE connecting any load. The 12 V 4 A charger is a spare and is not wired.", 40, ty + 10, width: 600, size: 8.5, color: cGray)

	// Title block
	rect(2330, 1410, 630, 150, fill: cWhite, stroke: cBlack, lw: 1.6)
	text("Dither Board", 2346, 1442, size: 24, bold: true)
	text("System blueprint: power, control, 25 tiles", 2346, 1462, size: 11)
	text("Rev 26 · 2026-11-21 · 106 × 56 cm, vector (zoom in)", 2346, 1482, size: 9, color: cGray)
	text("Prototype wiring: verify against the datasheets and with a multimeter before applying power.", 2346, 1502, size: 8, color: cGray)
	text("Repo: omeriadon/board-eng · hardware/schematics", 2346, 1520, size: 8, color: cGray)
	text("Generated by make_schematics.swift", 2346, 1538, size: 8, color: cGray)
}
