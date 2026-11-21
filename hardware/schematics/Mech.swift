// The physical design blueprint: one sheet, blue paper, white ink, SF Pro. Rev 22.
// Front elevation, section through one tile column (one tile retracted, one extended), exploded view, the
// 5 x 5 LED cell, the servo scotch-yoke drive and force check, dimension-chain checks, open items, system block diagram and the parts list.
// Every dimension comes from hardware/cad/tile.py (rev 22: HEAD 42, PITCH 43, K = 5 at 7.8 mm, STEM 20, STROKE 15, yoke R 7.76).
// Line styles: solid = decided; dashed light blue = proposed, not designed yet; amber = risk or open.
import CoreGraphics
import Foundation

let MW: CGFloat = 2800, MH: CGFloat = 1700

// MARK: Design numbers (mm)
let dN = 4, dK = 5
let dPitch: CGFloat = 43, dHead: CGFloat = 42, dRim: CGFloat = 1.2, dWall: CGFloat = 1.0
let dGridH: CGFloat = 8, dPCB: CGFloat = 1.6, dFloor: CGFloat = 2, dHeadH: CGFloat = 11.6, dDiff: CGFloat = 0.8
let dInner: CGFloat = dHead - 2 * dRim              // 39.6
let dCell: CGFloat = 7.8                            // = LED pitch of the module
let dGridOff: CGFloat = (dInner - CGFloat(dK) * dCell) / 2   // 0.3: module centred in the rim
let dStem: CGFloat = 20, dStemWall: CGFloat = 1.6, dStemLen: CGFloat = 40, dHole: CGFloat = 20.5
let dStroke: CGFloat = 15, dPad: CGFloat = 1.0
let zG1: CGFloat = 12.6, zG2: CGFloat = 30, dPlate: CGFloat = 3     // guide plates (front faces)
let zTail: CGFloat = 51.6                                           // stem end cap back face, retracted
let zServo0: CGFloat = 57.4, zServo1: CGFloat = 69.8, zShaft: CGFloat = 63.6   // servo case along z, shaft
let zFoot0: CGFloat = 72.6, zFoot1: CGFloat = 75.1                  // bracket foot
let zBack: CGFloat = 75.1                                           // back plate front face
let dR: CGFloat = 7.76                                              // crank radius
let hatchAlpha: CGFloat = 0.5
func gx(_ i: CGFloat) -> CGFloat { dRim + dGridOff + i * dCell }   // x of grid line / cell edge i inside a head

// MARK: Drawing helpers

func hatchIn(_ r: CGRect, spacing: CGFloat = 4.5, alpha: CGFloat = hatchAlpha, dash: [CGFloat] = []) {
	ctx.saveGState()
	ctx.clip(to: r)
	ctx.setStrokeColor(rgb(1, 1, 1, alpha)); ctx.setLineWidth(0.5); ctx.setLineDash(phase: 0, lengths: dash)
	var k = -r.height
	while k < r.width {
		ctx.move(to: CGPoint(x: r.minX + k, y: r.maxY)); ctx.addLine(to: CGPoint(x: r.minX + k + r.height, y: r.minY)); k += spacing
	}
	ctx.strokePath()
	ctx.restoreGState()
}

/// A solid cut in section: outline + hatch. proposed = dashed light-blue outline (not designed yet).
func cut(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, proposed: Bool = false, hatch: Bool = true, spacing: CGFloat = 4.5, fill: CGColor? = nil) {
	let r = CGRect(x: x, y: y, width: w, height: h)
	if let f = fill { ctx.setFillColor(f); ctx.fill(r) }
	if hatch { hatchIn(r, spacing: spacing, alpha: proposed ? 0.3 : hatchAlpha) }
	ctx.saveGState()
	ctx.setStrokeColor(proposed ? cBlue : cBlack); ctx.setLineWidth(proposed ? 1 : 1.2)
	if proposed { ctx.setLineDash(phase: 0, lengths: [4, 3]) }
	ctx.stroke(r)
	ctx.restoreGState()
}

func dimH(_ x1: CGFloat, _ x2: CGFloat, _ y: CGFloat, _ label: String, c: CGColor? = nil, size: CGFloat = 9) {
	let col = c ?? cBlue
	let mid = (x1 + x2) / 2
	arrow(mid, y, x1, y, col, w: 0.8); arrow(mid, y, x2, y, col, w: 0.8)
	let w = measure(label, size: size, bold: false) + 8
	if x2 - x1 > w + 14 {
		rect(mid - w / 2, y - size / 2 - 1.5, w, size + 3, fill: cWhite, stroke: nil)
		text(label, mid, y + size * 0.36, size: size, color: col, align: 1)
	} else {
		text(label, x2 + 8, y + size * 0.36, size: size, color: col)
	}
}

func dimV(_ x: CGFloat, _ y1: CGFloat, _ y2: CGFloat, _ label: String, c: CGColor? = nil, size: CGFloat = 9, labelLeft: Bool = false) {
	let col = c ?? cBlue
	let mid = (y1 + y2) / 2
	arrow(x, mid, x, y1, col, w: 0.8); arrow(x, mid, x, y2, col, w: 0.8)
	let w = measure(label, size: size, bold: false) + 8
	rect(labelLeft ? x - w - 4 : x + 4, mid - size / 2 - 1.5, w, size + 3, fill: cWhite, stroke: nil)
	text(label, labelLeft ? x - 8 : x + 8, mid + size * 0.36, size: size, color: col, align: labelLeft ? 2 : 0)
}

func ext(_ x1: CGFloat, _ y1: CGFloat, _ x2: CGFloat, _ y2: CGFloat) { line(x1, y1, x2, y2, 0.5, cBlue, dash: [2, 2]) }

/// Numbered balloon with a leader to (px, py).
func balloon(_ n: Int, _ bx: CGFloat, _ by: CGFloat, _ px: CGFloat, _ py: CGFloat) {
	line(bx, by, px, py, 0.7, cBlack)
	dot(px, py, 1.8, fill: cBlack)
	dot(bx, by, 9, fill: cWhite, stroke: cBlack, lw: 1)
	text("\(n)", bx, by + 3.6, size: 10, bold: true, align: 1)
}

func panel(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ code: String, _ title: String, _ sub: String = "") {
	rect(x, y, w, h, fill: nil, stroke: rgb(1, 1, 1, 0.55), lw: 1)
	dot(x + 22, y + 22, 13, fill: cWhite, stroke: cBlack, lw: 1.2)
	text(code, x + 22, y + 27, size: 14, bold: true, align: 1)
	text(title, x + 44, y + 26, size: 15, bold: true)
	if !sub.isEmpty { text(sub, x + 44, y + 42, size: 10, color: cGray) }
}

func zigzag(_ x1: CGFloat, _ x2: CGFloat, _ y: CGFloat) {
	var pts: [(CGFloat, CGFloat)] = [(x1, y)]
	var x = x1 + 8, up = true
	while x < x2 { pts.append((x, y + (up ? -5 : 5))); up.toggle(); x += 8 }
	pts.append((x2, y))
	poly(pts, 1, cBlack)
}

// MARK: Parts list (balloon numbers)

