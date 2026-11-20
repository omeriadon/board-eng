import BoardKit
import SwiftUI

/// A titled slider with its value on the right (Stipple's `ValueSlider`).
struct ValueSlider: View {
	let title: String
	@Binding var value: Float
	let range: ClosedRange<Float>
	var step: Float?
	var format: (Float) -> String

	init(_ title: String, value: Binding<Float>, in range: ClosedRange<Float>, step: Float? = nil,
	     format: @escaping (Float) -> String = { String(format: "%.2f", $0) }) {
		self.title = title
		_value = value
		self.range = range
		self.step = step
		self.format = format
	}

	var body: some View {
		VStack(alignment: .leading, spacing: 4) {
			LabeledContent(title) {
				Text(format(value))
					.monospacedDigit()
					.contentTransition(.numericText(value: Double(value)))
			}
			if let step {
				Slider(value: $value, in: range, step: step)
			} else {
				Slider(value: $value, in: range)
			}
		}
		.sensoryFeedback(.selection, trigger: step == nil ? 0 : value)
	}
}

extension RGB {
	init(_ color: Color) {
		let r = color.resolve(in: EnvironmentValues())
		self.init(r.red, r.green, r.blue)
		self = clamped
	}

	var color: Color { Color(.sRGB, red: Double(r), green: Double(g), blue: Double(b)) }
}

extension Binding where Value == RGB {
	var color: Binding<Color> {
		Binding<Color>(get: { wrappedValue.color }, set: { wrappedValue = RGB($0) })
	}
}

// MARK: - Direction dial

/// Eight-way compass (Stipple's). The ring of cells fades away from the chosen heading like a dither gradient, and a
/// pixel arrow in the middle swings round to point the way the wave travels.
struct DirectionDial: View {
	var title = "Direction"
	@Binding var degrees: Float

	private static let longNames = ["North", "Northeast", "East", "Southeast", "South", "Southwest", "West", "Northwest"]
	private let diameter: CGFloat = 92

	/// Unwrapped angle, so the arrow always turns the short way (NW → N is +45°, not −315°).
	@State private var rotation: Double = 0

	private var index: Int { Int((DitherSettings.snappedDirection(degrees) / 45).rounded()) % 8 }

	var body: some View {
		HStack {
			VStack(alignment: .leading, spacing: 2) {
				Text(title)
				Text(Self.longNames[index])
					.font(.subheadline)
					.foregroundStyle(.secondary)
					.contentTransition(.numericText())
			}
			Spacer()
			dial
		}
		.onAppear { rotation = Double(index * 45) }
		.onChange(of: index) { old, new in
			var delta = Double((new - old) * 45)
			if delta > 180 { delta -= 360 }
			if delta < -180 { delta += 360 }
			withAnimation(.spring(duration: 0.45, bounce: 0.35)) { rotation += delta }
		}
		.sensoryFeedback(.selection, trigger: index)
		.accessibilityElement(children: .ignore)
		.accessibilityLabel(title)
		.accessibilityValue(Self.longNames[index])
		.accessibilityAdjustableAction { direction in
			let step = direction == .increment ? 1 : 7
			degrees = Float((index + step) % 8 * 45)
		}
	}

	private var dial: some View {
		let radius = diameter / 2 - 9
		return ZStack {
			Circle().fill(.quaternary.opacity(0.6))
			ForEach(0 ..< 8, id: \.self) { slot in
				let angle = Double(slot) * .pi / 4
				let distance = min((slot - index + 8) % 8, (index - slot + 8) % 8)
				RoundedRectangle(cornerRadius: 2, style: .continuous)
					.fill(.tint)
					.opacity([1, 0.45, 0.22, 0.12, 0.08][distance])
					.frame(width: distance == 0 ? 11 : 8, height: distance == 0 ? 11 : 8)
					.offset(x: sin(angle) * radius, y: -cos(angle) * radius)
					.animation(.snappy, value: index)
			}
			PixelArrow()
				.fill(.tint)
				.frame(width: 26, height: 26)
				.rotationEffect(.degrees(rotation))
		}
		.frame(width: diameter, height: diameter)
		.contentShape(Circle())
		.gesture(
			DragGesture(minimumDistance: 0)
				.onChanged { value in
					let dx = value.location.x - diameter / 2, dy = value.location.y - diameter / 2
					guard dx * dx + dy * dy > 64 else { return }
					degrees = DitherSettings.snappedDirection(Float(atan2(dx, -dy) * 180 / .pi))
				}
		)
	}
}

