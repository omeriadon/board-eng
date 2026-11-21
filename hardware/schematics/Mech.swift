// The physical design blueprint: one sheet, blue paper, white ink, SF Pro.
// Front elevation, section through one tile column (one tile retracted, one extended), exploded view, the
// 6 x 6 LED cell, the drive chain and force check, dimension-chain checks, open items, system block diagram and the parts list.
// Every dimension comes from hardware/cad/tile.py (HEAD 38.8, STEM 20, STROKE 15, ...) with K = 6 (the file itself is still K = 4, N = 5).
// Line styles: solid = decided; dashed light blue = proposed, not designed yet; amber = risk or open.
import CoreGraphics
import Foundation

let MW: CGFloat = 2800, MH: CGFloat = 1700

// MARK: Design numbers (mm)
let dN = 4, dK = 6
let dPitch: CGFloat = 40, dHead: CGFloat = 38.8, dRim: CGFloat = 1.2, dWall: CGFloat = 1.0
let dGridH: CGFloat = 8, dPCB: CGFloat = 1.6, dFloor: CGFloat = 2, dHeadH: CGFloat = 11.6, dDiff: CGFloat = 0.8
let dInner: CGFloat = dHead - 2 * dRim              // 36.4
let dCell: CGFloat = dInner / CGFloat(dK)           // 6.07
let dStem: CGFloat = 20, dStemWall: CGFloat = 1.6, dStemLen: CGFloat = 40, dHole: CGFloat = 20.5
let dStroke: CGFloat = 15, dPad: CGFloat = 1.0
let zG1: CGFloat = 12.6, zG2: CGFloat = 28, dPlate: CGFloat = 3     // guide plates (front faces)
let zCarrier: CGFloat = 4                                            // nut carrier plug thickness
let zMotorFace: CGFloat = 54.4, dMotorLen: CGFloat = 8.3, dScrew: CGFloat = 28
let zBack: CGFloat = 86                                              // back plate front face
let hatchAlpha: CGFloat = 0.5

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
	BomPart(n: 1, name: "Diffuser sheet", qty: "16", spec: "3D-printed translucent sheet, ~0.8 mm (thickness not tested), glued flush on the head face", status: "PROPOSED"),
	BomPart(n: 2, name: "Tile head + light grid", qty: "16", spec: "Black PLA, 38.8 × 38.8 × 11.6; rim 1.2, grid walls 1.0 × 8 deep, 6 × 6 cells; printed face-down", status: "DECIDED"),
	BomPart(n: 3, name: "LED carrier (open)", qty: "16", spec: "Custom tile PCB REMOVED (rev 19). Proposed: premade 4 × 4 WS2812B module, 30 × 30 mm, 7.5 mm pitch, 5 V (K = 4); K = 6 cell clash then disappears. Not confirmed", status: "PROPOSED"),
	BomPart(n: 4, name: "Stem (floor plate + tube)", qty: "16", spec: "Black PLA; 20 × 20 square tube, 1.6 wall, 40 long; floor plate 2 thick presses into the head; V-notches every 1.5 mm", status: "DECIDED"),
	BomPart(n: 5, name: "Nut carrier", qty: "16", spec: "Printed plug at the tube tip, 4 thick; holds the M2 nut; M2 clearance hole for the screw", status: "NOT DESIGNED"),
	BomPart(n: 6, name: "M2 brass nut", qty: "16", spec: "Pitch unverified (M2 × 0.4 assumed); test on a pilot motor", status: "DECIDED"),
	BomPart(n: 7, name: "Stepper motor, 8 mm", qty: "16 (+2)", spec: "SINONING 2-phase 4-wire, bare 2 mm screw, 28 mm long, no nut; 20 steps/rev. Thrust 30 gf and 16.8–40 Ω are from OTHER motors' listings", status: "DECIDED"),
	BomPart(n: 8, name: "Front guide plate", qty: "1", spec: "3 mm clear acrylic, laser-cut; 20.5 mm square holes, 40 pitch; head rests on it via the pad", status: "DECIDED"),
	BomPart(n: 9, name: "Rear guide plate", qty: "1", spec: "3 mm clear acrylic; same holes; detent flexure cut into it (not designed)", status: "DECIDED"),
	BomPart(n: 10, name: "Motor plate", qty: "1", spec: "3 mm clear acrylic; 8.1 mm motor holes; motor retention not designed (clamp or glue)", status: "NOT DESIGNED"),
	BomPart(n: 11, name: "Front bezel", qty: "1", spec: "3 mm black acrylic, 180 × ~194, one window; holds LDR + sensor holes in the top border", status: "DECIDED"),
	BomPart(n: 12, name: "Back plate", qty: "1", spec: "3 mm clear acrylic; ball-head mount at centre; Pico antenna at the top edge", status: "DECIDED"),
	BomPart(n: 13, name: "M3 rods + spacers", qty: "4", spec: "~150 mm threaded rod through the corner holes; printed spacers set every gap", status: "DECIDED"),
	BomPart(n: 14, name: "Soft end-stop pad", qty: "16", spec: "TPU / silicone O-ring, ~1 mm, under each head; the head bottoms out on plate 8", status: "PROPOSED"),
	BomPart(n: 15, name: "Motor driver MX1508", qty: "16 (+2)", spec: "Dual H-bridge, 2–10 V, 1.5 A per channel; 4 inputs per motor", status: "DECIDED"),
	BomPart(n: 16, name: "74HC595", qty: "8 (+2)", spec: "Chained shift registers on 3V3, 2 motors each (4 bits per motor)", status: "DECIDED"),
	BomPart(n: 17, name: "74HCT245", qty: "1 (+4)", spec: "3.3 V → 5 V level shifter for five LED data lines, each through 330 Ω", status: "DECIDED"),
	BomPart(n: 18, name: "Raspberry Pi Pico W", qty: "1", spec: "Wi-Fi + BLE; provided by the school", status: "DECIDED"),
	BomPart(n: 19, name: "Status bar", qty: "1", spec: "24 × WS2815F on a straight board under the grid, fixed (does not move)", status: "NOT DESIGNED"),
	BomPart(n: 20, name: "Buck modules", qty: "2 (+1)", spec: "XL4016-class 8 A: 20 V → 12 V and 16 V → 5 V, aluminium heatsinks", status: "DECIDED"),
	BomPart(n: 21, name: "Chargers", qty: "3", spec: "12 V 4 A, 20 V 3.33 A, 16 V 3.75 A (own, provided)", status: "DECIDED"),
	BomPart(n: 22, name: "Power board", qty: "1", spec: "Rocker switch, three DC sockets, 10 resettable PTC fuses F1–F10, star ground", status: "DECIDED"),
	BomPart(n: 23, name: "Breadboards", qty: "2", spec: "Pico, level shifter, eight 595s, sensors (prototype wiring)", status: "DECIDED"),
	BomPart(n: 24, name: "Sensors", qty: "3", spec: "LDR GP26, NTC 10 kΩ GP27 (inside, near drivers), red status LED on the back", status: "DECIDED"),
	BomPart(n: 25, name: "Stand + ball head", qty: "1", spec: "Mini camera ball head 1/4\"-20 on a printed base; desk and wall use; ~1–1.5 kg", status: "NOT DESIGNED"),
	BomPart(n: 26, name: "Harness", qty: "~50", spec: "JST-XH 4-pin pairs; 3–4 core silicone wire with a service loop per tile", status: "DECIDED"),
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
	text("Mechanism, structure, parts and system on one sheet. 4 × 4 tiles · 6 × 6 LEDs per tile + 24-LED bar = 600 LEDs · 16 lead-screw steppers · Pico W · units mm unless stated · vector, zoom in", 40, 92, size: 15, color: cGray)
	text("Solid line = decided.   Dashed light blue = proposed, not designed.   Amber = risk or open.   Numbered circles match the parts list (panel I).   Figures marked [E] are my estimates; \"borrowed\" figures come from other motors' listings.", 40, 114, size: 13, color: cGray)
	// title block
	rect(2150, 30, 610, 88, fill: nil, stroke: cBlack, lw: 1.4)
	line(2150, 62, 2760, 62, 1, cBlack); line(2150, 90, 2760, 90, 1, cBlack); line(2420, 62, 2420, 118, 1, cBlack)
	text("DITHER BOARD · DESIGN BLUEPRINT", 2165, 52, size: 16, bold: true)
	text("Rev 18 · 2026-11-21", 2165, 82, size: 12); text("Sheet 1 / 1 · A0-style, vector", 2435, 82, size: 12)
	text("Drawn from tile.py (K = 6)", 2165, 108, size: 12); text("Prototype: nothing tested on hardware", 2435, 108, size: 12, color: cOrange)
	line(40, 126, MW - 40, 126, 1.2, cGray)

	dpFront(40, 140, 640, 620)
	dpSection(700, 140, 1220, 620)
	dpExploded(1940, 140, 820, 620)
	dpCell(40, 775, 640, 400)
	dpDrive(700, 775, 700, 400)
	dpChecks(1420, 775, 720, 400)
	dpOpen(2160, 775, 600, 400)
	dpSystem(40, 1190, 1380, 480)
	dpBOM(1440, 1190, 1320, 480)

	text("hardware/schematics/Mech.swift · generated: swiftc … Mech.swift make_schematics.swift (see make_schematics.swift header)", 40, MH - 10, size: 9, color: cGray)
	ctx.endPDFPage()
	ctx.closePDF()
}

