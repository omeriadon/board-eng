// Drawing helpers for make_schematics.swift: an A4 landscape PDF, y grows downwards.
import CoreGraphics
import CoreText
import Foundation

let PW: CGFloat = 842, PH: CGFloat = 595
let cs = CGColorSpaceCreateDeviceRGB()
func rgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> CGColor { CGColor(colorSpace: cs, components: [r, g, b, a])! }
let cBlack = rgb(0.08, 0.08, 0.1), cGray = rgb(0.45, 0.45, 0.5), cLight = rgb(0.9, 0.9, 0.92), cWhite = rgb(1, 1, 1)
let cRed = rgb(0.85, 0.15, 0.12), cOrange = rgb(0.95, 0.55, 0.05), cBlue = rgb(0.1, 0.35, 0.85), cGreen = rgb(0.1, 0.6, 0.25)
let cPurple = rgb(0.55, 0.2, 0.75), cYellow = rgb(0.98, 0.93, 0.6), cBoard = rgb(0.96, 0.95, 0.9), cTeal = rgb(0.05, 0.55, 0.6)

var ctx: CGContext!
var pageNumber = 0
var pageTitleText = ""

func openPDF(_ path: String) {
	var box = CGRect(x: 0, y: 0, width: PW, height: PH)
	ctx = CGContext(URL(fileURLWithPath: path) as CFURL, mediaBox: &box,
	                [kCGPDFContextTitle as String: "Dither Board schematics", kCGPDFContextAuthor as String: "omeriadon/board-eng"] as CFDictionary)!
}

func beginPage(_ title: String, _ subtitle: String = "") {
	pageNumber += 1
	pageTitleText = title
	ctx.beginPDFPage(nil)
	ctx.saveGState()
	ctx.translateBy(x: 0, y: PH)
	ctx.scaleBy(x: 1, y: -1)
	ctx.setFillColor(cWhite)
	ctx.fill(CGRect(x: 0, y: 0, width: PW, height: PH))
	text(title, 28, 30, size: 16, bold: true)
	if !subtitle.isEmpty { text(subtitle, 28, 44, size: 9, color: cGray) }
	line(28, 50, PW - 28, 50, 0.6, cGray)
	text("Dither Board · hardware/schematics · page \(pageNumber)", PW - 28, PH - 14, size: 8, color: cGray, align: 2)
	text("Prototype wiring: verify every connection against the datasheets and with a multimeter before applying power.", 28, PH - 14, size: 8, color: cGray)
}

func endPage() {
	ctx.restoreGState()
	ctx.endPDFPage()
}

func measure(_ s: String, size: CGFloat, bold: Bool) -> CGFloat {
	let font = CTFontCreateWithName((bold ? "Helvetica-Bold" : "Helvetica") as CFString, size, nil)
	let attr = NSAttributedString(string: s, attributes: [NSAttributedString.Key(kCTFontAttributeName as String): font])
	return CTLineGetTypographicBounds(CTLineCreateWithAttributedString(attr), nil, nil, nil)
}

/// align: 0 left, 1 centre, 2 right. `rotated` draws bottom-to-top, anchored at (x, y) as the start (or end for align 2).
func text(_ s: String, _ x: CGFloat, _ y: CGFloat, size: CGFloat = 8, bold: Bool = false, color: CGColor = cBlack, align: Int = 0, rotated: Bool = false) {
	let font = CTFontCreateWithName((bold ? "Helvetica-Bold" : "Helvetica") as CFString, size, nil)
	let attr = NSAttributedString(string: s, attributes: [
		NSAttributedString.Key(kCTFontAttributeName as String): font,
		NSAttributedString.Key(kCTForegroundColorAttributeName as String): color,
	])
	let l = CTLineCreateWithAttributedString(attr)
	let w = CTLineGetTypographicBounds(l, nil, nil, nil)
	let dx: CGFloat = align == 0 ? 0 : (align == 1 ? -w / 2 : -w)
	ctx.saveGState()
	ctx.translateBy(x: x, y: y)
	if rotated { ctx.rotate(by: -.pi / 2) }
	ctx.textMatrix = CGAffineTransform(scaleX: 1, y: -1)
	ctx.textPosition = CGPoint(x: dx, y: 0)
	CTLineDraw(l, ctx)
	ctx.restoreGState()
}

