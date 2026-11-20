import BoardKit
import SwiftUI

/// The timer bar: the top row of LEDs is the bar, the second row stays dark, and the dither shows below.
struct TimerView: View {
	@Environment(BoardStore.self) private var store

	private static let quick = [1, 5, 10, 15, 25, 45, 60]

	var body: some View {
		@Bindable var store = store
		let t = $store.state.timer
		let s = store.state.timer

		Form {
			ModeBanner(mode: .timer)

			Section {
				TimelineView(.periodic(from: .now, by: 0.25)) { _ in
					let now = BoardStore.nowMillis
					VStack(spacing: 4) {
						Text(Self.format(millis: s.remainingMillis(now: now)))
							.font(.system(size: 56, weight: .semibold, design: .rounded))
							.monospacedDigit()
							.contentTransition(.numericText())
						Text(status(s, now: now)).font(.subheadline).foregroundStyle(.secondary)
					}
					.frame(maxWidth: .infinity)
				}
				HStack {
					if s.isRunning {
						Button("Pause", systemImage: "pause.fill") { store.pauseTimer() }
							.disabled(s.isFinished(now: BoardStore.nowMillis))
					} else {
						Button(s.isPaused ? "Resume" : "Start", systemImage: "play.fill") { store.startTimer() }
					}
					Spacer()
					Button("Reset", systemImage: "arrow.counterclockwise", role: .destructive) { store.resetTimer() }
						.disabled(!s.isRunning && !s.isPaused)
				}
				.buttonStyle(.borderless)
			}

			Section {
				ScrollView(.horizontal) {
					HStack {
						ForEach(Self.quick, id: \.self) { minutes in
							Button("\(minutes) min") { store.state.timer.durationSeconds = minutes * 60 }
								.buttonStyle(.bordered)
								.tint(s.durationSeconds == minutes * 60 ? .accentColor : .secondary)
						}
					}
				}
				.scrollIndicators(.hidden)
				ValueSlider("Minutes", value: Binding(
					get: { Float(s.durationSeconds) / 60 },
					set: { store.state.timer.durationSeconds = max(1, Int(($0 * 60).rounded())) }
				), in: 1 ... 180, step: 1, format: { "\(Int($0)) min" })
			} header: {
				Text("Duration")
			}
			.disabled(s.isRunning || s.isPaused)

			Section {
				Picker("Bar", selection: t.style) {
					ForEach(TimerStyle.allCases, id: \.self) { Text($0.title) }
				}
				.pickerStyle(.segmented)
				ColorPicker("Bar Colour", selection: t.barColor.color, supportsOpacity: false)
				Toggle("Blink When Done", isOn: t.flashWhenDone)
			} header: {
				Text("Bar")
			} footer: {
				Text("Drain starts full and shrinks; Fill starts empty and grows. The bar is smooth to a fraction of one LED.")
			}
		}
		.formStyle(.grouped)
		.safeAreaInset(edge: .top, spacing: 0) { PreviewHeader() }
		.navigationTitle("Timer")
	}

	private func status(_ s: TimerSettings, now: UInt64) -> String {
		if s.isFinished(now: now) { return "Time's up" }
		if s.isRunning { return "Running" }
		return s.isPaused ? "Paused" : "Ready"
	}

	static func format(millis: UInt32) -> String {
		let total = Int((Double(millis) / 1000).rounded(.up))
		let h = total / 3600, m = total % 3600 / 60, sec = total % 60
		return h > 0 ? String(format: "%d:%02d:%02d", h, m, sec) : String(format: "%02d:%02d", m, sec)
	}
}
