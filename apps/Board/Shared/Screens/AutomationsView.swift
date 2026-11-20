import BoardKit
import SwiftUI

/// Things the board does by itself: schedules, room light, and what happens when you leave the desk.
/// They live in the board's state, so the board keeps following them when no app is open.
struct AutomationsView: View {
	@Environment(BoardStore.self) private var store

	var body: some View {
		@Bindable var store = store
		let a = $store.state.automation
		let auto = store.state.automation

		Form {
			Section {
				ForEach(a.schedules.indices, id: \.self) { i in
					NavigationLink {
						ScheduleEditor(schedule: a.schedules[i]) {
							store.state.automation.schedules.remove(at: i)
						}
					} label: {
						ScheduleRow(schedule: auto.schedules[i])
					}
				}
				.onDelete { store.state.automation.schedules.remove(atOffsets: $0) }
				if auto.schedules.count < AutomationSettings.maxSchedules {
					Button("Add Schedule", systemImage: "plus.circle.fill") {
						withAnimation(.smooth) { store.state.automation.schedules.append(Schedule()) }
					}
				}
			} header: {
				Text("Schedules")
			} footer: {
				Text("For example, turn off from 10 PM to 7 AM on school nights. A window that passes midnight belongs to the day it starts. Up to \(AutomationSettings.maxSchedules).")
			}

			Section {
				Toggle("Follow the Room", isOn: a.autoBrightness.isEnabled)
				if auto.autoBrightness.isEnabled {
					LabeledContent("Room Now") {
						Text(store.link.status.map { "\(Int(($0.ambientLight * 100).rounded()))%" } ?? "Board not connected")
							.foregroundStyle(.secondary)
					}
					ValueSlider("Darkest Room", value: a.autoBrightness.minimum, in: 0 ... 1, format: Self.percent)
					ValueSlider("Brightest Room", value: a.autoBrightness.maximum, in: 0 ... 1, format: Self.percent)
					Toggle("Turn Off in the Dark", isOn: a.autoBrightness.offInDark)
					if auto.autoBrightness.offInDark {
						ValueSlider("Dark Below", value: a.autoBrightness.darkLevel, in: 0 ... 0.5, format: Self.percent)
					}
				}
			} header: {
				Text("Brightness")
			} footer: {
				Text("Uses the light sensor on the board, so it dims at night without you doing anything.")
			}

			Section {
				Toggle("Notice When I'm Away", isOn: a.presence.isEnabled)
				if auto.presence.isEnabled {
					Stepper("After \(auto.presence.idleMinutes) min idle", value: a.presence.idleMinutes, in: 1 ... 120)
					Picker("Then", selection: a.presence.action) {
						ForEach(AwayAction.allCases, id: \.self) { Text($0.title) }
					}
					if auto.presence.action == .dim {
						ValueSlider("Away Brightness", value: a.presence.dimLevel, in: 0 ... 1, format: Self.percent)
					}
				}
			} header: {
				Text("Away From the Desk")
			} footer: {
				#if os(macOS)
					Text("The Mac decides you're away when the keyboard and mouse have been still, and tells the board.")
				#else
					Text("Your Mac decides when you're away from the desk. Turn this on here and the Mac app does the watching.")
				#endif
			}

			Section {
				Label("Shortcuts", systemImage: "square.2.layers.3d.fill")
				Text("Board adds actions to the Shortcuts app: turn the board on or off, set brightness, switch mode, turn jumping on or off, apply a colour theme, and start, pause or reset the timer. Use them in automations such as Focus changes or leaving home.")
					.font(.callout).foregroundStyle(.secondary)
			} header: {
				Text("Shortcuts and Siri")
			}
		}
		.formStyle(.grouped)
		.safeAreaInset(edge: .top, spacing: 0) { PreviewHeader() }
		.navigationTitle("Automations")
		.animation(.smooth, value: auto.autoBrightness.isEnabled)
		.animation(.smooth, value: auto.presence.isEnabled)
	}

