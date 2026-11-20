// The two breadboard layouts. One netlist (wires and parts) drives both the drawings and the wire-list tables.
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
var wireCounter = [0, 0, 0] // per board 1, 2 (index 0 unused), plus cross
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
let picoFunction: [Int: String] = [4: "LED0", 5: "LED1", 6: "LED2", 7: "LED3", 9: "BAR", 14: "CLK", 15: "SER", 16: "LATCH", 17: "OE", 20: "STAT", 31: "LDR", 32: "NTC", 34: "5Vmon", 36: "3V3", 39: "VSYS", 40: "VBUS"]
func picoCol(_ pin: Int) -> Int { pin <= 20 ? 2 + pin : 43 - pin }
func pico(_ pin: Int) -> Pt {
	let n = picoNames[pin]!
	return Pt(board: 1, col: CGFloat(picoCol(pin)), row: pin <= 20 ? rowI : rowB, desc: "BB1 Pico pin \(pin) (\(n)), col \(picoCol(pin))")
}

let n245: [String] = ["", "DIR", "A1", "A2", "A3", "A4", "A5", "A6", "A7", "A8", "GND", "B8", "B7", "B6", "B5", "B4", "B3", "B2", "B1", "OE", "VCC"]
let n595: [String] = ["", "QB", "QC", "QD", "QE", "QF", "QG", "QH", "GND", "QH'", "SRCLR", "SRCLK", "RCLK", "OE", "SER", "QA", "VCC"]
let c245 = 25
func col245(_ p: Int) -> Int { p <= 10 ? c245 + p - 1 : c245 + 20 - p }
func p245(_ p: Int) -> Pt { Pt(board: 1, col: CGFloat(col245(p)), row: p <= 10 ? rowJ : rowA, desc: "BB1 74HCT245 pin \(p) (\(n245[p])), col \(col245(p))") }

func chipBoard(_ idx: Int) -> Int { idx < 2 ? 1 : 2 }
func chipC0(_ idx: Int) -> Int { idx < 2 ? 42 + 8 * idx : 3 + 8 * (idx - 2) }
func col595(_ idx: Int, _ p: Int) -> Int { p <= 8 ? chipC0(idx) + p - 1 : chipC0(idx) + 16 - p }
func p595(_ idx: Int, _ p: Int) -> Pt {
	Pt(board: chipBoard(idx), col: CGFloat(col595(idx, p)), row: p <= 8 ? rowJ : rowA, desc: "BB\(chipBoard(idx)) 595 #\(idx) pin \(p) (\(n595[p])), col \(col595(idx, p))")
}

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

func upperStrip(_ board: Int, _ col: Int, _ what: String) -> Pt { Pt(board: board, col: CGFloat(col), row: rowA, desc: "BB\(board) upper band, col \(col) (\(what))") }
func lowerStrip(_ board: Int, _ col: Int, _ what: String) -> Pt { Pt(board: board, col: CGFloat(col), row: rowJ, desc: "BB\(board) lower band, col \(col) (\(what))") }
func gapTagUpper(_ board: Int, _ col: Int) -> Pt { Pt(board: board, col: CGFloat(col), row: 2.0, desc: "") }
func gapTagLower(_ board: Int, _ col: Int) -> Pt { Pt(board: board, col: CGFloat(col), row: 15.0, desc: "") }

let kSignal = cBlue, kData = cGreen, kChain = cPurple, k3 = cOrange, k5 = cRed, kG = cBlack

