import BoardKit
import SwiftUI

/// Colour themes that apply everywhere at once, plus the shared colours every mode uses.
struct ColoursView: View {
	@Environment(BoardStore.self) private var store
	@State private var naming = false
	@State private var name = ""

	var body: some View {
		@Bindable var store = store
		let t = $store.state.timer
		let a = $store.state.ambient

		Form {
			Section {
				ForEach(store.presets.allThemes) { theme in
					ThemeRow(theme: theme, selected: isApplied(theme), apply: {
						withAnimation(.smooth) { theme.apply(to: &store.state) }
					}, delete: theme.isCustom ? {
						withAnimation(.smooth) { store.presets.delete(theme) }
					} : nil)
				}
				Button("Save Current Palette as Theme", systemImage: "plus.circle.fill") {
					name = store.presets.suggestedThemeName
					naming = true
				}
				.disabled(store.state.dither.palette.isEmpty)
			} header: {
				Text("Themes")
			} footer: {
				Text("A theme sets the dither palette, the timer bar and the sun in one go. Shortcuts can apply the built-in ones.")
			}

			Section("Dither Palette") {
				SwatchRow(colors: store.state.dither.palette)
			}

			Section("Timer") {
				ColorPicker("Bar", selection: t.barColor.color, supportsOpacity: false)
				ColorPicker("Empty Track", selection: t.trackColor.color, supportsOpacity: false)
			}

			Section("Ambient") {
				ColorPicker("Sun", selection: a.sunColor.color, supportsOpacity: false)
				ColorPicker("Day Sky", selection: a.daySky.color, supportsOpacity: false)
				ColorPicker("Dawn and Dusk", selection: a.twilight.color, supportsOpacity: false)
				ColorPicker("Night Sky", selection: a.nightSky.color, supportsOpacity: false)
			}
		}
		.formStyle(.grouped)
		.safeAreaInset(edge: .top, spacing: 0) { PreviewHeader() }
		.navigationTitle("Colours")
		.alert("Save Theme", isPresented: $naming) {
			TextField("Name", text: $name)
			Button("Save") { store.presets.addTheme(name: name, colors: store.state.dither.palette) }
			Button("Cancel", role: .cancel) {}
		} message: {
			Text("Saves the dither palette as a theme.")
		}
	}

	private func isApplied(_ theme: ColorTheme) -> Bool { store.state.dither.palette == theme.colors.map(\.clamped) }
}

private struct ThemeRow: View {
	let theme: ColorTheme
	let selected: Bool
	let apply: () -> Void
	var delete: (() -> Void)?

	var body: some View {
		HStack {
			Button(action: apply) {
				HStack(spacing: 12) {
					SwatchRow(colors: theme.colors)
					Text(theme.name).foregroundStyle(.primary)
					Spacer()
					if selected { Image(systemName: "checkmark").foregroundStyle(.tint) }
				}
				.contentShape(Rectangle())
			}
			.buttonStyle(.plain)
			if let delete {
				Button(role: .destructive, action: delete) { Image(systemName: "trash") }
					.buttonStyle(.borderless)
					.accessibilityLabel("Delete \(theme.name)")
			}
		}
	}
}

struct SwatchRow: View {
	let colors: [RGB]

	var body: some View {
		HStack(spacing: 3) {
			ForEach(colors.indices, id: \.self) { i in
				RoundedRectangle(cornerRadius: 3, style: .continuous).fill(colors[i].color).frame(width: 20, height: 20)
			}
			if colors.isEmpty { Text("No colours").foregroundStyle(.secondary) }
		}
	}
}
