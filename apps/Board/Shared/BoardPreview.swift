import BoardKit
import SwiftUI

/// A live, to-scale preview of the board: every LED a square, grouped into tiles, each tile lifted and shadowed by
/// its height. It runs the same `BoardRenderer` as the firmware, including the motion speed limit.
struct BoardPreview: View {
	var state: BoardState
	var geometry: BoardGeometry

	@Environment(BoardStore.self) private var store
	@State private var player = PreviewPlayer()

	var body: some View {
		TimelineView(.animation(minimumInterval: 1 / 30, paused: !state.isOn && player.isSettled)) { context in
			let frame = player.frame(at: context.date, state: state, geometry: geometry,
			                         artwork: store.artwork, ambientLight: store.link.status?.ambientLight ?? 1)
			Canvas { ctx, size in
				draw(frame, in: ctx, size: size)
			}
		}
		.aspectRatio(Layout.aspect(for: geometry), contentMode: .fit)
		.accessibilityLabel("Board preview")
	}

	/// The proportions, as fractions of the width: the grid, then a gap, then the one-row status bar.
	private enum Layout {
		static let border: CGFloat = 0.045
		static let tileGap: CGFloat = 0.012
		static let barGap: CGFloat = 0.03

		static func aspect(for g: BoardGeometry) -> CGFloat {
			let grid = 1 - border * 2
			return 1 / (border + grid + barGap + grid / CGFloat(g.barPixelCount) + border)
		}
	}

	private func draw(_ frame: BoardFrame, in ctx: GraphicsContext, size: CGSize) {
		let g = frame.geometry
		let border = size.width * Layout.border
		let tileGap = size.width * Layout.tileGap
		let grid = size.width - border * 2
		let tilePitch = grid / CGFloat(g.tilesPerSide)
		let tileSize = tilePitch - tileGap
		let led = tileSize / CGFloat(g.ledsPerTileSide)
		let wall = led * 0.09

		ctx.fill(Path(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: size.width * 0.03), with: .color(.black))

		// Low tiles first, so a raised tile's shadow falls on the ones beside it.
		let order = (0 ..< g.tileCount).sorted { frame.lift[$0] < frame.lift[$1] }
		for index in order {
			let tc = index % g.tilesPerSide, tr = index / g.tilesPerSide
			let h = CGFloat(frame.lift[index])
			let lift = h * tilePitch * 0.09
			let origin = CGPoint(x: border + CGFloat(tc) * tilePitch + tileGap / 2 - lift,
			                     y: border + CGFloat(tr) * tilePitch + tileGap / 2 - lift)
			let tileRect = CGRect(origin: origin, size: CGSize(width: tileSize, height: tileSize))

			var shadow = ctx
			shadow.addFilter(.shadow(color: .black.opacity(0.9), radius: 1 + lift * 1.6, x: lift * 1.1, y: lift * 1.1))
			shadow.fill(Path(tileRect), with: .color(Color(white: 0.04)))

			for lr in 0 ..< g.ledsPerTileSide {
				for lc in 0 ..< g.ledsPerTileSide {
					let p = frame.pixel(column: tc * g.ledsPerTileSide + lc, row: tr * g.ledsPerTileSide + lr)
					let rect = CGRect(x: origin.x + CGFloat(lc) * led + wall / 2, y: origin.y + CGFloat(lr) * led + wall / 2,
					                  width: led - wall, height: led - wall)
					ctx.fill(Path(rect), with: .color(Color(red: Double(p.r) / 255, green: Double(p.g) / 255, blue: Double(p.b) / 255)))
				}
			}
		}

		// The status bar: fixed (it never lifts), under the grid with a gap, one LED per column.
		let barTop = border + grid + size.width * Layout.barGap
		for index in 0 ..< frame.bar.count {
			let tc = index / g.ledsPerTileSide, lc = index % g.ledsPerTileSide
			let p = frame.bar[index]
			let rect = CGRect(x: border + CGFloat(tc) * tilePitch + tileGap / 2 + CGFloat(lc) * led + wall / 2, y: barTop + wall / 2,
			                  width: led - wall, height: led - wall)
			ctx.fill(Path(rect), with: .color(Color(red: Double(p.r) / 255, green: Double(p.g) / 255, blue: Double(p.b) / 255)))
		}
	}
}

/// Steps a `BoardRenderer` with real elapsed time.
@MainActor
final class PreviewPlayer {
	private var renderer = BoardRenderer()
	private var last: Date?
	private(set) var isSettled = false
	private var cached: BoardFrame?