// MARK: A. Front elevation

func dpFront(_ px: CGFloat, _ py: CGFloat, _ pw: CGFloat, _ ph: CGFloat) {
	panel(px, py, pw, ph, "A", "Front elevation", "what you see: bezel, 4 × 4 tiles, status bar")
	let S: CGFloat = 2.3
	let boardW: CGFloat = 180, boardH: CGFloat = 194
	let ox = px + 90, oy = py + 92
	func X(_ mm: CGFloat) -> CGFloat { ox + mm * S }
	func Y(_ mm: CGFloat) -> CGFloat { oy + mm * S }
	// bezel
	rect(X(0), Y(0), boardW * S, boardH * S, fill: rgb(0.02, 0.14, 0.36), stroke: cBlack, lw: 1.6)
	// window
	rect(X(10), Y(10), 160 * S, 160 * S, fill: nil, stroke: cBlack, lw: 0.8, dash: [3, 2])
	for r in 0..<4 { for c in 0..<4 {
		let tx = 10 + CGFloat(c) * dPitch + (dPitch - dHead) / 2, ty = 10 + CGFloat(r) * dPitch + (dPitch - dHead) / 2
		rect(X(tx), Y(ty), dHead * S, dHead * S, fill: cLight, stroke: cBlack, lw: 1)
		if r == 1 && c == 1 {
			// 6 x 6 LED cells, drawn on this tile only
			for i in 0..<dK { for j in 0..<dK {
				let lx = tx + dRim + (CGFloat(i) + 0.5) * dCell, ly = ty + dRim + (CGFloat(j) + 0.5) * dCell
				rect(X(lx - 2.5), Y(ly - 2.5), 5 * S, 5 * S, fill: rgb(1, 0.95, 0.6), stroke: nil, bright: true)
			}}
		} else {
			// pitch hint for all other tiles: faint grid
			for i in 1..<dK {
				let o = dRim + CGFloat(i) * dCell
				line(X(tx + o), Y(ty + dRim), X(tx + o), Y(ty + dHead - dRim), 0.3, rgb(1, 1, 1, 0.35))
				line(X(tx + dRim), Y(ty + o), X(tx + dHead - dRim), Y(ty + o), 0.3, rgb(1, 1, 1, 0.35))
			}
		}
	}}
	// status bar: 24 LEDs under the grid
	rect(X(17), Y(176), 146 * S, 8 * S, fill: nil, stroke: cBlue, lw: 1, dash: [4, 3])
	for i in 0..<24 { dot(X(17 + (CGFloat(i) + 0.5) * 146 / 24), Y(180), 1.6, fill: rgb(1, 0.95, 0.6)) }
	// sensors (top border) and M3 holes
	dot(X(90), Y(5), 3, fill: nil, stroke: cBlack, lw: 1.2)
	dot(X(78), Y(5), 2, fill: nil, stroke: cBlack, lw: 1.2)
	for (cx, cy) in [(5, 5), (175, 5), (5, 189), (175, 189)] { dot(X(CGFloat(cx)), Y(CGFloat(cy)), 3.2 * S / 2, fill: cWhite, stroke: cBlack, lw: 1) }
	// section line A-A through tile column 1
	let ax = X(10 + dPitch + dPitch / 2)
	line(ax, Y(-12), ax, Y(boardH + 12), 1, cOrange, dash: [10, 3, 2, 3])
	text("B", ax - 16, Y(-12) + 4, size: 13, bold: true, color: cOrange); text("B", ax - 16, Y(boardH + 12) + 4, size: 13, bold: true, color: cOrange)
	arrow(ax, Y(-12), ax + 14, Y(-12), cOrange); arrow(ax, Y(boardH + 12), ax + 14, Y(boardH + 12), cOrange)
	// dimensions
	dimH(X(0), X(boardW), py + 62, "180")
	dimH(X(10), X(10 + dPitch), py + 78, "pitch 40")
	dimV(X(boardW) + 22, Y(0), Y(boardH), "≈ 194 [E]", labelLeft: false)
	dimV(X(0) - 20, Y(10), Y(170), "160 grid", labelLeft: true)
	// balloons
	balloon(11, px + pw - 60, Y(20), X(boardW - 5), Y(20))
	balloon(2, px + pw - 60, Y(60), X(10 + 2 * dPitch + 20), Y(10 + dPitch + 20))
	balloon(19, px + pw - 60, Y(180), X(158), Y(180))
	balloon(24, px + pw - 60, Y(2), X(90), Y(5))
	balloon(13, px + 44, Y(boardH - 12), X(5), Y(189))
	text("One tile is drawn with its 36 LEDs; the others show the 6 × 6 cell grid only.", px + 24, py + ph - 22, size: 10, color: cGray)
	text("Tile head 38.8, gap 1.2. Status bar position under the grid is [E]; it is fixed.", px + 24, py + ph - 8, size: 10, color: cGray)
}

