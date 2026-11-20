// Generates dither-board-schematics.pdf (A4 landscape pages) and, with a second argument, dither-board-poster.pdf (all pages on one big sheet).
// Usage: swiftc -O -parse-as-library Lib.swift Breadboard.swift Pages.swift make_schematics.swift -o /tmp/mkschem && /tmp/mkschem dither-board-schematics.pdf dither-board-poster.pdf
import CoreGraphics
import Foundation

func pageCover() {
	beginPage("Dither Board: schematics and breadboard wiring", "Rev 1 · 2026-11-20 · 4 × 4 tiles, 6 × 6 LEDs per tile + 24-LED status bar = 600 LEDs · 16 stepper motors · Raspberry Pi Pico W")
	var y: CGFloat = 70
	y = paragraph("What this is", 28, y, width: 380, size: 11, bold: true) + 2
	y = paragraph("The wiring for the prototype: the three chargers and two buck modules, the Pico W logic, and two breadboards that hold the Pico, the level shifter and all eight shift registers. The 16 motor drivers, the LED rows, the buck modules and all 12 V and motor current stay OFF the breadboards.", 28, y, width: 380) + 6
	y = paragraph("Pages", 28, y, width: 380, size: 11, bold: true) + 2
	for l in ["2  Power: chargers, buck modules, fuses, star ground", "3  Logic schematic: Pico, level shifter, shift registers, sensors", "4  Breadboard 1: Pico, 74HCT245, LED output block, shift registers 0 and 1", "5  Breadboard 2: shift registers 2 to 7, sensors, status LED", "6 onwards  Wire lists and parts for both breadboards", "then  Shift registers to motor drivers (64 wires) and the tile cables", "last  Models, checks before power-up, what is not decided yet"] {
		text(l, 36, y, size: 9); y += 12
	}
	y += 8
	y = paragraph("The one configuration", 28, y, width: 380, size: 11, bold: true) + 2
	for l in ["Charger A 12 V 4 A: LED rows 0 and 1, straight (12 V WS2815 LEDs).",
	          "Charger C 20 V 3.33 A: buck 1 to 12 V: LED rows 2 and 3 and the status bar.",
	          "Charger B 16 V 3.75 A: buck 2 to 5 V: motors, drivers, Pico, level shifter.",
	          "All negatives join at one star point. One power board, one switch.",
	          "Buck modules: XL4016-class, treated as 5 A continuous with a heatsink."] {
		y = paragraph("• " + l, 36, y, width: 372, size: 9)
	}
	// Reading guide (right column)
	let rx: CGFloat = 440
	var ry: CGFloat = 70
	ry = paragraph("How to read the breadboard pages", rx, ry, width: 370, size: 11, bold: true) + 2
	for l in ["Count columns as holes from the LEFT END of the board, 1 to 60. The printed numbers on the lower half of your board run backwards, so do not use them there; the upper half is printed 0 to 60 left to right.",
	          "Every chip has its notch to the LEFT. Pin 1 is bottom-left, so pins 1 to N/2 run along the LOWER band left to right and the rest along the UPPER band right to left.",
	          "'Upper band' is the one next to the top rails, 'lower band' the one next to the bottom rails. A–E and F–J lettering does not matter. If your board is mirrored, mirror the page.",
	          "A numbered circle is one end of a jumper wire. The same number is at the other end. The number matches the wire list after the breadboard pages.",
	          "Small tags (R1, C1) are parts; they are listed with their two ends in the part list.",
	          "The rails are split in the middle (between columns 30 and 31): each rail is two halves, joined by a jumper where the drawing shows one.",
	          "Top rails: upper = 3V3, lower = GND. Bottom rails: upper = 5 V logic, lower = GND."] {
		ry = paragraph("• " + l, rx + 8, ry, width: 362, size: 9)
	}
	ry += 6
	ry = paragraph("Colours", rx, ry, width: 370, size: 11, bold: true) + 4
	for (c, n) in [(cOrange, "3.3 V"), (cRed, "5 V logic"), (cBlack, "GND"), (cBlue, "signal"), (cGreen, "LED data"), (cPurple, "shift-register chain")] {
		dot(rx + 14, ry - 3, 5, fill: c); text(n, rx + 24, ry, size: 9); ry += 13
	}
	endPage()
}

