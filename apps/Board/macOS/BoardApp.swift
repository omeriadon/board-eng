import SwiftUI

@main
struct BoardApp: App {
	@State private var store = BoardStore()

	var body: some Scene {
		Window("Board", id: "main") {
			RootSplitView()
				.environment(store)
		}
		.defaultSize(width: 960, height: 680)

		// The Mac app runs all the time (presence, Music Mirror, long-task detection),
		// so quick controls live in the menu bar.
		MenuBarExtra("Board", systemImage: "square.grid.3x3.fill") {
			MenuBarPanel()
				.environment(store)
		}
		.menuBarExtraStyle(.window)
	}
}

struct RootSplitView: View {
	@State private var selection: AppSection? = .dither

	var body: some View {
		NavigationSplitView {
			List(selection: $selection) {
				ForEach(AppSection.Group.allCases, id: \.self) { group in
					Section(group.rawValue) {
						ForEach(AppSection.allCases.filter { $0.group == group }) { section in
							Label(section.title, systemImage: section.symbol)
								.tag(section)
						}
					}
				}
			}
			.navigationSplitViewColumnWidth(min: 190, ideal: 210)
		} detail: {
			NavigationStack {
				SectionDetail(section: selection ?? .dither)
			}
		}
		.toolbar {
			ToolbarItem(placement: .primaryAction) {
				QuickControls()
					.frame(width: 360)
			}
		}
	}
}

struct MenuBarPanel: View {
	@Environment(BoardStore.self) private var store
	@Environment(\.openWindow) private var openWindow

	var body: some View {
		VStack(spacing: 12) {
			BoardPreview(state: store.state, geometry: store.geometry)
				.frame(width: 220)
			QuickControls()
			Button("Open Board") { openWindow(id: "main") }
		}
		.padding()
		.frame(width: 300)
	}
}
