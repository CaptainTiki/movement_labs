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

## Lab 02: The Reservoir

One shared space replaces the five repeated basins. Three routes overlap across
16,000 horizontal pixels and about 2,800 vertical pixels:

- **Reservoir:** drop from the start into the west chute, carry slide speed beneath
  the gallery, then climb the long east bank. Tested full run: **36.05 seconds**.
- **Gallery:** jump the first gap and stay in the middle of the space. Cross the
  central atrium and drop onto the east bank. Tested full run: **56.97 seconds**.
- **Canopy:** climb the west shaft, cross above the other routes, then drop from
  the east launch onto the rising bank. Tested full run: **49.78 seconds**.

These are reproducible input-driven lines, not optimized records. The reservoir
line uses no wall jumps; the gallery needs neither wall jumps nor sliding. You
can also mix routes: the central shaft links all three elevations, the west
return shaft links the chute and gallery, and the mezzanine provides a running
and jumping ascent toward the canopy. The gallery can be traversed in reverse.
Gaps drop into other playable routes, with gardens, balconies and return ledges
between them. All routes share the east bank and finish.

Exploration has **31 optional discovery rings**, a labeled, colored overview map,
and recovery at the last visited rest stop. E disables finishing and recording,
so exploration cannot replace a timed ghost. R clears discoveries; progress is
per attempt. Exploring all branches is designed for **5–10 minutes**, but this
pacing still needs human playtesting. Timed recording supports up to 15 minutes.

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
world fall boundary, exploration, discovery display and map.

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
| Lab 02 | `movement_lab_02_v2` | `user://movement_lab_02_v2_last_run.json` |

Use Godot's **Project > Open User Data Folder** to find player saves. Each lab
loads only its own identifier. The reservoir redesign rejects both Lab 01 and
the earlier five-basin Lab 02 ghosts; their save files are left intact. Change the Lab 02 identifier and replay path when
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

The first suite has 20 regression checks; the second has 45 checks for collision,
wall forgiveness, bidirectional crossings, three complete routes, fixture
compatibility, long ghosts and exploration recovery. Tests use only
`tests/.runtime/`, which is ignored by Git. See `docs/LAB02_VALIDATION.md` for
results, changed files, slope findings and limitations.
