/// One rendered frame: a colour per LED (row-major) and a height per tile (row-major).
public struct BoardFrame: Hashable, Sendable {
	public var geometry: BoardGeometry
	public var pixels: [Pixel]
	/// The status bar under the grid, left to right (`geometry.barPixelCount` LEDs).
	public var bar: [Pixel]
	/// 0 ..< geometry.heightLevels for each tile: what the firmware drives the motors to.
	public var heights: [UInt8]
	/// The same heights as smooth positions, 0...1, for drawing.
	public var lift: [Float]
	/// Mean brightness of each tile's LEDs, 0...1.
	public var tileLevels: [Float]

	public init(geometry: BoardGeometry) {
		self.geometry = geometry
		pixels = Array(repeating: .off, count: geometry.pixelCount)
		bar = Array(repeating: .off, count: geometry.barPixelCount)
		heights = Array(repeating: 0, count: geometry.tileCount)
		lift = Array(repeating: 0, count: geometry.tileCount)
		tileLevels = Array(repeating: 0, count: geometry.tileCount)
	}

	public func pixel(column: Int, row: Int) -> Pixel { pixels[row * geometry.pixelsPerSide + column] }
	public func height(tileColumn: Int, tileRow: Int) -> UInt8 { heights[tileRow * geometry.tilesPerSide + tileColumn] }
	public func lift(tileColumn: Int, tileRow: Int) -> Float { lift[tileRow * geometry.tilesPerSide + tileColumn] }
}

/// Renders the animated light field. Pure Swift with no Foundation, SIMD or libm, so the exact same
/// code runs on the Pico W (Embedded Swift), in the server, and in the apps' live preview.
public struct DitherField: Sendable {
	private let permutation: [Int]
	private let gradients: [(Float, Float)]

	public init() {
		var perm = [Int](repeating: 0, count: 578)
		for v in 0 ..< 578 { perm[v] = (34 * v + 1) * v % 289 }
		var grad = [(Float, Float)](repeating: (0, 0), count: 289)
		for i in 0 ..< 289 {
			var gx = fract(Float(i) / 41) * 2 - 1
			let gy = abs(gx) - 0.5
			gx -= (gx + 0.5).rounded(.down)
			let k = 1.79284291400159 - 0.85373472095314 * (gx * gx + gy * gy)
			grad[i] = (gx * Float(k), gy * Float(k))
		}
		permutation = perm
		gradients = grad
	}

	/// Renders the lights at `offset`, the wave travel integrated by the caller (see `advance`).
	/// Heights are left at rest: `BoardRenderer` fills them in.
	public func render(_ s: DitherSettings, geometry g: BoardGeometry, offset: (x: Float, y: Float), brightness: Float = 1) -> BoardFrame {
		var frame = BoardFrame(geometry: g)
		let side = g.pixelsPerSide
		let cell = max(1, min(s.cellSize, side))
		let cells = (side + cell - 1) / cell
		let inv = 1 / Float(side)
		let inverseScale = 1 / max(s.scale, 0.05)
		let levels = max(s.colorLevels, 1.01) - 1
		let usesThreshold = s.ditherStrength != 0 && s.pattern != .none
		let plan = ColorPlan(s)

		var colors = [RGB](repeating: .black, count: side * side)
		var alphas = [Float](repeating: 0, count: side * side)

		for cellRow in 0 ..< cells {
			for cellColumn in 0 ..< cells {
				// The cell samples the field at its centre, so a 2 × 2 or 4 × 4 block shows one value.
				let cx = Float(cellColumn * cell) + Float(cell) * 0.5, cy = Float(cellRow * cell) + Float(cell) * 0.5
				let u = cx * inv, v = cy * inv
				var value = pattern(u * inverseScale - offset.x, v * inverseScale - offset.y, s)
				value = clamp((value - 0.5) * s.contrast + 0.5 + s.brightness, 0, 1)

				let t = usesThreshold ? (threshold(cellColumn, cellRow, s.pattern) - 0.25) * s.ditherStrength : 0
				var opacity = value + t / levels
				opacity = clamp(opacity - 0.2 * (1 - smoothstep(0.45, 0.8, opacity)), 0, 1)
				let alpha = (opacity * levels + 0.5).rounded(.down) / levels

				let color = plan.color(value: value, t: t, alpha: alpha, u: u, v: v)
				for dy in 0 ..< cell {
					for dx in 0 ..< cell {
						let column = cellColumn * cell + dx, row = cellRow * cell + dy
						guard column < side, row < side else { continue }
						colors[row * side + column] = color
						alphas[row * side + column] = alpha
					}
				}
			}
		}

		if s.blur > 0 { colors = Self.blurred(colors, side: side, amount: s.blur) }

		var tileSum = [Float](repeating: 0, count: g.tileCount)
		for row in 0 ..< side {
			for column in 0 ..< side {
				frame.pixels[row * side + column] = colors[row * side + column].scaled(brightness).pixel
				let tile = g.tile(forPixelColumn: column, row: row)
				tileSum[tile.row * g.tilesPerSide + tile.column] += alphas[row * side + column]
			}
		}
		let perTile = Float(g.ledsPerTileSide * g.ledsPerTileSide)
		for i in 0 ..< g.tileCount { frame.tileLevels[i] = tileSum[i] / perTile }
		return frame
	}

