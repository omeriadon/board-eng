// The breadboard layout (rev 26: one breadboard). One netlist (wires and parts) drives both the drawing and the wire-list tables.
import CoreGraphics
import Foundation

let pitch: CGFloat = 12.2
let bbX0: CGFloat = 70
let bbTop: CGFloat = 96
func cx(_ col: CGFloat) -> CGFloat { bbX0 + (col - 0.5) * pitch }
func cy(_ u: CGFloat) -> CGFloat { bbTop + u * pitch }

// Row positions in pitch units from the top of the board.
let rowTop3V3: CGFloat = 0.5, rowTopGND: CGFloat = 1.5
let rowA: CGFloat = 3.2, rowC: CGFloat = 5.2, rowE: CGFloat = 7.2, rowF: CGFloat = 10.2, rowH: CGFloat = 12.2, rowJ: CGFloat = 14.2
let rowB: CGFloat = 4.2, rowI: CGFloat = 13.2
let rowBot5V: CGFloat = 15.9, rowBotGND: CGFloat = 16.9

struct Pt {
	var board: Int // 0 = off the breadboards
	var col: CGFloat
	var row: CGFloat
	var desc: String
}

struct Wire { var id: String; var a: Pt; var b: Pt; var color: CGColor; var note: String }
struct Part { var id: String; var value: String; var a: Pt; var b: Pt; var tag: Pt; var note: String }

var wires: [Wire] = []
var parts: [Part] = []
var wireCounter = [0, 0] // board 1 (index 0 unused)
var partCounters: [String: Int] = [:]
var crossLetters = Array("abcdefghijklmnopqrstuvwxyz")
var extIDs = 0

func rail(_ board: Int, _ name: String, _ col: Int) -> Pt {
	switch name {
		case "3V3": return Pt(board: board, col: CGFloat(col), row: rowTop3V3, desc: "BB\(board) top rail 3V3, col \(col)")
		case "GNDT": return Pt(board: board, col: CGFloat(col), row: rowTopGND, desc: "BB\(board) top rail GND, col \(col)")
		case "5V": return Pt(board: board, col: CGFloat(col), row: rowBot5V, desc: "BB\(board) bottom rail 5 V, col \(col)")
		default: return Pt(board: board, col: CGFloat(col), row: rowBotGND, desc: "BB\(board) bottom rail GND, col \(col)")
	}
}
func ext(_ s: String) -> Pt { Pt(board: 0, col: 0, row: 0, desc: s) }

let picoNames: [Int: String] = [1: "GP0", 2: "GP1", 3: "GND", 4: "GP2", 5: "GP3", 6: "GP4", 7: "GP5", 8: "GND", 9: "GP6", 10: "GP7", 11: "GP8", 12: "GP9", 13: "GND", 14: "GP10", 15: "GP11", 16: "GP12", 17: "GP13", 18: "GND", 19: "GP14", 20: "GP15", 21: "GP16", 22: "GP17", 23: "GND", 24: "GP18", 25: "GP19", 26: "GP20", 27: "GP21", 28: "GND", 29: "GP22", 30: "RUN", 31: "GP26", 32: "GP27", 33: "AGND", 34: "GP28", 35: "VREF", 36: "3V3", 37: "3V3EN", 38: "GND", 39: "VSYS", 40: "VBUS"]
let picoFunction: [Int: String] = [4: "LED0", 5: "LED1", 6: "LED2", 7: "LED3", 9: "LED4", 10: "BAR", 17: "OE", 20: "STAT", 21: "SDA", 22: "SCL", 31: "LDR", 32: "NTC", 34: "5Vmon", 36: "3V3", 39: "VSYS", 40: "VBUS"]
func picoCol(_ pin: Int) -> Int { pin <= 20 ? 2 + pin : 43 - pin }
func pico(_ pin: Int) -> Pt {
	let n = picoNames[pin]!
	return Pt(board: 1, col: CGFloat(picoCol(pin)), row: pin <= 20 ? rowI : rowB, desc: "BB1 Pico pin \(pin) (\(n)), col \(picoCol(pin))")
}

let n245: [String] = ["", "DIR", "A1", "A2", "A3", "A4", "A5", "A6", "A7", "A8", "GND", "B8", "B7", "B6", "B5", "B4", "B3", "B2", "B1", "OE", "VCC"]
let c245 = 25
func col245(_ p: Int) -> Int { p <= 10 ? c245 + p - 1 : c245 + 20 - p }
func p245(_ p: Int) -> Pt { Pt(board: 1, col: CGFloat(col245(p)), row: p <= 10 ? rowJ : rowA, desc: "BB1 74HCT245 pin \(p) (\(n245[p])), col \(col245(p))") }

