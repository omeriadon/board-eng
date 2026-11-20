// Renderers for Ambient and Music Mirror. Like DitherField, plain Swift with no Foundation or libm.

public enum AmbientField {
	/// The sky, sun, moon and stars at `hour` (0...24). `seconds` drives the stars' twinkle.
	public static func render(_ a: AmbientSettings, geometry g: BoardGeometry, hour: Float, seconds: Float, brightness: Float) -> BoardFrame {
		var frame = BoardFrame(geometry: g)
		let side = g.pixelsPerSide
		let size = Float(side)
		let horizon = size * 0.78

		// Day runs sunrise → sunset; night is the rest. `progress` is how far through whichever one it is.
		let isDay = hour >= a.sunrise && hour <= a.sunset
		let nightLength = 24 - a.sunset + a.sunrise
		let progress: Float
		if isDay {
			progress = (hour - a.sunrise) / max(a.sunset - a.sunrise, 0.01)
		} else {
			progress = (hour > a.sunset ? hour - a.sunset : hour + 24 - a.sunset) / max(nightLength, 0.01)
		}
		let arc = sine(Float.pi * clamp(progress, 0, 1))
		let elevation = isDay ? arc : -arc

		let dayFactor = smoothstep(-0.05, 0.35, elevation)
		let nightFactor = 1 - smoothstep(-0.12, 0.12, elevation)
		let twilightFactor = clamp(1 - abs(elevation) * 4, 0, 1)

		let bodyX = (0.07 + 0.86 * clamp(progress, 0, 1)) * size
		let bodyY = horizon - arc * (horizon - 2.6)

		for row in 0 ..< side {
			for column in 0 ..< side {
				let px = Float(column) + 0.5, py = Float(row) + 0.5
				var color: RGB

				if py >= horizon {
					// Dark ground silhouette that picks up a little of the sky's light.
					color = RGB(0.01, 0.012, 0.02).mixed(a.twilight, twilightFactor * 0.08).mixed(a.daySky, dayFactor * 0.06)
				} else {
					let toHorizon = clamp(py / horizon, 0, 1)
					color = a.nightSky.mixed(a.daySky, dayFactor)
					color = color.mixed(a.twilight, twilightFactor * toHorizon * toHorizon * 0.9)

					if a.showStars, nightFactor > 0.05, py < horizon * 0.85 {
						let h = hash(column, row)
						if h % 100 < 5 {
							let phase = Float(h % 628) / 100
							let twinkle = 0.55 + 0.45 * sine(seconds * 2 + phase)
							color = color.mixed(RGB.white, nightFactor * twinkle * 0.85)
						}
					}

					if isDay || elevation > -0.2 {
						let dx = px - bodyX, dy = py - bodyY
						let d = squareRoot(dx * dx + dy * dy)
						let core = clamp(1 - (d - 1.2) / 0.9, 0, 1)
						let halo = a.glow * clamp(1 - d / 7, 0, 1)
						let sunVisible = 1 - smoothstep(0.1, 0.35, -elevation)
						color = color.mixed(a.sunColor, halo * halo * 0.65 * sunVisible).mixed(a.sunColor, core * sunVisible)
					}

					if a.showMoon, !isDay, nightFactor > 0.2 {
						let dx = px - bodyX, dy = py - bodyY
						let d = squareRoot(dx * dx + dy * dy)
						let core = clamp(1 - (d - 1.0) / 0.8, 0, 1)
						color = color.mixed(RGB(0.86, 0.9, 1), core * nightFactor)
					}
				}
				frame.pixels[row * side + column] = color.scaled(brightness).pixel
			}
		}
		return frame
	}

	@inline(__always) static func hash(_ x: Int, _ y: Int) -> Int {
		var h = UInt32(truncatingIfNeeded: x &* 374761393 &+ y &* 668265263)
		h = (h ^ (h >> 13)) &* 1274126177
		return Int((h ^ (h >> 16)) & 0x7FFFFFFF)
	}
}

public enum MusicField {
	/// The album art (optionally dithered with the dither settings) with the progress bar on the bottom two rows.
	/// Returns nil when there's no usable art, so the caller can fall back to another mode.
	public static func render(artwork: Artwork?, music m: MusicSettings, dither: DitherSettings, field: DitherField,
	                          geometry g: BoardGeometry, brightness: Float) -> BoardFrame? {
		guard let art = artwork, art.isValid else { return nil }
		var frame = BoardFrame(geometry: g)
		let side = g.pixelsPerSide
		let levels = max(dither.colorLevels, 2) - 1
		let usesThreshold = m.ditherArt && dither.ditherStrength != 0 && dither.pattern != .none

		for row in 0 ..< side {
			for column in 0 ..< side {
				// Nearest pixel of the art, so a different-sized artwork still fills the board.
				let ax = min(art.side - 1, column * art.side / side), ay = min(art.side - 1, row * art.side / side)
				var c = art.pixels[ay * art.side + ax].rgb
				if m.ditherArt {
					let t = usesThreshold ? (field.threshold(column, row, dither.pattern) - 0.5) * dither.ditherStrength / levels : 0
					@inline(__always) func q(_ v: Float) -> Float { clamp((clamp(v + t, 0, 1) * levels + 0.5).rounded(.down) / levels, 0, 1) }
					c = RGB(q(c.r), q(c.g), q(c.b))
				}
				frame.pixels[row * side + column] = c.scaled(brightness).pixel
			}
		}

		if m.showsProgress, side >= 4 {
			let margin = side - 2, barRow = side - 1
			for column in 0 ..< side {
				frame.pixels[margin * side + column] = .off
				let lit = clamp(m.progress * Float(side) - Float(column), 0, 1)
				let bar = RGB(0.07, 0.07, 0.08).mixed(RGB(1, 1, 1), 0.85 * lit)
				frame.pixels[barRow * side + column] = bar.scaled(brightness).pixel
			}
		}
		return frame
	}
}
