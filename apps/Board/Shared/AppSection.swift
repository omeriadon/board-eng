import SwiftUI

/// Every top-level destination. iOS shows these as tabs (5+ → "More"), iPadOS as a sidebar,
/// macOS as grouped sidebar rows.
enum AppSection: String, CaseIterable, Identifiable, Hashable {
	case dither, motion, colors, timer, ambient, music, automations, device

	var id: String { rawValue }

	var title: String {
		switch self {
			case .dither: "Dither"
			case .motion: "Motion"
			case .colors: "Colours"
			case .timer: "Timer"
			case .ambient: "Ambient"
			case .music: "Music"
			case .automations: "Automations"
			case .device: "Device"
		}
	}

	var symbol: String {
		switch self {
			case .dither: "square.grid.3x3.fill"
			case .motion: "arrow.up.and.down.square.fill"
			case .colors: "paintpalette.fill"
			case .timer: "timer"
			case .ambient: "sun.horizon.fill"
			case .music: "music.note"
			case .automations: "gearshape.2.fill"
			case .device: "cpu"
		}
	}

	/// Sidebar grouping (macOS + iPad).
	enum Group: String, CaseIterable {
		case display = "Display", style = "Style", automate = "Automate", hardware = "Board"
	}

	var group: Group {
		switch self {
			case .dither, .motion, .ambient, .music, .timer: .display
			case .colors: .style
			case .automations: .automate
			case .device: .hardware
		}
	}

	/// Music Mirror needs always-on now-playing access, so it is Mac only.
	var isAvailable: Bool {
		#if os(macOS)
			true
		#else
			self != .music
		#endif
	}
}

struct SectionDetail: View {
	let section: AppSection

	var body: some View {
		switch section {
			case .dither: DitherView()
			case .motion: MotionView()
			case .colors: PlaceholderView(section: section, summary: "Palettes shared by every mode: dither palette, sun colours, timer bar. Shortcuts can switch them.")
			case .timer: PlaceholderView(section: section, summary: "Timer bar across the top pixel row (second row stays dark as a margin). Start, pause, presets.")
			case .ambient: PlaceholderView(section: section, summary: "Idle mode: the sun crosses the board through the day, colours follow sunrise and sunset.")
			case .music: PlaceholderView(section: section, summary: "Mirror the current album art. Bottom two rows show playback progress; tiles can jump to the beat.")
			case .automations: PlaceholderView(section: section, summary: "Schedules, presence (keyboard/mouse on Mac, location on iPhone), ambient light, Shortcuts.")
			case .device: PlaceholderView(section: section, summary: "Connection, motion & quiet mode, tile calibration, diagnostics, firmware.")
		}
	}
}

struct PlaceholderView: View {
	let section: AppSection
	let summary: String

	var body: some View {
		ContentUnavailableView {
			Label(section.title, systemImage: section.symbol)
		} description: {
			Text(summary)
		}
		.navigationTitle(section.title)
	}
}