func addWire(_ a: Pt, _ b: Pt, _ c: CGColor, _ note: String = "", cross: Bool = false) {
	var id: String
	if cross { id = String(crossLetters.removeFirst()) }
	else if a.board == 0 || b.board == 0 { extIDs += 1; id = "P\(extIDs)" }
	else { let bd = a.board; wireCounter[bd] += 1; id = "\(wireCounter[bd])" }
	wires.append(Wire(id: id, a: a, b: b, color: c, note: note))
}

func addPart(_ prefix: String, _ value: String, a: Pt, b: Pt, tag: Pt, _ note: String = "") {
	partCounters[prefix, default: 0] += 1
	parts.append(Part(id: "\(prefix)\(partCounters[prefix]!)", value: value, a: a, b: b, tag: tag, note: note))
}

func upperStrip(_ board: Int, _ col: Int, _ what: String, row: CGFloat = rowA) -> Pt { Pt(board: board, col: CGFloat(col), row: row, desc: "BB\(board) upper band, col \(col) (\(what))") }
func lowerStrip(_ board: Int, _ col: Int, _ what: String) -> Pt { Pt(board: board, col: CGFloat(col), row: rowJ, desc: "BB\(board) lower band, col \(col) (\(what))") }
func gapTagUpper(_ board: Int, _ col: Int) -> Pt { Pt(board: board, col: CGFloat(col), row: 2.0, desc: "") }
func gapTagLower(_ board: Int, _ col: Int) -> Pt { Pt(board: board, col: CGFloat(col), row: 15.0, desc: "") }

let kSignal = cBlue, kData = cGreen, kChain = cPurple, k3 = cOrange, k5 = cRed, kG = cBlack