// MARK: B. Section through one tile column

func dpSection(_ px: CGFloat, _ py: CGFloat, _ pw: CGFloat, _ ph: CGFloat) {
	panel(px, py, pw, ph, "B", "Section B–B: one tile column, top tile retracted, lower tile extended 15", "front of the board is on the left; hatched = cut material; face of tile at z = 0 when retracted")
	let S: CGFloat = 4.9
	let ox = px + 40, oy = py + 150           // pt of z = -16, v = -30
	func X(_ z: CGFloat) -> CGFloat { ox + (z + 16) * S }
	func Y(_ v: CGFloat) -> CGFloat { oy + (v + 30) * S }
	let c1: CGFloat = 0, c2: CGFloat = 40, vTop: CGFloat = -30, vBot: CGFloat = 62
	// fixed plates with holes at the tile centres
	func plate(_ z0: CGFloat, _ t: CGFloat, hole: CGFloat, proposed: Bool = false) {
		var edges: [CGFloat] = [vTop]
		for c in [c1, c2] { edges.append(c - hole / 2); edges.append(c + hole / 2) }
		edges.append(vBot)
		var i = 0
		while i < edges.count { cut(X(z0), Y(edges[i]), t * S, (edges[i + 1] - edges[i]) * S, proposed: proposed); i += 2 }
	}
	// bezel: top border only
	cut(X(-dDiff), Y(vTop), 3 * S, 10 * S, hatch: true, spacing: 2.5)
	plate(zG1, dPlate, hole: dHole)
	plate(zG2, dPlate, hole: dHole)
	plate(zMotorFace, dPlate, hole: 8.1)
	cut(X(zBack), Y(vTop), dPlate * S, (vBot - vTop) * S)
	zigzag(X(-14), X(zBack + 3), Y(vBot) - 2)

	func tile(_ c: CGFloat, _ e: CGFloat) {
		func Z(_ z: CGFloat) -> CGFloat { X(z - e) }
		// diffuser, head rim, grid walls
		cut(Z(-dDiff), Y(c - dHead / 2), dDiff * S, dHead * S, proposed: true, hatch: false)
		cut(Z(0), Y(c - dHead / 2), dHeadH * S, dRim * S)
		cut(Z(0), Y(c + dHead / 2 - dRim), dHeadH * S, dRim * S)
		for k in -2...2 { cut(Z(0), Y(c + CGFloat(k) * dCell - dWall / 2), dGridH * S, dWall * S) }
		// LEDs (centre row) and PCB
		for k in 0..<dK {
			let v = c + (CGFloat(k) - 2.5) * dCell
			rect(Z(dGridH - 1.6), Y(v - 2.5), 1.6 * S, 5 * S, fill: rgb(1, 0.95, 0.6, 0.9), stroke: cBlack, lw: 0.6, bright: true)
		}
		cut(Z(dGridH), Y(c - dInner / 2), dPCB * S, dInner * S, spacing: 2.5)
		// floor plate with wire hole
		cut(Z(dGridH + dPCB), Y(c - dInner / 2 + 0.15), dFloor * S, (dInner / 2 - 0.15 - 3) * S)
		cut(Z(dGridH + dPCB), Y(c + 3), dFloor * S, (dInner / 2 - 0.15 - 3) * S)
		// pad ring
		cut(Z(dHeadH), Y(c - 17), dPad * S, 6.5 * S, proposed: true, hatch: false)
		cut(Z(dHeadH), Y(c + 10.5), dPad * S, 6.5 * S, proposed: true, hatch: false)
		// stem tube walls and detent notches
		cut(Z(dHeadH), Y(c - dStem / 2), dStemLen * S, dStemWall * S)
		cut(Z(dHeadH), Y(c + dStem / 2 - dStemWall), dStemLen * S, dStemWall * S)
		// nut carrier (proposed) and brass nut
		let zc = dHeadH + dStemLen - zCarrier
		cut(Z(zc), Y(c - dStem / 2 + dStemWall), zCarrier * S, (dStem / 2 - dStemWall - 1.1) * S, proposed: true)
		cut(Z(zc), Y(c + 1.1), zCarrier * S, (dStem / 2 - dStemWall - 1.1) * S, proposed: true)
		cut(Z(zc + 1.2), Y(c - 2), 1.6 * S, 4 * S, hatch: true, spacing: 1.6, fill: rgb(0.95, 0.8, 0.4, 0.4))
	}
	tile(c1, 0)
	tile(c2, dStroke)
	// screws and motors (fixed)
	for c in [c1, c2] {
		let r = CGRect(x: X(zMotorFace - dScrew), y: Y(c - 1), width: dScrew * S, height: 2 * S)
		ctx.setFillColor(rgb(1, 1, 1, 0.15)); ctx.fill(r)
		var zx = r.minX
		while zx < r.maxX { line(zx, r.minY, zx + 3, r.maxY, 0.5, cBlack); zx += 2.2 }
		ctx.setStrokeColor(cBlack); ctx.setLineWidth(1.2); ctx.stroke(r)
		cut(X(zMotorFace), Y(c - 4), dMotorLen * S, 8 * S, hatch: false, fill: rgb(0.16, 0.38, 0.72))
		text("motor", X(zMotorFace + 1), Y(c) + 3, size: 9, color: cBlack)
		// MX1508 on standoffs (proposed)
		cut(X(66), Y(c - 10.5), 1.6 * S, 21 * S, proposed: true, spacing: 2.5)
		cut(X(67.6), Y(c - 6), 3 * S, 4 * S, proposed: true, hatch: false)
		line(X(zMotorFace + dPlate), Y(c - 9), X(66), Y(c - 9), 1, cBlue, dash: [3, 2])
		line(X(zMotorFace + dPlate), Y(c + 9), X(66), Y(c + 9), 1, cBlue, dash: [3, 2])
	}
	// z-datum lines (retracted tile)
	for z in [0, dHeadH, zG1, zG1 + dPlate, zG2, zG2 + dPlate, dHeadH + dStemLen, zMotorFace, zBack, zBack + dPlate] as [CGFloat] {
		ext(X(z), Y(vTop) - 4, X(z), Y(vTop) - 34)
	}
	let dy = Y(vTop) - 38
	dimH(X(0), X(dHeadH), dy, "11.6", size: 8)
	dimH(X(zG1), X(zG1 + dPlate), dy, "3", size: 8)
	dimH(X(zG2), X(zG2 + dPlate), dy, "3", size: 8)
	dimH(X(zG1 + dPlate), X(zG2), dy - 16, "12.4 gap", size: 8)
	dimH(X(dHeadH), X(dHeadH + dStemLen), dy - 32, "stem 40", size: 8)
	dimH(X(zMotorFace), X(zBack), dy - 16, "bay 31.6 [E]", size: 8)
	dimH(X(0), X(zBack + dPlate), dy - 48, "front of head to back plate 89 (retracted) · 105 with a tile out [E bay]", size: 9)
	dimH(X(-dStroke), X(0), Y(vBot) + 14, "stroke 15", c: cOrange)
	dimH(X(zMotorFace - dScrew), X(zMotorFace), Y(vBot) + 14, "screw 28")
	// labels (balloons) right of drawing
	let bx = X(zBack + dPlate) + 70
	balloon(11, bx, Y(-25), X(0.5), Y(-25))
	balloon(1, X(-12), Y(-14), X(-0.4), Y(-8))
	balloon(2, X(4), Y(-24), X(4), Y(-18.8))
	balloon(3, X(10), Y(-24), X(8.8), Y(-17))
	balloon(4, X(30), Y(-14.5), X(30), Y(-9.2))
	balloon(8, X(zG1 + 1.5), Y(-27), X(zG1 + 1.5), Y(-20))
	balloon(9, X(zG2 + 1.5), Y(-27), X(zG2 + 1.5), Y(-20))
	balloon(5, X(49), Y(-14.5), X(49.6), Y(-6.5))
	balloon(6, X(54), Y(-3), X(49.6), Y(0))
	balloon(7, X(58), Y(-13), X(58), Y(-4))
	balloon(10, X(zMotorFace + 1.5), Y(-27), X(zMotorFace + 1.5), Y(-20))
	balloon(14, X(5), Y(26), X(12.1), Y(15))
	balloon(15, X(70), Y(-11), X(70), Y(-5))
	balloon(12, bx, Y(20), X(zBack + 1.5), Y(20))
	// legends
	let lx = X(zBack + dPlate) + 24
	var ly = py + 215
	for (t, c) in [("Detent notches on the stem (V, every 1.5 mm)\nand the flexure in plate 9 are not drawn:\nnot designed.", cOrange)] {
		for l in t.split(separator: "\n") { text(String(l), lx, ly, size: 11, color: c); ly += 14 }
	}
	ly += 8
	for l in ["Screw engagement needed: 4 (rest) + 15 (travel) + 1.6 (nut) = 20.6 mm, of 28 mm.",
	          "At full travel the stem still has 5.6 mm of tube behind plate 9.",
	          "Retracted, the nut carrier is 2.8 mm short of the motor face: the pad on plate 8 is the stop, not the motor.",
	          "Screw tip to floor plate when retracted: 14.8 mm."] {
		ly = paragraph(l, lx, ly, width: 420, size: 11, color: cBlack) + 6
	}
}

