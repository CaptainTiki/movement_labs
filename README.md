# movement_labs

A small, editable momentum platformer prototype. Run the project (F6 for the
movement_lab scene, or F5 for the project) to play the first movement study.

## Controls

| Action | Keyboard |
| --- | --- |
| Move | A / D or Left / Right |
| Jump | Space, W, or Up; tap for a short hop, hold for height |
| Slide | Hold S, Down, or Shift |
| Restart course | R |
| Show/hide previous-run ghost | G |

Move to start the timer. Follow the course to the amber finish gate. Falling
into a gap resets immediately. A completed run becomes the ghost for the next
attempt. The current run resets after three minutes to keep recording bounded.

## First course

- Flat starting area, a 30-degree descent, a 45-degree descent, two gaps,
  a 30-degree climb, and a finish platform.
- Acceleration and braking, air steering, variable jump height, 140 ms coyote
  time, and a 160 ms jump buffer.
- Downhill slides gain speed; uphill slides spend it. Jumping preserves lateral
  momentum. Slide is a movement mode with a visual pose, not a smaller collision
  shape: this course deliberately has no low tunnels.
- Camera follow, speed trail, three background depth layers, sparse motes,
  speed/state/timer readouts, peak speed, and jump count.
- Position-based ghost replay at 30 samples/second, with input, velocity, and
  movement-state telemetry. This is a visual recording, not deterministic input
  resimulation. Only the most recent completed run is saved.

## Editing

`scenes/movement_lab.tscn` is the main scene. Its terrain consists of ordinary
StaticBody2D nodes with editable CollisionPolygon2D, Polygon2D, and Line2D
children. When changing terrain, update the collision, fill, and visible edge
together. Spawn and Finish are markers. All course labels are scene nodes.

`scenes/player.tscn` contains the CharacterBody2D controller. Select Player in the
Inspector to tune running, jump forgiveness, and sliding. Its script is
`scripts/player.gd`; the course, timer, and recording are in `scripts/lab.gd`.

Input actions are stored in Project Settings > Input Map. The project remains
marked 4.7 as originally configured. The available local engine used for initial
validation was **Godot 4.6.3**, so no 4.7 runtime validation is claimed.

Ghost data is saved to `user://movement_lab_last_run.json`. Use Godot's
**Project > Open User Data Folder** to inspect it. The schema includes course
and format identifiers; change the course identifier in `lab.gd` when changing
the layout so ghosts from old layouts are not loaded.

## Validation

Run the behavioral checks with your Godot executable:

```text
godot --headless --path <project-folder> --log-file <absolute-log-path> --script res://tests/test_movement.gd
```

The checks exercise real physics, jump forgiveness, momentum on slopes, a full
course traversal, recording/reload, ghost toggle, and fall recovery. Their
temporary replay file lives in `tests/.runtime/`, never the player's save file.

Next playtest: tune acceleration and braking first, then jump height and air
steering, then slide friction. Collectibles, map exploration, controller bindings,
and additional moves are deferred until the basic movement feels right.
