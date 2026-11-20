import BoardKit
import SwiftUI

/// The sun crosses the board through the day; the sky follows it.
struct AmbientView: View {
	@Environment(BoardStore.self) private var store

	var body: some View {
		@Bindable var store = store
		let a = $store.state.ambient
		let s = store.state.ambient

		Form {
			ModeBanner(mode: .ambient)

			Section {
				ValueSlider("Sunrise", value: a.sunrise, in: 3 ... 10, step: 0.25, format: Self.clock)
				ValueSlider("Sunset", value: a.sunset, in: 15 ... 22, step: 0.25, format: Self.clock)
			} header: {
				Text("Day")
			} footer: {
				Text("The sun rises on the left at sunrise, peaks at noon and sets on the right. Later this can follow your real sunrise and sunset from your location.")
			}

			Section {
				Toggle("Time-lapse", isOn: a.timeLapse)
				if s.timeLapse {
					ValueSlider("A Whole Day Takes", value: a.lapseSeconds, in: 10 ... 300, step: 5, format: { "\(Int($0)) s" })
				}
			} header: {
				Text("Preview")
			} footer: {
				Text("Plays a whole day in seconds instead of following the clock, to see the sky change.")
			}

			Section("Sky") {
				ValueSlider("Sun Glow", value: a.glow, in: 0 ... 1)
				Toggle("Stars at Night", isOn: a.showStars)
				Toggle("Moon at Night", isOn: a.showMoon)
			}
		}
		.formStyle(.grouped)
		.safeAreaInset(edge: .top, spacing: 0) { PreviewHeader() }
		.navigationTitle("Ambient")
		.animation(.default, value: s.timeLapse)
	}

	static func clock(_ hours: Float) -> String {
		let total = Int((hours * 60).rounded()), h = total / 60, m = total % 60
		let suffix = h >= 12 ? "PM" : "AM"
		return String(format: "%d:%02d %@", h % 12 == 0 ? 12 : h % 12, m, suffix)
	}
}