struct BomPart { let n: Int; let name: String; let qty: String; let spec: String; let status: String }
let bom: [BomPart] = [
	BomPart(n: 1, name: "Diffuser sheet", qty: "16", spec: "3D-printed translucent sheet, ~0.8 mm (thickness not tested), 41.8 square, glued flush on the head face", status: "PROPOSED"),
	BomPart(n: 2, name: "Tile head + light grid", qty: "16", spec: "Black PLA, 42 × 42 × 11.6; rim 1.2, grid walls 1.0 × 8 deep, 5 × 5 cells at 7.8 mm; printed face-down", status: "DECIDED"),
	BomPart(n: 3, name: "LED module 5 × 5", qty: "16 (+2)", spec: "Electropeak ELC-02-099, 25 × WS2812B-5050, 39 mm (listed '3.9' = cm), 7.8 mm pitch, 5 V, A$1.80. Pads/thickness not on the page", status: "DECIDED"),
	BomPart(n: 4, name: "Stem (floor plate + tube + cap)", qty: "16", spec: "Black PLA; 20 × 20 tube, 1.6 wall, 40 long; floor plate 2 presses into the head; end cap with 2 × M2 pilots", status: "DECIDED"),
	BomPart(n: 5, name: "Yoke", qty: "16", spec: "Printed PLA: flange screwed to the end cap + 3 mm blade with an 8.75 × 2.3 slot (pin 2.0); printed on its side", status: "DECIDED"),
	BomPart(n: 6, name: "Crank pin + horn", qty: "16", spec: "Servo horn trimmed to one 11 mm arm; M2 screw or 2 mm steel pin at R = 7.76 mm riding in the slot", status: "DECIDED"),
	BomPart(n: 7, name: "Micro servo", qty: "16", spec: "SG90 (provided; plastic gears, 1.2 kg·cm listed); MG90S metal-gear fallback A$1.80. Swing ±75°, ~0.25 s", status: "DECIDED"),
	BomPart(n: 8, name: "Servo bracket", qty: "16", spec: "Printed: wall with a 23.3 × 12.9 cutout (ears rest on it) + foot, 2 × M3 to the back plate. Ear plane and hole spacing from memory [E]", status: "PROPOSED"),
	BomPart(n: 9, name: "Front guide plate", qty: "1", spec: "3 mm clear acrylic, laser-cut; 20.5 mm square holes, 43 pitch; head rests on it via the pad", status: "DECIDED"),
	BomPart(n: 10, name: "Rear guide plate", qty: "1", spec: "3 mm clear acrylic; same holes, 17.4 mm behind plate 9 (centre to centre)", status: "DECIDED"),
	BomPart(n: 11, name: "Back plate", qty: "1", spec: "3 mm clear acrylic; bracket foot holes, cable slots, ball-head mount at centre; Pico antenna at the top edge", status: "DECIDED"),
	BomPart(n: 12, name: "Front bezel", qty: "1", spec: "3 mm black acrylic, 192 × ~206, one window; holds LDR + sensor holes in the top border", status: "DECIDED"),
	BomPart(n: 13, name: "M3 rods + spacers", qty: "4", spec: "~150 mm threaded rod through the corner holes; printed spacers set every gap", status: "DECIDED"),
	BomPart(n: 14, name: "Soft end-stop pad", qty: "16", spec: "TPU / silicone O-ring, ~1 mm, under each head; the head bottoms out on plate 9", status: "PROPOSED"),
	BomPart(n: 15, name: "PCA9685", qty: "1", spec: "16-channel 12-bit PWM, I2C on GP16 SDA / GP17 SCL, 5 V servo power; A$4.03", status: "DECIDED"),
	BomPart(n: 16, name: "74HCT245", qty: "1 (+4)", spec: "3.3 V → 5 V level shifter for five LED data lines, each through 330 Ω", status: "DECIDED"),
	BomPart(n: 17, name: "Raspberry Pi Pico W", qty: "1", spec: "Wi-Fi + BLE; provided by the school", status: "DECIDED"),
	BomPart(n: 18, name: "Status bar", qty: "3 (+1)", spec: "Electropeak 8-LED straight modules ELC-02-097 (54 × 10 mm if cm), A$0.39 each; 24 LEDs, 20 used, fixed", status: "DECIDED"),
	BomPart(n: 19, name: "Buck modules", qty: "2 (+1)", spec: "XL4016-class 8 A: 20 V → 5 V (LEDs, cap ~5 A) and 16 V → 5 V (servos, Pico), aluminium heatsinks", status: "DECIDED"),
	BomPart(n: 20, name: "Chargers", qty: "3", spec: "20 V 3.33 A and 16 V 3.75 A used; 12 V 4 A spare (own, provided)", status: "DECIDED"),
	BomPart(n: 21, name: "Power board", qty: "1", spec: "Rocker switch, DC sockets, resettable PTC fuses, star ground", status: "DECIDED"),
	BomPart(n: 22, name: "Breadboards", qty: "2", spec: "Pico, level shifter, PCA9685 and sensors (prototype wiring); LED power goes on thick wire, not the rails", status: "DECIDED"),
	BomPart(n: 23, name: "Sensors", qty: "3", spec: "LDR GP26, NTC 10 kΩ GP27 (inside, near the bucks), red status LED on the back", status: "DECIDED"),
	BomPart(n: 24, name: "Stand + ball head", qty: "1", spec: "Mini camera ball head 1/4\"-20 on a printed base; desk and wall use; ~1–1.5 kg", status: "NOT DESIGNED"),
	BomPart(n: 25, name: "Harness", qty: "~50", spec: "JST-XH 3/4-pin pairs; module power + data per tile, servo leads with a service loop for 15 mm of travel", status: "DECIDED"),
]

func statusColor(_ s: String) -> CGColor {
	switch s { case "DECIDED": return cGreen; case "PROPOSED": return cBlue; default: return cOrange }
}

// MARK: Sheet

