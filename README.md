# Movement Labs

Open `project.godot` in Godot and press **F5** for **Lab 02**. The project remains
configured for Godot 4.7. Validation on this machine uses Godot **4.6.3**.

## Play

| Action | Key |
| --- | --- |
| Move | A / D or Left / Right |
| Jump / wall jump | Space, W, Up; tap for a short hop, hold for height |
| Slide / crouch | Hold S, Down, Shift |
| Restart current mode | R |
| Toggle previous completed run ghost | G |
| Switch to preserved Lab 01 / new Lab 02 | 1 / 2 |
| Timed run / exploration (Lab 02) | E; starts a fresh attempt |
| Course overview (Lab 02) | M |

Lab 02 spans 28,600 horizontal pixels across five connected basins. The teal
route carries speed down long slopes and through low shortcuts. Purple shafts,
launch ridges, stepping islands, return stairs and overlook spurs offer alternate
lines. Amber pockets catch missed gaps and provide a two-jump route back up.
Routes reconnect, and the fastest tested line does not use wall jumping.

The scripted full run takes about **31.3 seconds**, with five gap jumps and no
wall jumps. This is a reproducible test line, not a claim about the absolute
fastest possible route. Exploration has **45 optional discovery rings**, a map,
and recovery at the last visited basin rest stop. E disables the finish and
recording so exploration cannot replace a timed ghost. R clears discoveries;
progress is per attempt. Exploring all branches is designed for **5–10 minutes**,
but that pacing needs human playtesting. Timed recording supports up to 15 minutes.

## Movement and editing

`scenes/movement_lab_02.tscn` contains ordinary editable StaticBody2D terrain,
CollisionPolygon2D shapes, Polygon2D fills, Line2D edges, labels, discoveries and
rest-stop markers. Edit collision, fill and edge together. It is fully authored
in the scene; no generator or external package is needed to run it.

`scenes/player_02.tscn` uses `scripts/player_02.gd`. Select Player in the Inspector
to edit running, jump, slide and wall-jump parameters. Run, gravity, slide
friction, slope acceleration and ground-speed cap retain the original values.

- Wall jumping includes a 140 ms wall grace window, the existing 160 ms input
  buffer, a 120 ms launch control lock and a held-against-wall fall-speed cap.
- Sliding changes the capsule from 40 to 22 px high while keeping its feet fixed.
  A physics shape query blocks standing and jump expansion under a ceiling,
  including while airborne. Standing resumes automatically when clear.
- Floor snapping and the existing tangent-speed calculation remain intact.
  `maximum_speed` caps ground-tangent speed, not total airborne vector speed.

The shared `scripts/lab.gd` now exposes course ID, replay path, duration and
bounds with Lab 01 defaults. `scripts/lab_02.gd` supplies Lab 02's finish region,
local fall boundary, exploration, discovery display and map.

## Lab 01 regression baseline

Lab 01's scene, player scene, controller and original behavioral test are
unchanged. Press 1 or run `scenes/movement_lab.tscn` directly. Lab 01 retains its
original visual-only slide and user save location.

The uploaded replay is preserved byte-for-byte in
`tests/fixtures/lab01_7_78.json`: **7.783333 seconds, 235 samples, 1,046.83 px/s
peak slide velocity**. It is a positional recording sampled at 30 Hz, not a
deterministic input recording. Tests load and interpolate it in Lab 01, and
verify rejection in Lab 02. They never overwrite the fixture or the user's save.

## Ghosts and telemetry

| Course | Identifier | Save file |
| --- | --- | --- |
| Lab 01 | `movement_lab_01` | `user://movement_lab_last_run.json` |
| Lab 02 | `movement_lab_02_v1` | `user://movement_lab_02_v1_last_run.json` |

Use Godot's **Project > Open User Data Folder** to find player saves. Each lab
loads only its own identifier. Change the Lab 02 identifier and replay path when
making incompatible course changes. The most recent completed timed run becomes
the ghost. New optional telemetry fields record physical crouch, floor contact,
floor normal, actual velocity, tangent speed and wall-jump count. Ghosts display
the recorded crouch pose; original version-1 positional recordings still load.

## Validation

From this project directory, substitute your Godot executable:

```powershell
godot --headless --path . --fixed-fps 60 --script res://tests/test_movement.gd
godot --headless --path . --fixed-fps 60 --script res://tests/test_lab02.gd
```

The first suite has 20 regression checks; the second has 38 checks for collision,
wall forgiveness, actual branch traversals, the complete timed route, fixture
compatibility, long ghosts and exploration recovery. Tests use only
`tests/.runtime/`, which is ignored by Git. See `docs/LAB02_VALIDATION.md` for
results, changed files, slope findings and limitations.
