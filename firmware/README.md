# firmware — Pico W (Embedded Swift)

Not started; hardware work begins ~Feb 2027. Plan: Embedded Swift on the RP2040 with pico-sdk via C interop.
- PIO drives the WS2812 LEDs and the 74HC595 shift-register chain for the steppers.
- BLE + Wi-Fi (CYW43439).
- Built-in modes are rendered locally with `shared/BoardKit`.

See [`../docs/app-plan.md`](../docs/app-plan.md).
