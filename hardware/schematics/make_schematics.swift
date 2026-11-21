// Generates dither-board-schematics.pdf (A4 landscape pages) and, with a second argument, dither-board-poster.pdf (all pages on one big sheet).
// Usage: swiftc -O -parse-as-library Lib.swift Breadboard.swift Pages.swift Blueprint.swift Mech.swift make_schematics.swift -o /tmp/mkschem && /tmp/mkschem dither-board-schematics.pdf - dither-board-blueprint.pdf dither-board-design-blueprint.pdf   (use - to skip the poster or a blueprint)
import CoreGraphics
import Foundation

func pageCover() {
	beginPage("Dither Board: schematics and breadboard wiring", "Rev 26 · 2026-11-21 · 5 × 5 tiles, 5 × 5 LEDs per module + 25-LED status bar = 650 LEDs · 25 SG90 servos · 2 × PCA9685 · Raspberry Pi Pico W")
	var y: CGFloat = 70
	y = paragraph("What this is", 28, y, width: 380, size: 11, bold: true) + 2
	y = paragraph("The wiring for the prototype: the two chargers and three buck modules, the Pico W logic, and ONE breadboard that holds the Pico, the level shifter, the I2C and OE lines for the servo boards, and the sensors. The two PCA9685 boards, the 25 servos, the 26 LED modules, the buck modules and all LED and servo current stay OFF the breadboard.", 28, y, width: 380) + 6
	y = paragraph("Pages", 28, y, width: 380, size: 11, bold: true) + 2
	for l in ["2  Power: chargers, buck modules, fuses, star ground", "3  Logic schematic: Pico, 74HCT245, I2C to the PCA9685 boards, sensors", "4  Breadboard: Pico, 74HCT245, LED output block, I2C and OE, sensors, status LED", "5 onwards  Wire list and parts for the breadboard", "then  Servo channels (25 servos) and the tile cables", "last  Models, checks before power-up, what is not decided yet"] {
		text(l, 36, y, size: 9); y += 12
	}
	y += 8
	y = paragraph("The one configuration", 28, y, width: 380, size: 11, bold: true) + 2
	for l in ["Charger 20 V 3.33 A: two 5 A buck modules. Buck 1 feeds LED bus A (tiles 0 to 12), buck 2 LED bus B (tiles 13 to 24 + status bar). 10 A in total for the LEDs.",
	          "Charger 16 V 3.75 A: buck 3 to 5 V: the 25 servos, both PCA9685 boards, the Pico and the 74HCT245.",
	          "Charger 12 V 4 A: spare, not wired.",
	          "All negatives join at one star point. One power board, one switch.",
	          "Buck modules: XL4016-class, treated as 5 A continuous with a heatsink."] {
		y = paragraph("• " + l, 36, y, width: 372, size: 9)
	}
	// Reading guide (right column)
	let rx: CGFloat = 440
	var ry: CGFloat = 70
	ry = paragraph("How to read the breadboard page", rx, ry, width: 370, size: 11, bold: true) + 2
	for l in ["Count columns as holes from the LEFT END of the board, 1 to 60. The printed numbers on the lower half of your board run backwards, so do not use them there; the upper half is printed 0 to 60 left to right.",
	          "Every chip has its notch to the LEFT. Pin 1 is bottom-left, so pins 1 to N/2 run along the LOWER band left to right and the rest along the UPPER band right to left.",
	          "'Upper band' is the one next to the top rails, 'lower band' the one next to the bottom rails. A–E and F–J lettering does not matter. If your board is mirrored, mirror the page.",
	          "A numbered circle is one end of a jumper wire. The same number is at the other end. The number matches the wire list after the breadboard page.",
	          "Small tags (R1, C1) are parts; they are listed with their two ends in the part list.",
	          "The rails are split in the middle (between columns 30 and 31): each rail is two halves, joined by a jumper where the drawing shows one.",
	          "Top rails: upper = 3V3, lower = GND. Bottom rails: upper = 5 V logic, lower = GND."] {
		ry = paragraph("• " + l, rx + 8, ry, width: 362, size: 9)
	}
	ry += 6
	ry = paragraph("Colours", rx, ry, width: 370, size: 11, bold: true) + 4
	for (c, n) in [(cOrange, "3.3 V"), (cRed, "5 V logic"), (cBlack, "GND"), (cBlue, "signal (I2C, OE, sensors)"), (cGreen, "LED data")] {
		dot(rx + 14, ry - 3, 5, fill: c); text(n, rx + 24, ry, size: 9); ry += 13
	}
	endPage()
}

