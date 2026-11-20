// Draws the Board app icon with the real BoardKit renderer: a 4 × 4 board of dithered LED tiles, a few lifted.
// Build it together with BoardKit's sources (they're one module here, so there is no `import BoardKit`):
//   mkdir -p /tmp/mk && cp Tools/MakeIcon.swift /tmp/mk/main.swift   # top-level code needs a main.swift
//   swiftc -O /tmp/mk/main.swift ../shared/BoardKit/Sources/BoardKit/*.swift -o /tmp/makeicon
//   /tmp/makeicon <output.png> [plate]
// `plate` draws a macOS-style rounded plate with margin on a transparent canvas; without it the art fills the square.
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let size = 1024
let output = CommandLine.arguments.dropFirst().first ?? "/tmp/icon.png"
let plate = CommandLine.arguments.contains("plate")

// A frame with a few tiles raised: a ripple that has spread out from the lower left.
var state = BoardState()
state.dither = Preset.builtIn[0].settings
state.dither.colorLevels = 5
state.dither.contrast = 1.5
state.dither.brightness = 0.1
state.dither.backgroundColor = RGB(0.03, 0.01, 0.1)
state.brightness = 1
state.dither.waveSpeed = 0
state.motion.source = .ripple
state.motion.rippleOrigin = 6
state.motion.rippleSpacing = 4
state.motion.strength = 1
state.motion.speed = 1
state.motion.maxMovingTiles = 16
var renderer = BoardRenderer()
var frame = renderer.step(seconds: 0, state: state, geometry: .standard)
// Settle the lift, with the lights still: nudge the offset once so the field is a good-looking moment.
for _ in 0 ..< 14 { frame = renderer.step(seconds: 0.1, state: state, geometry: .standard) }
for _ in 0 ..< 40 { frame = renderer.step(seconds: 0.1, state: { var s = state; s.dither.waveSpeed = 0.03; return s }(), geometry: .standard) }

let space = CGColorSpace(name: CGColorSpace.sRGB)!
let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0, space: space,
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
ctx.translateBy(x: 0, y: CGFloat(size))
ctx.scaleBy(x: 1, y: -1)

func color(_ r: Double, _ g: Double, _ b: Double, _ a: Double = 1) -> CGColor {
	CGColor(colorSpace: space, components: [r, g, b, a])!
}

let margin = plate ? CGFloat(100) : 0
let side = CGFloat(size) - margin * 2
let origin = CGPoint(x: margin, y: margin)
let corner = plate ? side * 0.225 : 0

ctx.saveGState()
if plate {
	ctx.setShadow(offset: CGSize(width: 0, height: -10), blur: 28, color: color(0, 0, 0, 0.45))
}
let platePath = CGPath(roundedRect: CGRect(origin: origin, size: CGSize(width: side, height: side)), cornerWidth: corner, cornerHeight: corner, transform: nil)
ctx.addPath(platePath)
ctx.setFillColor(color(0.015, 0.012, 0.03))
ctx.fillPath()
ctx.restoreGState()
ctx.addPath(platePath)
ctx.clip()

// Soft backlight so the board reads against the dark.
let glow = CGGradient(colorsSpace: space, colors: [color(0.22, 0.08, 0.38, 0.55), color(0.02, 0.01, 0.05, 0)] as CFArray, locations: [0, 1])!
ctx.drawRadialGradient(glow, startCenter: CGPoint(x: origin.x + side * 0.35, y: origin.y + side * 0.7), startRadius: 0,
                       endCenter: CGPoint(x: origin.x + side * 0.35, y: origin.y + side * 0.7), endRadius: side * 0.8, options: [])

let g = frame.geometry
let border = side * 0.1
let grid = side - border * 2
let pitch = grid / CGFloat(g.tilesPerSide)
let gap = pitch * 0.07
let tileSize = pitch - gap
let led = tileSize / CGFloat(g.ledsPerTileSide)
let wall = led * 0.14

let order = (0 ..< g.tileCount).sorted { frame.lift[$0] < frame.lift[$1] }
for index in order {
	let tc = index % g.tilesPerSide, tr = index / g.tilesPerSide
	let h = CGFloat(frame.lift[index])
	let lift = h * pitch * 0.09
	let tile = CGRect(x: origin.x + border + CGFloat(tc) * pitch + gap / 2 - lift, y: origin.y + border + CGFloat(tr) * pitch + gap / 2 - lift,
	                  width: tileSize, height: tileSize)
	ctx.saveGState()
	ctx.setShadow(offset: CGSize(width: lift * 0.9, height: -lift * 0.9), blur: 6 + lift * 1.6, color: color(0, 0, 0, 0.85))
	ctx.setFillColor(color(0.03, 0.03, 0.04))
	ctx.addPath(CGPath(roundedRect: tile, cornerWidth: pitch * 0.05, cornerHeight: pitch * 0.05, transform: nil))
	ctx.fillPath()
	ctx.restoreGState()

	for lr in 0 ..< g.ledsPerTileSide {
		for lc in 0 ..< g.ledsPerTileSide {
			let p = frame.pixel(column: tc * g.ledsPerTileSide + lc, row: tr * g.ledsPerTileSide + lr)
			let rect = CGRect(x: tile.minX + CGFloat(lc) * led + wall / 2, y: tile.minY + CGFloat(lr) * led + wall / 2, width: led - wall, height: led - wall)
			ctx.setFillColor(color(Double(p.r) / 255, Double(p.g) / 255, Double(p.b) / 255))
			ctx.fill(rect)
		}
	}
}

guard let image = ctx.makeImage(),
      let destination = CGImageDestinationCreateWithURL(URL(fileURLWithPath: output) as CFURL, UTType.png.identifier as CFString, 1, nil) else { exit(1) }
CGImageDestinationAddImage(destination, image, nil)
guard CGImageDestinationFinalize(destination) else { exit(1) }
print("wrote \(output)")
