import BoardKit
import SwiftUI

/// The physical jumping, separate from the lights: switch it off, soften it, or give the tiles a wave of their own.
struct MotionView: View {
	@Environment(BoardStore.self) private var store
	@State private var confirmingReset = false

	var body: some View {
		@Bindable var store = store
		let m = $store.state.motion
		let s = store.state.motion

		Form {
			Section {
				Toggle("Tiles Move", isOn: m.isEnabled)
				ValueSlider("Strength", value: m.strength, in: 0 ... 1, format: { "\(Int(($0 * 100).rounded()))%" })
					.disabled(!s.isEnabled)
				ValueSlider("Speed", value: m.speed, in: 0 ... 1, format: { "\(Int(($0 * 100).rounded()))%" })
					.disabled(!s.isEnabled)
			} header: {
				Text("Jumping")
			} footer: {
				Text("Off, every tile rests flat and the motors stay silent. Strength is how far tiles travel; speed is how quickly they get there.")
			}

			Section {
				Picker("Driven By", selection: m.source) {
					ForEach(HeightSource.allCases, id: \.self) { Text($0.title) }
				}
				switch s.source {
					case .wave:
						DirectionDial(title: "Direction", degrees: m.waveDirection)
						ValueSlider("Wave Speed", value: m.waveSpeed, in: 0 ... MotionSettings.maxWaveSpeed, format: { String(format: "%.3f", $0) })
						ValueSlider("Frequency", value: m.waveFrequency, in: 0.1 ... 6)
						ValueSlider("Scale", value: m.waveScale, in: 0.1 ... 8)
					case .ripple:
						PositionPicker(title: "Starts From", position: m.rippleOrigin)
						ValueSlider("Ring Spacing", value: m.rippleSpacing, in: 1 ... 8, format: { String(format: "%.1f tiles", $0) })
						ValueSlider("Ring Speed", value: m.rippleSpeed, in: 0 ... 1)
					case .lights, .invertedLights, .off:
						EmptyView()
				}
			} header: {
				Text("Height")
			} footer: {
				Text(footer(for: s.source))
			}
			.disabled(!s.isEnabled)

			Section {
				Toggle("Quiet Mode", isOn: m.quietMode)
				Stepper(value: m.maxMovingTiles, in: 1 ... 16) {
					LabeledContent("Tiles at Once", value: "\(s.maxMovingTiles)")
				}
			} header: {
				Text("Sound")
			} footer: {
				Text("Quiet mode moves tiles slower and fewer at a time, so the clicks never stack up. Fewer tiles at once also eases the power draw.")
			}
			.disabled(!s.isEnabled)

			Section {
				Button("Reset Motion Settings", role: .destructive) { confirmingReset = true }
			}
		}
		.formStyle(.grouped)
		.safeAreaInset(edge: .top, spacing: 0) { PreviewHeader() }
		.navigationTitle("Motion")
		.confirmationDialog("Reset all motion settings?", isPresented: $confirmingReset, titleVisibility: .visible) {
			Button("Reset", role: .destructive) { withAnimation(.smooth) { store.state.motion = MotionSettings() } }
		}
		.animation(.default, value: s.source)
		.animation(.default, value: s.isEnabled)
	}

	private func footer(for source: HeightSource) -> String {
		switch source {
			case .lights: "Tiles rise where the lights are bright."
			case .invertedLights: "Tiles rise where the lights are dark, so the glow sits in a dip."
			case .wave: "A slow wave of its own: the tiles drift whatever the lights are doing."
			case .ripple: "Rings spread across the board from the spot you pick."
			case .off: "Tiles hold still. Only the lights change."
		}
	}
}