	func frame(at date: Date, state: BoardState, geometry: BoardGeometry, artwork: Artwork? = nil, ambientLight: Float = 1) -> BoardFrame {
		let dt = Float(last.map { date.timeIntervalSince($0) } ?? 0)
		last = date
		renderer.artwork = artwork
		let context = RenderContext(unixMillis: UInt64(date.timeIntervalSince1970 * 1000),
		                            utcOffsetSeconds: Int32(TimeZone.current.secondsFromGMT(for: date)), ambientLight: ambientLight)
		let frame = renderer.step(seconds: dt, state: state, geometry: geometry, context: context)
		isSettled = !state.isOn && frame.lift.allSatisfy { $0 < 0.001 }
		cached = frame
		return frame
	}
}

/// A small, live, light-only board for the preset grid.
struct MiniBoard: View {
	let settings: DitherSettings
	var selected = false

	@Environment(\.isScrolling) private var isScrolling
	@State private var player = PreviewPlayer()

	var body: some View {
		// Paused while the list scrolls (the minis are the expensive part), and slow: they only need to look alive.
		TimelineView(.animation(minimumInterval: 1 / 6, paused: isScrolling)) { context in
			var state = BoardState()
			state.dither = settings
			state.motion.isEnabled = false
			let frame = player.frame(at: context.date, state: state, geometry: .standard)
			return Canvas { ctx, size in
				let side = frame.geometry.pixelsPerSide
				let cell = size.width / CGFloat(side)
				ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.black))
				for row in 0 ..< side {
					for column in 0 ..< side {
						let p = frame.pixel(column: column, row: row)
						ctx.fill(Path(CGRect(x: CGFloat(column) * cell, y: CGFloat(row) * cell, width: cell, height: cell).insetBy(dx: 0.2, dy: 0.2)),
						         with: .color(Color(red: Double(p.r) / 255, green: Double(p.g) / 255, blue: Double(p.b) / 255)))
					}
				}
			}
		}
		.frame(width: 84, height: 84)
		.clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
		.overlay {
			RoundedRectangle(cornerRadius: 10, style: .continuous)
				.strokeBorder(selected ? AnyShapeStyle(.tint) : AnyShapeStyle(.white.opacity(0.18)), lineWidth: selected ? 2.5 : 1)
		}
		.shadow(color: .black.opacity(0.25), radius: 6, y: 3)
		.allowsHitTesting(false)
	}
}

/// The one live preview, pinned above the settings, with the connection state and (optionally) a save-as-preset button.
struct PreviewHeader: View {
	@Environment(BoardStore.self) private var store
	var savesPresets = false

	@State private var naming = false
	@State private var name = ""
	@State private var saved = 0

	var body: some View {
		BoardPreview(state: store.state, geometry: store.geometry)
			.frame(maxWidth: 260)
			.padding(.vertical, 12)
			.frame(maxWidth: .infinity)
			.overlay(alignment: .topLeading) { ConnectionBadge().padding(14) }
			.overlay(alignment: .bottomTrailing) {
				if savesPresets {
					Button {
						name = store.presets.suggestedName
						naming = true
					} label: {
						HStack(spacing: 1) {
							Image(systemName: "plus").font(.caption.bold())
							Image(systemName: "heart.fill")
						}
						.padding(.vertical, 4)
					}
					.buttonStyle(.glass)
					.accessibilityLabel("Save as Preset")
					.padding(14)
				}
			}
			.background(.bar, ignoresSafeAreaEdges: .top)
			.sensoryFeedback(.success, trigger: saved)
			.alert("Save as Preset", isPresented: $naming) {
				TextField("Name", text: $name)
				Button("Save") {
					withAnimation(.smooth) { store.presets.add(name: name, settings: store.state.dither) }
					saved += 1
				}
				Button("Cancel", role: .cancel) {}
			} message: {
				Text("Saves the current dither look. Touch and hold a preset to delete it.")
			}
	}
}

/// Which links to the board are up.
struct ConnectionBadge: View {
	@Environment(BoardStore.self) private var store

	var body: some View {
		let up = store.link.connected
		Label(store.link.summary, systemImage: up.isEmpty ? "wifi.slash" : (up.contains(.bluetooth) ? "dot.radiowaves.left.and.right" : "wifi"))
			.font(.caption2.weight(.medium))
			.foregroundStyle(up.isEmpty ? .secondary : .primary)
			.padding(.horizontal, 8).padding(.vertical, 4)
			.background(.thinMaterial, in: Capsule())
			.accessibilityLabel("Connection: \(store.link.summary)")
	}
}


private struct IsScrollingKey: EnvironmentKey { static let defaultValue = false }

extension EnvironmentValues {
	/// True while the surrounding list is scrolling; heavy live views pause themselves.
	var isScrolling: Bool {
		get { self[IsScrollingKey.self] }
		set { self[IsScrollingKey.self] = newValue }
	}
}
