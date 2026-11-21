// Keeps the LED current under what the two 5 V buck converters can supply.
//
// The rule is one sentence: add up what every LED wants (absolute amps, not a brightness), and if the total is over
// the budget, multiply every LED by the same factor so the total lands exactly on the budget. Black LEDs draw nothing,
// so the budget they leave unused is automatically available to the bright ones: a mostly dark picture can go to full
// brightness while an all-white picture is dimmed to what the supply allows. One factor for everything keeps the
// picture's contrast and colours; only the overall level changes.
//
// No Foundation, SIMD or libm: this compiles as Embedded Swift for the firmware.

public enum PowerLimiter {
	/// A WS2812B draws about 20 mA per colour channel at 255 (60 mA for a full white LED). Current is linear in the
	/// 8-bit value, so scaling the value scales the current.
	public static let ampsPerChannel: Float = 0.020
	/// What an LED draws while showing black (its controller chip stays powered). Scaling can't remove this.
	public static let idleAmpsPerLED: Float = 0.001

	/// The current one LED wants, in amps (without the idle draw).
	public static func amps(_ p: Pixel) -> Float {
		Float(Int(p.r) + Int(p.g) + Int(p.b)) / 255 * ampsPerChannel
	}

	/// The factor (0...1) to multiply every draw by so that `total` fits in `budget`. 1 means no change is needed.
	public static func scale(total: Float, budget: Float) -> Float {
		if total <= budget { return 1 }
		if budget <= 0 { return 0 }
		return budget / total
	}

	/// The core of the limiter: the absolute power draw of each LED in, the (possibly scaled-down) draw of each LED
	/// out. Same units in and out; `budget` is in the same unit as the draws.
	public static func limited(_ draws: [Float], budget: Float) -> [Float] {
		var total: Float = 0
		for d in draws { total += d }
		let k = scale(total: total, budget: budget)
		if k == 1 { return draws }
		return draws.map { $0 * k }
	}

	/// Total current of some pixels in amps, idle draw included.
	public static func totalAmps(_ pixels: [Pixel]) -> Float {
		var total = Float(pixels.count) * idleAmpsPerLED
		for p in pixels { total += amps(p) }
		return total
	}

	/// Multiplies the 8-bit values by `k`, rounding down so the result never goes over the budget.
	static func scaled(_ p: Pixel, _ k: Float) -> Pixel {
		if k >= 1 { return p }
		return Pixel(r: UInt8(Float(p.r) * k), g: UInt8(Float(p.g) * k), b: UInt8(Float(p.b) * k))
	}

	/// The factor that keeps both LED buses within `busLimitAmps` each. Both halves get the same factor (the tighter
	/// bus decides), so there is never a visible step in brightness across the board.
	public static func scale(for frame: BoardFrame, busLimitAmps: Float = BoardGeometry.ledBusLimitAmps) -> Float {
		let g = frame.geometry
		var bus: (a: Float, b: Float) = (0, 0)
		var count: (a: Int, b: Int) = (0, 0)
		let side = g.pixelsPerSide
		for i in 0 ..< frame.pixels.count {
			let tile = g.tile(forPixelColumn: i % side, row: i / side)
			if g.ledBus(ofTile: tile.row * g.tilesPerSide + tile.column) == 0 {
				bus.a += amps(frame.pixels[i])
				count.a += 1
			} else {
				bus.b += amps(frame.pixels[i])
				count.b += 1
			}
		}
		// The status bar hangs on the second bus.
		for p in frame.bar { bus.b += amps(p) }
		count.b += frame.bar.count
		let ka = scale(total: bus.a, budget: busLimitAmps - Float(count.a) * idleAmpsPerLED)
		let kb = scale(total: bus.b, budget: busLimitAmps - Float(count.b) * idleAmpsPerLED)
		return ka < kb ? ka : kb
	}

	/// Dims the frame's LEDs (grid and status bar) in place so neither bus goes over its limit. Returns the factor
	/// that was applied (1 = nothing changed). Tile heights are not touched.
	@discardableResult
	public static func limit(_ frame: inout BoardFrame, busLimitAmps: Float = BoardGeometry.ledBusLimitAmps) -> Float {
		let k = scale(for: frame, busLimitAmps: busLimitAmps)
		if k >= 1 { return 1 }
		for i in 0 ..< frame.pixels.count { frame.pixels[i] = scaled(frame.pixels[i], k) }
		for i in 0 ..< frame.bar.count { frame.bar[i] = scaled(frame.bar[i], k) }
		return k
	}
}
