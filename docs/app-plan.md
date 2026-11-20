# App, Server & Firmware Plan

_Last updated: 2026-11-20 (rev 1). These are initial thoughts, not final._

The project has three software parts, all in this monorepo:

| Folder | What | Language / framework |
|---|---|---|
| `firmware/` | Runs on the **Pico W**: LEDs, steppers, sensors, BLE + Wi-Fi | **Embedded Swift** (RP2040), pico-sdk via C interop |
| `server/` | Bridge for remote access, schedules, integrations | **Swift + Vapor** |
| `apps/` | **iOS + macOS** client (shared code, platform-specific features), maybe **watchOS** later | **SwiftUI** |
| `shared/` | `BoardKit`, a Swift package shared by all three: protocol types, settings models, **the dither engine** | Swift (written to also compile as Embedded Swift) |

Timeline: the school project starts in ~3 months (≈ Feb 2027). The design portfolio is next year. **The apps can start now**, to get the UI/UX right early; hardware and firmware wait.

---

## 1. Feature list (everything discussed so far)

### Display modes
- **Dither:** the core mode. Settings modelled on **Stipple** (`Xcode_App_Library/Stipple`):
  - Wave: speed, direction, frequency, amplitude, scale, contrast, brightness
  - Pattern: Bayer 8×8 / 4×4 / 2×2, halftone, lines, crosshatch, noise
  - Strength and colour levels
  - Palette (up to 8 colours, colour field)
  - Presets
  - Stipple settings that don't apply to fixed physical pixels: cell size, gap, corner radius, blur
  - **New for the board: motion settings:**
    - Height mapping: tile height follows the block's average brightness, or a separate wave
    - Motion amount and speed
    - Quiet mode
    - Max tiles moving at once
- **Ambient / Sun (idle mode):** shows the sun (or similar) and animates through the day. Sunrise and sunset come from location; colours shift through the day.
- **Music Mirror (Mac only):**
  - Album art of the currently playing track, dithered to the board resolution
  - **Bottom two pixel rows:** playback progress
  - **Optional:** tiles jump to the beat
- **Timer overlay:**
  - **Top two pixel rows:** row 1 is the timer bar, row 2 is a black margin
  - The rest of the board keeps running the current mode
- **Colours:** palettes and presets, changeable from Shortcuts.

### Automations
- **Schedules:** turn on/off at times or days, and switch modes on a schedule.
- **Presence (Mac):** keyboard/mouse activity and other at-my-desk cues. The board sleeps (stops moving, dims) when you're away and wakes when you're back. Settings: idle timeout, which cues count, what "away" does.
- **Presence (iPhone):** location (home/away), Focus modes.
- **Ambient light sensor:** brightness curve, min/max, night-off threshold.
- **Shortcuts / Siri / Automations:** expose plenty of **App Intents**, for example:
  - Turn on/off
  - Set mode, preset, colour or brightness
  - Start/stop the timer
  - Get the board's state
- **Long task waiting** (the problem statement): the Mac app detects a long-running task (e.g. Claude Code) and switches the board to a "waiting" pattern.

### Device
- Connection: BLE, local Wi-Fi, or via the server.
- Calibration: home all tiles, test pattern, per-tile test.
- Motion: quiet mode, speed, simultaneous tiles.
- Diagnostics: internal temperature (NTC), firmware version, uptime.
- Status LED behaviour.

---

## 2. Navigation — initial thoughts

**One shared section model, platform-specific containers.**

```swift
enum AppSection: Hashable { case board, modes, automations, device }
```

### iPhone / iPad: `TabView` with `.tabViewStyle(.sidebarAdaptable)`
- **iPhone:** a tab bar with 4 tabs (Liquid Glass on iOS 26). **iPad:** the same code becomes a sidebar.
- I'd pick this over a single `NavigationStack`. The app has four distinct jobs (control it now / tune modes / automate / device), and a tab bar keeps the Board tab one tap away.

