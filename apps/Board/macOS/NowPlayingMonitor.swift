import AppKit
import BoardKit
import Observation

/// Watches Music and Spotify for what's playing and mirrors the album art onto the board.
/// It only reads while the board is in Music Mirror, and never launches either app.
@Observable
final class NowPlayingMonitor {
	struct Track: Equatable {
		var title: String
		var artist: String
		var app: String
		var isPlaying: Bool
	}

	private(set) var track: Track?
	private(set) var artworkImage: NSImage?
	private(set) var permissionDenied = false

	@ObservationIgnored private var task: Task<Void, Never>?
	@ObservationIgnored private var currentKey = ""

	func start(store: BoardStore) {
		guard task == nil else { return }
		task = Task { [weak self] in
			while !Task.isCancelled {
				if store.state.mode == .music {
					await self?.poll(store)
				} else {
					self?.idle(store)
				}
				try? await Task.sleep(for: .seconds(1))
			}
		}
	}

	func stop() {
		task?.cancel()
		task = nil
	}

	/// Music Mirror isn't showing: forget the track so the next visit starts clean.
	private func idle(_ store: BoardStore) {
		guard track != nil || artworkImage != nil else { return }
		track = nil
		artworkImage = nil
		currentKey = ""
		store.artwork = nil
	}

	private func poll(_ store: BoardStore) async {
		let running = Set(NSWorkspace.shared.runningApplications.compactMap(\.bundleIdentifier))
		var found: NowPlayingScripts.Reading?
		var denied = false

		for player in NowPlayingScripts.Player.allCases where running.contains(player.bundleID) {
			switch await NowPlayingScripts.read(player) {
				case let .playing(reading) where found == nil || reading.isPlaying:
					found = reading
					if reading.isPlaying { break }
				case .denied: denied = true
				default: break
			}
			if found?.isPlaying == true { break }
		}
		permissionDenied = denied && found == nil

		guard let reading = found else {
			if track != nil { idle(store) }
			return
		}

		let next = Track(title: reading.title, artist: reading.artist, app: reading.player.name, isPlaying: reading.isPlaying)
		if track != next { track = next }

		let key = "\(reading.player.name)|\(reading.title)|\(reading.artist)"
		if key != currentKey {
			currentKey = key
			artworkImage = nil
			store.artwork = nil
			var data = await NowPlayingScripts.artworkData(reading)
			// Apple Music streaming tracks don't hand their art to scripts, so ask Apple's public search for the cover.
			if data == nil, reading.player == .music, UserDefaults.standard.object(forKey: "lookUpArtOnline") as? Bool ?? true {
				data = await NowPlayingScripts.onlineArtwork(title: reading.title, artist: reading.artist)
			}
			if let data, let image = NSImage(data: data), key == currentKey {
				artworkImage = image
				store.artwork = Self.artwork(from: image, side: store.geometry.pixelsPerSide, id: Self.hash(key))
			}
		}

		let progress = reading.duration > 0 ? Float(min(max(reading.position / reading.duration, 0), 1)) : 0
		let music = store.state.music
		if music.isPlaying != reading.isPlaying || abs(music.progress - progress) > 0.01 {
			store.state.music.isPlaying = reading.isPlaying
			store.state.music.progress = progress
		}
	}

	private static func hash(_ text: String) -> UInt32 {
		var h: UInt32 = 2_166_136_261
		for byte in text.utf8 { h = (h ^ UInt32(byte)) &* 16_777_619 }
		return h == 0 ? 1 : h
	}

