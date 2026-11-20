import BoardKit
import SwiftUI

/// A live, to-scale preview of the board: every LED as a square, grouped into tiles,
/// with each tile's height shown as a lift + shadow. Uses the same BoardKit renderer as the firmware.
struct BoardPreview: View {
	var state: BoardState
	var geometry: BoardGeometry

	@State private var renderer = PreviewRenderer()

	var body: some View {
		TimelineView(.animation(minimumInterval: 1 / 30, paused: !state.isOn)) { context in
			let frame = renderer.frame(at: context.date, state: state, geometry: geometry)
			Canvas { ctx, size in
				draw(frame, in: ctx, size: size)
			}
		}
		.aspectRatio(1, contentMode: .fit)
		.accessibilityLabel("Board preview")
	}

	private func draw(_ frame: BoardFrame, in ctx: GraphicsContext, size: CGSize) {
		let g = frame.geometry
		let border = size.width * 0.045
		let tileGap = size.width * 0.006
		let grid = size.width - border * 2
		let tilePitch = grid / CGFloat(g.tilesPerSide)
		let tileSize = tilePitch - tileGap
		let led = tileSize / CGFloat(g.ledsPerTileSide)
		let wall = led * 0.09

		ctx.fill(Path(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: size.width * 0.02), with: .color(.black))

		for tr in 0 ..< g.tilesPerSide {
			for tc in 0 ..< g.tilesPerSide {
				let h = CGFloat(frame.height(tileColumn: tc, tileRow: tr)) / CGFloat(max(g.heightLevels - 1, 1))
				let lift = h * tilePitch * 0.07
				let origin = CGPoint(x: border + CGFloat(tc) * tilePitch + tileGap / 2 - lift,
				                     y: border + CGFloat(tr) * tilePitch + tileGap / 2 - lift)
				let tileRect = CGRect(origin: origin, size: CGSize(width: tileSize, height: tileSize))
				// shadow grows as the tile rises
				var shadow = ctx
				shadow.addFilter(.shadow(color: .black.opacity(0.9), radius: 1 + lift * 1.5, x: lift, y: lift))
				shadow.fill(Path(tileRect), with: .color(Color(white: 0.04)))

				for lr in 0 ..< g.ledsPerTileSide {
					for lc in 0 ..< g.ledsPerTileSide {
						let p = frame.pixel(column: tc * g.ledsPerTileSide + lc, row: tr * g.ledsPerTileSide + lr)
						let rect = CGRect(x: origin.x + CGFloat(lc) * led + wall / 2,
						                  y: origin.y + CGFloat(lr) * led + wall / 2,
						                  width: led - wall, height: led - wall)
						ctx.fill(Path(rect), with: .color(Color(red: Double(p.r) / 255, green: Double(p.g) / 255, blue: Double(p.b) / 255)))
					}
				}
			}
		}
	}
}

/// Integrates wave travel between frames so speed changes never jump.
@MainActor
final class PreviewRenderer {
	private let field = DitherField()
	private var offset: (x: Float, y: Float) = (0, 0)
	private var last: Date?

	func frame(at date: Date, state: BoardState, geometry: BoardGeometry) -> BoardFrame {
		let dt = Float(min(last.map { date.timeIntervalSince($0) } ?? 0, 0.1))
		last = date
		offset = DitherField.advance(offset, seconds: dt, settings: state.dither)
		let brightness: Float = state.isOn ? 0.25 + 0.75 * state.brightness : 0
		return field.render(state.dither, geometry: geometry, offset: offset, brightness: brightness)
	}
}