func buildNetlist() {
	// ---- Power in and rail housekeeping, BB1
	addWire(rail(1, "5V", 1), ext("Buck 2 output via F10 (logic rail, +5 V)"), k5, "Only 5 V input to the breadboards")
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
	// ---- 74HCT245
	for (i, pin) in [4, 5, 6, 7, 9].enumerated() { addWire(pico(pin), p245(2 + i), kData, "GP\(picoNames[pin]!.dropFirst(2)) → A\(i + 1)") }
	for p in [7, 8, 9] { addWire(p245(p), rail(1, "GNDB", col245(p)), kG, "Unused input to GND") }
	addWire(p245(1), rail(1, "5V", col245(1)), k5, "DIR high = A to B")
	addWire(p245(10), rail(1, "GNDB", col245(10)), kG, "")
	addWire(p245(19), rail(1, "GNDT", col245(19)), kG, "OE low = enabled")
	addWire(p245(20), rail(1, "5V", 24), k5, "VCC from the 5 V rail")
	addPart("C", "100 nF", a: p245(20), b: rail(1, "GNDT", col245(20)), tag: gapTagUpper(1, col245(20)), "74HCT245 decoupling")
	// ---- LED output block (cols 35 to 40): input column X, output column Y
	let blocks: [(x: Int, upper: Bool)] = [(35, true), (35, false), (37, true), (37, false), (39, true)]
	for (r, bl) in blocks.enumerated() {
		let inP = bl.upper ? upperStrip(1, bl.x, "LED line \(r) in") : lowerStrip(1, bl.x, "LED line \(r) in")
		let outP = bl.upper ? upperStrip(1, bl.x + 1, "LED line \(r) out") : lowerStrip(1, bl.x + 1, "LED line \(r) out")
		let bPin = 18 - r // B1 = pin 18 ... B5 = pin 14
		addWire(p245(bPin), inP, kData, "B\(r + 1) → line \(r)")
		addPart("R", "330 Ω", a: inP, b: outP, tag: Pt(board: 1, col: CGFloat(bl.x) + 0.5, row: bl.upper ? 4.6 : 12.8, desc: ""), "Series resistor, LED line \(r)")
		addPart("R", "10 kΩ", a: inP, b: bl.upper ? rail(1, "GNDT", bl.x) : rail(1, "GNDB", bl.x), tag: bl.upper ? gapTagUpper(1, bl.x) : gapTagLower(1, bl.x), "Pull-down, LED line \(r)")
		let target = r < 4 ? "LED row \(r) connector, DIN" : "Status bar connector, DIN"
		addWire(outP, ext(target), kData, "Off-board (via 330 Ω)")
	}
	// ---- 595 chain control from the Pico
	addWire(pico(14), p595(0, 11), kChain, "Clock (SRCLK)")
	addWire(pico(15), p595(0, 14), kChain, "Data (SER)")
	addWire(pico(16), p595(0, 12), kChain, "Latch (RCLK)")
	addWire(pico(17), p595(0, 13), kChain, "Output enable (OE, active low)")
	addPart("R", "10 kΩ", a: p595(0, 13), b: rail(1, "3V3", col595(0, 13)), tag: gapTagUpper(1, col595(0, 13)), "OE pull-up: motors stay off until the firmware lets go")
	// ---- every 595: power
	for idx in 0 ..< 8 {
		let bd = chipBoard(idx)
		addWire(p595(idx, 16), rail(bd, "3V3", col595(idx, 16)), k3, "VCC to 3V3")
		addWire(p595(idx, 10), rail(bd, "3V3", col595(idx, 10)), k3, "SRCLR high")
		addWire(p595(idx, 8), rail(bd, "GNDB", col595(idx, 8)), kG, "")
		addPart("C", "100 nF", a: p595(idx, 16), b: rail(bd, "GNDT", col595(idx, 16)), tag: gapTagUpper(bd, col595(idx, 16)), "595 #\(idx) decoupling")
	}
	// ---- BB2 rails
	addWire(rail(1, "3V3", 58), rail(2, "3V3", 1), k3, "3V3 to breadboard 2", cross: true)
	addWire(rail(1, "GNDT", 59), rail(2, "GNDT", 1), kG, "GND to breadboard 2", cross: true)
	addWire(rail(1, "GNDB", 60), rail(2, "GNDB", 1), kG, "GND to breadboard 2", cross: true)
	addWire(rail(2, "GNDT", 2), rail(2, "GNDB", 2), kG, "Joins the two GND rails")
	addWire(rail(2, "3V3", 30), rail(2, "3V3", 31), k3, "Rail break jumper")
	addWire(rail(2, "GNDT", 30), rail(2, "GNDT", 31), kG, "Rail break jumper")
	addWire(rail(2, "GNDB", 30), rail(2, "GNDB", 31), kG, "Rail break jumper")
	// ---- chain between 595s
	for idx in 0 ..< 7 {
		let cross = idx == 1
		addWire(p595(idx, 9), p595(idx + 1, 14), kChain, "QH' → SER", cross: cross)
		addWire(p595(idx, 11), p595(idx + 1, 11), kChain, "SRCLK", cross: cross)
		addWire(p595(idx, 12), p595(idx + 1, 12), kChain, "RCLK", cross: cross)
		addWire(p595(idx, 13), p595(idx + 1, 13), kChain, "OE", cross: cross)
	}
	// ---- sensors and status LED on BB2 (cols 53 to 56)
	let ldrNode = upperStrip(2, 52, "LDR node"), ntcNode = upperStrip(2, 56, "NTC node"), ledNode = lowerStrip(2, 58, "status LED node")
	addWire(pico(31), ldrNode, kSignal, "LDR divider midpoint → GP26 (ADC0)", cross: true)
	addWire(pico(32), ntcNode, kSignal, "NTC divider midpoint → GP27 (ADC1)", cross: true)
	addWire(pico(20), ledNode, kSignal, "GP15 → status LED", cross: true)
	addPart("LDR", "LDR (light sensor)", a: rail(2, "3V3", 52), b: ldrNode, tag: Pt(board: 2, col: 52, row: 2.0, desc: ""), "Can also sit behind the bezel hole on two long wires")
	addPart("R", "10 kΩ", a: ldrNode, b: rail(2, "GNDT", 52), tag: Pt(board: 2, col: 52, row: 4.6, desc: ""), "LDR divider")
	addPart("C", "100 nF", a: ldrNode, b: rail(2, "GNDT", 53), tag: Pt(board: 2, col: 52, row: 6.0, desc: ""), "ADC noise filter")
	addPart("R", "10 kΩ", a: rail(2, "3V3", 56), b: ntcNode, tag: Pt(board: 2, col: 56, row: 2.0, desc: ""), "NTC divider")
	addPart("NTC", "10 kΩ NTC thermistor (β ≈ 3950)", a: ntcNode, b: rail(2, "GNDT", 56), tag: Pt(board: 2, col: 56, row: 4.6, desc: ""), "Mount near the buck heatsinks / drivers on long wires")
	addPart("C", "100 nF", a: ntcNode, b: rail(2, "GNDT", 57), tag: Pt(board: 2, col: 56, row: 6.0, desc: ""), "ADC noise filter")
	addPart("R", "4.7 kΩ", a: ledNode, b: lowerStrip(2, 59, "LED anode"), tag: Pt(board: 2, col: 58.5, row: 12.8, desc: ""), "Dim on purpose (~0.3 mA)")
	addPart("LED", "Status LED (red)", a: lowerStrip(2, 59, "anode"), b: rail(2, "GNDB", 59), tag: gapTagLower(2, 59), "Cathode (flat side) to GND")
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
	if board == 1 {
		drawPico()
		drawChip(name: "74HCT245", c0: c245, pins: 20, names: n245, colFor: col245)
		text("LED output block", cx(37.5), cy(8.5) + 2, size: 7.5, bold: true, color: cGreen, align: 1)
	}
	for idx in 0 ..< 8 where chipBoard(idx) == board {
		drawChip(name: "595 #\(idx)", c0: chipC0(idx), pins: 16, names: n595, colFor: { col595(idx, $0) })
	}
	for p in parts {
		if p.tag.board == board { partTag(p) }
	}
	for w in wires {
		if w.a.board == board { wireDot(w.a, id: w.id, color: w.color) }
		if w.b.board == board { wireDot(w.b, id: w.id, color: w.color) }
	}
}

