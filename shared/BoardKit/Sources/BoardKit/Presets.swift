#if !hasFeature(Embedded)
	/// A named look. Presets are made and used in the apps; the board only ever receives the resulting settings.
	public struct Preset: Identifiable, Hashable, Codable, Sendable {
		public var id: String
		public var name: String
		public var settings: DitherSettings
		public var isCustom: Bool

		public init(id: String? = nil, name: String, settings: DitherSettings, isCustom: Bool = false) {
			self.id = id ?? name
			self.name = name
			self.settings = settings.bounded()
			self.isCustom = isCustom
		}

		private static func make(_ name: String, _ configure: (inout DitherSettings) -> Void) -> Preset {
			var s = DitherSettings()
			configure(&s)
			return Preset(name: name, settings: s)
		}

		/// Stipple's presets, re-tuned for 16 × 16 LEDs (so no gaps, corner radii or joined squares).
		public static let builtIn: [Preset] = [
			make("Aurora") { _ in },
			make("Ember") { s in
				s.waveSpeed = 0.02; s.colorLevels = 10
				s.waveColor = .black; s.backgroundColor = .black
				s.palette = [RGB(hex: 0x7A5230), RGB(hex: 0xC9A07A)]
			},
			make("Phosphor") { s in
				s.waveColor = RGB(hex: 0x39FF6A); s.backgroundStyle = .black; s.backgroundColor = .black
				s.palette = []; s.pattern = .lines; s.colorLevels = 3; s.waveSpeed = 0.04; s.waveDirection = 180
			},
			make("Tide") { s in
				s.palette = [RGB(hex: 0x0B3D91), RGB(hex: 0x1E88E5), RGB(hex: 0x4DD0E1), RGB(hex: 0xE0F7FA)]
				s.backgroundColor = RGB(hex: 0x020814); s.pattern = .halftone; s.waveDirection = 90; s.scale = 1.4
			},
			make("Bloom") { s in
				s.palette = [RGB(hex: 0xFF5F6D), RGB(hex: 0xFFC371), RGB(hex: 0xC471F5)]
				s.colorField = true; s.backgroundColor = RGB(hex: 0x12030A); s.cellSize = 2; s.colorLevels = 3
			},
			make("Mono") { s in
				s.waveColor = .white; s.backgroundStyle = .black; s.backgroundColor = .black
				s.palette = []; s.pattern = .bayer4; s.colorLevels = 2; s.waveSpeed = 0.03
			},
			make("Paper") { s in
				s.waveColor = RGB(hex: 0xF2EDE3); s.colorPlacement = .background; s.squareStyle = .black
				s.palette = []; s.pattern = .crosshatch; s.contrast = 1.3
			},
			make("Sunset") { s in
				s.palette = [RGB(hex: 0x2B1055), RGB(hex: 0xD53369), RGB(hex: 0xFF8C42), RGB(hex: 0xFFD166)]
				s.backgroundColor = RGB(hex: 0x10031C); s.waveDirection = 0; s.scale = 0.8; s.colorLevels = 5; s.waveSpeed = 0.03
			},
			make("Haze") { s in
				s.palette = [RGB(hex: 0x5B5FEF), RGB(hex: 0xA77BFF), RGB(hex: 0xFF9EC7)]
				s.colorField = true; s.backgroundColor = RGB(hex: 0x0A0820); s.blur = 0.6; s.pattern = .bayer4; s.waveSpeed = 0.025
			},
			make("Glacier") { s in
				s.waveColor = RGB(hex: 0xBFEFFF); s.palette = []; s.backgroundStyle = .dim; s.pattern = .bayer2
				s.waveSpeed = 0.015; s.waveDirection = 270; s.contrast = 1.2
			},
			make("Lava") { s in
				s.palette = [RGB(hex: 0x3A0000), RGB(hex: 0xB31312), RGB(hex: 0xFF6A00), RGB(hex: 0xFFE259)]
				s.backgroundStyle = .black; s.cellSize = 2; s.waveAmplitude = 0.6; s.waveSpeed = 0.035; s.colorLevels = 6
			},
			make("Neon") { s in
				s.palette = [RGB(hex: 0x00F5FF), RGB(hex: 0xFF00E5)]
				s.colorField = true; s.backgroundStyle = .black; s.pattern = .lines; s.contrast = 1.6
				s.waveSpeed = 0.06; s.waveDirection = 45
			},
			make("Sakura") { s in
				s.palette = [RGB(hex: 0xFFD6E0), RGB(hex: 0xFF8FAB), RGB(hex: 0xFB6F92)]
				s.backgroundColor = RGB(hex: 0x1C0A12); s.pattern = .halftone; s.cellSize = 2
				s.waveSpeed = 0.02; s.waveDirection = 225
			},
			make("Moss") { s in
				s.palette = [RGB(hex: 0x1B4332), RGB(hex: 0x40916C), RGB(hex: 0x95D5B2)]
				s.backgroundColor = RGB(hex: 0x050F0A); s.pattern = .noise; s.scale = 1.8; s.waveSpeed = 0.02
			},
			make("Midnight") { s in
				s.waveColor = RGB(hex: 0x3D5AFE); s.palette = []; s.backgroundStyle = .black
				s.brightness = -0.2; s.contrast = 1.4; s.waveSpeed = 0.012
			},
			make("Sepia") { s in
				s.waveColor = RGB(hex: 0x704214); s.colorPlacement = .background; s.squareStyle = .white
				s.palette = []; s.pattern = .bayer8; s.colorLevels = 3; s.waveSpeed = 0.02
			},
			make("Candy") { s in
				s.palette = [RGB(hex: 0xFFADAD), RGB(hex: 0xFDFFB6), RGB(hex: 0xCAFFBF), RGB(hex: 0x9BF6FF), RGB(hex: 0xBDB2FF)]
				s.colorField = true; s.backgroundColor = RGB(hex: 0x15101F); s.cellSize = 2; s.colorLevels = 3; s.waveSpeed = 0.03
			},
			make("Static") { s in
				s.waveColor = .white; s.palette = []; s.backgroundStyle = .black; s.pattern = .noise
				s.waveFrequency = 8; s.scale = 3; s.waveSpeed = 0.066
			},
		]
	}

	/// A set of colours that can be applied everywhere at once: the dither palette, the timer bar and the sun.
	public struct ColorTheme: Identifiable, Hashable, Codable, Sendable {
		public var id: String
		public var name: String
		public var colors: [RGB]
		public var isCustom: Bool

		public init(id: String? = nil, name: String, colors: [RGB], isCustom: Bool = false) {
			self.id = id ?? name
			self.name = name
			self.colors = Array(colors.prefix(DitherSettings.maxPaletteCount)).map { $0.clamped }
			self.isCustom = isCustom
		}

		/// Dither palette ← every colour; timer bar and sun ← the brightest; night sky ← the darkest.
		public func apply(to state: inout BoardState) {
			guard !colors.isEmpty else { return }
			state.dither.palette = colors
			let byLight = colors.sorted { $0.luminance < $1.luminance }
			state.timer.barColor = byLight.last!
			state.ambient.sunColor = byLight.last!
			state.ambient.nightSky = byLight.first!.scaled(0.25)
		}

		private static func theme(_ name: String, _ hex: [UInt32]) -> ColorTheme { ColorTheme(name: name, colors: hex.map { RGB(hex: $0) }) }

		public static let builtIn: [ColorTheme] = [
			theme("Aurora", [0x1FD9FF, 0x8C2EFF, 0xFF338C, 0xFFB82E]),
			theme("Ember", [0x7A5230, 0xC9A07A, 0xFFD9A8]),
			theme("Tide", [0x0B3D91, 0x1E88E5, 0x4DD0E1, 0xE0F7FA]),
			theme("Sunset", [0x2B1055, 0xD53369, 0xFF8C42, 0xFFD166]),
			theme("Moss", [0x1B4332, 0x40916C, 0x95D5B2]),
			theme("Sakura", [0xFFD6E0, 0xFF8FAB, 0xFB6F92]),
			theme("Neon", [0x00F5FF, 0xFF00E5]),
			theme("Candy", [0xFFADAD, 0xFDFFB6, 0xCAFFBF, 0x9BF6FF, 0xBDB2FF]),
			theme("Lava", [0x3A0000, 0xB31312, 0xFF6A00, 0xFFE259]),
			theme("Mono", [0x202020, 0x808080, 0xFFFFFF]),
		]
	}
#endif