func wrap(_ s: String, width: CGFloat, size: CGFloat, bold: Bool = false) -> [String] {
	var lines: [String] = [], cur = ""
	for word in s.split(separator: " ", omittingEmptySubsequences: true) {
		let t = cur.isEmpty ? String(word) : cur + " " + word
		if measure(t, size: size, bold: bold) > width, !cur.isEmpty { lines.append(cur); cur = String(word) } else { cur = t }
	}
	if !cur.isEmpty { lines.append(cur) }
	return lines.isEmpty ? [""] : lines
}

/// Wrapped paragraph; returns the y below it.
@discardableResult
func paragraph(_ s: String, _ x: CGFloat, _ y: CGFloat, width: CGFloat, size: CGFloat = 9, bold: Bool = false, color: CGColor = cBlack, leading: CGFloat? = nil) -> CGFloat {
	var yy = y
	let lead = leading ?? size + 3
	for l in wrap(s, width: width, size: size, bold: bold) { text(l, x, yy, size: size, bold: bold, color: color); yy += lead }
	return yy
}

func line(_ x1: CGFloat, _ y1: CGFloat, _ x2: CGFloat, _ y2: CGFloat, _ w: CGFloat = 1, _ c: CGColor = cBlack, dash: [CGFloat] = []) {
	ctx.saveGState()
	ctx.setStrokeColor(c); ctx.setLineWidth(w); ctx.setLineDash(phase: 0, lengths: dash); ctx.setLineCap(.round)
	ctx.move(to: CGPoint(x: x1, y: y1)); ctx.addLine(to: CGPoint(x: x2, y: y2)); ctx.strokePath()
	ctx.restoreGState()
}

func poly(_ pts: [(CGFloat, CGFloat)], _ w: CGFloat = 1, _ c: CGColor = cBlack, dash: [CGFloat] = []) {
	guard pts.count > 1 else { return }
	ctx.saveGState()
	ctx.setStrokeColor(c); ctx.setLineWidth(w); ctx.setLineDash(phase: 0, lengths: dash); ctx.setLineJoin(.round); ctx.setLineCap(.round)
	ctx.move(to: CGPoint(x: pts[0].0, y: pts[0].1))
	for p in pts.dropFirst() { ctx.addLine(to: CGPoint(x: p.0, y: p.1)) }
	ctx.strokePath()
	ctx.restoreGState()
}

func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, fill: CGColor? = nil, stroke: CGColor? = cBlack, lw: CGFloat = 1, r: CGFloat = 0, dash: [CGFloat] = []) {
	let rr = CGRect(x: x, y: y, width: w, height: h)
	let path = CGPath(roundedRect: rr, cornerWidth: r, cornerHeight: r, transform: nil)
	ctx.saveGState()
	if let f = fill { ctx.setFillColor(f); ctx.addPath(path); ctx.fillPath() }
	if let s = stroke { ctx.setStrokeColor(s); ctx.setLineWidth(lw); ctx.setLineDash(phase: 0, lengths: dash); ctx.addPath(path); ctx.strokePath() }
	ctx.restoreGState()
}

func dot(_ x: CGFloat, _ y: CGFloat, _ r: CGFloat, fill: CGColor?, stroke: CGColor? = nil, lw: CGFloat = 0.8) {
	let rr = CGRect(x: x - r, y: y - r, width: 2 * r, height: 2 * r)
	ctx.saveGState()
	if let f = fill { ctx.setFillColor(f); ctx.fillEllipse(in: rr) }
	if let s = stroke { ctx.setStrokeColor(s); ctx.setLineWidth(lw); ctx.strokeEllipse(in: rr) }
	ctx.restoreGState()
}

func arrow(_ x1: CGFloat, _ y1: CGFloat, _ x2: CGFloat, _ y2: CGFloat, _ c: CGColor = cBlack, w: CGFloat = 1) {
	line(x1, y1, x2, y2, w, c)
	let a = atan2(y2 - y1, x2 - x1), s: CGFloat = 5
	poly([(x2 - s * cos(a - 0.45), y2 - s * sin(a - 0.45)), (x2, y2), (x2 - s * cos(a + 0.45), y2 - s * sin(a + 0.45))], w, c)
}

// Schematic symbols (horizontal unless said otherwise).
func resistor(_ x: CGFloat, _ y: CGFloat, _ len: CGFloat = 30, _ c: CGColor = cBlack, vertical: Bool = false) {
	if vertical {
		line(x, y, x, y + len * 0.25, 1, c); rect(x - 4, y + len * 0.25, 8, len * 0.5, fill: cWhite, stroke: c); line(x, y + len * 0.75, x, y + len, 1, c)
	} else {
		line(x, y, x + len * 0.25, y, 1, c); rect(x + len * 0.25, y - 4, len * 0.5, 8, fill: cWhite, stroke: c); line(x + len * 0.75, y, x + len, y, 1, c)
	}
}