// MARK: Pages

func pageBB(_ board: Int) {
	if board == 1 {
		beginPage("Breadboard 1: Pico W, 74HCT245, LED output block, shift registers 0 and 1", "Chips: notch to the LEFT. Numbered circles are jumper wires (wire list pages follow); yellow tags are parts. Letters (a, b…) go to the other breadboard.")
	} else {
		beginPage("Breadboard 2: shift registers 2 to 7, sensors, status LED", "Chips: notch to the LEFT. Numbered circles are jumper wires (wire list pages follow); yellow tags are parts. Letters (a, b…) come from breadboard 1.")
	}
	drawBreadboard(board)
	var y = cy(19.6) + 8
	let bullets1 = [
		"Place the Pico first with its USB end at the left: pin 1 at column 3 on the lower band and pin 40 at column 3 on the upper band. Pico pins cover columns 3 to 22. Pin labels: LED0 to LED3 = GP2 to GP5, BAR = GP6, CLK/SER/LATCH/OE = GP10 to GP13, STAT = GP15, LDR = GP26, NTC = GP27, 5Vmon = GP28 (optional, not wired).",
		"The Pico body hides the holes between its pin rows, so each Pico pin has only the two holes outside the body (upper band: next to the top rails; lower band: next to the bottom rails). Every Pico pin needs one jumper, and that is what the numbered circles use.",
		"The 74HCT245 sits at columns 25 to 34, the LED output block at columns 35 to 40 (three column pairs; each line goes in at the left column, through a 330 Ω to the right column, and out to the tile row), and shift registers 0 and 1 at 42 to 57. A jumper over the rail split joins the left and right halves of each rail.",
		"Fit and check the power rails and the decoupling capacitors BEFORE any chip is inserted: 3V3 on the top (upper) rail, 5 V only on the bottom (upper) rail, left half, and GND on both lower rails.",
	]
	let bullets2 = [
		"Six shift registers (#2 to #7) sit at columns 3 to 50, with no gaps. Each takes VCC and SRCLR from the 3V3 rail, GND from the bottom GND rail, and the four chain signals from the previous chip (wires from breadboard 1 for chip #2).",
		"The 3V3 and GND rails come from breadboard 1 over wires a, b, c (rails are never connected to 5 V on this board).",
		"Sensors sit at columns 52 to 57 and the status LED at 58 and 59. Their signal wires (letters h, i, j) go to the Pico on breadboard 1. The NTC should really sit near the buck heatsinks or the motor drivers (long wires), and the LDR behind the bezel hole.",
		"The 64 outputs of the eight shift registers go off-board to the 16 motor drivers (see the drivers page), not shown here.",
	]
	for l in (board == 1 ? bullets1 : bullets2) { y = paragraph("• " + l, 28, y, width: PW - 56, size: 8.5) }
	endPage()
}

