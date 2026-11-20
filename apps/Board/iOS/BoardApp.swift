import SwiftUI

@main
struct BoardApp: App {
	@State private var store = BoardStore.shared

	var body: some Scene {
		WindowGroup {
			RootTabView()
				.environment(store)
		}
	}
}

/// iPhone: tab bar (more than five tabs collapse into "More").
/// iPad: `.sidebarAdaptable` turns the same tabs into a sidebar.
struct RootTabView: View {
	@State private var selection: AppSection = .dither

	var body: some View {
		TabView(selection: $selection) {
			ForEach(AppSection.allCases.filter(\.isAvailable)) { section in
				Tab(section.title, systemImage: section.symbol, value: section) {
					NavigationStack {
						SectionDetail(section: section)
					}
				}
			}
		}
		.tabViewStyle(.sidebarAdaptable)
		.tabViewBottomAccessory {
			QuickControls(showsModePicker: false)
				.padding(.horizontal)
		}
	}
}
