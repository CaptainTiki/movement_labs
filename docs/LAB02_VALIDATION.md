# Lab 02 implementation and validation

## Local source and delivery

Inspected `D:\Godot\REPOs\movement_labs`, on `main` at `0dad3ae`
(`First Player Controller`). The working tree was clean before this work.
All development and validation are local. No commit, push, pull request or other
GitHub mutation was performed.

## Changed and added files

- `project.godot`: launches Lab 02 by default; retains the 4.7 feature tag.
- `scripts/lab.gd`: configurable course/replay limits, finish/fall hooks, optional
  richer telemetry, crouching ghost pose, validated longer replays, lab switching.
- `scripts/lab_02.gd` (new): exploration mode, 45 discoveries, recovery rest stops,
  course map and Lab 02 finish/fall checks.
- `scripts/player_02.gd` and `scenes/player_02.tscn` (new): forgiving wall jumps,
  reduced slide capsule and safe standing clearance. Original tuning retained.
- `scenes/movement_lab_02.tscn` (new): five descending basins, varying shaft
  heights, upper crossings and spurs, low shortcuts, recovery pockets and rejoins.
- `tests/test_lab02.gd` (new): 38 real-physics and replay checks.
- `tests/fixtures/lab01_7_78.json` (new): exact uploaded baseline replay.
- `README.md` and this report: controls, editing, validation and scope.
- Godot-generated `.gd.uid` files accompany new scripts and the new test.

Byte comparisons verified that `scripts/player.gd`, `scenes/player.tscn`,
`scenes/movement_lab.tscn` and `tests/test_movement.gd` remain unchanged.

## Validation results

Engine available: **Godot 4.6.3 stable**, official build `7d41c59c4`.

- Original Lab 01 suite: **20 / 20 pass**.
- Lab 02 suite: **38 / 38 pass**.
- Complete, input-driven Lab 02 traversal: **31.32 seconds**, **zero wall jumps**.
  No teleports occur during this traversal. Reported actual-velocity peak is
  about **1,160 px/s**, including airborne movement and slope transitions.
- Separate input-driven checks climb the first shaft, land on all five upper
  islands and rejoin the main descent, and escape the lower catch pocket with
  two ordinary jumps. Tests place the player at the beginning of each isolated
  scenario; they do not teleport within those branch traversals.
- Crouch checks cover capsule dimensions, foot anchoring, tunnel entry, blocked
  standing/jump expansion, automatic standing on exit and airborne clearance.
- Wall checks cover both normals, buffered contact, recent/expired wall contact,
  launch lock, held input and controlled descent.
- Replay checks include the original 235-sample fixture, interpolation, course
  isolation, additional telemetry, 18,001 samples over ten minutes, crouch pose,
  malformed input rejection, and exploration not overwriting timed ghosts.
- OpenGL runtime rendered screenshots of spawn, shaft, tunnel and overview map;
  these were inspected for readable layout and visible collision geometry.

## Lab 01 replay and slope investigation

Fixture SHA-256:
`d277cc9ef862d249fdb814e3a0a25abd1a1255f3f5afddf8f095d108b9e243b8`

Duration: 7.78333333333331 seconds. Samples: 235. Peak stored velocity while
sliding: 1,046.833374 px/s. Peak stored vector length across the whole replay:
1,178.916729 px/s, during an airborne jump (horizontal plus vertical speed).

Examples of the discontinuities in the original replay:

| Time | Position x | Stored velocity change | Context |
| --- | ---: | --- | --- |
| 2.83 s | 1166 | vx ~705.5 -> 822.3 | 30-degree slope to flat |
| 3.23 s | 1480 | vx ~787.4 -> 578.7 | flat into 45-degree slope |
| 3.57 s | 1710 | vx ~742.5 -> 1046.8 | 45-degree slope to flat |
| 4.57 s | 2720 | (1008.8, 381.7) -> (753.2, -425.3) | airborne landing into uphill section |

The controller keeps a scalar ground speed, redirects it using the current floor
tangent, enables `floor_constant_speed`, and then calls `move_and_slide`.
Horizontal components therefore change at slope joins. Collision response and
floor snapping also affect the velocity reported after movement. The old 30 Hz
replay has no floor normals or actual-velocity field, so it cannot establish the
exact frame-level contribution of each behavior. It is evidence for further
investigation, not a reason to replace the physics model. No wholesale retune
was made. New telemetry records those missing fields for the next playtest.

## Remaining limits

- Godot 4.7 is configured but not installed here; no 4.7 runtime result is claimed.
- The 5–10 minute exploration duration is a design target, not a measured human
  result. All 45 markers and every return spur still need a human exploration
  pass. Automated traversal covers representative branches and the full spine.
- The route shares a five-basin structural pattern; individual shaft heights
  vary. Future playtests can guide more distinctive geometry per basin.
- Ghosts remain positional recordings, not deterministic input resimulation.
- The original slope-transition behavior is retained. A replay's vector speed
  can exceed the 1,050 ground-speed cap during jumps or floor correction.
- Exploration progress lasts for the current attempt. E and R reset it.

## Final local-checkout validation

Applied the listed files to `D:\Godot\REPOs\movement_labs` after verifying it
was still clean. Godot's headless editor import in that checkout completed
without errors. Both suites were rerun there: **20/20 + 38/38 = 58/58 passing**,
and the full timed run measured **31.317 seconds**. The earlier staging editor
safe-save warning did not occur in the final checkout. `git diff --check` passed.
Git only noted its configured CRLF-to-LF normalization on edited text files.

Branch remains `main`, HEAD remains `0dad3ae`, and changes are unstaged and
uncommitted. No commit, push or GitHub update was made.