func buildNetlist() {
	// ---- Power in and rail housekeeping, BB1
	addWire(rail(1, "5V", 1), ext("Buck 3 output via F7 (logic rail, +5 V)"), k5, "Only 5 V input to the breadboard")
	addWire(rail(1, "GNDB", 1), ext("Star GND"), kG, "")
	addWire(rail(1, "GNDT", 2), rail(1, "GNDB", 2), kG, "Joins the two GND rails")
	addWire(rail(1, "3V3", 30), rail(1, "3V3", 31), k3, "Rail break jumper")
	addWire(rail(1, "GNDT", 30), rail(1, "GNDT", 31), kG, "Rail break jumper")
	addWire(rail(1, "GNDB", 30), rail(1, "GNDB", 31), kG, "Rail break jumper")
	// ---- Pico power
	addWire(pico(36), rail(1, "3V3", 7), k3, "Pico 3V3(OUT) feeds the 3V3 rail")
	addWire(pico(3), rail(1, "GNDB", 5), kG, "")
	addWire(pico(38), rail(1, "GNDT", 5), kG, "")
	addWire(pico(33), rail(1, "GNDT", 10), kG, "AGND")
	addWire(rail(1, "5V", 2), upperStrip(1, 1, "D1 anode"), k5, "5 V to the VSYS diode")
	addPart("D", "1N5819 Schottky", a: upperStrip(1, 1, "anode"), b: upperStrip(1, 4, "cathode, Pico pin 39 VSYS"), tag: gapTagUpper(1, 2), "Stripe (cathode) on the VSYS side, column 4. Bend the leads to span 3 columns")
	addPart("C", "100 µF 10 V electrolytic", a: upperStrip(1, 4, "+ leg, VSYS"), b: rail(1, "GNDT", 4), tag: gapTagUpper(1, 4), "Long (+) leg on VSYS; at the Pico")
	// ---- 74HCT245: six LED data lines (five tile rows and the status bar)
	for (i, pin) in [4, 5, 6, 7, 9, 10].enumerated() { addWire(pico(pin), p245(2 + i), kData, "GP\(picoNames[pin]!.dropFirst(2)) → A\(i + 1)") }
	for p in [8, 9] { addWire(p245(p), rail(1, "GNDB", col245(p)), kG, "Unused input (A\(p - 1)) to GND") }
	addWire(p245(1), rail(1, "5V", col245(1)), k5, "DIR high = A to B")
	addWire(p245(10), rail(1, "GNDB", col245(10)), kG, "")
	addWire(p245(19), rail(1, "GNDT", col245(19)), kG, "OE low = enabled")
	addWire(p245(20), rail(1, "5V", 24), k5, "VCC from the 5 V rail")
	addPart("C", "100 nF", a: p245(20), b: rail(1, "GNDT", col245(20)), tag: gapTagUpper(1, col245(20)), "74HCT245 decoupling")
	// ---- LED output block (cols 35 to 40): input column X, output column Y
	let blocks: [(x: Int, upper: Bool)] = [(35, true), (35, false), (37, true), (37, false), (39, true), (39, false)]
	for (r, bl) in blocks.enumerated() {
		let inP = bl.upper ? upperStrip(1, bl.x, "LED line \(r) in") : lowerStrip(1, bl.x, "LED line \(r) in")
		let outP = bl.upper ? upperStrip(1, bl.x + 1, "LED line \(r) out") : lowerStrip(1, bl.x + 1, "LED line \(r) out")
		let bPin = 18 - r // B1 = pin 18 ... B6 = pin 13
		addWire(p245(bPin), inP, kData, "B\(r + 1) → line \(r)")
		addPart("R", "330 Ω", a: inP, b: outP, tag: Pt(board: 1, col: CGFloat(bl.x) + 0.5, row: bl.upper ? 4.6 : 12.8, desc: ""), "Series resistor, LED line \(r)")
		addPart("R", "10 kΩ", a: inP, b: bl.upper ? rail(1, "GNDT", bl.x) : rail(1, "GNDB", bl.x), tag: bl.upper ? gapTagUpper(1, bl.x) : gapTagLower(1, bl.x), "Pull-down, LED line \(r)")
		let target = r < 5 ? "Tile row \(r) cable, DIN of tile \(5 * r)" : "Status bar cable, DIN"
		addWire(outP, ext(target), kData, "Off-board (via 330 Ω)")
	}
	// ---- I2C and OE for the two PCA9685 servo boards (cols 42 to 46, upper band)
	let sdaNode = upperStrip(1, 42, "SDA node"), sclNode = upperStrip(1, 44, "SCL node"), oeNode = upperStrip(1, 46, "OE node")
	addWire(pico(21), sdaNode, kSignal, "GP16 → I2C0 SDA")
	addWire(pico(22), sclNode, kSignal, "GP17 → I2C0 SCL")
	addWire(pico(17), oeNode, kSignal, "GP13 → PCA9685 OE (active low)")
	addPart("R", "4.7 kΩ", a: sdaNode, b: rail(1, "3V3", 42), tag: gapTagUpper(1, 42), "SDA pull-up (leave out if the PCA9685 boards you buy already have one)")
	addPart("R", "4.7 kΩ", a: sclNode, b: rail(1, "3V3", 44), tag: gapTagUpper(1, 44), "SCL pull-up (same)")
	addPart("R", "1 kΩ", a: oeNode, b: rail(1, "3V3", 46), tag: gapTagUpper(1, 46), "OE pull-up: servos stay off until the firmware lets go. 1 kΩ beats any pull-down on the board")
	addWire(upperStrip(1, 42, "SDA node, 2nd hole", row: rowB), ext("PCA9685 #0 and #1, SDA pin (both boards in parallel)"), kSignal, "Off-board, one short cable")
	addWire(upperStrip(1, 44, "SCL node, 2nd hole", row: rowB), ext("PCA9685 #0 and #1, SCL pin (both boards in parallel)"), kSignal, "Off-board, same cable")
	addWire(upperStrip(1, 46, "OE node, 2nd hole", row: rowB), ext("PCA9685 #0 and #1, OE pin (both boards in parallel)"), kSignal, "Off-board, same cable")
	addWire(rail(1, "3V3", 48), ext("PCA9685 #0 and #1, VCC pin (chip logic, 3V3)"), k3, "Off-board, same cable. Servo power does NOT come from here")
	addWire(rail(1, "GNDT", 49), ext("PCA9685 #0 and #1, GND pin"), kG, "Off-board, same cable")
	// ---- sensors and status LED (cols 52 to 59)
	let ldrNode = upperStrip(1, 52, "LDR node"), ntcNode = upperStrip(1, 56, "NTC node"), ledNode = lowerStrip(1, 58, "status LED node")
	addWire(pico(31), ldrNode, kSignal, "LDR divider midpoint → GP26 (ADC0)")
	addWire(pico(32), ntcNode, kSignal, "NTC divider midpoint → GP27 (ADC1)")
	addWire(pico(20), ledNode, kSignal, "GP15 → status LED")
	addPart("LDR", "LDR (light sensor)", a: rail(1, "3V3", 52), b: ldrNode, tag: Pt(board: 1, col: 52, row: 2.0, desc: ""), "Can also sit behind the bezel hole on two long wires")
	addPart("R", "10 kΩ", a: ldrNode, b: rail(1, "GNDT", 52), tag: Pt(board: 1, col: 52, row: 4.6, desc: ""), "LDR divider")
	addPart("C", "100 nF", a: ldrNode, b: rail(1, "GNDT", 53), tag: Pt(board: 1, col: 52, row: 6.0, desc: ""), "ADC noise filter")
	addPart("R", "10 kΩ", a: rail(1, "3V3", 56), b: ntcNode, tag: Pt(board: 1, col: 56, row: 2.0, desc: ""), "NTC divider")
	addPart("NTC", "10 kΩ NTC thermistor (β ≈ 3950)", a: ntcNode, b: rail(1, "GNDT", 56), tag: Pt(board: 1, col: 56, row: 4.6, desc: ""), "Mount near the buck heatsinks on long wires")
	addPart("C", "100 nF", a: ntcNode, b: rail(1, "GNDT", 57), tag: Pt(board: 1, col: 56, row: 6.0, desc: ""), "ADC noise filter")
	addPart("R", "4.7 kΩ", a: ledNode, b: lowerStrip(1, 59, "LED anode"), tag: Pt(board: 1, col: 58.5, row: 12.8, desc: ""), "Dim on purpose (~0.3 mA)")
	addPart("LED", "Status LED (red)", a: lowerStrip(1, 59, "anode"), b: rail(1, "GNDB", 59), tag: gapTagLower(1, 59), "Cathode (flat side) to GND")
}