/// An upward arrow drawn from square cells, on a 5 × 5 grid.
nonisolated private struct PixelArrow: Shape {
	private static let cells: [(Int, Int)] = [(2, 0), (1, 1), (2, 1), (3, 1), (0, 2), (2, 2), (4, 2), (2, 3), (2, 4)]

	func path(in rect: CGRect) -> Path {
		let cell = min(rect.width, rect.height) / 5
		let gap = cell * 0.12
		var path = Path()
		for (x, y) in Self.cells {
			path.addRoundedRect(
				in: CGRect(x: rect.minX + CGFloat(x) * cell + gap / 2, y: rect.minY + CGFloat(y) * cell + gap / 2,
				           width: cell - gap, height: cell - gap),
				cornerSize: CGSize(width: cell * 0.2, height: cell * 0.2)
			)
		}
		return path
	}
}

// MARK: - Position picker

/// A miniature board split into nine spots (Stipple's dock picker). Tap or drag to choose one; a block slides to it.
/// Used for where ripples start; later for where the timer bar and the sun sit.
struct PositionPicker: View {
	var title = "Origin"
	/// 0 top-left ... 4 centre ... 8 bottom-right, row-major.
	@Binding var position: Int

	static let names = ["Top Left", "Top", "Top Right", "Left", "Centre", "Right", "Bottom Left", "Bottom", "Bottom Right"]
	private let side: CGFloat = 96

	var body: some View {
		HStack {
			VStack(alignment: .leading, spacing: 2) {
				Text(title)
				Text(Self.names[position])
					.font(.subheadline)
					.foregroundStyle(.secondary)
					.contentTransition(.numericText())
			}
			Spacer()
			grid
		}
		.sensoryFeedback(.selection, trigger: position)
		.animation(.spring(duration: 0.4, bounce: 0.3), value: position)
		.accessibilityElement(children: .ignore)
		.accessibilityLabel(title)
		.accessibilityValue(Self.names[position])
		.accessibilityAdjustableAction { direction in
			position = (position + (direction == .increment ? 1 : 8)) % 9
		}
	}

	private var grid: some View {
		let cell = side / 3
		return ZStack(alignment: .topLeading) {
			RoundedRectangle(cornerRadius: 18, style: .continuous).fill(.quaternary.opacity(0.6))
			ForEach(0 ..< 9, id: \.self) { slot in
				RoundedRectangle(cornerRadius: 2, style: .continuous)
					.fill(.secondary.opacity(0.35))
					.frame(width: 6, height: 6)
					.frame(width: cell, height: cell)
					.offset(x: CGFloat(slot % 3) * cell, y: CGFloat(slot / 3) * cell)
			}
			RoundedRectangle(cornerRadius: 7, style: .continuous)
				.fill(.tint)
				.frame(width: cell - 12, height: cell - 12)
				.frame(width: cell, height: cell)
				.offset(x: CGFloat(position % 3) * cell, y: CGFloat(position / 3) * cell)
		}
		.frame(width: side, height: side)
		.contentShape(Rectangle())
		.gesture(
			DragGesture(minimumDistance: 0)
				.onChanged { value in
					let column = min(max(Int(value.location.x / cell), 0), 2), row = min(max(Int(value.location.y / cell), 0), 2)
					position = row * 3 + column
				}
		)
	}
}