func drawDesignBlueprint(_ path: String) {
	var box = CGRect(x: 0, y: 0, width: MW, height: MH)
	ctx = CGContext(URL(fileURLWithPath: path) as CFURL, mediaBox: &box,
	                [kCGPDFContextTitle as String: "Dither Board: design blueprint", kCGPDFContextAuthor as String: "omeriadon/board-eng"] as CFDictionary)!
	ctx.beginPDFPage(nil)
	ctx.translateBy(x: 0, y: MH)
	ctx.scaleBy(x: 1, y: -1)
	ctx.setFillColor(cWhite); ctx.fill(CGRect(x: 0, y: 0, width: MW, height: MH))
	blueprintGrid(MW, MH)

	text("Dither Board: design blueprint", 40, 62, size: 44, bold: true)
	text("Mechanism, structure, parts and system on one sheet. 4 × 4 tiles · 5 × 5 LEDs per tile (premade modules) + 20-LED bar = 420 LEDs · 16 servo scotch yokes · Pico W · units mm unless stated · vector, zoom in", 40, 92, size: 15, color: cGray)
	text("Solid line = decided.   Dashed light blue = proposed, not designed.   Amber = risk or open.   Numbered circles match the parts list (panel I).   Figures marked [E] are my estimates; servo outline numbers are from memory of the SG90 datasheet.", 40, 114, size: 13, color: cGray)
	// title block
	rect(2150, 30, 610, 88, fill: nil, stroke: cBlack, lw: 1.4)
	line(2150, 62, 2760, 62, 1, cBlack); line(2150, 90, 2760, 90, 1, cBlack); line(2420, 62, 2420, 118, 1, cBlack)
	text("DITHER BOARD · DESIGN BLUEPRINT", 2165, 52, size: 16, bold: true)
	text("Rev 22 · 2026-11-21", 2165, 82, size: 12); text("Sheet 1 / 1 · A0-style, vector", 2435, 82, size: 12)
	text("Drawn from tile.py rev 22 (K = 5, N = 4)", 2165, 108, size: 12); text("Prototype: nothing tested on hardware", 2435, 108, size: 12, color: cOrange)
	line(40, 126, MW - 40, 126, 1.2, cGray)

	dpFront(40, 140, 640, 620)
	dpSection(700, 140, 1220, 620)
	dpExploded(1940, 140, 820, 620)
	dpCell(40, 775, 640, 400)
	dpDrive(700, 775, 760, 400)
	dpChecks(1480, 775, 680, 400)
	dpOpen(2180, 775, 580, 400)
	dpSystem(40, 1190, 1380, 480)
	dpBOM(1440, 1190, 1320, 480)

	text("hardware/schematics/Mech.swift · generated: swiftc … Mech.swift make_schematics.swift (see make_schematics.swift header)", 40, MH - 10, size: 9, color: cGray)
	ctx.endPDFPage()
	ctx.closePDF()
}

// MARK: A. Front elevation

func dpFront(_ px: CGFloat, _ py: CGFloat, _ pw: CGFloat, _ ph: CGFloat) {
	panel(px, py, pw, ph, "A", "Front elevation", "what you see: bezel, 4 × 4 tiles, status bar")
	let S: CGFloat = 2.2
	let boardW: CGFloat = 192, boardH: CGFloat = 206
	let ox = px + 90, oy = py + 92
	func X(_ mm: CGFloat) -> CGFloat { ox + mm * S }
	func Y(_ mm: CGFloat) -> CGFloat { oy + mm * S }
	rect(X(0), Y(0), boardW * S, boardH * S, fill: rgb(0.02, 0.14, 0.36), stroke: cBlack, lw: 1.6)
	rect(X(10), Y(10), 172 * S, 172 * S, fill: nil, stroke: cBlack, lw: 0.8, dash: [3, 2])
	for r in 0..<4 { for c in 0..<4 {
		let tx = 10 + CGFloat(c) * dPitch + (dPitch - dHead) / 2, ty = 10 + CGFloat(r) * dPitch + (dPitch - dHead) / 2
		rect(X(tx), Y(ty), dHead * S, dHead * S, fill: cLight, stroke: cBlack, lw: 1)
		if r == 1 && c == 1 {
			for i in 0..<dK { for j in 0..<dK {
				let lx = tx + gx(CGFloat(i) + 0.5), ly = ty + gx(CGFloat(j) + 0.5)
				rect(X(lx - 2.5), Y(ly - 2.5), 5 * S, 5 * S, fill: rgb(1, 0.95, 0.6), stroke: nil, bright: true)
			}}
		} else {
			for i in 1..<dK {
				let o = gx(CGFloat(i))
				line(X(tx + o), Y(ty + dRim), X(tx + o), Y(ty + dHead - dRim), 0.3, rgb(1, 1, 1, 0.35))
				line(X(tx + dRim), Y(ty + o), X(tx + dHead - dRim), Y(ty + o), 0.3, rgb(1, 1, 1, 0.35))
			}
		}
	}}
	// status bar: three 8-LED sticks (24 LEDs, 162 mm), 20 used
	rect(X(15), Y(187), 162 * S, 10 * S, fill: nil, stroke: cBlue, lw: 1, dash: [4, 3])
	for i in 0..<24 {
		let cx = X(15 + (CGFloat(i) + 0.5) * 6.75), used = i < 20
		dot(cx, Y(192), 1.6, fill: used ? rgb(1, 0.95, 0.6) : nil, stroke: used ? nil : cGray, lw: 0.6)
	}
	dot(X(96), Y(5), 3, fill: nil, stroke: cBlack, lw: 1.2)
	dot(X(84), Y(5), 2, fill: nil, stroke: cBlack, lw: 1.2)
	for (cx, cy) in [(5, 5), (187, 5), (5, 201), (187, 201)] { dot(X(CGFloat(cx)), Y(CGFloat(cy)), 3.2 * S / 2, fill: cWhite, stroke: cBlack, lw: 1) }
	let ax = X(10 + dPitch + dPitch / 2)
	line(ax, Y(-12), ax, Y(boardH + 12), 1, cOrange, dash: [10, 3, 2, 3])
	text("B", ax - 16, Y(-12) + 4, size: 13, bold: true, color: cOrange); text("B", ax - 16, Y(boardH + 12) + 4, size: 13, bold: true, color: cOrange)
	arrow(ax, Y(-12), ax + 14, Y(-12), cOrange); arrow(ax, Y(boardH + 12), ax + 14, Y(boardH + 12), cOrange)
	dimH(X(0), X(boardW), py + 62, "192")
	dimH(X(10), X(10 + dPitch), py + 78, "pitch 43")
	dimV(X(boardW) + 22, Y(0), Y(boardH), "≈ 206 [E]", labelLeft: false)
	dimV(X(0) - 20, Y(10), Y(182), "172 grid", labelLeft: true)
	balloon(12, px + pw - 50, Y(20), X(boardW - 5), Y(20))
	balloon(2, px + pw - 50, Y(60), X(10 + 2 * dPitch + 20), Y(10 + dPitch + 20))
	balloon(18, px + pw - 50, Y(192), X(168), Y(192))
	balloon(23, px + pw - 50, Y(2), X(96), Y(5))
	balloon(13, px + 44, Y(boardH - 12), X(5), Y(201))
	text("One tile is drawn with its 25 LEDs; the others show the 5 × 5 cell grid only.", px + 24, py + ph - 22, size: 10, color: cGray)
	text("Tile head 42, gap 1. Status bar: 3 sticks of 8, 20 used, fixed; its position under the grid is [E].", px + 24, py + ph - 8, size: 10, color: cGray)
}

// MARK: B. Section through one tile column

