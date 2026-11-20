/// Turns a `BoardState` into frames over time: the lights from `DitherField`, the tile heights from the motion
/// settings, and the slew limit that keeps the motors quiet. The preview in the apps and the firmware both call
/// `step`, so what you see in the app is what the board does.
public struct BoardRenderer: Sendable {
	private let field = DitherField()
	private var lightOffset: (x: Float, y: Float) = (0, 0)
	private var motionOffset: (x: Float, y: Float) = (0, 0)
	private var ripplePhase: Float = 0
	private var positions: [Float] = []

	public init() {}

	/// Advances time by `seconds` and returns the frame to show now.
	public mutating func step(seconds: Float, state raw: BoardState, geometry g: BoardGeometry) -> BoardFrame {
		let state = raw.bounded()
		let dt = clamp(seconds, 0, 0.1)
		lightOffset = DitherField.advance(lightOffset, seconds: dt, settings: state.dither)
		let m = state.motion
		motionOffset = DitherField.travel(motionOffset, degrees: m.waveDirection, speed: m.waveSpeed * 4, seconds: dt)
		ripplePhase += m.rippleSpeed * dt
		ripplePhase -= ripplePhase.rounded(.down)

		let brightness: Float = state.isOn ? 0.25 + 0.75 * state.brightness : 0
		var frame = field.render(state.dither, geometry: g, offset: lightOffset, brightness: brightness)

		if positions.count != g.tileCount { positions = Array(repeating: 0, count: g.tileCount) }
		let targets = targetHeights(state: state, levels: frame.tileLevels, geometry: g)
		slew(towards: targets, motion: m, seconds: dt)

		let top = Float(g.heightLevels - 1)
		for i in 0 ..< g.tileCount {
			frame.lift[i] = positions[i]
			frame.heights[i] = UInt8(clamp((positions[i] * top + 0.5).rounded(.down), 0, top))
		}
		return frame
	}

	/// Where each tile wants to be, 0...1, before the speed limit.
	func targetHeights(state: BoardState, levels: [Float], geometry g: BoardGeometry) -> [Float] {
		let m = state.motion
		var out = [Float](repeating: 0, count: g.tileCount)
		guard m.isEnabled, state.isOn, m.source != .off else { return out }
		let n = g.tilesPerSide
		for row in 0 ..< n {
			for column in 0 ..< n {
				let i = row * n + column
				let u = (Float(column) + 0.5) / Float(n), v = (Float(row) + 0.5) / Float(n)
				var h: Float
				switch m.source {
					case .lights: h = levels[i]
					case .invertedLights: h = 1 - levels[i]
					case .wave:
						let x = u * Float(n) * m.waveFrequency / (4 * m.waveScale) - motionOffset.x
						let y = v * Float(n) * m.waveFrequency / (4 * m.waveScale) - motionOffset.y
						h = clamp(0.5 + 0.6 * field.noise(x + 5.3, y + 9.1), 0, 1)
					case .ripple:
						let ox = Float(m.rippleOrigin % 3) * 0.5, oy = Float(m.rippleOrigin / 3) * 0.5
						let dx = (u - ox) * Float(n), dy = (v - oy) * Float(n)
						let d = squareRoot(dx * dx + dy * dy)
						h = 0.5 + 0.5 * cosine(2 * Float.pi * (d / m.rippleSpacing - ripplePhase))
					case .off: h = 0
				}
				out[i] = clamp(h, 0, 1) * m.strength
			}
		}
		return out
	}

	/// Moves every tile towards its target, no faster than the speed setting and with at most `maxMovingTiles`
	/// moving at once (the ones furthest from their target go first). Quiet mode is slower and allows fewer.
	private mutating func slew(towards targets: [Float], motion m: MotionSettings, seconds: Float) {
		// One full stroke takes 2.5 s at speed 0 and 0.4 s at speed 1.
		var rate = 0.4 + 2.1 * m.speed
		var allowed = m.maxMovingTiles
		if m.quietMode { rate *= 0.4; allowed = max(1, allowed / 2) }
		let maxStep = rate * seconds
		// Tiles within one motor step of their target stay put: no needless ticking.
		let deadband: Float = 0.02

		var order = Array(0 ..< positions.count)
		order.sort { abs(targets[$0] - positions[$0]) > abs(targets[$1] - positions[$1]) }
		var moving = 0
		for i in order {
			let error = targets[i] - positions[i]
			if abs(error) <= deadband { continue }
			if moving >= allowed { break }
			moving += 1
			let step = min(abs(error), maxStep)
			positions[i] += error > 0 ? step : -step
		}
	}
}