	/// Mixes every LED with the average of its eight neighbours.
	static func blurred(_ colors: [RGB], side: Int, amount: Float) -> [RGB] {
		var out = colors
		for row in 0 ..< side {
			for column in 0 ..< side {
				var r: Float = 0, g: Float = 0, b: Float = 0, n: Float = 0
				for dy in -1 ... 1 {
					for dx in -1 ... 1 {
						let x = column + dx, y = row + dy
						guard x >= 0, y >= 0, x < side, y < side else { continue }
						let c = colors[y * side + x]
						r += c.r; g += c.g; b += c.b; n += 1
					}
				}
				out[row * side + column] = colors[row * side + column].mixed(RGB(r / n, g / n, b / n), amount)
			}
		}
		return out
	}

	/// Advances a wave offset by `seconds` along `degrees`. Uses a small polynomial sine so it needs no libm.
	public static func travel(_ offset: (x: Float, y: Float), degrees: Float, speed: Float, seconds: Float) -> (x: Float, y: Float) {
		let radians = degrees * Float.pi / 180
		return (offset.x + cosine(radians) * speed * seconds, offset.y + sine(radians) * speed * seconds)
	}

	public static func advance(_ offset: (x: Float, y: Float), seconds: Float, settings s: DitherSettings) -> (x: Float, y: Float) {
		travel(offset, degrees: s.waveDirection, speed: clamp(s.waveSpeed, 0, DitherSettings.maxWaveSpeed) * 4, seconds: seconds)
	}

	/// Smooth 2-D noise for the motion field, roughly -1...1.
	func noise(_ x: Float, _ y: Float) -> Float { perlin(x, y) }

	// MARK: Field

	@inline(__always)
	private func pattern(_ x: Float, _ y: Float, _ s: DitherSettings) -> Float {
		let wx = fbm(x + 17.3, y + 41.7, s)
		let wy = fbm(x + 73.1, y + 11.9, s)
		return fbm(x + wx - 0.5, y + wy - 0.5, s)
	}

	@inline(__always)
	private func fbm(_ x0: Float, _ y0: Float, _ s: DitherSettings) -> Float {
		var x = x0, y = y0, value: Float = 0, weight: Float = 1
		for _ in 0 ..< 4 {
			value += weight * abs(perlin(x, y))
			x *= s.waveFrequency
			y *= s.waveFrequency
			weight *= s.waveAmplitude
			if weight == 0 { break }
		}
		return value
	}

	/// Classic Perlin noise matching Stipple's (mod-289 permutation, Taylor-normalised gradients).
	@inline(__always)
	func perlin(_ x: Float, _ y: Float) -> Float {
		guard abs(x) < 1e7, abs(y) < 1e7 else { return 0 }
		let floorX = x.rounded(.down), floorY = y.rounded(.down)
		let fx = x - floorX, fy = y - floorY
		var ix = Int(floorX) % 289, iy = Int(floorY) % 289
		if ix < 0 { ix += 289 }
		if iy < 0 { iy += 289 }
		let ix1 = ix == 288 ? 0 : ix + 1, iy1 = iy == 288 ? 0 : iy + 1
		let px0 = permutation[ix], px1 = permutation[ix1]
		let g00 = gradients[permutation[px0 + iy]], g10 = gradients[permutation[px1 + iy]]
		let g01 = gradients[permutation[px0 + iy1]], g11 = gradients[permutation[px1 + iy1]]
		let n00 = g00.0 * fx + g00.1 * fy
		let n10 = g10.0 * (fx - 1) + g10.1 * fy
		let n01 = g01.0 * fx + g01.1 * (fy - 1)
		let n11 = g11.0 * (fx - 1) + g11.1 * (fy - 1)
		let u = fx * fx * fx * (fx * (fx * 6 - 15) + 10)
		let v = fy * fy * fy * (fy * (fy * 6 - 15) + 10)
		let nx0 = n00 + (n10 - n00) * u
		let nx1 = n01 + (n11 - n01) * u
		return 2.3 * (nx0 + (nx1 - nx0) * v)
	}

	// MARK: Thresholds

	private static let bayer8: [Float] = [
		0, 48, 12, 60, 3, 51, 15, 63, 32, 16, 44, 28, 35, 19, 47, 31,
		8, 56, 4, 52, 11, 59, 7, 55, 40, 24, 36, 20, 43, 27, 39, 23,
		2, 50, 14, 62, 1, 49, 13, 61, 34, 18, 46, 30, 33, 17, 45, 29,
		10, 58, 6, 54, 9, 57, 5, 53, 42, 26, 38, 22, 41, 25, 37, 21,
	]
	private static let bayer4: [Float] = [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]
	private static let bayer2: [Float] = [0, 2, 3, 1]