func dpSection(_ px: CGFloat, _ py: CGFloat, _ pw: CGFloat, _ ph: CGFloat) {
	panel(px, py, pw, ph, "B", "Section B–B at the stem axis: top tile retracted, lower tile extended 15", "front of the board is on the left; hatched = cut; the half nearer the pin is removed, so horn, pin and yoke blade are not in this cut (see E)")
	let S: CGFloat = 4.5
	let ox = px + 40, oy = py + 150
	func X(_ z: CGFloat) -> CGFloat { ox + (z + 16) * S }
	func Y(_ v: CGFloat) -> CGFloat { oy + (v + 30) * S }
	let c1: CGFloat = 0, c2: CGFloat = dPitch, vTop: CGFloat = -30, vBot: CGFloat = 66
	func plate(_ z0: CGFloat, _ t: CGFloat, hole: CGFloat) {
		var edges: [CGFloat] = [vTop]
		for c in [c1, c2] { edges.append(c - hole / 2); edges.append(c + hole / 2) }
		edges.append(vBot)
		var i = 0
		while i < edges.count { cut(X(z0), Y(edges[i]), t * S, (edges[i + 1] - edges[i]) * S); i += 2 }
	}
	cut(X(-dDiff), Y(vTop), 3 * S, 10 * S, hatch: true, spacing: 2.5)
	plate(zG1, dPlate, hole: dHole)
	plate(zG2, dPlate, hole: dHole)
	cut(X(zBack), Y(vTop), dPlate * S, (vBot - vTop) * S)
	zigzag(X(-14), X(zBack + 3), Y(vBot) - 2)

	func tile(_ c: CGFloat, _ e: CGFloat) {
		func Z(_ z: CGFloat) -> CGFloat { X(z - e) }
		cut(Z(-dDiff), Y(c - dHead / 2), dDiff * S, dHead * S, proposed: true, hatch: false)
		cut(Z(0), Y(c - dHead / 2), dHeadH * S, dRim * S)
		cut(Z(0), Y(c + dHead / 2 - dRim), dHeadH * S, dRim * S)
		for k in 1..<dK { cut(Z(0), Y(c - dInner / 2 + gx(CGFloat(k)) - dRim - dWall / 2 + 0.0), dGridH * S, dWall * S) }
		for k in 0..<dK {
			let v = c - dInner / 2 + gx(CGFloat(k) + 0.5) - dRim
			rect(Z(dGridH - 1.6), Y(v - 2.5), 1.6 * S, 5 * S, fill: rgb(1, 0.95, 0.6, 0.9), stroke: cBlack, lw: 0.6, bright: true)
		}
		cut(Z(dGridH), Y(c - 19.5), dPCB * S, 39 * S, spacing: 2.5)
		cut(Z(dGridH + dPCB), Y(c - dInner / 2 + 0.15), dFloor * S, (dInner / 2 - 0.15 - 3) * S)
		cut(Z(dGridH + dPCB), Y(c + 3), dFloor * S, (dInner / 2 - 0.15 - 3) * S)
		cut(Z(dHeadH), Y(c - 19), dPad * S, 8.75 * S, proposed: true, hatch: false)
		cut(Z(dHeadH), Y(c + 10.25), dPad * S, 8.75 * S, proposed: true, hatch: false)
		cut(Z(dHeadH), Y(c - dStem / 2), dStemLen * S, dStemWall * S)
		cut(Z(dHeadH), Y(c + dStem / 2 - dStemWall), dStemLen * S, dStemWall * S)
		cut(Z(zTail - 2), Y(c - dStem / 2), 2 * S, dStem * S)           // end cap
		cut(Z(zTail), Y(c - 8), 2 * S, 16 * S)                          // yoke flange
	}
	tile(c1, 0)
	tile(c2, dStroke)
	// servos (fixed): the ear plane is in the cut; wall and foot of the bracket lie beyond it
	for c in [c1, c2] {
		rect(X(zFoot0 - 18), Y(c - 17.5), 18 * S, 36 * S, fill: nil, stroke: cGray, lw: 0.8, dash: [3, 2])   // bracket wall, beyond the cut
		rect(X(zFoot0), Y(c - 17.5), 2.5 * S, 36 * S, fill: nil, stroke: cGray, lw: 0.8, dash: [3, 2])        // foot
		cut(X(zServo0), Y(c - 15.74), (zServo1 - zServo0) * S, 32.5 * S, spacing: 3.2, fill: rgb(0.16, 0.38, 0.72))
		rect(X(zServo0), Y(c - 10.89), (zServo1 - zServo0) * S, 22.8 * S, fill: nil, stroke: cBlack, lw: 0.7)
		dot(X(zShaft), Y(c - 4.89), 2.6, fill: cWhite, stroke: cBlack, lw: 0.8)
		text("servo", X(zServo0 + 1.2), Y(c + 9), size: 9, color: cBlack)
	}
	for z in [0, dHeadH, zG1, zG1 + dPlate, zG2, zG2 + dPlate, zTail, zServo0, zServo1, zBack, zBack + dPlate] as [CGFloat] {
		ext(X(z), Y(vTop) - 4, X(z), Y(vTop) - 34)
	}
	let dy = Y(vTop) - 38
	dimH(X(0), X(dHeadH), dy, "11.6", size: 8)
	dimH(X(zG1), X(zG1 + dPlate), dy, "3", size: 8)
	dimH(X(zG2), X(zG2 + dPlate), dy, "3", size: 8)
	dimH(X(zG1 + dPlate), X(zG2), dy - 16, "14.4 gap", size: 8)
	dimH(X(dHeadH), X(zTail), dy - 32, "stem 40", size: 8)
	dimH(X(zServo0), X(zServo1), dy - 16, "12.4", size: 8)
	dimH(X(zBack), X(zBack + dPlate), dy - 16, "3", size: 8)
	dimH(X(0), X(zBack + dPlate), dy - 48, "front of head to back plate 78.1 (+0.8 diffuser) retracted · 94 with a tile out", size: 9)
	dimH(X(-dStroke), X(0), Y(vBot) + 14, "stroke 15", c: cOrange)
	let bx = X(zBack + dPlate) + 70
	balloon(12, bx, Y(-25), X(0.5), Y(-25))
	balloon(1, X(-12), Y(-14), X(-0.4), Y(-8))
	balloon(2, X(4), Y(-24), X(4), Y(-19.2))
	balloon(3, X(9), Y(-24), X(7.5), Y(-15.6))
	balloon(4, X(30), Y(-14.5), X(30), Y(-9.2))
	balloon(9, X(zG1 + 1.5), Y(-27), X(zG1 + 1.5), Y(-20))
	balloon(10, X(zG2 + 1.5), Y(-27), X(zG2 + 1.5), Y(-20))
	balloon(14, X(5), Y(27), X(12.1), Y(19.5))
	balloon(5, X(zTail + 1), Y(-18), X(zTail + 1), Y(-7))
	balloon(7, X(zShaft), Y(-24), X(zShaft), Y(-14))
	balloon(8, X(zFoot0 - 8), Y(-24), X(zFoot0 - 8), Y(-17.5))
	balloon(11, bx, Y(58), X(zBack + 1.5), Y(58))
	let lx = X(zBack + dPlate) + 24
	var ly = py + 215
	ly = paragraph("Not in this cut: the yoke blade and pin are 12–16 mm to the −x side of the axis; the bracket wall and foot (grey dashed) are 0.5 mm to the +x side. The servo's shaft points sideways, so only its ear plane is cut here.", lx, ly, width: 440, size: 11, color: cOrange)
	ly += 8
	for l in ["Sweep check in tile.py assembly(): 9 stroke positions, head + stem + yoke against servo, horn, bracket, both guide plates and the back plate: 0.000 mm³ overlap.",
	          "Retracted, the yoke flange back face (z 53.6) is 1.0 mm from the bracket wall front (z 54.6).",
	          "Extended, the stem tail (z 36.6) still sits 3.6 mm behind rear plate 10.",
	          "The servo case is 5.8 mm clear of the stem end cap when retracted (case front z 57.4, cap z 51.6).",
	          "The yoke blade ends at z 74.3, 0.8 mm short of the back plate."] {
		ly = paragraph(l, lx, ly, width: 440, size: 11, color: cBlack) + 6
	}
}

