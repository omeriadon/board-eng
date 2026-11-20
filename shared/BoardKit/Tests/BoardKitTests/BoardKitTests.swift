import Testing
@testable import BoardKit
import Foundation

@Suite struct BoardKitTests {
	@Test func geometrySizes() {
		let g = BoardGeometry(tilesPerSide: 5, ledsPerTileSide: 4)
		#expect(g.pixelsPerSide == 20)
		#expect(g.pixelCount == 400)
		#expect(g.tileCount == 25)
		#expect(g.tile(forPixelColumn: 7, row: 19) == (1, 4))
	}

	@Test func frameHasRightShapeAndHeightsInRange() {
		let g = BoardGeometry.standard
		let frame = DitherField().render(DitherSettings(), geometry: g, offset: (0.3, 0.7))
		#expect(frame.pixels.count == g.pixelCount)
		#expect(frame.heights.count == g.tileCount)
		#expect(frame.heights.allSatisfy { Int($0) < g.heightLevels })
	}

	@Test func flatModeKeepsTilesRetracted() {
		var s = DitherSettings()
		s.heightMode = .flat
		let frame = DitherField().render(s, geometry: .standard, offset: (1, 2))
		#expect(frame.heights.allSatisfy { $0 == 0 })
	}

	@Test func zeroBrightnessIsBlack() {
		let frame = DitherField().render(DitherSettings(), geometry: .standard, offset: (0, 0), brightness: 0)
		#expect(frame.pixels.allSatisfy { $0 == .off })
	}

	@Test func sineMatchesFoundation() {
		for i in -40 ... 40 {
			let x = Float(i) * 0.37
			#expect(abs(sine(x) - Foundation.sin(x)) < 0.001)
			#expect(abs(cosine(x) - Foundation.cos(x)) < 0.001)
		}
	}

	@Test func stateRoundTripsThroughJSON() throws {
		var state = BoardState()
		state.mode = .timer
		state.dither.pattern = .halftone
		let data = try JSONEncoder().encode(state)
		#expect(try JSONDecoder().decode(BoardState.self, from: data) == state)
	}

	@Test func hexRoundTrip() {
		#expect(RGB(hex: 0x8C2EFF).hex == 0x8C2EFF)
	}
}