// MARK: Drawing

func hole(_ col: CGFloat, _ row: CGFloat) { rect(cx(col) - 1.6, cy(row) - 1.6, 3.2, 3.2, fill: rgb(0.35, 0.35, 0.38), stroke: nil) }

func drawBoardFrame(title: String) {
	let x1 = cx(0.4) - 4, x2 = cx(60.6) + 4
	rect(x1, cy(-0.7), x2 - x1, cy(17.9) - cy(-0.7), fill: cBoard, stroke: cGray, lw: 1, r: 4)
	rect(x1 + 2, cy(7.9), x2 - x1 - 4, cy(9.5) - cy(7.9), fill: rgb(0.86, 0.85, 0.8), stroke: nil)
	for c in 1 ... 60 {
		for r in [rowTop3V3, rowTopGND, rowBot5V, rowBotGND] { hole(CGFloat(c), r) }
		for r in [3.2, 4.2, 5.2, 6.2, 7.2, 10.2, 11.2, 12.2, 13.2, 14.2] { hole(CGFloat(c), CGFloat(r)) }
		text("\(c)", cx(CGFloat(c)), cy(-1.0), size: 7, color: cGray, align: 1)
		if c % 5 == 0 || c == 1 { text("\(c)", cx(CGFloat(c)), cy(18.7), size: 7.5, bold: true, color: cGray, align: 1) }
	}
	// rail colours and split
	line(x1 + 3, cy(0.0), x2 - 3, cy(0.0), 1.5, cRed.copy(alpha: 0.7)!); line(x1 + 3, cy(2.0), x2 - 3, cy(2.0), 1.5, cBlue.copy(alpha: 0.7)!)
	line(x1 + 3, cy(15.4), x2 - 3, cy(15.4), 1.5, cRed.copy(alpha: 0.7)!); line(x1 + 3, cy(17.4), x2 - 3, cy(17.4), 1.5, cBlue.copy(alpha: 0.7)!)
	for u in [rowTop3V3, rowTopGND, rowBot5V, rowBotGND] { rect(cx(30.5) - 2, cy(u) - 5, 4, 10, fill: cBoard, stroke: nil) }
	text("split", cx(30.5), cy(-1.6), size: 7, color: cGray, align: 1)
	text("3V3  +", 28, cy(rowTop3V3) + 3, size: 8, bold: true, color: cOrange)
	text("GND  −", 28, cy(rowTopGND) + 3, size: 8, bold: true)
	text("5 V  +", 28, cy(rowBot5V) + 3, size: 8, bold: true, color: cRed)
	text("GND  −", 28, cy(rowBotGND) + 3, size: 8, bold: true)
	text("upper band", 28, cy(rowC) + 3, size: 8, color: cGray)
	text("lower band", 28, cy(rowH) + 3, size: 8, color: cGray)
}

