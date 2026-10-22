extends "res://scripts/lab.gd"
## Exploration never writes over a timed ghost. R resets the current mode.

var exploring: bool = false
var visited: Dictionary = {}
var map_open: bool = false
var recovery_point := Vector2(140, 478)
var map_lines: Array[PackedVector2Array] = []

func _ready() -> void:
	super._ready()
	$HUD/Map.draw.connect(draw_map)
	for body in $Terrain.get_children():
		var edge := body.get_node_or_null("Edge") as Line2D
		if edge:
			map_lines.append(edge.points)

func _physics_process(delta: float) -> void:
	if exploring and player.position.y > recovery_floor():
		player.reset_at(recovery_point)
		camera.position = player.position + Vector2(150, -80)
		camera.reset_smoothing()
	super._physics_process(delta)
	if exploring:
		ghost.visible = false
	for stop in $RestStops.get_children():
		if player.position.distance_to(stop.position) < 200.0:
			recovery_point = stop.position
	for marker in $Discoveries.get_children():
		if player.position.distance_to(marker.position) < 48.0:
			visited[marker.name] = true
	$HUD/Exploration.text = "%s  /  FOUND %d / %d%s" % ["EXPLORE" if exploring else "TIMED RUN", visited.size(), $Discoveries.get_child_count(), "  /  ALL FOUND" if visited.size() == $Discoveries.get_child_count() else ""]
	if exploring:
		message.text = "EXPLORE  /  E: TIMED RUN  /  R: START OVER"
	$HUD/Map.queue_redraw()
	queue_redraw()

func recovery_floor() -> float:
	# Recover near the current basin, not thousands of pixels below the first gap.
	var basin := clampi(int(player.position.x / 5600.0), 0, 4)
	return 500.0 + basin * 950.0 + 1300.0

func record_sample() -> void:
	if not exploring:
		super.record_sample()

func reset_run() -> void:
	super.reset_run()
	visited.clear()
	recovery_point = $Spawn.position

func _unhandled_key_input(event: InputEvent) -> void:
	super._unhandled_key_input(event)
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_E:
			exploring = not exploring
			reset_run()
		elif event.physical_keycode == KEY_M:
			map_open = not map_open

func _draw() -> void:
	for marker in $Discoveries.get_children():
		var color := Color("8ff0d1") if visited.has(marker.name) else Color("efb667")
		draw_arc(marker.position, 13, 0, TAU, 20, color, 2.0)
		if visited.has(marker.name):
			draw_circle(marker.position, 4, color)

func draw_map() -> void:
	if not map_open:
		return
	var canvas: Node2D = $HUD/Map
	var size := get_viewport_rect().size
	var box := Rect2(24, 125, size.x - 48, size.y - 150)
	canvas.draw_rect(box, Color(0.025, 0.06, 0.08, 0.96))
	var scale_factor: float = minf((box.size.x - 40.0) / 29800.0, (box.size.y - 40.0) / 6500.0)
	var origin := box.position + Vector2(28, 45)
	for line in map_lines:
		var points := PackedVector2Array()
		for point in line:
			points.append(origin + (point + Vector2(200, 700)) * scale_factor)
		canvas.draw_polyline(points, Color("639d99"), 2.0)
	for marker in $Discoveries.get_children():
		canvas.draw_circle(origin + (marker.position + Vector2(200, 700)) * scale_factor, 3, Color("8ff0d1") if visited.has(marker.name) else Color("efb667"))
	canvas.draw_circle(origin + (player.position + Vector2(200, 700)) * scale_factor, 5, Color.WHITE)
	canvas.draw_string(ThemeDB.fallback_font, box.position + Vector2(16, 24), "FIVE BASINS   /   WHITE: YOU   /   AMBER: UNEXPLORED   /   M: CLOSE", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color.WHITE)

func finish_reached() -> bool:
	return not exploring and Rect2($Finish.position + Vector2(-10, -160), Vector2(150, 180)).has_point(player.position)

func run_failed() -> bool:
	return not exploring and (player.position.y > recovery_floor() or elapsed >= max_run_seconds)
