import Testing
@testable import BoardKit
import Foundation

@Suite struct BoardKitTests {
	@Test func standardBoardIs5x5TilesOf5x5LEDs() {
		let g = BoardGeometry.standard
		#expect(g.tilesPerSide == 5)
		#expect(g.pixelsPerSide == 25)
		#expect(g.pixelCount == 625)
		#expect(g.tileCount == 25)
		#expect(g.tile(forPixelColumn: 7, row: 19) == (1, 3))
	}

	@Test func layoutIsAdjustable() {
		let g = BoardGeometry(tilesPerSide: 6, ledsPerTileSide: 5)
		#expect(g.pixelsPerSide == 30)
		#expect(g.totalLEDCount == 930)
		#expect(g.fullScreenNits(atLimitAmps: 5) < BoardGeometry.standard.fullScreenNits(atLimitAmps: 5))
		let frame = DitherField().render(DitherSettings(), geometry: g, offset: (0.3, 0.7))
		#expect(frame.pixels.count == 900)
		#expect(frame.tileLevels.count == 36)
	}

	@Test func frameHasRightShape() {
		let g = BoardGeometry.standard
		let frame = DitherField().render(DitherSettings(), geometry: g, offset: (0.3, 0.7))
		#expect(frame.pixels.count == g.pixelCount)
		#expect(frame.tileLevels.count == g.tileCount)
		#expect(frame.tileLevels.allSatisfy { $0 >= 0 && $0 <= 1 })
	}

	@Test func limiterLeavesLightLoadsAlone() {
		#expect(PowerLimiter.limited([0.1, 0.2, 0], budget: 1) == [0.1, 0.2, 0])
		#expect(PowerLimiter.scale(total: 3, budget: 3) == 1)
	}

	@Test func limiterScalesEveryLEDByTheSameFactor() {
		let out = PowerLimiter.limited([0.4, 0.2, 0, 0.4], budget: 0.5)
		#expect(abs(out.reduce(0, +) - 0.5) < 1e-6)
		#expect(out[2] == 0)
		#expect(abs(out[0] / out[1] - 2) < 1e-5)
	}

	@Test func limiterZeroBudgetIsBlack() {
		#expect(PowerLimiter.limited([0.1, 0.2], budget: 0) == [0, 0])
	}

	@Test func darkPicturesKeepFullBrightness() {
		// One lit LED on an otherwise black board: nothing may be dimmed.
		var frame = BoardFrame(geometry: .standard)
		frame.pixels[100] = Pixel(r: 255, g: 255, b: 255)
		#expect(PowerLimiter.limit(&frame) == 1)
		#expect(frame.pixels[100] == Pixel(r: 255, g: 255, b: 255))
	}

	@Test func allWhiteIsDimmedToTheBusLimit() {
		let g = BoardGeometry.standard
		var frame = BoardFrame(geometry: g)
		for i in 0 ..< frame.pixels.count { frame.pixels[i] = Pixel(r: 255, g: 255, b: 255) }
		for i in 0 ..< frame.bar.count { frame.bar[i] = Pixel(r: 255, g: 255, b: 255) }
		let k = PowerLimiter.limit(&frame)
		#expect(k > 0.1 && k < 0.3)
		// Neither bus goes over 5 A.
		var a: Float = Float(g.totalLEDCount / 2) * PowerLimiter.idleAmpsPerLED
		var b = a
		let side = g.pixelsPerSide
		for i in 0 ..< frame.pixels.count {
			let t = g.tile(forPixelColumn: i % side, row: i / side)
			if g.ledBus(ofTile: t.row * g.tilesPerSide + t.column) == 0 { a += PowerLimiter.amps(frame.pixels[i]) }
			else { b += PowerLimiter.amps(frame.pixels[i]) }
		}
		for p in frame.bar { b += PowerLimiter.amps(p) }
		#expect(a <= 5 && b <= 5)
		// Uniform scale: the colours stay neutral grey.
		#expect(frame.pixels.allSatisfy { $0.r == $0.g && $0.g == $0.b })
	}

	@Test func theBusSplitIsEven() {
		let g = BoardGeometry.standard
		let first = (0 ..< g.tileCount).filter { g.ledBus(ofTile: $0) == 0 }.count
		#expect(first == 13)
		#expect(g.tileCount - first == 12)  // plus the 25-LED bar = 325 LEDs, the same as bus 0
	}

	@Test func zeroBrightnessIsBlack() {
		let frame = DitherField().render(DitherSettings(), geometry: .standard, offset: (0, 0), brightness: 0)
		#expect(frame.pixels.allSatisfy { $0 == .off })
	}

