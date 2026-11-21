# Build Notes — for when it's time to actually make it

## 3D printing (Prusa MK4S)

Slower speed and higher quality settings help surface finish and consistency. **Dimensional accuracy comes mostly from calibration**, so set these in PrusaSlicer before printing tiles:

1. **Elephant foot compensation** (Print Settings → Advanced): stops the first layer bulging outward. Matters most for the tile heads, which print face-down. The CAD also has a 0.4 mm chamfer on that edge as backup.
2. **XY size compensation** (Print Settings → Advanced): small +/- tweak if holes or outer sizes come out consistently too big or too small. Tune it with the coupon.
3. **Correct filament profile / flow:** use the matching Prusa profile for your exact filament (or calibrate flow) so walls come out the right thickness.
4. **Print `cad/out/test_clearance_coupon.stl` first.**
   - It has four square holes at 0.15 / 0.20 / 0.25 / 0.30 mm clearance per side (1–4 dimples mark which is which), plus a short test stem.
   - Pick the hole the stem slides through smoothly without wobble.
   - Put that value into `STEM_CLEAR` in `cad/tile.py` and regenerate.
5. Print **all tiles in the same orientation with the same filament roll**, so they shrink identically.
   - Heads: face-down. Stems: upright.
6. Raise quality and lower speed on top of the above for cleaner walls.

## Laser cutting

- The PDFs in `cad/out/` are **1:1 scale in mm** with red hairline (0.1 mm) cut lines. Import at 100%; don't "fit to page".
- Measure the laser's **kerf** on a scrap test square. If the guide holes come out too big, adjust `STEM_CLEAR` or compensate in the laser software.
- `laser_front_bezel_black.pdf` → black acrylic, 3 mm
- `laser_guide_plate_x2.pdf` → clear acrylic, 3 mm, **cut 2**
- `laser_diffusers_smoked.pdf` → smoked "LED" acrylic, ~2 mm

## Assembly reminders

- Glue the diffusers flush on the tile heads with an acrylic-safe glue that won't fog it. Test on scrap first: CA (superglue) can frost clear acrylic.
- Dry-lube the stems with PTFE spray or graphite.
- Check every tile slides freely in both guide plates before attaching the servos.