func labelUpper(_ s: String, col: CGFloat, color: CGColor = cWhite) { // above the pin row E, reading up
	text(s, cx(col) + 3, cy(rowE) - 0.75 * pitch, size: 7.5, color: color, rotated: true)
}
func labelLower(_ s: String, col: CGFloat, color: CGColor = cWhite) { // below the pin row F, reading up (start at the bottom end)
	let w = measure(s, size: 7.5, bold: false)
	text(s, cx(col) + 3, cy(rowF) + 0.75 * pitch + w, size: 7.5, color: color, rotated: true)
}

func drawChip(name: String, c0: Int, pins: Int, names: [String], colFor: (Int) -> Int) {
	let half = pins / 2
	let x1 = cx(CGFloat(c0)) - 0.5 * pitch, x2 = cx(CGFloat(c0 + half - 1)) + 0.5 * pitch
	let y1 = cy(rowE) + 0.45 * pitch, y2 = cy(rowF) - 0.45 * pitch
	rect(x1, y1, x2 - x1, y2 - y1, fill: rgb(0.2, 0.2, 0.24), stroke: cBlack, lw: 1, r: 2)
	dot(x1, (y1 + y2) / 2, 3, fill: cBoard)
	text(name, (x1 + x2) / 2, (y1 + y2) / 2 + 3, size: 8, bold: true, color: cWhite, align: 1)
	for p in 1 ... pins {
		let c = CGFloat(colFor(p))
		let upper = p > half
		rect(cx(c) - 2, cy(upper ? rowE : rowF) - 2, 4, 4, fill: cYellow, stroke: nil)
		let col: CGColor = ["VCC": cOrange, "GND": cBlack][names[p]] ?? cBlack
		if upper { labelUpper(names[p], col: c, color: col) } else { labelLower(names[p], col: c, color: col) }
	}
}

func drawPico() {
	let x1 = cx(3) - 0.6 * pitch, x2 = cx(22) + 0.6 * pitch
	let y1 = cy(rowC) - 0.55 * pitch, y2 = cy(rowH) + 0.55 * pitch
	rect(x1 - 6, (y1 + y2) / 2 - 12, 8, 24, fill: rgb(0.7, 0.7, 0.75), stroke: cBlack, r: 2)
	rect(x1, y1, x2 - x1, y2 - y1, fill: rgb(0.08, 0.45, 0.25), stroke: cBlack, lw: 1, r: 3)
	text("Pico W · USB left · antenna right (keep clear)", (x1 + x2) / 2, cy(8.75) + 2.6, size: 7.5, bold: true, color: cWhite, align: 1)
	for pin in 1 ... 40 {
		let c = CGFloat(picoCol(pin)), upper = pin > 20
		rect(cx(c) - 2, cy(upper ? rowC : rowH) - 2, 4, 4, fill: cYellow, stroke: nil)
		let nm = picoNames[pin]!, fn = picoFunction[pin]
		let used = fn != nil
		let label = used ? fn! : nm
		let color: CGColor = used ? cWhite : rgb(0.75, 0.9, 0.8)
		if upper { // hangs down from the pin row, reading up
			let w = measure(label, size: 7, bold: false)
			text(label, cx(c) + 3, cy(rowC) + 0.75 * pitch + w, size: 7, color: color, rotated: true)
		} else {
			text(label, cx(c) + 3, cy(rowH) - 0.75 * pitch, size: 7, color: color, rotated: true)
		}
	}
}

func wireDot(_ p: Pt, id: String, color: CGColor) {
	let x = cx(p.col), y = cy(p.row)
	dot(x, y, 5.4, fill: color, stroke: cWhite, lw: 0.8)
	text(id, x, y + 2.4, size: id.count > 2 ? 5.6 : 6.6, bold: true, color: cWhite, align: 1)
}

func partTag(_ part: Part) {
	let x = cx(part.tag.col), y = cy(part.tag.row)
	let w = max(16, measure(part.id, size: 6.8, bold: true) + 6)
	rect(x - w / 2, y - 5, w, 10, fill: cYellow, stroke: cBlack, lw: 0.6, r: 2)
	text(part.id, x, y + 2.5, size: 6.8, bold: true, align: 1)
}