// MARK: C. Exploded view

func dpExploded(_ px: CGFloat, _ py: CGFloat, _ pw: CGFloat, _ ph: CGFloat) {
	panel(px, py, pw, ph, "C", "Exploded view of one tile and its drive", "front-to-back order; plates shown as a one-cell patch; oblique projection, not to scale in depth")
	let S: CGFloat = 2.4
	let dxz: CGFloat = 0.5, dyz: CGFloat = -0.32
	func blk(_ cx: CGFloat, _ cy: CGFloat, _ w: CGFloat, _ h: CGFloat, _ d: CGFloat, fill: CGColor, dashed: Bool = false, inner: ((CGFloat, CGFloat, CGFloat, CGFloat) -> Void)? = nil) {
		let x0 = cx - w * S / 2, y0 = cy - h * S / 2, W = w * S, H = h * S
		let ox = d * S * dxz, oy = d * S * dyz
		ctx.saveGState()
		if dashed { ctx.setLineDash(phase: 0, lengths: [4, 3]) }
		ctx.setLineWidth(1); ctx.setLineJoin(.round)
		ctx.setFillColor(rgb(0.2, 0.45, 0.8)); ctx.setStrokeColor(dashed ? cBlue : cBlack)
		ctx.move(to: CGPoint(x: x0, y: y0)); ctx.addLine(to: CGPoint(x: x0 + ox, y: y0 + oy)); ctx.addLine(to: CGPoint(x: x0 + W + ox, y: y0 + oy)); ctx.addLine(to: CGPoint(x: x0 + W, y: y0)); ctx.closePath(); ctx.drawPath(using: .fillStroke)
		ctx.setFillColor(rgb(0.13, 0.36, 0.7))
		ctx.move(to: CGPoint(x: x0 + W, y: y0)); ctx.addLine(to: CGPoint(x: x0 + W + ox, y: y0 + oy)); ctx.addLine(to: CGPoint(x: x0 + W + ox, y: y0 + H + oy)); ctx.addLine(to: CGPoint(x: x0 + W, y: y0 + H)); ctx.closePath(); ctx.drawPath(using: .fillStroke)
		ctx.setFillColor(fill)
		ctx.addRect(CGRect(x: x0, y: y0, width: W, height: H)); ctx.drawPath(using: .fillStroke)
		ctx.restoreGState()
		inner?(x0, y0, W, H)
	}
	let midY = py + 520
	let stepX: CGFloat = 52, stepY: CGFloat = -30
	struct E { let n: Int; let w: CGFloat; let h: CGFloat; let d: CGFloat; let proposed: Bool; let kind: Int }
	// back to front
	let parts: [E] = [
		E(n: 11, w: 56, h: 56, d: 3, proposed: false, kind: 0),    // back plate patch (no hole)
		E(n: 8, w: 22, h: 36, d: 20, proposed: true, kind: 12),    // bracket
		E(n: 7, w: 12.4, h: 22.8, d: 22.8, proposed: false, kind: 13), // servo
		E(n: 6, w: 3, h: 3, d: 9, proposed: false, kind: 14),      // pin
		E(n: 5, w: 16, h: 17, d: 22.7, proposed: false, kind: 15), // yoke
		E(n: 10, w: 56, h: 56, d: 3, proposed: false, kind: 1),    // rear guide
		E(n: 9, w: 56, h: 56, d: 3, proposed: false, kind: 1),     // front guide
		E(n: 14, w: 36, h: 36, d: 1, proposed: true, kind: 7),     // pad
		E(n: 4, w: 20, h: 20, d: 40, proposed: false, kind: 8),    // stem
		E(n: 3, w: 39, h: 39, d: 1.6, proposed: false, kind: 9),   // module
		E(n: 2, w: 42, h: 42, d: 11.6, proposed: false, kind: 10), // head
		E(n: 1, w: 42, h: 42, d: 0.8, proposed: true, kind: 11),   // diffuser
	]
	let n = CGFloat(parts.count)
	let off: [Int: (CGFloat, CGFloat)] = [8: (-10, 118), 7: (110, 150), 6: (110, 230), 5: (60, 160)]
	for (i, p) in parts.enumerated() {
		let k = CGFloat(i)
		let fromFront = n - 1 - k
		let cxp = px + 60 + fromFront * stepX + (off[p.n]?.0 ?? 0)
		let cyp = midY + fromFront * stepY + (off[p.n]?.1 ?? 0)
		blk(cxp, cyp, p.w, p.h, p.d, fill: rgb(0.1, 0.33, 0.68), dashed: p.proposed) { x0, y0, W, H in
			switch p.kind {
			case 1:
				let hw = 20.5 * S
				rect(x0 + W / 2 - hw / 2, y0 + H / 2 - hw / 2, hw, hw, fill: cWhite, stroke: cBlack, lw: 0.8)
			case 8:
				rect(x0 + 5, y0 + 5, W - 10, H - 10, fill: cWhite, stroke: cBlack, lw: 0.8)
			case 9, 10:
				if p.kind == 10 {
					for i in 1..<dK {
						let o = gx(CGFloat(i)) * S
						line(x0 + o, y0 + dRim * S, x0 + o, y0 + H - dRim * S, 0.5, cBlack)
						line(x0 + dRim * S, y0 + o, x0 + W - dRim * S, y0 + o, 0.5, cBlack)
					}
				} else {
					for i in 0..<dK { for j in 0..<dK {
						rect(x0 + (3.9 + CGFloat(i) * dCell - 2.5) * S, y0 + (3.9 + CGFloat(j) * dCell - 2.5) * S, 5 * S, 5 * S, fill: rgb(1, 0.95, 0.6), stroke: nil, bright: true)
					}}
				}
			case 13:
				dot(x0 + W / 2, y0 + 6 * S / 2.4, 3, fill: cWhite, stroke: cBlack, lw: 0.6)
			case 15:
				rect(x0 + W / 2 - 1.2 * S, y0 + 4 * S, 2.3 * S, 9 * S, fill: cWhite, stroke: cBlack, lw: 0.8)
			case 12:
				rect(x0 + 4, y0 + H / 2 - 12.9 * S / 2, W - 8, 12.9 * S, fill: cWhite, stroke: cBlack, lw: 0.8)
			default: break
			}
		}
		let up = (Int(k) % 2 == 0)
		var bxp = cxp + (up ? 4 : -6), byp = cyp + (up ? -(p.h * S / 2 + 56) : (p.h * S / 2 + 44))
		if p.n == 6 { bxp = cxp + 26; byp = cyp + 22 }
		if p.n == 7 { bxp = cxp + 46; byp = cyp + 36 }
		if p.n == 5 { bxp = cxp - 40; byp = cyp + 40 }
		if p.n == 8 { bxp = cxp + 26; byp = cyp + 62 }
		balloon(p.n, bxp, byp, cxp, cyp + (byp > cyp ? p.h * S / 2 * 0.4 : -p.h * S / 2 * 0.4))
	}
	text("Assembly order: print head (2) face-down, drop the LED module (3) in, press the stem (4) into the head,", px + 24, py + 80, size: 11, color: cGray)
	text("glue the diffuser (1) on, fit the pad (14), slide the stem through plates 9 and 10, screw the yoke (5) to the", px + 24, py + 95, size: 11, color: cGray)
	text("end cap, seat the servo (7) in its bracket (8) with the trimmed horn and pin (6) in the slot, screw the bracket to plate 11.", px + 24, py + 110, size: 11, color: cGray)
	text("Front of the board is bottom left; the back of the board is top right.", px + 24, py + 125, size: 11, color: cGray)
}

