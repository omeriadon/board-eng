import BoardKit
import SwiftUI

/// How the app reaches the board, what the board says about itself, and calibration tools.
struct DeviceView: View {
	@Environment(BoardStore.self) private var store
	@State private var testTile = 0
	@State private var confirmReboot = false

	var body: some View {
		@Bindable var store = store
		@Bindable var connection = store.connection
		let status = store.link.status
		let up = store.link.connected

		Form {
			Section {
				LinkRow(kind: .bluetooth, connected: up.contains(.bluetooth), detail: store.bluetooth.statusText)
				LinkRow(kind: .wifi, connected: up.contains(.wifi), detail: store.webSocket.lastError ?? (connection.useServer ? "Through your server" : "Off"))
			} header: {
				Text("Connections")
			} footer: {
				Text("Changes go out on every connected link at once. It doesn't matter to the board which one they came by.")
			}

			Section {
				Toggle("Use Bluetooth", isOn: $connection.useBluetooth)
				Toggle("Use Server (Wi-Fi)", isOn: $connection.useServer)
				if connection.useServer {
					TextField("Server Address", text: $connection.serverURL, prompt: Text("board.example.com"))
						.autocorrectionDisabled()
						#if os(iOS)
						.textInputAutocapitalization(.never)
						.keyboardType(.URL)
						#endif
					SecureField("Password", text: $connection.token)
				}
			} header: {
				Text("Settings")
			} footer: {
				Text("The server keeps the time for the board and lets you control it from anywhere. The password is stored in your keychain.")
			}
			.onChange(of: connection.useBluetooth) { store.applyConnectionSettings() }
			.onChange(of: connection.useServer) { store.applyConnectionSettings() }
			.onChange(of: connection.serverURL) { store.applyConnectionSettingsSoon() }
			.onChange(of: connection.token) { store.applyConnectionSettingsSoon() }
			.onSubmit { store.applyConnectionSettings() }

			Section {
				Stepper(value: $store.geometry.tilesPerSide, in: BoardGeometry.tileRange) {
					LabeledContent("Tiles per Side", value: "\(store.geometry.tilesPerSide)")
				}
				Stepper(value: $store.geometry.ledsPerTileSide, in: BoardGeometry.ledRange) {
					LabeledContent("LEDs per Tile Side", value: "\(store.geometry.ledsPerTileSide)")
				}
				LabeledContent("Pixels", value: "\(store.geometry.pixelsPerSide) × \(store.geometry.pixelsPerSide) = \(store.geometry.pixelCount)")
				LabeledContent("Tiles (Motors)", value: "\(store.geometry.tileCount)")
				LabeledContent("LEDs with Status Bar", value: "\(store.geometry.totalLEDCount)")
				LabeledContent("Full-White Current", value: String(format: "%.0f A", store.geometry.fullWhiteAmps))
				LabeledContent("Full-Screen Brightness at \(Int(BoardGeometry.ledLimitAmps)) A", value: "≈ \(store.geometry.fullScreenNits(atLimitAmps: BoardGeometry.ledLimitAmps)) nits")
				LayoutPresets()
			} header: {
				Text("Board Layout")
			} footer: {
				Text("For planning: change these to see how the board would look and what it would draw. The board's own hardware has to be built to match. Brightness is an estimate for the 5 × 5 LED module with a printed diffuser, at the planned 10 A LED limit (two 5 A bucks).")
			}

			Section("Board") {
				if let status {
					LabeledContent("Firmware", value: "\(status.firmware)")
					LabeledContent("Running For", value: Self.duration(status.uptimeSeconds))
					LabeledContent("Case Temperature") {
						Text("\(Int(status.temperature.rounded())) °C").foregroundStyle(status.temperature >= 60 ? .red : .secondary)
					}
					LabeledContent("Room Light", value: "\(Int((status.ambientLight * 100).rounded()))%")
					if status.isHoming { Label("Finding tile positions…", systemImage: "arrow.triangle.2.circlepath") }
				} else {
					Label("Connect to the board to see its status.", systemImage: "cpu").foregroundStyle(.secondary)
				}
			}

			Section {
				Button("Find Tile Zero Positions", systemImage: "scope") { store.send(.homeAll) }
				Button("Run Test Pattern", systemImage: "waveform.path.ecg") { store.send(.testPattern) }
				Button("Stop Test", systemImage: "stop.circle") { store.send(.stopTest) }
				Stepper("Tile \(testTile + 1) of \(store.geometry.tileCount)", value: $testTile, in: 0 ... store.geometry.tileCount - 1)
				Button("Jump Tile \(testTile + 1)", systemImage: "arrow.up.square") { store.send(.testTile, argument: UInt8(testTile)) }
			} header: {
				Text("Calibration")
			} footer: {
				Text("Zero positions run automatically at power-up. The test pattern lifts every tile in turn, so you can hear and see that none are stuck.")
			}
			.disabled(up.isEmpty)

			Section {
				Button("Restart Board", systemImage: "power", role: .destructive) { confirmReboot = true }
					.disabled(up.isEmpty)
			}
		}
		.formStyle(.grouped)
		.safeAreaInset(edge: .top, spacing: 0) { PreviewHeader() }
		.navigationTitle("Device")
		.confirmationDialog("Restart the board?", isPresented: $confirmReboot) {
			Button("Restart", role: .destructive) { store.send(.reboot) }
		} message: {
			Text("It reconnects by itself in a few seconds.")
		}
	}

	static func duration(_ seconds: UInt32) -> String {
		let d = seconds / 86400, h = seconds % 86400 / 3600, m = seconds % 3600 / 60
		if d > 0 { return "\(d)d \(h)h" }
		return h > 0 ? "\(h)h \(m)m" : "\(m)m \(seconds % 60)s"
	}
}

private struct LayoutPresets: View {
	@Environment(BoardStore.self) private var store

	private static let presets: [(String, Int, Int)] = [
		("Planned: 5 × 5 tiles, 5 LEDs", 5, 5),
		("4 × 4 tiles, 5 LEDs", 4, 5),
		("4 × 4 tiles, 6 LEDs", 4, 6),
		("6 × 6 tiles, 5 LEDs", 6, 5),
	]

	var body: some View {
		Menu("Presets", systemImage: "square.grid.3x3") {
			ForEach(Self.presets, id: \.0) { preset in
				Button(preset.0) { store.geometry = BoardGeometry(tilesPerSide: preset.1, ledsPerTileSide: preset.2) }
			}
		}
	}
}

private struct LinkRow: View {
	let kind: LinkKind
	let connected: Bool
	let detail: String

	var body: some View {
		LabeledContent {
			Text(connected ? "Connected" : "Not connected").foregroundStyle(connected ? .green : .secondary)
		} label: {
			Label {
				VStack(alignment: .leading) {
					Text(kind.title)
					Text(detail).font(.caption).foregroundStyle(.secondary)
				}
			} icon: {
				Image(systemName: kind.symbol)
			}
		}
	}
}