// MARK: Power

func pagePower() {
	beginPage("Power: two chargers, three buck modules", "Block level. Fuse values are PTC hold currents. Set all three bucks with a multimeter before connecting any load.")

	box(28, 58, 150, 34, "Power board, one switch", ["both plugs"], fill: rgb(1, 0.95, 0.9))

	let colBrick: CGFloat = 28, colConv: CGFloat = 244, colBus: CGFloat = 372, colOut: CGFloat = 482, colLoad: CGFloat = 536
	func branch(from x0: CGFloat, mid: CGFloat, fin: String, conv: String, convLines: [String], busTitle: String, busLines: [String], color: CGColor, outs: [(String, String, String)]) {
		fuse(x0, mid, fin, len: 46)
		box(colConv, mid - 26, 118, 52, conv, convLines, fill: rgb(0.9, 1, 0.9))
		line(x0 + 46, mid, colConv, mid, 1.4, color)
		line(colConv + 118, mid, colBus, mid, 1.4, color)
		box(colBus, mid - 26, 100, 52, busTitle, busLines, fill: rgb(1, 0.92, 0.92))
		for (i, o) in outs.enumerated() {
			let y = mid + (CGFloat(i) - CGFloat(outs.count - 1) / 2) * 36
			poly([(colBus + 100, mid), (colOut - 6, mid), (colOut - 6, y), (colOut, y)], 1.4, color)
			fuse(colOut, y, o.0, len: 50)
			box(colLoad, y - 14, 160, 28, o.1, [], fill: cWhite)
			text(o.2, colLoad + 168, y + 3, size: 8, color: cGray)
		}
	}
	// Charger 20 V: two buck branches
	let midA: CGFloat = 122, midB: CGFloat = 196
	box(colBrick, 133, 150, 52, "Charger 20 V 3.33 A", ["66 W · regulated switch-mode"], fill: rgb(0.88, 0.93, 1))
	line(178, 159, 186, 159, 1.4); line(186, midA, 186, midB, 1.4); dot(186, 159, 2, fill: cBlack)
	line(186, midA, 192, midA, 1.4); line(186, midB, 192, midB, 1.4)
	branch(from: 192, mid: midA, fin: "F1 2 A", conv: "BUCK 1 → 5.0 V", convLines: ["XL4016-class, heatsink", "5 A max, 1.4 A in"], busTitle: "5 V LED BUS A", busLines: ["1000 µF 10 V"], color: cMag,
	       outs: [("F3 5 A", "LED bus A: tiles 0–12", "13 modules · 325 LEDs")])
	branch(from: 192, mid: midB, fin: "F2 2 A", conv: "BUCK 2 → 5.0 V", convLines: ["XL4016-class, heatsink", "5 A max, 1.4 A in"], busTitle: "5 V LED BUS B", busLines: ["1000 µF 10 V"], color: cMag,
	       outs: [("F4 5 A", "LED bus B: tiles 13–24 + bar", "12 modules + bar · 325 LEDs")])
	// Charger 16 V
	let midC: CGFloat = 290
	box(colBrick, midC - 26, 150, 52, "Charger 16 V 3.75 A", ["60 W · regulated switch-mode"], fill: rgb(0.88, 0.93, 1))
	branch(from: 178, mid: midC, fin: "F5 2 A", conv: "BUCK 3 → 5.0 V", convLines: ["XL4016-class, heatsink", "worst case 4.3 of ~5 A"], busTitle: "5 V SERVO BUS", busLines: ["470 µF 16 V"], color: cRed,
	       outs: [("F6 5 A", "Servo rail: 2 × PCA9685 V+", "6 servos moving at once"), ("F7 1 A", "Logic rail → D1 → Pico VSYS", "Pico, 74HCT245 (via the breadboard)")])
	// Spare charger
	box(colBrick, 336, 150, 24, "Charger 12 V 4 A: spare", [], fill: rgb(0.95, 0.95, 0.95))
	text("not wired", 188, 352, size: 8, color: cGray)

	// Mains lines to chargers (dashed)
	let mids: [CGFloat] = [159, midC]
	line(18, 75, 28, 75, 1, cBlack, dash: [3, 2]); line(18, 75, 18, mids[1], 1, cBlack, dash: [3, 2])
	for y in mids { line(18, y, colBrick, y, 1, cBlack, dash: [3, 2]) }

	// Star ground
	rect(28, 370, PW - 56, 20, fill: rgb(0.93, 0.93, 0.93), stroke: cBlack, lw: 1.1, r: 4)
	text("STAR GND: the negative of both chargers, all three bucks, the buses and the breadboard's GND rails join at ONE point. Never join positives.", PW / 2, 384, size: 8.5, bold: true, align: 1)

	var next = 0
	let t = Table(widths: [150, 120, 290, 140, 80], header: ["Group", "Source", "Worst-case load", "Fuses", "Firmware cap"], rows: [
		["LED bus A: tiles 0–12 (325 LEDs)", "20 V charger, buck 1 (~88 %)", "Capped at 5 A = 25 W at 5 V (buck 1 at 100 % of ~5 A, so give it a heatsink and a fan). Input 1.4 A. Full white would be 19.5 A", "F1 2 A (20 V side); F3 5 A", "5 A bus, 1 A module"],
		["LED bus B: tiles 13–24 + bar (325 LEDs)", "20 V charger, buck 2", "Same as bus A. Both bucks together draw 2.8 A of the charger's 3.33 A (85 %)", "F2 2 A (20 V side); F4 5 A", "5 A bus, 1 A module"],
		["Servos, 2 × PCA9685, Pico, 74HCT245", "16 V charger, buck 3 (~88 %)", "6 servos × 0.25 A typical = 1.5 A (stalled 0.65 A each: 3.9 A) + Pico 0.3 A + boards 0.1 A = 4.3 A worst; buck 3 at ~86 % of 5 A. Input 1.6 A of 3.75 A", "F5 2 A (16 V side); F6 5 A; F7 1 A", "6 servos at once"],
	], size: 8)
	var y = drawTable(t, 28, 400, limit: PH - 26, next: &next) + 8
	for l in ["All LED power is 10 A at most (about 2,260 nits full-screen white, estimated). The firmware limiter works per bus and is NOT built yet: until it is, keep the brightness low.",
	          "Before connecting: measure each charger with nothing attached (a regulated brick reads near its label), then set each buck on a multimeter. Check the plug polarity on every charger. Heatsink every buck (insulate the tab from other metal)."] {
		y = paragraph("• " + l, 28, y, width: PW - 56, size: 8.5)
	}
	endPage()
}