// MARK: C. Exploded view

func dpExploded(_ px: CGFloat, _ py: CGFloat, _ pw: CGFloat, _ ph: CGFloat) {
	panel(px, py, pw, ph, "C", "Exploded view of one tile and its drive", "front-to-back order; plates shown as a one-cell patch; oblique projection, not to scale in depth")
	// oblique projection: x right, y down, depth z goes up-right at ~(0.55, -0.35) per mm * S
	let S: CGFloat = 2.5
	let dxz: CGFloat = 0.5, dyz: CGFloat = -0.32
	func blk(_ cx: CGFloat, _ cy: CGFloat, _ w: CGFloat, _ h: CGFloat, _ d: CGFloat, fill: CGColor, dashed: Bool = false, inner: ((CGFloat, CGFloat, CGFloat, CGFloat) -> Void)? = nil) {
		let x0 = cx - w * S / 2, y0 = cy - h * S / 2, W = w * S, H = h * S
		let ox = d * S * dxz, oy = d * S * dyz
		ctx.saveGState()
		if dashed { ctx.setLineDash(phase: 0, lengths: [4, 3]) }
		ctx.setLineWidth(1); ctx.setLineJoin(.round)
		// top and right faces
		ctx.setFillColor(rgb(0.2, 0.45, 0.8)); ctx.setStrokeColor(dashed ? cBlue : cBlack)
		ctx.move(to: CGPoint(x: x0, y: y0)); ctx.addLine(to: CGPoint(x: x0 + ox, y: y0 + oy)); ctx.addLine(to: CGPoint(x: x0 + W + ox, y: y0 + oy)); ctx.addLine(to: CGPoint(x: x0 + W, y: y0)); ctx.closePath(); ctx.drawPath(using: .fillStroke)
		ctx.setFillColor(rgb(0.13, 0.36, 0.7))
		ctx.move(to: CGPoint(x: x0 + W, y: y0)); ctx.addLine(to: CGPoint(x: x0 + W + ox, y: y0 + oy)); ctx.addLine(to: CGPoint(x: x0 + W + ox, y: y0 + H + oy)); ctx.addLine(to: CGPoint(x: x0 + W, y: y0 + H)); ctx.closePath(); ctx.drawPath(using: .fillStroke)
		ctx.setFillColor(fill)
		ctx.addRect(CGRect(x: x0, y: y0, width: W, height: H)); ctx.drawPath(using: .fillStroke)
		ctx.restoreGState()
		inner?(x0, y0, W, H)
	}
	let midY = py + 540
	let stepX: CGFloat = 50, stepY: CGFloat = -30
	// parts from the back to the front so the front ones overlap
	// (n, name, w, h, depth, drawer)
	struct E { let n: Int; let w: CGFloat; let h: CGFloat; let d: CGFloat; let proposed: Bool; let kind: Int }
	let parts: [E] = [
		E(n: 12, w: 56, h: 56, d: 3, proposed: false, kind: 0),   // back plate patch
		E(n: 15, w: 24, h: 21, d: 6, proposed: true, kind: 3),    // driver
		E(n: 10, w: 56, h: 56, d: 3, proposed: false, kind: 1),   // motor plate
		E(n: 7, w: 8, h: 8, d: 36, proposed: false, kind: 4),     // motor + screw
		E(n: 6, w: 4, h: 4, d: 1.6, proposed: false, kind: 5),    // nut
		E(n: 5, w: 16.8, h: 16.8, d: 4, proposed: true, kind: 6), // carrier
		E(n: 9, w: 56, h: 56, d: 3, proposed: false, kind: 1),    // rear guide
		E(n: 8, w: 56, h: 56, d: 3, proposed: false, kind: 1),    // front guide
		E(n: 14, w: 36, h: 36, d: 1, proposed: true, kind: 7),    // pad
		E(n: 4, w: 20, h: 20, d: 40, proposed: false, kind: 8),   // stem
		E(n: 3, w: 36.4, h: 36.4, d: 1.6, proposed: false, kind: 9), // pcb
		E(n: 2, w: 38.8, h: 38.8, d: 11.6, proposed: false, kind: 10), // head
		E(n: 1, w: 38.8, h: 38.8, d: 0.8, proposed: true, kind: 11),   // diffuser
	]
	let n = CGFloat(parts.count)
	for (i, p) in parts.enumerated() {
		let k = CGFloat(i)
		// i = 0 is the farthest back (top right)
		// position: back parts at the top right, front parts bottom left
		let fromFront = n - 1 - k
		let off: [Int: (CGFloat, CGFloat)] = [5: (-30, 95), 6: (10, 80), 15: (60, 95)]
		let cxp = px + 80 + fromFront * stepX + (off[p.n]?.0 ?? 0)
		let cyp = midY + fromFront * stepY + (off[p.n]?.1 ?? 0)
		blk(cxp, cyp, p.w, p.h, p.d, fill: rgb(0.1, 0.33, 0.68), dashed: p.proposed) { x0, y0, W, H in
			switch p.kind {
			case 1, 0:   // plate with a square hole
				let hw = 20.5 * S
				rect(x0 + W / 2 - hw / 2, y0 + H / 2 - hw / 2, hw, hw, fill: cWhite, stroke: cBlack, lw: 0.8)
			case 3:
				rect(x0 + 3, y0 + 3, 8, 8, fill: rgb(0.02, 0.14, 0.36), stroke: cBlack, lw: 0.6)
			case 4:
				dot(x0 + W / 2, y0 + H / 2, W / 2, fill: rgb(0.2, 0.5, 0.85), stroke: cBlack)
			case 6:
				dot(x0 + W / 2, y0 + H / 2, 3, fill: cWhite, stroke: cBlack, lw: 0.6)
			case 8:
				rect(x0 + 5, y0 + 5, W - 10, H - 10, fill: cWhite, stroke: cBlack, lw: 0.8)
			case 9, 10:
				if p.kind == 10 {
					for i in 1..<6 {
						let o = (dRim + CGFloat(i) * dCell) * S
						line(x0 + o, y0 + dRim * S, x0 + o, y0 + H - dRim * S, 0.5, cBlack)
						line(x0 + dRim * S, y0 + o, x0 + W - dRim * S, y0 + o, 0.5, cBlack)
					}
				} else {
					for i in 0..<6 { for j in 0..<6 {
						rect(x0 + (dRim + (CGFloat(i) + 0.5) * dCell - 2.5) * S, y0 + (dRim + (CGFloat(j) + 0.5) * dCell - 2.5) * S, 5 * S, 5 * S, fill: rgb(1, 0.95, 0.6), stroke: nil, bright: true)
					}}
				}
			default: break
			}
		}
		// balloon: alternate above and below
		let up = (Int(k) % 2 == 0)
		let bxp = cxp + (up ? 4 : -6), byp = cyp + (up ? -(p.h * S / 2 + 56) : (p.h * S / 2 + 44))
		balloon(p.n, bxp, byp, cxp, cyp + (up ? -p.h * S / 2 * 0.4 : p.h * S / 2 * 0.4))
	}
	// the lead screw drawn over the motor
	text("Assembly order: print head (2) face-down, drop PCB (3) in, press stem (4) into the head,", px + 24, py + 80, size: 11, color: cGray)
	text("glue diffuser (1) on the face, fit the pad (14), slide the stem through plates 8 and 9,", px + 24, py + 95, size: 11, color: cGray)
	text("thread the nut (6) into the carrier (5), then run the motor's screw (7) through it.", px + 24, py + 110, size: 11, color: cGray)
	text("Front of the board is bottom left; the back of the board is top right.", px + 24, py + 125, size: 11, color: cGray)
}