// MARK: Power

func pagePower() {
	beginPage("Power: three chargers, two buck modules", "Block level. Fuse values are PTC hold currents. Set both bucks with a multimeter before connecting any load.")

	// Mains
	box(28, 58, 150, 34, "Power board, one switch", ["all three plugs"], fill: rgb(1, 0.95, 0.9))

	let colBrick: CGFloat = 28, colFuse: CGFloat = 188, colConv: CGFloat = 244, colBus: CGFloat = 372, colOut: CGFloat = 482, colLoad: CGFloat = 536
	func chain(top: CGFloat, height: CGFloat, brick: String, brickLines: [String], fin: String, conv: String, convLines: [String], busTitle: String, busLines: [String], outs: [(String, String, String)]) {
		let mid = top + height / 2
		box(colBrick, mid - 26, 150, 52, brick, brickLines, fill: rgb(0.88, 0.93, 1))
		fuse(colFuse - 10, mid, fin, len: 52)
		box(colConv, mid - 26, 118, 52, conv, convLines, fill: conv.hasPrefix("BUCK") ? rgb(0.9, 1, 0.9) : cLight)
		line(colConv + 118, mid, colBus, mid, 1.4, cRed)
		box(colBus, mid - 26, 100, 52, busTitle, busLines, fill: rgb(1, 0.92, 0.92))
		let n = outs.count
		let step: CGFloat = height / CGFloat(n)
		for (i, o) in outs.enumerated() {
			let y = top + step * (CGFloat(i) + 0.5)
			poly([(colBus + 100, mid), (colOut - 6, mid), (colOut - 6, y), (colOut, y)], 1.4, cRed)
			fuse(colOut, y, o.0, len: 50)
			box(colLoad, y - 14, 160, 28, o.1, [], fill: cWhite)
			text(o.2, colLoad + 168, y + 3, size: 8, color: cGray)
		}
	}
	// A
	chain(top: 96, height: 64, brick: "Charger A: 12 V 4 A", brickLines: ["48 W · regulated switch-mode"], fin: "F1 4 A",
	      conv: "no converter", convLines: ["12 V goes straight to LEDs"], busTitle: "12 V BUS A", busLines: ["1000 µF 25 V"],
	      outs: [("F2 3 A", "LED row 0 (144 LEDs)", "20 AWG · 41 W for rows 0+1"), ("F3 3 A", "LED row 1 (144 LEDs)", "≤ 3 A each")])
	// C
	chain(top: 168, height: 96, brick: "Charger C: 20 V 3.33 A", brickLines: ["66 W · regulated switch-mode"], fin: "F4 3 A",
	      conv: "BUCK 1 → 12.0 V", convLines: ["XL4016-class, heatsink", "worst case 4.1 A of ~5 A"], busTitle: "12 V BUS C", busLines: ["1000 µF 25 V"],
	      outs: [("F5 3 A", "LED row 2 (144 LEDs)", "49 W for rows 2+3+bar"), ("F6 3 A", "LED row 3 (144 LEDs)", "max 36 W per row"), ("F7 1 A", "Status bar (24 LEDs)", "")])
	// B
	chain(top: 276, height: 70, brick: "Charger B: 16 V 3.75 A", brickLines: ["60 W · regulated switch-mode"], fin: "F8 2 A",
	      conv: "BUCK 2 → 5.0 V", convLines: ["XL4016-class, heatsink", "worst case 4.4 A of ~5 A"], busTitle: "5 V BUS", busLines: ["470 µF 16 V"],
	      outs: [("F9 5 A", "Motor rail: 16 drivers", "6 tiles moving at once"), ("F10 1 A", "Logic rail → D1 → Pico VSYS", "Pico, 74HCT245 (via breadboard 1)")])

	// Mains lines to bricks (dashed)
	let mids: [CGFloat] = [96 + 32, 168 + 48, 276 + 35]
	line(18, 75, 28, 75, 1, cBlack, dash: [3, 2]); line(18, 75, 18, mids[2], 1, cBlack, dash: [3, 2])
	for y in mids { line(18, y, colBrick, y, 1, cBlack, dash: [3, 2]) }

	// Star ground
	rect(28, 354, PW - 56, 22, fill: rgb(0.93, 0.93, 0.93), stroke: cBlack, lw: 1.1, r: 4)
	text("STAR GND: the negative of A, B, C, both bucks, the buses and both breadboards' GND rails join at ONE point. Never join positives.", PW / 2, 369, size: 8.5, bold: true, align: 1)

	var next = 0
	let t = Table(widths: [150, 120, 250, 140, 100], header: ["Group", "Source", "Worst-case load", "Fuses", "Firmware cap"], rows: [
		["LED rows 0–1 (288 LEDs)", "A, direct", "41 W = 3.4 A at 12 V (A is 4 A)", "F1 4 A; rows F2/F3 3 A", "41 W; row ≤ 36 W"],
		["LED rows 2–3 + bar (312 LEDs)", "C through buck 1 (~88 %)", "49 W = 4.1 A at 12 V; buck 1 at ~82 % of 5 A. Input draw 2.8 A of 3.33 A", "F4 3 A (20 V side); F5/F6 3 A; F7 1 A", "49 W; row ≤ 36 W"],
		["Motors, drivers, Pico, 74HCT245", "B through buck 2", "6 motors × 0.6 A = 3.6 A + drivers 0.5 A + Pico 0.3 A = 4.4 A; buck 2 at ~88 % of 5 A. Input draw 1.6 A of 3.75 A", "F8 2 A (16 V side); F9 5 A; F10 1 A", "6 tiles at once"],
	], size: 8)
	var y = drawTable(t, 28, 386, next: &next) + 12
	for l in ["Both buck modules run near their limit: heatsink each (the aluminium one you make; insulate the tab from other metal) and consider a fan. If buck 2 is hot, lower the tiles-at-once limit. Measure a real motor's coil current first.",
	          "Before connecting: measure each charger with nothing attached (a regulated brick reads near its label), then set each buck on a multimeter. Polarity: check the plug diagram on every charger.",
	          "The firmware power limiter works per group (rows 0–1; rows 2–3 + bar) and is NOT built yet. Until it is, keep the brightness low."] {
		y = paragraph("• " + l, 28, y, width: PW - 56, size: 8.5)
	}
	endPage()
}