// MARK: D. The 5 x 5 cell

func dpCell(_ px: CGFloat, _ py: CGFloat, _ pw: CGFloat, _ ph: CGFloat) {
	panel(px, py, pw, ph, "D", "Tile head, front view, 5 × 5 LEDs", "tile.py rev 22: premade 39 mm module, LED pitch 7.8 mm = cell pitch; module centred in the 39.6 mm rim opening")
	let S: CGFloat = 5.6
	let ox = px + 36, oy = py + 76
	rect(ox, oy, dHead * S, dHead * S, fill: nil, stroke: cBlack, lw: 1.6)
	rect(ox + dRim * S, oy + dRim * S, dInner * S, dInner * S, fill: nil, stroke: cBlack, lw: 0.8)
	for i in 1..<dK {
		let o = gx(CGFloat(i)) * S
		rect(ox + o - dWall * S / 2, oy + dRim * S, dWall * S, dInner * S, fill: rgb(0.2, 0.45, 0.8), stroke: nil)
		rect(ox + dRim * S, oy + o - dWall * S / 2, dInner * S, dWall * S, fill: rgb(0.2, 0.45, 0.8), stroke: nil)
	}
	for i in 0..<dK { for j in 0..<dK {
		let cx = ox + gx(CGFloat(i) + 0.5) * S, cy = oy + gx(CGFloat(j) + 0.5) * S
		rect(cx - 2.5 * S, cy - 2.5 * S, 5 * S, 5 * S, fill: rgb(1, 0.95, 0.6, 0.9), stroke: cBlack, lw: 0.5, bright: true)
	}}
	dimH(ox, ox + dHead * S, oy - 14, "42")
	dimV(ox - 14, oy + gx(0) * S, oy + gx(1) * S, "7.8", size: 8, labelLeft: true)
	let zs: CGFloat = 24, zx = px + 400, zy = py + 110
	text("ONE CELL ×24", zx, zy - 26, size: 11, bold: true)
	rect(zx, zy, dCell * zs, dCell * zs, fill: nil, stroke: cGray, lw: 0.8, dash: [4, 3])
	let wallC = rgb(0.2, 0.45, 0.8)
	rect(zx - dWall * zs / 2, zy - dWall * zs / 2, dCell * zs + dWall * zs, dWall * zs / 2, fill: wallC, stroke: nil)
	rect(zx - dWall * zs / 2, zy + dCell * zs, dCell * zs + dWall * zs, dWall * zs / 2, fill: wallC, stroke: nil)
	rect(zx - dWall * zs / 2, zy, dWall * zs / 2, dCell * zs, fill: wallC, stroke: nil)
	rect(zx + dCell * zs, zy, dWall * zs / 2, dCell * zs, fill: wallC, stroke: nil)
	let ledW = 5.0 * zs
	rect(zx + dCell * zs / 2 - ledW / 2, zy + dCell * zs / 2 - ledW / 2, ledW, ledW, fill: rgb(1, 0.95, 0.6, 0.85), stroke: cBlack, lw: 1, bright: true)
	let open = (dCell - dWall) * zs
	rect(zx + dCell * zs / 2 - open / 2, zy + dCell * zs / 2 - open / 2, open, open, fill: nil, stroke: cGreen, lw: 1.2, dash: [3, 2])
	dimH(zx, zx + dCell * zs, zy + dCell * zs + 34, "pitch 7.8")
	dimH(zx + dCell * zs / 2 - open / 2, zx + dCell * zs / 2 + open / 2, zy + dCell * zs + 18, "opening 6.8", c: cGreen)
	text("LED body 5.0", zx + dCell * zs / 2, zy + dCell * zs / 2 + 4, size: 10, color: cBlack, align: 1)
	var ty = py + 340
	text("CLASH RESOLVED", px + 24, ty, size: 13, bold: true, color: cGreen); ty += 16
	_ = paragraph("The 6 × 6 design left 0.035 mm a side around a 5.0 mm LED. A 7.8 mm cell with 1.0 mm walls opens to 6.8 mm: 0.9 mm a side. The cost is a bigger tile (head 42, pitch 43, board 192) and LEDs 7.8 mm apart inside a tile but 11.8 mm across a tile gap, so the picture has slightly wider seams.", px + 24, ty, width: pw - 48, size: 10.5, color: cBlack)
}

// MARK: E. Drive chain and force

