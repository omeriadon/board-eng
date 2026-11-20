/// Turns a `BoardState` into frames over time: the lights for the current mode, the tile heights from the motion
/// settings, and the slew limit that keeps the motors quiet. The preview in the apps and the firmware both call
/// `step`, so what you see in the app is what the board does.
public struct BoardRenderer: Sendable {
	private let field = DitherField()
	private var lightOffset: (x: Float, y: Float) = (0, 0)
	private var motionOffset: (x: Float, y: Float) = (0, 0)
	private var ripplePhase: Float = 0
	private var clock: Float = 0
	private var positions: [Float] = []

	/// The current album art (Music Mirror). The firmware stores the last one it received.
	public var artwork: Artwork?
	/// A beat just landed: 1 right after it, falling to 0. Set by whoever detects beats (the Mac); nothing yet.
	public var beatPulse: Float = 0

	public init() {}

	/// Advances time by `seconds` and returns the frame to show now.
	public mutating func step(seconds: Float, state raw: BoardState, geometry g: BoardGeometry,
	                          context: RenderContext = RenderContext()) -> BoardFrame {
		let state = Automation.effective(raw.bounded(), context: context)
		let dt = clamp(seconds, 0, 0.1)
		clock += dt
		lightOffset = DitherField.advance(lightOffset, seconds: dt, settings: state.dither)
		let m = state.motion
		motionOffset = DitherField.travel(motionOffset, degrees: m.waveDirection, speed: m.waveSpeed * 4, seconds: dt)
		ripplePhase += m.rippleSpeed * dt
		ripplePhase -= ripplePhase.rounded(.down)
		beatPulse = max(0, beatPulse - dt * 4)

		let brightness: Float = state.isOn ? 0.25 + 0.75 * state.brightness : 0
		var frame = lights(state: state, geometry: g, context: context, brightness: brightness)

		if positions.count != g.tileCount { positions = Array(repeating: 0, count: g.tileCount) }
		var targets = targetHeights(state: state, levels: frame.tileLevels, geometry: g)
		if state.mode == .music, state.music.beatJump > 0, beatPulse > 0, state.motion.isEnabled, state.isOn {
			let bump = beatPulse * state.music.beatJump
			for i in 0 ..< targets.count { targets[i] = clamp(targets[i] + bump, 0, 1) }
		}
		slew(towards: targets, motion: m, seconds: dt)

		let top = Float(g.heightLevels - 1)
		for i in 0 ..< g.tileCount {
			frame.lift[i] = positions[i]
			frame.heights[i] = UInt8(clamp((positions[i] * top + 0.5).rounded(.down), 0, top))
		}
		return frame
	}

	/// The LEDs for the current mode, with `tileLevels` filled in for the heights.
	private func lights(state: BoardState, geometry g: BoardGeometry, context c: RenderContext, brightness: Float) -> BoardFrame {
		switch state.mode {
			case .dither:
				return field.render(state.dither, geometry: g, offset: lightOffset, brightness: brightness)

			case .ambient:
				let a = state.ambient
				let hour: Float
				if a.timeLapse {
					let t = Float(c.unixMillis % 1_000_000_000) / 1000 / a.lapseSeconds
					hour = (t - t.rounded(.down)) * 24
				} else {
					hour = c.unixMillis > 0 ? c.hourOfDay : 12
				}
				var frame = AmbientField.render(a, geometry: g, hour: hour, seconds: clock, brightness: brightness)
				fillLevels(&frame)
				return frame

			case .music:
				if var frame = MusicField.render(artwork: artwork, music: state.music, geometry: g, brightness: brightness) {
					fillLevels(&frame)
					return frame
				}
				// Nothing playing: keep the board alive with the dither field.
				return field.render(state.dither, geometry: g, offset: lightOffset, brightness: brightness)

			case .timer:
				var frame = field.render(state.dither, geometry: g, offset: lightOffset, brightness: brightness)
				drawTimer(&frame, timer: state.timer, now: c.unixMillis, brightness: brightness)
				return frame
		}
	}

	/// Tile heights from the mean brightness of each tile's LEDs.
	private func fillLevels(_ frame: inout BoardFrame) {
		let g = frame.geometry, side = g.pixelsPerSide
		var sums = [Float](repeating: 0, count: g.tileCount)
		for row in 0 ..< side {
			for column in 0 ..< side {
				let tile = g.tile(forPixelColumn: column, row: row)
				sums[tile.row * g.tilesPerSide + tile.column] += frame.pixels[row * side + column].rgb.luminance
			}
		}
		let perTile = Float(g.ledsPerTileSide * g.ledsPerTileSide)
		for i in 0 ..< g.tileCount { frame.tileLevels[i] = clamp(sums[i] / perTile, 0, 1) }
	}

	/// The timer fills the status bar; the board above keeps showing the dither field.
	private func drawTimer(_ frame: inout BoardFrame, timer t: TimerSettings, now: UInt64, brightness: Float) {
		let remaining = t.fractionRemaining(now: now)
		var shown = t.style == .drain ? remaining : 1 - remaining

		if t.isFinished(now: now) {
			let since = now - t.endsAtMillis
			if t.flashWhenDone, since < TimerSettings.flashMillis {
				shown = (since / 500) % 2 == 0 ? 1 : 0
			} else {
				shown = t.style == .drain ? 0 : 1
			}
		}

		let count = frame.bar.count
		for column in 0 ..< count {
			let lit = clamp(shown * Float(count) - Float(column), 0, 1)
			frame.bar[column] = t.trackColor.mixed(t.barColor, lit).scaled(brightness).pixel
		}
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