// MARK: D. The 6 x 6 cell

func dpCell(_ px: CGFloat, _ py: CGFloat, _ pw: CGFloat, _ ph: CGFloat) {
	panel(px, py, pw, ph, "D", "Tile head, front view, 6 × 6 LEDs", "tile.py geometry with K = 6; cell = (38.8 − 2 × 1.2) / 6")
	let S: CGFloat = 6.4
	let ox = px + 40, oy = py + 76
	rect(ox, oy, dHead * S, dHead * S, fill: nil, stroke: cBlack, lw: 1.6)
	rect(ox + dRim * S, oy + dRim * S, dInner * S, dInner * S, fill: nil, stroke: cBlack, lw: 0.8)
	for i in 0...dK { // grid walls: K-1 inner ones
		if i == 0 || i == dK { continue }
		let o = (dRim + CGFloat(i) * dCell) * S
		rect(ox + o - dWall * S / 2, oy + dRim * S, dWall * S, dInner * S, fill: rgb(0.2, 0.45, 0.8), stroke: nil)
		rect(ox + dRim * S, oy + o - dWall * S / 2, dInner * S, dWall * S, fill: rgb(0.2, 0.45, 0.8), stroke: nil)
	}
	for i in 0..<dK { for j in 0..<dK {
		let cx = ox + (dRim + (CGFloat(i) + 0.5) * dCell) * S, cy = oy + (dRim + (CGFloat(j) + 0.5) * dCell) * S
		rect(cx - 2.5 * S, cy - 2.5 * S, 5 * S, 5 * S, fill: rgb(1, 0.95, 0.6, 0.9), stroke: cBlack, lw: 0.5, bright: true)
	}}
	dimH(ox, ox + dHead * S, oy - 14, "38.8")
	dimV(ox - 14, oy + dRim * S, oy + (dRim + dCell) * S, "6.07", size: 8, labelLeft: true)
	// zoom of one cell
	let zs: CGFloat = 30, zx = px + 380, zy = py + 100
	text("ONE CELL ×30", zx, zy - 22, size: 11, bold: true)
	rect(zx, zy, dCell * zs, dCell * zs, fill: nil, stroke: cGray, lw: 0.8, dash: [4, 3])
	let wallC = rgb(0.2, 0.45, 0.8)
	rect(zx - dWall * zs / 2, zy - dWall * zs / 2, dCell * zs + dWall * zs, dWall * zs / 2, fill: wallC, stroke: nil)
	rect(zx - dWall * zs / 2, zy + dCell * zs, dCell * zs + dWall * zs, dWall * zs / 2, fill: wallC, stroke: nil)
	rect(zx - dWall * zs / 2, zy, dWall * zs / 2, dCell * zs, fill: wallC, stroke: nil)
	rect(zx + dCell * zs, zy, dWall * zs / 2, dCell * zs, fill: wallC, stroke: nil)
	let ledW = 5.0 * zs
	rect(zx + dCell * zs / 2 - ledW / 2, zy + dCell * zs / 2 - ledW / 2, ledW, ledW, fill: rgb(1, 0.95, 0.6, 0.85), stroke: cBlack, lw: 1, bright: true)
	let open = (dCell - dWall) * zs
	rect(zx + dCell * zs / 2 - open / 2, zy + dCell * zs / 2 - open / 2, open, open, fill: nil, stroke: cOrange, lw: 1.2, dash: [3, 2])
	dimH(zx, zx + dCell * zs, zy + dCell * zs + 34, "pitch 6.07")
	dimH(zx + dCell * zs / 2 - open / 2, zx + dCell * zs / 2 + open / 2, zy + dCell * zs + 18, "opening 5.07", c: cOrange)
	text("LED body 5.0", zx + dCell * zs / 2, zy + dCell * zs / 2 + 4, size: 10, color: cBlack, align: 1)
	var ty = py + 336
	text("OPEN CLASH", px + 24, ty, size: 13, bold: true, color: cOrange); ty += 16
	ty = paragraph("A 5.0 mm LED in a 5.07 mm opening leaves 0.035 mm a side; the printer holds ±0.1–0.2. Needs ≥ 5.3: walls ≤ 0.77 mm, or a 0.8 mm rim (cell 6.2), or K = 5 (cell 7.3). ingredients.md said 6.5 mm; the real cell is 6.07.", px + 24, ty, width: pw - 48, size: 10.5, color: cBlack)
}

