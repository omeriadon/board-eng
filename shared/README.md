# shared — BoardKit

A Swift package used by the firmware, server and apps.
- `BoardGeometry`: tiles per side, LEDs per tile, height levels
- `RGB` / `Pixel`, `BoardMode`, `DitherPattern`, `HeightMode`, `DitherSettings`, `BoardState` (Codable except in Embedded builds)
- `DitherField`: the animated dither renderer ported from Stipple, producing a `BoardFrame` (LED colours + tile heights)

Rules: **no Foundation, SIMD or libm in `Sources/`**, so the same code compiles as Embedded Swift for the Pico W. Tests can use Foundation.

```sh
cd shared/BoardKit && swift test
```
