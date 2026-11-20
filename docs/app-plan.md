# App, Server & Firmware Plan

_Last updated: 2026-11-20 (rev 2). Navigation revised by the builder; app + BoardKit scaffolded._

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

## 2. Navigation (rev 2, builder's revision)

**Builder's rules:**
- **No "Board" home tab.** The live preview and dither controls belong to **Dither**.
- **Timer is its own section**, not part of the board controls.
- **Don't condense unrelated things into fewer tabs.** More than 5 tabs on iPhone is fine: iOS adds a **More** tab. That also makes the Mac sidebar bigger and nicer.
- **Colours** are global palettes used by every mode (the dither palette, sun colours, timer bar colour), and Shortcuts can switch them. It's its own section.

**Sections (`AppSection`, in this order):**

| # | Section | Contents | Group (sidebar) |
|---|---|---|---|
| 1 | **Dither** | Live board preview (pixels + tile heights) + Stipple-style settings (wave, pattern, levels, tiles/motion, quiet mode) | Display |
| 2 | **Colours** | Palettes and presets shared by every mode | Style |
| 3 | **Timer** | Top pixel row is the timer bar, second row a margin. Start/pause, presets | Display |
| 4 | **Ambient** | Sun-through-the-day idle mode | Display |
| 5 | **Music** | Music Mirror: album art, progress in the bottom 2 rows, beat-jumping tiles. **Mac only**; hidden on iOS | Display |
| 6 | **Automations** | Schedules, presence (Mac keyboard/mouse, iPhone location), ambient light sensor, Shortcuts | Automate |
| 7 | **Device** | Connection, motion & quiet mode, calibration, diagnostics, firmware | Board |

- **iPhone:** `TabView` + `.sidebarAdaptable`. Dither, Colours, Timer and Ambient sit in the tab bar; the rest go under **More**.
  - **Quick controls** (power + brightness) live in the iOS 26 `tabViewBottomAccessory`, like the Music mini-player, so they're reachable from every tab without a Board tab.
- **iPad:** the same `TabView` becomes a sidebar.
- **Mac:** `NavigationSplitView`, with the sidebar grouped Display / Style / Automate / Board.
  - Quick controls (power, brightness, mode) sit in the toolbar.
  - A **`MenuBarExtra`** shows a live mini preview + quick controls, because the Mac app runs all the time.
- **watchOS (later):** power, mode, timer start; the Digital Crown sets brightness.

**Scaffolded (builds for iOS 26 + macOS 26):** `apps/project.yml` (XcodeGen) → `apps/Board.xcodeproj`.
- Shared code is in `apps/Board/Shared`: `AppSection`, `BoardStore`, `BoardPreview`, `DitherView`, `QuickControls`.
- Platform entry points are in `apps/Board/iOS` and `apps/Board/macOS`.
- The Dither section is fully wired to `BoardKit` (live preview + all settings); the other sections are placeholders.

## 3. Architecture thoughts

- **The board should work on its own.**
  - The Pico W renders built-in modes (dither, sun, timer) **locally** with the shared `BoardKit` engine. 400 pixels at 30 fps is easy for an RP2040.
  - Apps and server send **settings**, not frames.
  - Frames are streamed only where needed: an album-art image once per track, plus beat events.
- **Transport:**
  - BLE for setup and nearby control.
  - Local Wi-Fi (WebSocket/HTTP on the Pico, found via mDNS/Bonjour) for normal app control.
  - Server for remote access and integrations.
- **The server runs in the cloud** (builder's decision). Hosting provider TBD.

  Server jobs: remote control away from home, schedules even when no device is awake (the Pico can also keep time with NTP), fetching weather and sunrise data (HTTPS is heavy on a Pico), and relaying Mac-only data.
- **Embedded Swift constraints:** no Foundation and limited existentials/reflection. `BoardKit`'s engine and protocol types must stick to plain Swift (structs, enums, fixed arrays, Float math). Then the same code compiles for the Pico, the server and the apps.

### Firmware requirement: time sync
- **On startup and after any power loss, the Pico W asks the server for the current time** (`GET /time`, plus `?tz=` for the local offset) and sets its clock.
- Schedules, the sun mode and the timer depend on this.
- Fallback if the server is unreachable: plain NTP (`pool.ntp.org`). If neither works, keep running modes that don't need the time and retry with backoff.

### Music Mirror caveats (Mac)
- **Now playing:** Apple restricted the `MediaRemote` private framework for third-party apps in macOS 15.4.
  - **Reliable route:** query **Music.app** and **Spotify** directly via AppleScript / ScriptingBridge for track, position and artwork. This needs the Automation permission.
  - A community "mediaremote-adapter" workaround exists for other players, but it's fragile.
- **Now playing approach (decided):** AppleScript / ScriptingBridge to Music.app and Spotify, with the one-time Automation permission.
- **Beat detection:** deferred. No public beat API exists; the approach will be decided later (the builder doesn't want system-audio capture for now).
- **iPhone:** `MPMusicPlayerController.systemMusicPlayer` only covers Apple Music and only while the app is in the foreground, which is why this mode is Mac only.

---

## 4. Status / next steps (software)

- ✅ `shared/BoardKit`: geometry, colours, settings, `BoardState` (Codable when not Embedded), and the **dither engine** ported from Stipple. It's libm/Foundation-free; 7 tests pass.
  - ⚠️ Not yet verified as Embedded Swift: no Embedded-capable toolchain is installed. Install one with `swiftly` (Swift 6.x release toolchains include the Embedded stdlib) before firmware work.
- ✅ `apps/`: iOS + macOS app shell with the revised navigation; the Dither section is live.
- ⏳ `server/`: Vapor scaffold in progress (`/health`, `/time`, board state, WebSocket).

Original next steps:

1. Agree on the navigation above.
2. Scaffold:
   - `shared/BoardKit` (Swift package: settings models + dither engine ported from Stipple)
   - `apps/` (multiplatform Xcode project, iOS + macOS targets)
   - `server/` (Vapor package)
   - `firmware/` (Embedded Swift + pico-sdk toolchain)
3. Build the Board tab with a live preview first, then the Dither settings.
