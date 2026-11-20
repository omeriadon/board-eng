# board-eng — Kinetic Dither Board (monorepo)

A school engineering-design project: a **mechanical, kinetic 3D version of a dither effect**. It's a square board of moving tiles, each carrying a grid of square RGB pixels. The lights draw a fine dither pattern; the tiles slide in and out to add slow, calming 3D motion and a soft mechanical-keyboard-like sound.

**Problem it addresses:** during short, unpredictable waits in focused work (AI tools, builds, renders), people reach for their phones and doomscroll. The board is a screen-free, calming desk object that gives idle attention somewhere to rest.

## Layout

| Folder | What |
|---|---|
| [`docs/`](docs) | [`context.md`](docs/context.md) (all decisions and history), [`app-plan.md`](docs/app-plan.md) (features, navigation, architecture), [`prospectful.md`](docs/prospectful.md) (ideas for later) |
| [`hardware/`](hardware) | [`ingredients.md`](hardware/ingredients.md) (parts list), [`BUILD-NOTES.md`](hardware/BUILD-NOTES.md) (print/laser checklist), [`cad/`](hardware/cad) (parametric generator + STL/PDF outputs) |
| [`firmware/`](firmware) | Pico W code, Embedded Swift (not started) |
| [`server/`](server) | Swift + Vapor server (not started) |
| [`apps/`](apps) | SwiftUI iOS + macOS clients, maybe watchOS (not started) |
| [`shared/`](shared) | `BoardKit` Swift package shared by everything (not started) |

## Hardware parts (`hardware/cad/out/`)

| File | Make with | Qty |
|---|---|---|
| `tile_head.stl` | Prusa MK4S, black PLA, **face-down** | N² |
| `tile_stem.stl` | Prusa MK4S, black PLA, upright | N² |
| `test_clearance_coupon.stl` | Print first: a test plate with 4 slightly different hole sizes + a short stem, to find the best sliding fit | 1 |
| `laser_diffusers_smoked.pdf` | Laser, smoked "LED" acrylic ~2 mm | 1 sheet |
| `laser_front_bezel_black.pdf` | Laser, black acrylic 3 mm | 1 |
| `laser_guide_plate_x2.pdf` | Laser, clear acrylic 3 mm | 2 |
| `blueprint_tile.pdf` | Dimensioned drawing | — |

Laser PDFs are **1:1 scale in mm**, red hairline = cut. Read [`hardware/BUILD-NOTES.md`](hardware/BUILD-NOTES.md) before printing or cutting. Main CAD from here on is **Shapr3D**; the generator is a parametric reference.

Regenerate:
```sh
python3 -m venv .venv
.venv/bin/pip install manifold3d numpy trimesh svglib reportlab
.venv/bin/python hardware/cad/tile.py
```

Repo rule: only PDF / STL / source / markdown are committed, no HTML or SVG.