	static func percent(_ v: Float) -> String { "\(Int((v * 100).rounded()))%" }
}

private let dayLetters = ["M", "T", "W", "T", "F", "S", "S"]
private let dayNames = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

func clockText(minute: Int) -> String {
	let h = minute / 60, m = minute % 60
	return String(format: "%d:%02d %@", h % 12 == 0 ? 12 : h % 12, m, h >= 12 ? "PM" : "AM")
}

private struct ScheduleRow: View {
	let schedule: Schedule

	var body: some View {
		VStack(alignment: .leading, spacing: 2) {
			HStack {
				Text("\(clockText(minute: schedule.startMinute)) – \(clockText(minute: schedule.endMinute))").font(.headline)
				if !schedule.isEnabled { Text("Off").font(.caption).foregroundStyle(.secondary) }
			}
			Text("\(actionText) · \(daysText)").font(.subheadline).foregroundStyle(.secondary)
		}
		.opacity(schedule.isEnabled ? 1 : 0.5)
	}

	private var actionText: String {
		switch schedule.action {
			case .off: "Turn off"
			case .dim: "Dim to \(Int((schedule.dimLevel * 100).rounded()))%"
			case .switchMode: "Show \(schedule.mode.title)"
		}
	}

	private var daysText: String {
		if schedule.days == 0b1111111 { return "Every day" }
		if schedule.days == 0b0011111 { return "Weekdays" }
		if schedule.days == 0b1100000 { return "Weekends" }
		if schedule.days == 0 { return "Never" }
		return (0 ..< 7).filter { schedule.days & (1 << UInt8($0)) != 0 }.map { dayNames[$0] }.joined(separator: " ")
	}
}

private struct ScheduleEditor: View {
	@Binding var schedule: Schedule
	let delete: () -> Void
	@Environment(\.dismiss) private var dismiss

	var body: some View {
		Form {
			Section {
				Toggle("Enabled", isOn: $schedule.isEnabled)
				DatePicker("From", selection: time($schedule.startMinute), displayedComponents: .hourAndMinute)
				DatePicker("Until", selection: time($schedule.endMinute), displayedComponents: .hourAndMinute)
			}

			Section("Days") {
				HStack(spacing: 6) {
					ForEach(0 ..< 7, id: \.self) { day in
						let on = schedule.days & (1 << UInt8(day)) != 0
						Button {
							schedule.days ^= 1 << UInt8(day)
						} label: {
							Text(dayLetters[day]).font(.subheadline.weight(.semibold)).frame(maxWidth: .infinity, minHeight: 32)
						}
						.buttonStyle(.borderedProminent)
						.tint(on ? .accentColor : .gray.opacity(0.35))
						.accessibilityLabel(dayNames[day])
						.accessibilityAddTraits(on ? .isSelected : [])
					}
				}
			}

			Section("Then") {
				Picker("Do", selection: $schedule.action) {
					ForEach(ScheduleAction.allCases, id: \.self) { Text($0.title) }
				}
				switch schedule.action {
					case .off: EmptyView()
					case .dim: ValueSlider("Brightness", value: $schedule.dimLevel, in: 0 ... 1, format: AutomationsView.percent)
					case .switchMode:
						Picker("Show", selection: $schedule.mode) {
							ForEach(BoardMode.allCases, id: \.self) { Text($0.title) }
						}
				}
			}

			Section {
				Button("Delete Schedule", role: .destructive) { delete(); dismiss() }
			}
		}
		.formStyle(.grouped)
		.navigationTitle("Schedule")
	}

	private func time(_ minute: Binding<Int>) -> Binding<Date> {
		Binding {
			Calendar.current.date(bySettingHour: minute.wrappedValue / 60, minute: minute.wrappedValue % 60, second: 0, of: .now) ?? .now
		} set: {
			let c = Calendar.current.dateComponents([.hour, .minute], from: $0)
			minute.wrappedValue = (c.hour ?? 0) * 60 + (c.minute ?? 0)
		}
	}
}
