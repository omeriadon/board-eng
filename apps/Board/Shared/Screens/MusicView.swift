import BoardKit
import SwiftUI

/// Music Mirror: the album art of what's playing on the Mac, dithered onto the board, with progress along the bottom.
/// It only works on the Mac, which can watch Music and Spotify all the time.
struct MusicView: View {
	var body: some View {
		#if os(macOS)
			MacMusicView()
		#else
			ContentUnavailableView("Mac Only", systemImage: "music.note",
			                       description: Text("Music Mirror needs your Mac to watch what's playing. Open Board on your Mac to use it."))
				.navigationTitle("Music")
		#endif
	}
}

#if os(macOS)
	private struct MacMusicView: View {
		@Environment(BoardStore.self) private var store
		@Environment(NowPlayingMonitor.self) private var nowPlaying
		@AppStorage("lookUpArtOnline") private var lookUpArtOnline = true

		var body: some View {
			@Bindable var store = store
			let m = $store.state.music

			Form {
				ModeBanner(mode: .music)

				Section("Now Playing") {
					if let track = nowPlaying.track {
						HStack(spacing: 14) {
							Group {
								if let image = nowPlaying.artworkImage {
									Image(nsImage: image).resizable().interpolation(.high)
								} else {
									Image(systemName: "music.note").font(.title).foregroundStyle(.secondary)
								}
							}
							.frame(width: 64, height: 64)
							.background(.quaternary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
							.clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
							VStack(alignment: .leading, spacing: 2) {
								Text(track.title).font(.headline).lineLimit(1)
								Text(track.artist).foregroundStyle(.secondary).lineLimit(1)
								Text("\(track.app) · \(track.isPlaying ? "Playing" : "Paused")").font(.caption).foregroundStyle(.secondary)
							}
						}
					} else if nowPlaying.permissionDenied {
						Label("Board isn't allowed to control Music or Spotify. Turn it on in System Settings → Privacy & Security → Automation.", systemImage: "lock.fill")
					} else {
						Label("Nothing is playing in Music or Spotify.", systemImage: "music.note.slash").foregroundStyle(.secondary)
					}
				}

				Section {
					Toggle("Progress on the Bottom Rows", isOn: m.showsProgress)
					Toggle("Dither the Album Art", isOn: m.ditherArt)
					Toggle("Look Up Missing Covers Online", isOn: $lookUpArtOnline)
				} header: {
					Text("Board")
				} footer: {
					Text("Dithering uses the Dither tab's colour levels and pattern. Apple Music streaming songs don't share their cover with other apps, so the cover is found with Apple's public search, which is sent only the song's title and artist. With nothing playing, the board shows the dither field.")
				}

				Section {
					ValueSlider("Beat Jump", value: m.beatJump, in: 0 ... 1, format: { "\(Int(($0 * 100).rounded()))%" })
						.disabled(true)
				} header: {
					Text("Motion")
				} footer: {
					Text("Tiles jumping to the beat is wired into the board already, but beat detection isn't built yet, so this stays off for now.")
				}
			}
			.formStyle(.grouped)
			.safeAreaInset(edge: .top, spacing: 0) { PreviewHeader() }
			.navigationTitle("Music")
			.onAppear { nowPlaying.start(store: store) }
		}
	}
#endif
