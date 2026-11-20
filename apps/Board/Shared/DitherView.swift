import BoardKit
import SwiftUI

/// The Dither mode: the live board pinned on top, every Stipple option below that makes sense on LEDs.
struct DitherView: View {
	@Environment(BoardStore.self) private var store
	@State private var confirmingReset = false

	var body: some View {
		@Bindable var store = store
		let d = $store.state.dither
		let s = store.state.dither

		Form {
			PresetSection(current: s) { preset in
				withAnimation(.smooth) { store.state.dither = preset.settings }
			}

			Section("Wave") {
				ValueSlider("Speed", value: d.waveSpeed, in: 0 ... DitherSettings.maxWaveSpeed, format: { String(format: "%.3f", $0) })
				DirectionDial(degrees: d.waveDirection)
				ValueSlider("Frequency", value: d.waveFrequency, in: 0.5 ... 8)
				ValueSlider("Amplitude", value: d.waveAmplitude, in: 0 ... 1)
				ValueSlider("Scale", value: d.scale, in: 0.2 ... 4)
				ValueSlider("Contrast", value: d.contrast, in: 0.2 ... 3)
				ValueSlider("Brightness", value: d.brightness, in: -0.6 ... 0.6)
			}

			Section {
				Picker("Pattern", selection: d.pattern) {
					ForEach(DitherPattern.allCases, id: \.self) { Text($0.title) }
				}
				ValueSlider("Strength", value: d.ditherStrength, in: 0 ... 1)
				ValueSlider("Colour Levels", value: d.colorLevels, in: 2 ... 16, step: 1, format: { "\(Int($0))" })
				LabeledContent("Cell Size") {
					Picker("Cell Size", selection: d.cellSize) {
						ForEach(DitherSettings.cellSizes, id: \.self) { Text("\($0)×\($0)").tag($0) }
					}
					.pickerStyle(.segmented)
					.labelsHidden()
					.frame(maxWidth: 190)
				}
			} header: {
				Text("Cells")
			} footer: {
				Text("Cell size is how many LEDs share one dither cell: 1×1 is every LED, 4×4 is one cell per tile.")
			}

			Section("Colour") {
				ColorPicker("Wave", selection: d.waveColor.color, supportsOpacity: false)
				Picker("Background", selection: d.backgroundStyle) {
					ForEach(BackgroundStyle.allCases, id: \.self) { Text($0.title) }
				}
				if s.backgroundStyle == .custom {
					ColorPicker("Background Colour", selection: d.backgroundColor.color, supportsOpacity: false)
				}
				Picker("Colour Goes On", selection: d.colorPlacement) {
					ForEach(ColorPlacement.allCases, id: \.self) { Text($0.title) }
				}
				if s.colorPlacement == .background {
					Picker("Squares", selection: d.squareStyle) {
						ForEach(SquareStyle.allCases, id: \.self) { Text($0.title) }
					}
				}
			}

			PaletteSection(palette: d.palette, colorField: d.colorField)

			Section {
				ValueSlider("Blur", value: d.blur, in: 0 ... 1, format: { "\(Int(($0 * 100).rounded()))%" })
			} header: {
				Text("Composition")
			} footer: {
				Text("Blends each LED with its neighbours for a softer, glowing field.")
			}

			Section {
				Button("Reset Dither Settings", role: .destructive) { confirmingReset = true }
			}
		}
		.formStyle(.grouped)
		.safeAreaInset(edge: .top, spacing: 0) { PreviewHeader(savesPresets: true) }
		.navigationTitle("Dither")
		.confirmationDialog("Reset all dither settings?", isPresented: $confirmingReset, titleVisibility: .visible) {
			Button("Reset", role: .destructive) { withAnimation(.smooth) { store.state.dither = DitherSettings() } }
		}
		.animation(.default, value: s.backgroundStyle)
		.animation(.default, value: s.colorPlacement)
	}
}

/// A row of live miniature boards, each playing its preset. Tap applies; touch and hold deletes your own.
private struct PresetSection: View {
	@Environment(BoardStore.self) private var store
	let current: DitherSettings
	let apply: (Preset) -> Void
	@State private var tapped = 0

