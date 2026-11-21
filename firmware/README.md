# firmware — Pico W (Embedded Swift)

Not started; hardware work begins ~Feb 2027. Plan: Embedded Swift on the RP2040 with pico-sdk via C interop.
- PIO drives the WS2812 LEDs (six data lines through a 74HCT245); servos through two PCA9685 boards over I2C.
- **Power limit:** every frame, run `PowerLimiter.limit(&frame)` from `shared/BoardKit` before sending LED data: it scales all LEDs by one factor so each 5 A LED bus stays in budget.
- BLE + Wi-Fi (CYW43439).
- Built-in modes are rendered locally with `shared/BoardKit`.

See [`../docs/app-plan.md`](../docs/app-plan.md).

## Requirements noted so far
- **Time sync:** on startup and after any power loss, ask the server for the current time (`GET /time?tz=<zone>`), with NTP as a fallback. Schedules, the sun mode and the timer depend on it.
- **Re-home** all tiles on boot (drive each to its end stop), and periodically when idle.
- **Thermal safety:** if the NTC reads too hot, dim the LEDs and pause the motors.
- **Ambient light:** the LDR sets the LED brightness curve.
- **Status LED:** dim when on; breathes when an app or the server is connected.

## Toolchain setup (before starting)
The Xcode toolchain has no Embedded Swift stdlib. Install a Swift release toolchain with `swiftly` (it includes `embedded` support), plus the pico-sdk and the `arm-none-eabi` tools. Use Apple's `swift-embedded-examples` (rpi-pico-w) as the starting template. `shared/BoardKit` is written to compile as Embedded Swift (no Foundation, SIMD or libm) but still needs verifying with that toolchain.