	@inline(__always)
	func threshold(_ column: Int, _ row: Int, _ pattern: DitherPattern) -> Float {
		let x = Float(column), y = Float(row)
		switch pattern {
			case .bayer8: return Self.bayer8[(row % 8) * 8 + column % 8] / 64
			case .bayer4: return Self.bayer4[(row % 4) * 4 + column % 4] / 16
			case .bayer2: return Self.bayer2[(row % 2) * 2 + column % 2] / 4
			case .halftone:
				let rx = fract((x + y) * 0.70710678 / 4) - 0.5, ry = fract((x - y) * 0.70710678 / 4) - 0.5
				return clamp(squareRoot(rx * rx + ry * ry) * 1.41421356, 0, 0.999)
			case .lines: return abs(fract(y / 4) - 0.5) * 2 * 0.999
			case .crosshatch:
				let a = abs(fract((x + y) / 6) - 0.5) * 2, b = abs(fract((x - y) / 6) - 0.5) * 2
				return min(a, b) * 0.999
			case .noise: return fract(52.9829189 * fract(x * 0.06711056 + y * 0.00583715))
			case .none: return 0.25
		}
	}
}

// MARK: - libm-free maths

@inline(__always) func squareRoot(_ v: Float) -> Float { v <= 0 ? 0 : v.squareRoot() }

/// Sine via range reduction + a 7th-order polynomial; plenty for wave direction.
@inline(__always) func sine(_ x: Float) -> Float {
	let twoPi: Float = 6.2831853
	var r = x - (x / twoPi).rounded(.down) * twoPi  // 0 ..< 2π
	if r > Float.pi { r -= twoPi }                    // -π ... π
	var sign: Float = 1
	if r > Float.pi / 2 { r = Float.pi - r } else if r < -Float.pi / 2 { r = -Float.pi - r }
	if r < 0 { r = -r; sign = -1 }
	let r2 = r * r
	return sign * r * (1 - r2 / 6 * (1 - r2 / 20 * (1 - r2 / 42)))
}

@inline(__always) func cosine(_ x: Float) -> Float { sine(x + Float.pi / 2) }

// MARK: - Colour plan

/// Stipple's `ColorPlan`: how a cell's brightness becomes a colour, for every background / placement / palette mode.
struct ColorPlan {
	let levels: Float
	let background: RGB
	let wave: RGB
	let placementBackground: Bool
	let colorField: Bool
	let palette: [RGB]
	let source: [RGB]

	init(_ s: DitherSettings) {
		levels = max(s.colorLevels, 1.01) - 1
		placementBackground = s.colorPlacement == .background
		let effective: RGB = switch s.backgroundStyle {
			case .black: .black
			case .white: .white
			case .dim: s.waveColor.scaled(0.2)
			case .custom: s.backgroundColor
		}
		wave = placementBackground ? (s.squareStyle == .black ? .black : .white) : s.waveColor
		background = placementBackground ? s.waveColor : effective
		source = s.palette
		palette = placementBackground ? [] : s.palette
		colorField = s.colorField && !s.palette.isEmpty
	}

	/// The palette blended across the board: each colour sits on a ring and a point takes a distance-weighted mix.
	func tint(u: Float, v: Float) -> RGB {
		let n = source.count
		var r: Float = 0, g: Float = 0, b: Float = 0, total: Float = 0
		for index in 0 ..< n {
			var px: Float = 0.5, py: Float = 0.5
			if n > 1 {
				let angle = Float(index) / Float(n) * 2 * Float.pi - Float.pi / 2
				px = 0.5 + cosine(angle) * 0.38
				py = 0.5 + sine(angle) * 0.38
			}
			let dx = u - px, dy = v - py
			let w = 1 / (dx * dx + dy * dy + 0.015)
			r += source[index].r * w; g += source[index].g * w; b += source[index].b * w
			total += w
		}
		total = max(total, 0.0001)
		var c = RGB(r / total, g / total, b / total)
		let peak = max(c.r, max(c.g, c.b))
		let gain = 2.85 + (1.2 - 2.85) * smoothstep(0.12, 0.85, peak)
		c = RGB(clamp(c.r * gain + 0.24, 0, 1), clamp(c.g * gain + 0.24, 0, 1), clamp(c.b * gain + 0.24, 0, 1))
		return c
	}

	func color(value: Float, t: Float, alpha: Float, u: Float, v: Float) -> RGB {
		var back = background
		let foreground: RGB
		if colorField {
			let tint = tint(u: u, v: v)
			back = placementBackground ? tint : background
			foreground = placementBackground ? wave : tint
		} else if palette.count > 1 {
			let count = Float(palette.count)
			var pv = value + t / (count - 1)
			pv = clamp(pv - 0.2 * (1 - smoothstep(0.45, 0.8, pv)), 0, 1)
			foreground = palette[min(palette.count - 1, Int((pv * (count - 1) + 0.5).rounded(.down)))]
		} else {
			foreground = wave
		}
		return back.mixed(foreground, alpha)
	}
}