func allPages() {
	pageCover()
	pagePower()
	pageLogic()
	pageBB(1)
	pageBB(2)
	pageWireLists()
	pageParts()
	pageDrivers()
	pageModels()
}

@main
struct Main {
	static func main() {
		let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "dither-board-schematics.pdf"
		buildNetlist()
		openPDF(out)
		allPages()
		ctx.closePDF()
		print("wrote", out)
		if CommandLine.arguments.count > 2 {
			// One big sheet with everything: 4 columns x 3 rows, in page order 1...12.
			let poster = CommandLine.arguments[2]
			// page: 1 cover, 2 power, 3 logic, 4 BB1, 5 BB2, 6-9 wire lists, 10 parts, 11 drivers, 12 models
			let slots: [(Int, Int)] = [(0, 0), (1, 0), (2, 0), (0, 1), (1, 1), (0, 2), (1, 2), (2, 2), (3, 2), (2, 1), (3, 0), (3, 1)]
			openPoster(poster, columns: 4, rows: 3, slots: slots)
			posterHeaderBand()
			allPages()
			closePoster()
			print("wrote", poster)
		}
	}
}

func posterHeaderBand() {
	text("Dither Board: everything on one sheet", 40, 62, size: 44, bold: true)
	text("4 × 4 tiles · 6 × 6 LEDs per tile + 24-LED status bar = 600 LEDs · 16 stepper motors · Raspberry Pi Pico W · three chargers, two buck modules, two breadboards", 40, 92, size: 16, color: cGray)
	text("Each panel is one A4 page, drawn at full size, so zoom in to read it. The page number in each panel footer is the number on the cover's contents list (and in the separate multi-page PDF).", 40, 116, size: 13, color: cGray)
	text("Row 1: cover, power, logic schematic, drivers.  Row 2: breadboard 1, breadboard 2, parts, models.  Row 3: wire lists for both breadboards.", 40, 136, size: 13, color: cGray)
	line(40, 144, posterW - 40, 144, 1.2, cGray)
}