func dpDrive(_ px: CGFloat, _ py: CGFloat, _ pw: CGFloat, _ ph: CGFloat) {
	panel(px, py, pw, ph, "E", "Servo scotch-yoke drive and force check", "rotary to linear: pin on the horn rides in a slot in the yoke on the stem; view on the right is along the servo shaft")
	let steps = ["Pico I2C\nGP16/17", "PCA9685\n50 Hz PWM", "SG90\nservo", "horn + pin\nR 7.76", "yoke slot\n8.75 × 2.3", "stem →\ntile"]
	let bw: CGFloat = 100, gap: CGFloat = 20
	let bx0 = px + 18, by = py + 64
	for (i, s) in steps.enumerated() {
		let x = bx0 + CGFloat(i) * (bw + gap)
		rect(x, by, bw, 40, fill: cLight, stroke: cBlack, lw: 1, r: 3)
		let ls = s.split(separator: "\n").map(String.init)
		for (j, l) in ls.enumerated() { text(l, x + bw / 2, by + 17 + CGFloat(j) * 13, size: 10, bold: j == 0, align: 1) }
		if i < steps.count - 1 { arrow(x + bw, by + 20, x + bw + gap, by + 20, cBlack) }
	}
	// crank view along the shaft: z to the right (back), y down
	let S: CGFloat = 10
	let sx = px + 560, sy = py + 215
	text("VIEW ALONG THE SERVO SHAFT", sx, py + 120, size: 10.5, bold: true, align: 1)
	let stemAxisY = sy + 4.89 * S
	line(sx - 120, stemAxisY, sx + 120, stemAxisY, 0.7, cBlue, dash: [10, 3, 2, 3])
	text("stem axis", sx - 118, stemAxisY - 4, size: 9, color: cBlue)
	let circle = CGRect(x: sx - dR * S, y: sy - dR * S, width: 2 * dR * S, height: 2 * dR * S)
	ctx.saveGState(); ctx.setStrokeColor(cGray); ctx.setLineWidth(0.8); ctx.setLineDash(phase: 0, lengths: [4, 3]); ctx.strokeEllipse(in: circle); ctx.restoreGState()
	dot(sx, sy, 3, fill: cWhite, stroke: cBlack, lw: 1)
	for (p, theta, col) in [(0.0, 75.0, cOrange), (7.5, 0.0, cWhite), (15.0, -75.0, cGreen)] as [(CGFloat, Double, CGColor)] {
		let th = CGFloat(theta) * .pi / 180
		let pz = dR * sin(th), py2 = dR * cos(th)
		// slot (moves with the stem): centred on the pin z, y range ±4.375 about the stem axis
		let slotW = 2.3 * S, slotH = 8.75 * S
		rect(sx + pz * S - slotW / 2, stemAxisY - slotH / 2, slotW, slotH, fill: nil, stroke: col, lw: 1.2)
		line(sx, sy, sx + pz * S, sy + py2 * S, 1.6, col)
		dot(sx + pz * S, sy + py2 * S, 1.1 * S / 2 + 1, fill: col, stroke: cBlack, lw: 0.6)
		_ = p
	}
	let ly0 = stemAxisY + 4.375 * S + 14
	text("retracted", sx + 7.5 * S, ly0, size: 9, color: cOrange, align: 1); text("mid", sx, ly0, size: 9, align: 1); text("extended", sx - 7.5 * S, ly0, size: 9, color: cGreen, align: 1)
	text("R 7.76", sx + 8, sy - 8, size: 9)
	text("stroke 15 = 2 R sin 75° · pin y ±2.88 of the slot's ±4.4", sx, ly0 + 18, size: 9, color: cGray, align: 1)
	let lines = [
		"PCA9685 gives the servo a 50 Hz pulse in 4.9 µs counts: 150° of swing ≈ 340 counts, so about 0.06 mm of tile travel per count at worst, against 10 height levels needed.",
		"Crank R = 7.76 mm, swing ±75° of the servo's ±90°: tile position = R sin θ, stroke 2 R sin 75° = 15.0 mm. Ends are slow and precise, the middle fast; 150° at 0.1 s per 60° ≈ 0.25 s unloaded.",
		"Torque needed: tile ≈ 30 g [E] (0.3 N) + guide friction ≈ 0.3 N [E] = 0.6 N × 7.76 mm = 4.7 mN·m = 0.047 kg·cm, against 1.2 kg·cm listed for the SG90 at 4.8 V: about 25×. A servo's torque is the same at every angle, so using 150° of 180° costs nothing.",
		"Force at the pin if the servo stalls: 1.2 kg·cm / 7.76 mm ≈ 15 N, 25× the load.",
		"Holding unpowered: the yoke lever is R cos θ, 2.0 mm at the ends and 7.76 mm mid-travel, so the tile's weight loads the horn with at most 0.02 kg·cm. A servo gearbox resists back-driving far more, so it holds with the pulse off (stop the pulse to remove hold hum).",
	]
	var y = py + 124
	for l in lines { y = paragraph(l, px + 18, y, width: 440, size: 10.5) + 4 }
	y = py + ph - 52
	text("MARGIN", px + 18, y, size: 12, bold: true, color: cGreen)
	_ = paragraph("About 25× on torque even derated for a weak supply. Not measured: borrowed listing figures (SG90 1.2 kg·cm) and an estimated tile mass. The 3-tile pilot should weigh a finished tile and pull it with a scale.", px + 18, y + 14, width: pw - 36, size: 10)
}

// MARK: F. Checks

func dpChecks(_ px: CGFloat, _ py: CGFloat, _ pw: CGFloat, _ ph: CGFloat) {
	panel(px, py, pw, ph, "F", "Does the dimension chain close?", "worked from the section (panel B) and tile.py assembly(); estimates marked [E]")
	let rows: [(String, String, String, Int)] = [
		("Pin stays in slot", "slot 8.75 long, pin travels y ±2.88 about the slot centre: 0.5 mm margin at the ends of travel", "OK, 0.5 mm", 0),
		("Stroke sweep", "9 positions, moving set against servo, horn, pin, bracket, plates, back plate", "0.000 mm³", 0),
		("Stem in plate 10", "extended: tube tip z 36.6, plate 10 back face z 33", "OK, 3.6 mm", 0),
		("Servo vs stem tail", "retracted: servo case front z 57.4, end cap z 51.6, flange z 53.6, bracket wall z 54.6", "OK, 1.0 mm", 0),
		("Guide wobble, 0.25 mm", "plate centres 17.4 mm apart; head front 29 mm out when extended: ±(29 × 0.5 / 17.4 + 0.25) ≈ ±1.1 mm", "MARGINAL vs 1.0 gap", 1),
		("Guide wobble, 0.15 mm", "±(29 × 0.3 / 17.4 + 0.15) ≈ ±0.65 mm; set by the clearance coupon", "OK if achieved", 0),
		("Torque vs weight", "tile ≈ 30 g [E]: head 6 g, stem 10 g, yoke 2 g, module ≈ 8 g, diffuser, wire. 0.047 kg·cm needed against 1.2 listed", "OK, ≈ 25×", 0),
		("Cell clearance", "6.8 mm opening − 5.0 mm LED = 0.9 mm a side", "OK", 0),
		("Servo outline", "case 22.8 × 12.4, ear plane 5.5 below the top face, hole spacing 27.8: all from memory of the SG90 datasheet", "MEASURE the servo", 1),
		("Depth", "−0.8 front to 78.1 back = 78.9 mm retracted; ≈ 94 mm with a tile out (was 89.8 / 105)", "7.9 to 9.4 cm", 0),
	]
	let wC: CGFloat = 130, wR: CGFloat = 400, wV: CGFloat = 130
	let x0 = px + 10
	var y = py + 62
	rect(x0, y - 11, wC + wR + wV, 17, fill: cLight, stroke: nil)
	text("Check", x0 + 4, y + 2, size: 10, bold: true); text("Calculation", x0 + wC + 4, y + 2, size: 10, bold: true); text("Result", x0 + wC + wR + 4, y + 2, size: 10, bold: true)
	y += 20
	for (c, calc, res, lvl) in rows {
		let lines = wrap(calc, width: wR - 10, size: 10)
		let h = CGFloat(lines.count) * 12.5 + 8
		text(c, x0 + 4, y + 1, size: 10, bold: true)
		var ly = y + 1
		for l in lines { text(l, x0 + wC + 4, ly, size: 10); ly += 12.5 }
		text(res, x0 + wC + wR + 4, y + 1, size: 10, bold: true, color: lvl == 0 ? cGreen : (lvl == 1 ? cOrange : cRed))
		line(x0, y + h - 9, x0 + wC + wR + wV, y + h - 9, 0.3, rgb(1, 1, 1, 0.3))
		y += h
	}
}

// MARK: G. Open items

func dpOpen(_ px: CGFloat, _ py: CGFloat, _ pw: CGFloat, _ ph: CGFloat) {
	panel(px, py, pw, ph, "G", "Open and unmeasured", "dashed in panels B and C, or flagged [E]")
	var y = py + 70
	let items = [
		"Servo bracket (8): ear plane and hole spacing are from memory; print the cutout wall once and fit the real servo before printing 16.",
		"LED module (3): pad layout, board thickness and the 39 mm size (listed '3.9') are not on the page; ask the seller or check on arrival. Chains of 25 need power and data wires per module.",
		"Yoke slot wear: PLA slot, steel pin; a dab of grease. Check after 10,000 cycles.",
		"Diffuser (1): a printed translucent sheet, thickness and evenness untested; brightness figures (≈ 1,750 nits full-screen at 5 A) assume 25 % transmission.",
		"Horn: trimmed to one arm; pin hole at R = 7.76 mm drilled or the pin pressed into a printed collar.",
		"Homing: none needed, servo angles are absolute; calibrate two end angles per tile in the app.",
		"Wire loom: module power + data and servo lead per tile with a service loop for 15 mm of travel; routing through the floor plate hole is not drawn.",
		"Stand and ball-head mount (24), back plate cut file, M3 rod spacers (13).",
	]
	for s in items { y = paragraph("• " + s, px + 18, y, width: pw - 36, size: 11) + 5 }
}