// MARK: E. Drive chain and force

func dpDrive(_ px: CGFloat, _ py: CGFloat, _ pw: CGFloat, _ ph: CGFloat) {
	panel(px, py, pw, ph, "E", "Drive chain and force check", "rotary to linear: the project's own screw drive; numbers marked 'borrowed' are not measured on this motor")
	let steps = ["Pico GPIO", "74HC595\n4 bits", "MX1508\nH-bridges", "stepper\n2 coils", "M2 × 0.4\nscrew", "brass nut\ncarrier", "stem →\ntile"]
	let bw: CGFloat = 84, gap: CGFloat = 14
	let bx0 = px + 18, by = py + 64
	for (i, s) in steps.enumerated() {
		let x = bx0 + CGFloat(i) * (bw + gap)
		rect(x, by, bw, 40, fill: cLight, stroke: cBlack, lw: 1, r: 3)
		let ls = s.split(separator: "\n").map(String.init)
		for (j, l) in ls.enumerated() { text(l, x + bw / 2, by + (ls.count == 1 ? 24 : 17 + CGFloat(j) * 13), size: 10, bold: j == 0, align: 1) }
		if i < steps.count - 1 { arrow(x + bw, by + 20, x + bw + gap, by + 20, cBlack) }
	}
	let lines = [
		"Full-step bipolar sequence (IN1–IN4 = coil A+, A−, B+, B−): 1010 → 0110 → 0101 → 1001, 20 steps per revolution.",
		"Lead 0.4 mm per rev [assumed M2 × 0.4, unverified] → 0.02 mm per step. 15 mm stroke = 750 steps = 37.5 rev.",
		"At 500 pps: 25 rev/s (1500 rpm) and 1.5 s per full stroke (the 1 s in the notes was for 10 mm). At 300 pps: 2.5 s.",
		"Self-locking: lead angle ≈ 4.2° (pitch dia ≈ 1.74 mm) against a brass-on-steel friction angle ≈ 9–11°. Holds unpowered, but a finger pushing a tile in can strip the nut.",
		"Coil current (borrowed, 16.8 Ω at 5 V): ≈ 0.3 A per phase, 0.6 A per motor; six moving at once ≈ 3.6 A, inside the 5 A buck.",
	]
	var y = py + 124
	for l in lines { y = paragraph(l, px + 18, y, width: pw - 36, size: 10.5) + 3 }
	// FBDs
	let fy = py + 262
	text("Face-up on a desk: worst case", px + 18, fy - 6, size: 10.5, bold: true)
	// face-up
	func fbd(_ x: CGFloat, _ y: CGFloat, vertical: Bool) {
		if vertical {
			rect(x - 26, y, 52, 10, fill: cLight, stroke: cBlack, lw: 1)      // head
			rect(x - 8, y + 10, 16, 56, fill: nil, stroke: cBlack, lw: 1)       // stem
			arrow(x + 40, y + 36, x + 40, y + 6, cGreen, w: 1.6)                // thrust up... drawn as force of motor
			text("thrust 30 gf (borrowed)", x + 48, y + 18, size: 9, color: cGreen)
			arrow(x - 40, y + 14, x - 40, y + 46, cRed, w: 1.6)
			text("tile ≈ 27 g [E]", x - 46, y + 62, size: 9, color: cRed, align: 2)
		} else {
			rect(x - 26, y, 10, 52, fill: cLight, stroke: cBlack, lw: 1)
			rect(x - 16, y + 18, 66, 16, fill: nil, stroke: cBlack, lw: 1)
			arrow(x + 20, y + 4, x + 20, y + 24 + 8, cRed, w: 1.6)
			text("27 g carried by the plate holes: friction ≈ 8 gf [E]", x + 60, y + 14, size: 9, color: cRed)
			arrow(x + 60, y + 44, x + 12, y + 44, cGreen, w: 1.6)
			text("thrust 30 gf", x + 66, y + 47, size: 9, color: cGreen)
		}
	}
	fbd(px + 120, fy + 6, vertical: true)
	text("On a wall: friction only", px + 340, fy - 6, size: 10.5, bold: true)
	fbd(px + 370, fy + 14, vertical: false)
	y = py + ph - 52
	text("MARGIN", px + 18, y, size: 12, bold: true, color: cOrange)
	_ = paragraph("Face-up: 30 gf (another motor's figure) against ≈ 27 gf of tile + wire spring + detent leaves ~3 gf. Wall-mounted is fine. The 3-motor pilot must measure real thrust before the other 15 are bought.", px + 18, y + 14, width: pw - 36, size: 10)
}