func allPages() {
	pageCover()
	pagePower()
	pageLogic()
	pageBB()
	pageWireLists()
	pageParts()
	pageServos()
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
		if CommandLine.arguments.count > 2, CommandLine.arguments[2] != "-" {
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
		// Blueprints use the blue theme (SF Pro, white ink), so they are drawn after the white pages.
		if CommandLine.arguments.count > 3, CommandLine.arguments[3] != "-" {
			applyBlueprintTheme(); applyBlueprintThemeExtras()
			drawBlueprint(CommandLine.arguments[3])
			print("wrote", CommandLine.arguments[3])
		}
		if CommandLine.arguments.count > 4 {
			applyBlueprintTheme(); applyBlueprintThemeExtras()
			drawDesignBlueprint(CommandLine.arguments[4])
			print("wrote", CommandLine.arguments[4])
		}
	}
}

func posterHeaderBand() {
	text("Dither Board: everything on one sheet", 40, 62, size: 44, bold: true)
	text("5 × 5 tiles · 5 × 5 LEDs per module + 25-LED status bar = 650 LEDs · 25 SG90 servos · 2 × PCA9685 · Raspberry Pi Pico W · two chargers, three buck modules, one breadboard", 40, 92, size: 16, color: cGray)
	text("Each panel is one A4 page, drawn at full size, so zoom in to read it. Pages run in order, left to right, row by row.", 40, 116, size: 13, color: cGray)
	text("Cover, power, logic schematic, breadboard, wire list, parts, servo channels, models.", 40, 136, size: 13, color: cGray)
	line(40, 144, posterW - 40, 144, 1.2, cGray)
}
