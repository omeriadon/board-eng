import BoardKit
import SwiftUI

/// The Dither mode: live preview on top, Stipple-style settings below.
struct DitherView: View {
	@Environment(BoardStore.self) private var store

	var body: some View {
		@Bindable var store = store
		let d = $store.state.dither
		Form {
			Section {
				BoardPreview(state: store.state, geometry: store.geometry)
					.frame(maxWidth: 420)
					.frame(maxWidth: .infinity)
					.listRowBackground(Color.clear)
					.listRowInsets(EdgeInsets())
			}

			Section("Wave") {
				ValueSlider("Speed", value: d.waveSpeed, in: 0 ... DitherSettings.maxWaveSpeed)
				ValueSlider("Direction", value: d.waveDirection, in: 0 ... 360, format: { "\(Int($0))°" })
				ValueSlider("Frequency", value: d.waveFrequency, in: 0.5 ... 8)
				ValueSlider("Amplitude", value: d.waveAmplitude, in: 0 ... 1)
				ValueSlider("Scale", value: d.scale, in: 0.2 ... 4)
				ValueSlider("Contrast", value: d.contrast, in: 0.2 ... 3)
				ValueSlider("Brightness", value: d.brightness, in: -0.6 ... 0.6)
			}

			Section("Dither") {
				Picker("Pattern", selection: d.pattern) {
					ForEach(DitherPattern.allCases, id: \.self) { Text($0.title) }
				}
				ValueSlider("Strength", value: d.ditherStrength, in: 0 ... 1)
				ValueSlider("Colour Levels", value: d.colorLevels, in: 2 ... 16, step: 1, format: { "\(Int($0))" })
			}

			Section {
				Picker("Height", selection: d.heightMode) {
					ForEach(HeightMode.allCases, id: \.self) { Text($0.title) }
				}
				ValueSlider("Motion", value: d.motionAmount, in: 0 ... 1)
				Toggle("Quiet Mode", isOn: d.quietMode)
			} header: {
				Text("Tiles")
			} footer: {
				Text("Quiet mode moves tiles slower, eased and out of sync so the clicks never stack up.")
			}
		}
		.formStyle(.grouped)
		.navigationTitle("Dither")
	}
}

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
			HStack {
				Text(title)
				Spacer()
				Text(format(value)).monospacedDigit().foregroundStyle(.secondary)
			}
			if let step {
				Slider(value: $value, in: range, step: step)
			} else {
				Slider(value: $value, in: range)
			}
		}
	}
}