// MARK: F. Checks

func dpChecks(_ px: CGFloat, _ py: CGFloat, _ pw: CGFloat, _ ph: CGFloat) {
	panel(px, py, pw, ph, "F", "Does the dimension chain close?", "worked from the section (panel B); estimates marked [E]")
	// (check, calculation, result, level) level: 0 ok, 1 marginal/risk, 2 fail
	let rows: [(String, String, String, Int)] = [
		("Screw engagement", "4 rest gap + 15 travel + 1.6 nut = 20.6 mm needed; the screw is 28 mm", "OK, 7.4 spare", 0),
		("Stem stays in plate 9", "extended: tube tip at z = 36.6, plate 9 back face at 31, so 5.6 mm of tube behind it", "OK", 0),
		("Retract end-stop", "pad (1 mm) lands on plate 8 first; the carrier is 2.8 mm from the motor face", "OK, 2.8 mm", 0),
		("Screw tip vs floor plate", "retracted: screw tip at z = 26.4, floor plate at 11.6", "OK, 14.8 mm", 0),
		("Guide wobble, 0.25 mm", "span between plate centres 15.4 mm; head front 29 mm out when extended: ±(29 × 0.5 / 15.4 + 0.25) ≈ ±1.2 mm", "MARGINAL vs 1.2 gap", 1),
		("Guide wobble, 0.15 mm", "±(29 × 0.3 / 15.4 + 0.15) ≈ ±0.7 mm; set by the clearance coupon", "OK if achieved", 0),
		("Thrust vs weight", "tile ≈ 27 g [E]: PLA 12 cm³ = 15 g, PCB + 36 LEDs 7 g, nut, carrier, wire, diffuser 5 g. Thrust 30 gf is borrowed from another motor", "RISK face-up", 1),
		("Cell clearance", "5.07 mm opening − 5.0 mm LED = 0.07 mm (0.035 a side)", "FAIL as drawn", 2),
		("Depth", "−0.8 front to 89 back = 89.8 mm retracted; ≈ 105 mm with a tile out (bay depth 31.6 is [E])", "9 to 10.5 cm", 0),
	]
	let wC: CGFloat = 150, wR: CGFloat = 400, wV: CGFloat = 130
	let x0 = px + 14
	var y = py + 62
	rect(x0, y - 11, wC + wR + wV, 17, fill: cLight, stroke: nil)
	text("Check", x0 + 4, y + 2, size: 10.5, bold: true); text("Calculation", x0 + wC + 4, y + 2, size: 10.5, bold: true); text("Result", x0 + wC + wR + 4, y + 2, size: 10.5, bold: true)
	y += 20
	for (c, calc, res, lvl) in rows {
		let lines = wrap(calc, width: wR - 10, size: 10.5)
		let h = CGFloat(lines.count) * 13 + 8
		text(c, x0 + 4, y + 1, size: 10.5, bold: true)
		var ly = y + 1
		for l in lines { text(l, x0 + wC + 4, ly, size: 10.5); ly += 13 }
		text(res, x0 + wC + wR + 4, y + 1, size: 10.5, bold: true, color: lvl == 0 ? cGreen : (lvl == 1 ? cOrange : cRed))
		line(x0, y + h - 9, x0 + wC + wR + wV, y + h - 9, 0.3, rgb(1, 1, 1, 0.3))
		y += h
	}
}

// MARK: G. Open items