func capacitor(_ x: CGFloat, _ y: CGFloat, vertical: Bool = true, _ c: CGColor = cBlack) {
	if vertical {
		line(x, y, x, y + 7, 1, c); line(x - 6, y + 7, x + 6, y + 7, 1.4, c); line(x - 6, y + 11, x + 6, y + 11, 1.4, c); line(x, y + 11, x, y + 18, 1, c)
	} else {
		line(x, y, x + 7, y, 1, c); line(x + 7, y - 6, x + 7, y + 6, 1.4, c); line(x + 11, y - 6, x + 11, y + 6, 1.4, c); line(x + 11, y, x + 18, y, 1, c)
	}
}

func ground(_ x: CGFloat, _ y: CGFloat, _ c: CGColor = cBlack) {
	line(x, y, x, y + 5, 1, c); line(x - 7, y + 5, x + 7, y + 5, 1.2, c); line(x - 4.5, y + 8, x + 4.5, y + 8, 1.2, c); line(x - 2, y + 11, x + 2, y + 11, 1.2, c)
}

/// A fuse: small box on a horizontal wire from (x, y), `len` long, with its label above.
func fuse(_ x: CGFloat, _ y: CGFloat, _ label: String, len: CGFloat = 46) {
	line(x, y, x + 8, y, 1.4); rect(x + 8, y - 4.5, len - 16, 9, fill: cYellow, stroke: cBlack); line(x + len - 8, y, x + len, y, 1.4)
	text(label, x + len / 2, y - 8, size: 8, bold: true, align: 1)
}

func diode(_ x: CGFloat, _ y: CGFloat, _ c: CGColor = cBlack) { // anode left, cathode right
	line(x, y, x + 10, y, 1, c)
	ctx.saveGState(); ctx.setFillColor(c); ctx.move(to: CGPoint(x: x + 10, y: y - 6)); ctx.addLine(to: CGPoint(x: x + 10, y: y + 6)); ctx.addLine(to: CGPoint(x: x + 22, y: y)); ctx.fillPath(); ctx.restoreGState()
	line(x + 22, y - 6, x + 22, y + 6, 1.6, c); line(x + 22, y, x + 32, y, 1, c)
}

func box(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ title: String, _ lines: [String] = [], fill: CGColor = cLight, size: CGFloat = 8, bold: Bool = true) {
	rect(x, y, w, h, fill: fill, stroke: cBlack, lw: 1.1, r: 4)
	text(title, x + w / 2, y + 12, size: 9, bold: bold, align: 1)
	var yy = y + 24
	for l in lines { text(l, x + w / 2, yy, size: size, align: 1); yy += size + 2 }
}

// Tables.
struct Table {
	var widths: [CGFloat]
	var header: [String]
	var rows: [[String]]
	var size: CGFloat = 8
}

/// Draws a table starting at (x, y); returns the y below it. Rows that don't fit stop at `limit` and are returned.
@discardableResult
func drawTable(_ t: Table, _ x: CGFloat, _ y: CGFloat, limit: CGFloat = PH - 30, from start: Int = 0, next: inout Int) -> CGFloat {
	var yy = y
	func rowHeight(_ r: [String]) -> CGFloat {
		var lines = 1
		for (i, c) in r.enumerated() { lines = max(lines, wrap(c, width: t.widths[i] - 6, size: t.size).count) }
		return CGFloat(lines) * (t.size + 2) + 4
	}
	func drawRow(_ r: [String], head: Bool, fill: CGColor?) {
		let h = rowHeight(r)
		if let f = fill { rect(x, yy, t.widths.reduce(0, +), h, fill: f, stroke: nil) }
		var xx = x
		for (i, c) in r.enumerated() {
			var ly = yy + t.size + 1
			for l in wrap(c, width: t.widths[i] - 6, size: t.size, bold: head) { text(l, xx + 3, ly, size: t.size, bold: head); ly += t.size + 2 }
			xx += t.widths[i]
		}
		line(x, yy + h, x + t.widths.reduce(0, +), yy + h, 0.4, cGray)
		yy += h
	}
	drawRow(t.header, head: true, fill: cLight)
	var i = start
	while i < t.rows.count {
		if yy + rowHeight(t.rows[i]) > limit { next = i; return yy }
		drawRow(t.rows[i], head: false, fill: i % 2 == 1 ? rgb(0.97, 0.97, 0.98) : nil)
		i += 1
	}
	next = t.rows.count
	return yy
}
