# Lab 02: Reservoir redesign and validation

## Source and local status

Inspected the user's new local commit `8e461a1` (`Longer Route / Wall Jump`) on
`main` in `D:\Godot\REPOs\movement_labs`. Its course and controllers matched
the preceding delivered build. This revision changes the course structure in
response to feedback that it was too linear and repetitive. No GitHub access,
commit, push or pull request was used.

## What changed

The five repeated basins are replaced by one layered reservoir. The low chute,
middle gallery and upper canopy share space and reconnect through a central
atrium, a west return shaft, a mezzanine ascent and the east bank. Routes can be
mixed and the middle gallery can be traversed in reverse. Discovery rings are
placed across 31 ledges and junctions, rather than repeating nine markers in
every basin. The map now draws route colors, shaft outlines and landmark labels.

Changed files in this revision:

- `scenes/movement_lab_02.tscn`: new authored terrain, labels, rest stops, rings,
  finish position, and `movement_lab_02_v2` identifier/save path.
- `scripts/lab_02.gd`: world-wide fall boundary instead of the old basin formula;
  smaller, colored and labeled overview map with visible shaft connections.
- `tests/test_lab02.gd`: new three-route traversals, elevation checks, reverse
  gallery traversal, inter-route shaft climbs, and old Lab 02 ghost rejection.
- `README.md`: current route descriptions, timings, controls and replay ID.
- `docs/LAB02_VALIDATION.md`: this report.

Both player controllers, Lab 01's scene/player/test, shared `scripts/lab.gd`,
project configuration and the uploaded baseline replay are unchanged by this
revision. There is no physics retune.

## Validation

Available engine: **Godot 4.6.3 stable**, official build `7d41c59c4`.

- Lab 01 regression suite: **20 checks**.
- Updated Lab 02 suite: **45 checks passed** in the staged build.
- Complete reservoir line: **36.05 s**, no wall jumps; actual-velocity peak about
  **1,128 px/s**, including air and slope transitions.
- Complete canopy line: **49.78 s**, including the west shaft ascent from spawn.
- Complete gallery line: **56.97 s**, no slide or wall jump required.
- All three full runs use only player inputs, without teleporting. Telemetry
  checks that each actually uses its intended elevation at x=6,500.
- Separate physics checks climb from the reservoir through the central gallery
  crossing to the canopy; climb the west return shaft from chute to gallery;
  and traverse the gallery back to the start through both western gaps.
- Existing real collider, wall forgiveness, buffered jump, ceiling clearance,
  long ghost, malformed replay and exploration recovery checks remain.
- Both original Lab 01 ghosts and the previous `movement_lab_02_v1` ghosts are
  rejected by the new course. Their files are not changed or deleted.
- OpenGL captures verify the scene and overview map render with the new layout.

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

- Godot 4.7 remains configured but is not installed here; no 4.7 validation is
  claimed. Use the same two commands in README to check with that engine.
- The automated runs establish reachable routes and useful timing baselines;
  they do not establish how enjoyable, readable or expressive the course feels.
- The 5–10 minute exploration target is not yet a measured human result. A human
  pass through all 31 rings, mezzanine turns and smaller return ledges is still
  needed. Those details may need further adjustment after playtesting.
- Ghosts are positional recordings, not deterministic input resimulation.
- Exploration discoveries reset with E/R and are not persisted between sessions.

## Final checkout verification

The revision was applied to the local main checkout at 8e461a1 after verifying
that it was clean and that the preserved controllers, Lab 01 files and fixture
matched byte-for-byte. Godot editor import and both suites completed in the
checkout: 20/20 and 45/45 passing (65 total). The diff whitespace check passed.
Changes remain unstaged and uncommitted. No commit or push was performed.