func dpOpen(_ px: CGFloat, _ py: CGFloat, _ pw: CGFloat, _ ph: CGFloat) {
	panel(px, py, pw, ph, "G", "Not designed yet", "drawn dashed in panels B and C")
	var y = py + 70
	let items = [
		"Nut carrier (5): a printed plug in the stem tip holding an M2 nut. How the nut is trapped and kept from turning is open.",
		"Motor retention (10): an 8 mm bare cylinder in an 8.1 mm hole needs a clamp, glue or a printed cradle.",
		"LED carrier (3): custom tile PCB removed; a premade 4 × 4 module (7.5 mm pitch) is proposed, which also needs the pixel count changed from 24 to 16.",
		"Detents: V-notches every 1.5 mm on the stem and a flexure in plate 9. Adds friction against a thrust margin that is already thin.",
		"Diffuser (1): a printed translucent sheet, thickness and evenness untested; test print before the tile heads.",
		"Homing and soft limits: no limit switch. Firmware re-homes against the end stop; stalls are silent.",
		"Wire loom: 4 conductors per tile with a service loop for 15 mm of travel; routing through the floor plate hole is not drawn.",
		"Stand and ball-head mount (25), status bar board (19), M3 rod spacers (13).",
	]
	for s in items { y = paragraph("• " + s, px + 18, y, width: pw - 36, size: 11.5) + 6 }
}

// MARK: H. System block diagram

func dpSystem(_ px: CGFloat, _ py: CGFloat, _ pw: CGFloat, _ ph: CGFloat) {
	panel(px, py, pw, ph, "H", "System block diagram", "details and pin numbers: dither-board-blueprint.pdf and dither-board-schematics.pdf")
	func b(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ t1: String, _ t2: String = "", fill: CGColor = cLight, num: Int? = nil) {
		rect(px + x, py + y, w, h, fill: fill, stroke: cBlack, lw: 1.1, r: 4)
		text(t1, px + x + w / 2, py + y + (t2.isEmpty ? h / 2 + 4 : 16), size: 10.5, bold: true, align: 1)
		if !t2.isEmpty { text(t2, px + x + w / 2, py + y + 30, size: 9, align: 1) }
		if let n = num { dot(px + x + w - 2, py + y + 2, 8, fill: cWhite, stroke: cBlack, lw: 0.8); text("\(n)", px + x + w - 2, py + y + 5.5, size: 8, bold: true, align: 1) }
	}
	func a(_ x1: CGFloat, _ y1: CGFloat, _ x2: CGFloat, _ y2: CGFloat, _ c: CGColor) { arrow(px + x1, py + y1, px + x2, py + y2, c, w: 1.6) }
	func l(_ x1: CGFloat, _ y1: CGFloat, _ x2: CGFloat, _ y2: CGFloat, _ c: CGColor) { line(px + x1, py + y1, px + x2, py + y2, 1.6, c) }
	// chargers and bucks
	b(20, 70, 120, 40, "Charger A", "12 V 4 A", num: 21)
	b(20, 170, 120, 40, "Charger C", "20 V 3.33 A", num: 21)
	b(20, 270, 120, 40, "Charger B", "16 V 3.75 A", num: 21)
	b(190, 160, 110, 60, "Power board", "switch · fuses F1–F10", num: 22)
	b(350, 160, 100, 60, "BUCK 20→12 V", "XL4016", num: 20)
	b(350, 260, 100, 60, "BUCK 16→5 V", "XL4016", num: 20)
	l(140, 90, 190, 180, cRed); l(140, 190, 190, 190, cRed); l(140, 290, 190, 205, cOrange)
	a(300, 190, 350, 190, cRed); a(300, 205, 350, 290, cOrange)
	// rails
	b(520, 70, 130, 40, "12 V rows 0–1", "straight from A", fill: rgb(1, 0.92, 0.92))
	b(520, 160, 130, 50, "12 V rows 2–3 + bar", "from buck 1", fill: rgb(1, 0.92, 0.92))
	b(520, 270, 130, 50, "5 V rail", "motors, drivers, Pico, 245", fill: rgb(1, 0.95, 0.9))
	l(140, 80, 520, 90, cRed); a(450, 190, 520, 185, cRed); a(450, 290, 520, 295, cOrange)
	// controller
	b(720, 270, 120, 56, "Pico W", "Wi-Fi + BLE", fill: rgb(0.88, 0.96, 0.9), num: 18)
	l(650, 295, 720, 298, cOrange)
	b(720, 380, 120, 40, "Phone / Mac app", "BLE or Wi-Fi")
	arrow(px + 780, py + 380, px + 780, py + 326, cBlue, w: 1.4); arrow(px + 770, py + 326, px + 770, py + 380, cBlue, w: 1.4)
	b(720, 190, 120, 44, "LDR + NTC", "ADC GP26 / GP27", num: 24)
	arrow(px + 780, py + 234, px + 780, py + 270, cBlue, w: 1.4)
	// LED path
	b(920, 120, 120, 44, "74HCT245", "3V3 → 5 V · 5 lines", num: 17)
	b(1090, 100, 250, 84, "LED tiles + bar", "4 rows × 4 tiles × 36 + bar 24 = 600 WS2815F", num: 3)
	a(840, 290, 920, 150, cBlue); a(1040, 142, 1090, 142, cGreen)
	a(650, 95, 1090, 110, cRed); a(650, 185, 1090, 168, cRed)
	// motor path
	b(920, 270, 110, 56, "74HC595 ×8", "chained · 3V3", num: 16)
	b(1075, 270, 110, 56, "MX1508 ×16", "one per motor", num: 15)
	b(1230, 270, 110, 56, "Stepper ×16", "8 mm lead screw", num: 7)
	a(840, 298, 920, 298, cBlue); a(1030, 298, 1075, 298, cBlue); a(1185, 298, 1230, 298, cBlue)
	line(px + 585, py + 320, px + 585, py + 352, 1.6, cOrange); line(px + 585, py + 352, px + 1130, py + 352, 1.6, cOrange); arrow(px + 1130, py + 352, px + 1130, py + 326, cOrange, w: 1.6)
	b(1230, 380, 110, 40, "Screw → nut → tile", "15 mm stroke", fill: cLight)
	a(1285, 326, 1285, 380, cBlack)
	text("Line colours: red = 12 V, orange = 5 V / 16 V, blue = logic, green = LED data.", px + 20, py + ph - 14, size: 10, color: cGray)
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