func drawBreadboard(_ board: Int) {
	drawBoardFrame(title: "BB\(board)")
	drawPico()
	drawChip(name: "74HCT245", c0: c245, pins: 20, names: n245, colFor: col245)
	text("LED output block", cx(37.5), cy(8.5) + 2, size: 7.5, bold: true, color: cGreen, align: 1)
	text("I2C, OE", cx(44), cy(8.5) + 2, size: 7.5, bold: true, color: cBlue, align: 1)
	text("sensors, status LED", cx(56), cy(8.5) + 2, size: 7.5, bold: true, color: cBlue, align: 1)
	for p in parts {
		if p.tag.board == board { partTag(p) }
	}
	for w in wires {
		if w.a.board == board { wireDot(w.a, id: w.id, color: w.color) }
		if w.b.board == board { wireDot(w.b, id: w.id, color: w.color) }
	}
}

// MARK: Pages

func pageBB() {
	beginPage("Breadboard: Pico W, 74HCT245, LED output block, I2C and OE, sensors, status LED", "Chips: notch to the LEFT. Numbered circles are jumper wires (wire list page follows); yellow tags are parts.")
	drawBreadboard(1)
	var y = cy(19.6) + 8
	let bullets = [
		"Place the Pico first with its USB end at the left: pin 1 at column 3 on the lower band and pin 40 at column 3 on the upper band. Pico pins cover columns 3 to 22. Pin labels: LED0 to LED4 = GP2 to GP6, BAR = GP7, OE = GP13, STAT = GP15, SDA = GP16, SCL = GP17, LDR = GP26, NTC = GP27, 5Vmon = GP28 (optional, not wired).",
		"The Pico body hides the holes between its pin rows, so each Pico pin has only the two holes outside the body (upper band: next to the top rails; lower band: next to the bottom rails). Every Pico pin needs one jumper, and that is what the numbered circles use.",
		"The 74HCT245 sits at columns 25 to 34, the LED output block at 35 to 40 (three column pairs on each band; each line goes in at the left column, through a 330 Ω to the right column, and out to the tile row), the I2C and OE block at 42 to 46, the sensors at 52 to 57 and the status LED at 58 and 59. A jumper over the rail split joins the left and right halves of each rail.",
		"Fit and check the power rails and the decoupling capacitors BEFORE any chip is inserted: 3V3 on the top (upper) rail, 5 V only on the bottom (upper) rail, left half, and GND on both lower rails.",
		"Everything else is off the breadboard: the two PCA9685 boards (one short cable carries SDA, SCL, OE, 3V3 and GND to both; their V+ comes straight from the servo rail), the 25 servos, the 26 LED modules and all LED and servo current. The six LED lines leave through the 330 Ω block to the tile rows and the status bar.",
		"The NTC should really sit near the buck heatsinks (long wires) and the LDR behind the bezel hole.",
	]
	for l in bullets { y = paragraph("• " + l, 28, y, width: PW - 56, size: 8.5) }
	endPage()
}

func pageWireLists() {
	let rows: [[String]] = wires.map { w in
		var colorName = "signal"
		if w.color === cOrange { colorName = "3V3" } else if w.color === cRed { colorName = "5 V" } else if w.color === cBlack { colorName = "GND" } else if w.color === cGreen { colorName = "LED data" }
		return [w.id, w.a.desc, w.b.desc, colorName, w.note]
	}
	let t = Table(widths: [34, 270, 270, 52, 136], header: ["ID", "From", "To", "Colour", "Note"], rows: rows, size: 7.5)
	var start = 0, first = true
	repeat {
		beginPage("Wire list: breadboard" + (first ? "" : " (continued)"), "P1, P2… leave the breadboard.")
		var nx = 0
		_ = drawTable(t, 28, 60, limit: PH - 26, from: start, next: &nx)
		start = nx; first = false
		endPage()
	} while start < rows.count
}

func pageParts() {
	beginPage("Parts on the breadboard", "Tags on the drawing. Values only; footprints are the usual through-hole parts.")
	let rows = parts.map { p in [p.id, p.value, p.a.desc, p.b.desc, p.note] }
	let t = Table(widths: [40, 150, 230, 230, 112], header: ["Tag", "Part", "One end", "Other end", "Note"], rows: rows, size: 7.5)
	var nx = 0
	_ = drawTable(t, 28, 60, limit: PH - 26, next: &nx)
	endPage()
	if nx < rows.count {
		beginPage("Parts on the breadboard (continued)")
		var n2 = 0
		_ = drawTable(t, 28, 60, limit: PH - 26, from: nx, next: &n2)
		endPage()
	}
}
