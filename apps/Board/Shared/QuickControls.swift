import BoardKit
import SwiftUI

/// Power, brightness and mode: always one tap away (iOS tab bar accessory, Mac toolbar + menu bar).
struct QuickControls: View {
	@Environment(BoardStore.self) private var store
	var showsModePicker = true

	var body: some View {
		@Bindable var store = store
		HStack(spacing: 12) {
			Toggle(isOn: $store.state.isOn) {
				Image(systemName: "power")
			}
			.toggleStyle(.button)
			.accessibilityLabel(store.state.isOn ? "Turn board off" : "Turn board on")

			Slider(value: $store.state.brightness, in: 0 ... 1) {
				Text("Brightness")
			} minimumValueLabel: {
				Image(systemName: "sun.min")
			} maximumValueLabel: {
				Image(systemName: "sun.max")
			}
			.disabled(!store.state.isOn)

			if showsModePicker {
				Picker("Mode", selection: $store.state.mode) {
					ForEach(BoardMode.allCases, id: \.self) { Text($0.title) }
				}
				.labelsHidden()
				.fixedSize()
			}
		}
	}
}