// MARK: H. System block diagram

func dpSystem(_ px: CGFloat, _ py: CGFloat, _ pw: CGFloat, _ ph: CGFloat) {
	panel(px, py, pw, ph, "H", "System block diagram", "details and pin numbers: dither-board-blueprint.pdf and dither-board-schematics.pdf (their wiring still shows the old stepper plan)")
	func b(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ t1: String, _ t2: String = "", fill: CGColor = cLight, num: Int? = nil, dashed: Bool = false) {
		rect(px + x, py + y, w, h, fill: fill, stroke: dashed ? cGray : cBlack, lw: 1.1, r: 4, dash: dashed ? [4, 3] : [])
		text(t1, px + x + w / 2, py + y + (t2.isEmpty ? h / 2 + 4 : 16), size: 10.5, bold: true, align: 1)
		if !t2.isEmpty { text(t2, px + x + w / 2, py + y + 30, size: 9, align: 1) }
		if let n = num { dot(px + x + w - 2, py + y + 2, 8, fill: cWhite, stroke: cBlack, lw: 0.8); text("\(n)", px + x + w - 2, py + y + 5.5, size: 8, bold: true, align: 1) }
	}
	func a(_ x1: CGFloat, _ y1: CGFloat, _ x2: CGFloat, _ y2: CGFloat, _ c: CGColor) { arrow(px + x1, py + y1, px + x2, py + y2, c, w: 1.6) }
	func l(_ x1: CGFloat, _ y1: CGFloat, _ x2: CGFloat, _ y2: CGFloat, _ c: CGColor) { line(px + x1, py + y1, px + x2, py + y2, 1.6, c) }
	b(20, 70, 120, 40, "Charger C", "20 V 3.33 A", num: 20)
	b(20, 180, 120, 40, "Charger B", "16 V 3.75 A", num: 20)
	b(20, 290, 120, 40, "Charger A", "12 V 4 A, spare", num: 20, dashed: true)
	b(190, 110, 110, 130, "Power board", "switch · fuses", num: 21)
	b(350, 90, 110, 60, "BUCK 20→5 V", "LEDs, cap ~5 A", num: 19)
	b(350, 200, 110, 60, "BUCK 16→5 V", "servos + logic", num: 19)
	l(140, 90, 190, 135, cRed); l(140, 200, 190, 215, cOrange)
	a(300, 120, 350, 120, cRed); a(300, 230, 350, 230, cOrange)
	b(520, 90, 130, 50, "5 V LED rail", "thick wire, not the breadboard", fill: rgb(1, 0.95, 0.9))
	b(520, 200, 130, 50, "5 V servo + logic rail", "servos ≈ 2 A, Pico, 245", fill: rgb(1, 0.95, 0.9))
	a(460, 120, 520, 115, cRed); a(460, 230, 520, 225, cOrange)
	b(720, 270, 120, 56, "Pico W", "Wi-Fi + BLE", fill: rgb(0.88, 0.96, 0.9), num: 17)
	l(585, 250, 585, 298, cOrange); a(585, 298, 720, 298, cOrange)
	b(720, 380, 120, 40, "Phone / Mac app", "BLE or Wi-Fi")
	arrow(px + 780, py + 380, px + 780, py + 326, cBlue, w: 1.4); arrow(px + 770, py + 326, px + 770, py + 380, cBlue, w: 1.4)
	b(720, 190, 120, 44, "LDR + NTC", "ADC GP26 / GP27", num: 23)
	arrow(px + 780, py + 234, px + 780, py + 270, cBlue, w: 1.4)
	// LED path
	b(920, 120, 120, 44, "74HCT245", "3V3 → 5 V · 5 lines", num: 16)
	b(1090, 100, 250, 84, "LED modules + bar", "16 × 25 + 20 = 420 WS2812B, 4 rows + bar", num: 3)
	a(840, 285, 920, 150, cBlue); a(1040, 142, 1090, 142, cGreen)
	a(650, 115, 1090, 112, cRed)
	// servo path
	b(920, 270, 110, 56, "PCA9685", "I2C GP16 / GP17", num: 15)
	b(1075, 270, 110, 56, "Servo ×16", "SG90, PWM", num: 7)
	b(1230, 270, 110, 56, "Scotch yoke", "R 7.76, ±75°", num: 6)
	a(840, 298, 920, 298, cBlue); a(1030, 298, 1075, 298, cBlue); a(1185, 298, 1230, 298, cBlue)
	line(px + 585, py + 352, px + 1130, py + 352, 1.6, cOrange); line(px + 585, py + 298, px + 585, py + 352, 1.6, cOrange); arrow(px + 1130, py + 352, px + 1130, py + 326, cOrange, w: 1.6)
	b(1230, 380, 110, 40, "Stem → tile", "15 mm stroke", fill: cLight)
	a(1285, 326, 1285, 380, cBlack)
	text("Line colours: red = 5 V LED power, orange = 5 V servo / logic, blue = logic, green = LED data. Charger A (12 V) is not used.", px + 20, py + ph - 14, size: 10, color: cGray)
}

// MARK: I. Parts list

func dpBOM(_ px: CGFloat, _ py: CGFloat, _ pw: CGFloat, _ ph: CGFloat) {
	panel(px, py, pw, ph, "I", "Parts list", "numbers match the balloons; status colours: green decided, blue proposed, amber not designed")
	let widths: [CGFloat] = [28, 190, 60, 820, 150]
	let rowH: CGFloat = 15.2
	let x0 = px + 16
	var y = py + 56
	let head = ["#", "Part", "Qty", "Spec / note", "Status"]
	rect(x0, y - 10, widths.reduce(0, +), 15, fill: cLight, stroke: nil)
	var xx = x0
	for (i, h) in head.enumerated() { text(h, xx + 3, y + 1, size: 9.5, bold: true); xx += widths[i] }
	y += 14
	for p in bom {
		xx = x0
		let cells = ["\(p.n)", p.name, p.qty, p.spec, p.status]
		for (i, c) in cells.enumerated() {
			let color: CGColor = i == 4 ? statusColor(p.status) : cBlack
			var s = c
			let maxW = widths[i] - 6
			while measure(s, size: 10, bold: i == 4) > maxW && s.count > 4 { s.removeLast() }
			if s != c { s += "…" }
			text(s, xx + 3, y, size: 10, bold: i == 4 || i == 0, color: color)
			xx += widths[i]
		}
		line(x0, y + 3.5, x0 + widths.reduce(0, +), y + 3.5, 0.3, rgb(1, 1, 1, 0.3))
		y += rowH
	}
}