func pageWireLists() {
	for board in [1, 2] {
		let rows: [[String]] = wires.filter { w in
			if w.id.first!.isLetter && w.id.count == 1 { return w.a.board == board || w.b.board == board ? (board == 1 ? true : w.b.board == 2 || w.a.board == 2) : false }
			return w.a.board == board || w.b.board == board
		}.filter { w in w.id.first!.isLetter && w.id.count == 1 ? (board == 1 ? w.a.board == 1 : w.b.board == 2 || w.a.board == 2) : true }
		.map { w in
			var colorName = "signal"
			if w.color === cOrange { colorName = "3V3" } else if w.color === cRed { colorName = "5 V" } else if w.color === cBlack { colorName = "GND" } else if w.color === cGreen { colorName = "LED data" } else if w.color === cPurple { colorName = "chain" }
			return [w.id, w.a.desc, w.b.desc, colorName, w.note]
		}
		let t = Table(widths: [34, 270, 270, 52, 136], header: ["ID", "From", "To", "Colour", "Note"], rows: rows, size: 7.5)
		var start = 0, first = true
		repeat {
			beginPage("Wire list: breadboard \(board)" + (first ? "" : " (continued)"), "Cross-board wires (letters) are listed on the breadboard where they start. P1, P2… leave the breadboards.")
			var nx = 0
			_ = drawTable(t, 28, 60, limit: PH - 26, from: start, next: &nx)
			start = nx; first = false
			endPage()
		} while start < rows.count
	}
}

func pageParts() {
	beginPage("Parts on the breadboards", "Tags on the drawings. Values only; footprints are the usual through-hole parts.")
	let rows = parts.map { p in [p.id, p.value, p.a.desc, p.b.desc, p.note] }
	let t = Table(widths: [40, 150, 230, 230, 112], header: ["Tag", "Part", "One end", "Other end", "Note"], rows: rows, size: 7.5)
	var nx = 0
	_ = drawTable(t, 28, 60, limit: PH - 26, next: &nx)
	endPage()
	if nx < rows.count {
		beginPage("Parts on the breadboards (continued)")
		var n2 = 0
		_ = drawTable(t, 28, 60, limit: PH - 26, from: nx, next: &n2)
		endPage()
	}
}