	@Test func cellSizeMakesBlocksOfEqualPixels() {
		var s = DitherSettings()
		s.cellSize = 4
		let f = DitherField().render(s, geometry: .standard, offset: (0.2, 0.9))
		for tileRow in 0 ..< 4 {
			for tileColumn in 0 ..< 4 {
				let first = f.pixel(column: tileColumn * 4, row: tileRow * 4)
				for dy in 0 ..< 4 { for dx in 0 ..< 4 { #expect(f.pixel(column: tileColumn * 4 + dx, row: tileRow * 4 + dy) == first) } }
			}
		}
	}

	@Test func blurSoftensNeighbours() {
		var s = DitherSettings()
		s.pattern = .noise
		let crisp = DitherField().render(s, geometry: .standard, offset: (0, 0))
		s.blur = 1
		let soft = DitherField().render(s, geometry: .standard, offset: (0, 0))
		#expect(crisp != soft)
	}

	@Test func backgroundPlacementUsesWaveColourAsBackground() {
		var s = DitherSettings()
		s.colorPlacement = .background; s.squareStyle = .black; s.waveColor = RGB(1, 0, 0)
		s.palette = []; s.pattern = .none; s.colorLevels = 2; s.waveAmplitude = 0; s.brightness = -1
		// value 0 everywhere: pure background, which is the wave colour.
		let f = DitherField().render(s, geometry: .standard, offset: (0, 0))
		#expect(f.pixels.allSatisfy { $0.r == 255 && $0.g == 0 })
	}

	@Test func sineMatchesFoundation() {
		for i in -40 ... 40 {
			let x = Float(i) * 0.37
			#expect(abs(sine(x) - Foundation.sin(x)) < 0.001)
			#expect(abs(cosine(x) - Foundation.cos(x)) < 0.001)
		}
	}

	@Test func hexRoundTrip() {
		#expect(RGB(hex: 0x8C2EFF).hex == 0x8C2EFF)
	}

	@Test func builtInPresetsAreAllValid() {
		#expect(Preset.builtIn.count == 18)
		for p in Preset.builtIn { #expect(p.settings == p.settings.bounded()) }
	}
}

@Suite struct MotionTests {
	private func run(_ state: BoardState, seconds: Float) -> BoardFrame {
		var renderer = BoardRenderer()
		var frame = renderer.step(seconds: 0, state: state, geometry: .standard)
		for _ in 0 ..< Int(seconds * 30) { frame = renderer.step(seconds: 1 / 30, state: state, geometry: .standard) }
		return frame
	}

	@Test func disabledMotionKeepsTilesFlat() {
		var s = BoardState()
		s.motion.isEnabled = false
		let f = run(s, seconds: 3)
		#expect(f.heights.allSatisfy { $0 == 0 })
	}

	@Test func zeroStrengthKeepsTilesFlat() {
		var s = BoardState()
		s.motion.strength = 0
		#expect(run(s, seconds: 3).heights.allSatisfy { $0 == 0 })
	}

	@Test func stillSourceKeepsTilesFlat() {
		var s = BoardState()
		s.motion.source = .off
		#expect(run(s, seconds: 3).heights.allSatisfy { $0 == 0 })
	}

	@Test func sourcesActuallyMoveTiles() {
		for source in [HeightSource.lights, .invertedLights, .wave, .ripple] {
			var s = BoardState()
			s.motion.source = source
			s.motion.maxMovingTiles = 16
			let f = run(s, seconds: 4)
			#expect(f.heights.contains { $0 > 0 }, "\(source)")
		}
	}

	@Test func strengthCapsTravel() {
		var s = BoardState()
		s.motion.source = .ripple; s.motion.strength = 0.3; s.motion.maxMovingTiles = 16
		let f = run(s, seconds: 4)
		let top = Float(BoardGeometry.standard.heightLevels - 1)
		#expect(f.heights.allSatisfy { Float($0) <= (0.3 * top).rounded(.up) })
	}

	@Test func onlyMaxMovingTilesMoveAtOnce() {
		var s = BoardState()
		s.motion.source = .ripple; s.motion.maxMovingTiles = 2; s.motion.strength = 1
		var renderer = BoardRenderer()
		_ = renderer.step(seconds: 0, state: s, geometry: .standard)
		let a = renderer.step(seconds: 1 / 30, state: s, geometry: .standard)
		let b = renderer.step(seconds: 1 / 30, state: s, geometry: .standard)
		let moved = zip(a.lift, b.lift).filter { abs($0 - $1) > 1e-6 }.count
		#expect(moved <= 2)
	}

	@Test func quietModeIsSlower() {
		var loud = BoardState(), quiet = BoardState()
		for i in 0 ..< 2 {
			var s = BoardState()
			s.motion.source = .ripple; s.motion.strength = 1; s.motion.maxMovingTiles = 16; s.motion.quietMode = i == 1
			if i == 0 { loud = s } else { quiet = s }
		}
		let l = run(loud, seconds: 0.5).lift.reduce(0, +), q = run(quiet, seconds: 0.5).lift.reduce(0, +)
		#expect(q < l)
	}
}

@Suite struct WireTests {
	private func sampleState() -> BoardState {
		var s = BoardState()
		s.isOn = false; s.brightness = 0.25; s.mode = .timer
		s.dither.pattern = .halftone; s.dither.cellSize = 2; s.dither.blur = 0.5
		s.dither.waveDirection = 270; s.dither.colorField = true
		s.dither.palette = [RGB(hex: 0x123456), RGB(hex: 0xABCDEF)]
		s.dither.backgroundStyle = .dim; s.dither.colorPlacement = .background
		s.motion.source = .ripple; s.motion.rippleOrigin = 8; s.motion.quietMode = true
		s.motion.strength = 0.5; s.motion.maxMovingTiles = 7
		return s.bounded()
	}

	@Test func stateRoundTrips() {
		let message = BoardMessage.state(Revision(counter: 77, origin: 3), sampleState())
		let back = BoardMessage(decoding: message.encoded())
		guard case let .state(rev, state)? = back else { Issue.record("did not decode"); return }
		#expect(rev == Revision(counter: 77, origin: 3))
		// Colours travel as 8-bit, exactly what the LEDs show.
		// Stable: sending what was received changes nothing further.
		#expect(BoardMessage(decoding: BoardMessage.state(rev, state).encoded()) == .state(rev, state))
		#expect(state.dither.pattern == .halftone && state.dither.cellSize == 2 && state.mode == .timer)
		#expect(state.dither.palette.map(\.hex) == [0x123456, 0xABCDEF])
		#expect(state.motion == sampleState().motion)
		#expect(message.encoded().count < 160)
	}

	@Test func otherMessagesRoundTrip() {
		var status = BoardStatus()
		status.firmware = 12; status.uptimeSeconds = 9999; status.temperature = 31.5; status.ambientLight = 0.4
		status.links = 3; status.isHoming = true
		for m in [BoardMessage.status(status), .requestState, .time(unixMillis: 1_795_176_436_251, utcOffsetSeconds: 28800)] {
			#expect(BoardMessage(decoding: m.encoded()) == m)
		}
	}

	@Test func malformedBytesAreRejected() {
		let good = BoardMessage.state(Revision(counter: 1, origin: 1), sampleState()).encoded()
		#expect(BoardMessage(decoding: []) == nil)
		#expect(BoardMessage(decoding: Array(good.dropLast())) == nil)
		#expect(BoardMessage(decoding: good + [0]) == nil)
		var wrongVersion = good; wrongVersion[0] = 99
		#expect(BoardMessage(decoding: wrongVersion) == nil)
		var wrongType = good; wrongType[1] = 99
		#expect(BoardMessage(decoding: wrongType) == nil)
	}

	@Test func corruptValuesAreClamped() {
		var s = sampleState()
		s.motion.strength = 1
		var bytes = BoardMessage.state(Revision(counter: 1, origin: 1), s).encoded()
		// Overwrite the first motion float run with NaN / huge values anywhere after the header.
		for i in stride(from: 10, to: bytes.count - 4, by: 7) { bytes[i] = 0xFF }
		if case let .state(_, state)? = BoardMessage(decoding: bytes) {
			#expect(state == state.bounded())
		}
	}

	@Test func duplicateOverTwoLinksAppliesOnce() {
		var phone = StateSync(origin: 5)
		var board = StateSync(origin: 0)
		var s = phone.state
		s.brightness = 0.9
		let message = phone.change(to: s)
		// The phone sends the same bytes over Bluetooth and Wi-Fi.
		let overBluetooth = BoardMessage(decoding: message.encoded())!
		let overWifi = BoardMessage(decoding: message.encoded())!
		let r_overBluetooth_706 = board.receive(overBluetooth)
		#expect(r_overBluetooth_706)
		let r_overWifi_565 = board.receive(overWifi)
		#expect(!r_overWifi_565)
		#expect(board.state.brightness == 0.9)
	}

	@Test func staleMessagesAreIgnoredAndNewestWins() {
		var phone = StateSync(origin: 5), mac = StateSync(origin: 6), board = StateSync(origin: 0)
		var a = BoardState(); a.brightness = 0.1
		var b = BoardState(); b.brightness = 0.8
		let first = phone.change(to: a)
		let r_first_575 = board.receive(first)
		#expect(r_first_575)
		mac.receive(first)
		let second = mac.change(to: b)
		let r_second_902 = board.receive(second)
		#expect(r_second_902)
		// The first message limps in late over the slower link.
		let r_first_373 = board.receive(first)
		#expect(!r_first_373)
		#expect(board.state.brightness == 0.8)
		// And the phone catches up to the Mac's change, so its next change outranks both.
		phone.receive(second)
		let third = phone.change(to: a)
		let r_third_574 = board.receive(third)
		#expect(r_third_574)
	}

	@Test func jsonStillRoundTripsForStorage() throws {
		let s = sampleState()
		let data = try JSONEncoder().encode(s)
		#expect(try JSONDecoder().decode(BoardState.self, from: data) == s)
	}
}

private extension BoardMessage {
	var stateValue: BoardState? { if case let .state(_, s) = self { s } else { nil } }
}