| Tab | Contents |
|---|---|
| **Board** (home) | **Live preview** of the board (pixel grid + tile heights shaded or subtly 3D), power, brightness, **current mode picker**, preset carousel, timer start |
| **Modes** | List → Dither (Stipple-style form), Ambient/Sun, Music Mirror (shown greyed on iPhone with "Mac only"), Timer, Colours & palettes |
| **Automations** | Schedules, Presence, Ambient light, Shortcuts gallery |
| **Device** | Connection, motion & quiet mode, calibration, diagnostics, app settings |

### Mac: `NavigationSplitView` sidebar
- The same 4 sections, but **Modes and Automations expand into their sub-items** in the sidebar (Dither, Ambient, Music, Timer / Schedules, Presence, Light, Shortcuts).
- The detail pane always has the live preview pinned at the top.
- **Plus a `MenuBarExtra`:** the Mac app has to run all the time (presence detection, Music Mirror, long-task detection), so it should be a **menu-bar app with launch-at-login**. The main window opens from the menu bar. The menu bar popover holds quick controls: power, mode, brightness, timer.
- App-level settings go in the standard `Settings` scene (⌘,).

### watchOS (maybe later)
- A single screen: power, mode, timer start. The Digital Crown sets brightness, like Stipple's crown preset switching.

### Design notes
- **The live preview is the hero.** It uses the same `BoardKit` dither engine as the firmware, so the phone shows exactly what the board shows.
- Reuse Stipple's patterns: `ValueSlider`, `PresetSection`, `PaletteSection`, `Codable` settings with defaulting decoders.

---

## 3. Architecture thoughts

- **The board should work on its own.**
  - The Pico W renders built-in modes (dither, sun, timer) **locally** with the shared `BoardKit` engine. 400 pixels at 30 fps is easy for an RP2040.
  - Apps and server send **settings**, not frames.
  - Frames are streamed only where needed: an album-art image once per track, plus beat events.
- **Transport:**
  - BLE for setup and nearby control.
  - Local Wi-Fi (WebSocket/HTTP on the Pico, found via mDNS/Bonjour) for normal app control.
  - Server for remote access and integrations.
- **The Vapor server can't run on the Pico.** It needs a host:
  - The Mac at home: free, but only works while the Mac is on.
  - A home Raspberry Pi: one-off cost.
  - A small VPS / Fly.io: ~$0–6/month.

  Server jobs: remote control away from home, schedules even when no device is awake (the Pico can also keep time with NTP), fetching weather and sunrise data (HTTPS is heavy on a Pico), and relaying Mac-only data.
  **Open question:** is the server needed for v1, or can it come later?
- **Embedded Swift constraints:** no Foundation and limited existentials/reflection. `BoardKit`'s engine and protocol types must stick to plain Swift (structs, enums, fixed arrays, Float math). Then the same code compiles for the Pico, the server and the apps.

### Music Mirror caveats (Mac)
- **Now playing:** Apple restricted the `MediaRemote` private framework for third-party apps in macOS 15.4.
  - **Reliable route:** query **Music.app** and **Spotify** directly via AppleScript / ScriptingBridge for track, position and artwork. This needs the Automation permission.
  - A community "mediaremote-adapter" workaround exists for other players, but it's fragile.
- **Beat:** no public API gives beats for Apple Music, and Spotify's audio-features API is deprecated.
  - **Plan:** capture system audio with **Core Audio process taps** (macOS 14.2+) or ScreenCaptureKit audio, then run onset/beat detection locally, sending "beat" events to the board.
- **iPhone:** `MPMusicPlayerController.systemMusicPlayer` only covers Apple Music and only while the app is in the foreground, which is why this mode is Mac only.

---

## 4. Next steps (software)

1. Agree on the navigation above.
2. Scaffold:
   - `shared/BoardKit` (Swift package: settings models + dither engine ported from Stipple)
   - `apps/` (multiplatform Xcode project, iOS + macOS targets)
   - `server/` (Vapor package)
   - `firmware/` (Embedded Swift + pico-sdk toolchain)
3. Build the Board tab with a live preview first, then the Dither settings.