	/// Centre-crops to a square and shrinks to the board's pixels.
	static func artwork(from image: NSImage, side: Int, id: UInt32) -> Artwork? {
		guard let cg = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
		let edge = min(cg.width, cg.height)
		let crop = CGRect(x: (cg.width - edge) / 2, y: (cg.height - edge) / 2, width: edge, height: edge)
		guard let square = cg.cropping(to: crop),
		      let space = CGColorSpace(name: CGColorSpace.sRGB),
		      let ctx = CGContext(data: nil, width: side, height: side, bitsPerComponent: 8, bytesPerRow: side * 4, space: space,
		                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue),
		      let data = ctx.data
		else { return nil }
		ctx.interpolationQuality = .high
		ctx.draw(square, in: CGRect(x: 0, y: 0, width: side, height: side))
		let bytes = data.bindMemory(to: UInt8.self, capacity: side * side * 4)
		let pixels = (0 ..< side * side).map { Pixel(r: bytes[$0 * 4], g: bytes[$0 * 4 + 1], b: bytes[$0 * 4 + 2]) }
		return Artwork(id: id, side: side, pixels: pixels)
	}
}

/// AppleScript for Music and Spotify, run off the main thread so a slow player can't freeze the window.
nonisolated enum NowPlayingScripts {
	enum Player: CaseIterable, Sendable {
		case music, spotify

		var bundleID: String { self == .music ? "com.apple.Music" : "com.spotify.client" }
		var name: String { self == .music ? "Music" : "Spotify" }
	}

	struct Reading: Sendable {
		var player: Player
		var title: String
		var artist: String
		var isPlaying: Bool
		var position: Double
		var duration: Double
		var artworkURL: String?
	}

	enum Result: Sendable {
		case stopped, denied, playing(Reading)
	}

	@concurrent static func read(_ player: Player) async -> Result {
		let source: String
		switch player {
			case .music:
				source = """
				tell application "Music"
					if player state is stopped then return {"stopped"}
					set t to current track
					return {name of t, artist of t, (player state is playing) as text, (player position) as text, (duration of t) as text}
				end tell
				"""
			case .spotify:
				source = """
				tell application "Spotify"
					if player state is stopped then return {"stopped"}
					set t to current track
					return {name of t, artist of t, (player state is playing) as text, (player position) as text, ((duration of t) / 1000) as text, artwork url of t}
				end tell
				"""
		}
		var error: NSDictionary?
		guard let script = NSAppleScript(source: source) else { return .stopped }
		let out = script.executeAndReturnError(&error)
		if let code = error?[NSAppleScript.errorNumber] as? Int { return code == -1743 ? .denied : .stopped }
		guard out.numberOfItems >= 5 else { return .stopped }

		func text(_ i: Int) -> String { out.atIndex(i)?.stringValue ?? "" }
		func number(_ i: Int) -> Double { Double(text(i).replacingOccurrences(of: ",", with: ".")) ?? 0 }
		return .playing(Reading(player: player, title: text(1), artist: text(2), isPlaying: text(3) == "true",
		                        position: number(4), duration: number(5), artworkURL: out.numberOfItems >= 6 ? text(6) : nil))
	}

	/// Apple's public iTunes Search API: no key, and it only ever sees the title and artist.
	@concurrent static func onlineArtwork(title: String, artist: String) async -> Data? {
		var parts = URLComponents(string: "https://itunes.apple.com/search")
		parts?.queryItems = [.init(name: "term", value: "\(artist) \(title)"), .init(name: "media", value: "music"),
		                     .init(name: "entity", value: "song"), .init(name: "limit", value: "1")]
		guard let url = parts?.url,
		      let (json, _) = try? await URLSession.shared.data(from: url),
		      let root = try? JSONSerialization.jsonObject(with: json) as? [String: Any],
		      let first = (root["results"] as? [[String: Any]])?.first,
		      let small = first["artworkUrl100"] as? String,
		      let big = URL(string: small.replacingOccurrences(of: "100x100", with: "300x300"))
		else { return nil }
		return try? await URLSession.shared.data(from: big).0
	}

	@concurrent static func artworkData(_ reading: Reading) async -> Data? {
		switch reading.player {
			case .music:
				var error: NSDictionary?
				let script = NSAppleScript(source: "tell application \"Music\" to return data of artwork 1 of current track")
				let out = script?.executeAndReturnError(&error)
				return error == nil ? out?.data : nil
			case .spotify:
				guard let text = reading.artworkURL, let url = URL(string: text) else { return nil }
				return try? await URLSession.shared.data(from: url).0
		}
	}
}