	var body: some View {
		Section {
			ScrollView(.horizontal) {
				LazyHGrid(rows: [GridItem(.fixed(112), spacing: 14), GridItem(.fixed(112))], spacing: 14) {
					ForEach(store.presets.all) { preset in
						PresetTile(preset: preset, selected: preset.settings == current.bounded(), action: {
							tapped += 1
							apply(preset)
						}, delete: preset.isCustom ? {
							withAnimation(.smooth) { store.presets.delete(preset) }
						} : nil)
						.transition(.scale.combined(with: .opacity))
						.scrollTransition(axis: .horizontal) { content, phase in
							content
								.scaleEffect(phase.isIdentity ? 1 : 0.78)
								.blur(radius: phase.isIdentity ? 0 : 8)
								.opacity(phase.isIdentity ? 1 : 0.25)
						}
					}
				}
				.scrollTargetLayout()
			}
			.contentMargins(.horizontal, 16, for: .scrollContent)
			.contentMargins(.vertical, 14, for: .scrollContent)
			.scrollIndicators(.hidden)
			.scrollTargetBehavior(.viewAligned)
			.listRowInsets(EdgeInsets())
			.sensoryFeedback(.impact(weight: .light), trigger: tapped)
		} header: {
			Text("Presets")
		} footer: {
			Text("Save your own with the heart button above. Touch and hold one of yours to delete it.")
		}
	}
}

private struct PresetTile: View {
	let preset: Preset
	let selected: Bool
	let action: () -> Void
	var delete: (() -> Void)?

	var body: some View {
		// A Menu owns its own menu, so each tile deletes itself (a Form row would adopt a contextMenu for the whole row).
		if let delete {
			Menu {
				Button("Delete", systemImage: "trash", role: .destructive, action: delete)
			} label: {
				content
			} primaryAction: {
				action()
			}
			.menuStyle(.button)
			.buttonStyle(.plain)
		} else {
			content
				.contentShape(Rectangle())
				.onTapGesture(perform: action)
				.accessibilityAddTraits(.isButton)
		}
	}

	private var content: some View {
		VStack(spacing: 6) {
			MiniBoard(settings: preset.settings, selected: selected)
			HStack(spacing: 3) {
				if preset.isCustom { Image(systemName: "heart.fill").font(.system(size: 8)).foregroundStyle(.pink) }
				Text(preset.name)
					.font(.caption2.weight(selected ? .semibold : .regular))
					.foregroundStyle(selected ? AnyShapeStyle(.tint) : AnyShapeStyle(.primary))
					.lineLimit(1)
			}
			.frame(maxWidth: 84)
		}
	}
}

private struct PaletteSection: View {
	@Binding var palette: [RGB]
	@Binding var colorField: Bool

	/// Bounds-checked, so a picker that outlives its row during a delete never indexes past the end.
	private func color(at index: Int) -> Binding<Color> {
		Binding(
			get: { palette.indices.contains(index) ? palette[index].color : .clear },
			set: { if palette.indices.contains(index) { palette[index] = RGB($0) } }
		)
	}

	var body: some View {
		Section {
			ForEach(palette.indices, id: \.self) { index in
				HStack {
					ColorPicker("Colour \(index + 1)", selection: color(at: index), supportsOpacity: false)
					Button(role: .destructive) {
						withAnimation { _ = palette.remove(at: index) }
					} label: {
						Image(systemName: "minus.circle.fill").foregroundStyle(.red)
					}
					.buttonStyle(.plain)
					.accessibilityLabel("Remove colour \(index + 1)")
				}
			}
			if palette.count < DitherSettings.maxPaletteCount {
				Button("Add Colour", systemImage: "plus.circle.fill") {
					withAnimation { palette.append(palette.last ?? RGB(1, 1, 1)) }
				}
			}
			Toggle("Spread Colours Across Board", isOn: $colorField)
				.disabled(palette.isEmpty)
		} header: {
			Text("Palette")
		} footer: {
			Text("With two or more colours, brighter parts of the wave use later colours. Spread blends the palette across the board instead. With one or none, the wave colour is used.")
		}
	}
}
