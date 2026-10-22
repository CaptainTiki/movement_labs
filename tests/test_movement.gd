extends SceneTree
## Run headlessly with --path <project> --script res://tests/test_movement.gd.
## Writes only its own replay fixture under res://tests/.runtime/.

var lab
var player
var failures: Array[String] = []
var assertions: int = 0
var jump_events: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, description: String) -> void:
	assertions += 1
	if condition:
		print("PASS: ", description)
	else:
		failures.append(description)
		printerr("FAIL: ", description)

func frames(count: int) -> void:
	for i in range(count):
		await physics_frame
	# Resume after the physics callbacks, so observations see the completed step.
	await process_frame

func release_all() -> void:
	for action in ["move_left", "move_right", "jump", "slide", "restart", "toggle_ghost"]:
		Input.action_release(action)

func place(point: Vector2) -> void:
	release_all()
	player.reset_at(point)
	await frames(10)

func jump_height(hold_frames: int) -> float:
	await place(Vector2(250.0, 478.0))
	var start_y: float = player.position.y
	var top: float = start_y
	Input.action_press("jump")
	for i in range(60):
		if i == hold_frames:
			Input.action_release("jump")
		await frames(1)
		top = minf(top, player.position.y)
	release_all()
	return start_y - top

func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://tests/.runtime")
	lab = load("res://scenes/movement_lab.tscn").instantiate()
	lab.replay_path = "res://tests/.runtime/test_run.json"
	root.add_child(lab)
	lab.set_physics_process(false)
	player = lab.get_node("Player")
	player.jumped.connect(func(): jump_events += 1)
	await frames(15)
	check(player.is_on_floor(), "player settles on the spawn platform")
	Input.action_press("move_right")
	await frames(30)
	check(absf(player.velocity.x - player.run_speed) < 1.0, "run reaches configured speed")
	Input.action_release("move_right")
	await frames(15)
	check(absf(player.velocity.x) < 1.0, "release brakes to a stop")
	var short_height := await jump_height(2)
	var full_height := await jump_height(35)
	check(full_height > short_height + 60.0, "held jump rises higher than tap (%.1f vs %.1f px)" % [full_height, short_height])
	check(player.is_on_floor(), "jump returns to the floor")

	# Leave a real ledge and jump two ticks later.
	await place(Vector2(2160.0, 905.8461))
	Input.action_press("move_right")
	var left_floor := false
	for i in range(40):
		await frames(1)
		if not player.is_on_floor():
			left_floor = true
			break
	await frames(2)
	var before_jump: int = jump_events
	Input.action_press("jump")
	await frames(1)
	check(left_floor and jump_events == before_jump + 1 and player.velocity.y < 0.0, "coyote jump works after leaving a ledge")

	# Expired coyote time must not allow an extra air jump.
	await place(Vector2(2250.0, 790.0))
	await frames(12)
	before_jump = jump_events
	Input.action_press("jump")
	await frames(2)
	check(jump_events == before_jump, "no air jump after coyote window expires")

	# Press jump just before a real landing, without pressing again on impact.
	await place(Vector2(300.0, 280.0))
	for i in range(80):
		await frames(1)
		if player.position.y > 430.0 and not player.is_on_floor():
			break
	before_jump = jump_events
	Input.action_press("jump")
	await frames(10)
	check(jump_events == before_jump + 1 and player.velocity.y < 0.0, "buffered jump fires on landing")

	# Compare a descent with ordinary running and with the slide held.
	await place(Vector2(740.0, 478.0))
	Input.action_press("move_right")
	var ordinary_peak: float = 0.0
	for i in range(130):
		await frames(1)
		ordinary_peak = maxf(ordinary_peak, player.get_real_velocity().length())
		if player.position.x > 1400.0:
			break
	await place(Vector2(740.0, 478.0))
	Input.action_press("move_right")
	await frames(12)
	Input.action_press("slide")
	var slide_peak: float = 0.0
	var lost_floor: bool = false
	for i in range(150):
		await frames(1)
		slide_peak = maxf(slide_peak, player.get_real_velocity().length())
		if player.position.x > 810.0 and player.position.x < 1120.0 and not player.is_on_floor():
			lost_floor = true
		if player.position.x > 1400.0:
			break
	check(slide_peak > ordinary_peak + 100.0, "downhill slide gains speed (%.1f vs %.1f px/s)" % [slide_peak, ordinary_peak])
	check(not lost_floor, "slide remains attached to the 30-degree slope")
	var launch_x_speed: float = player.velocity.x
	Input.action_press("jump")
	await frames(1)
	check(player.velocity.x >= launch_x_speed - 15.0 and player.velocity.y < 0.0, "slide jump carries horizontal momentum")

	# Build a fast entry and observe it spend speed on an uphill slide.
	await place(Vector2(2540.0, 905.8461))
	player.ground_speed = 700.0
	Input.action_press("slide")
	await frames(30)
	check(player.position.x > 2600.0 and absf(player.ground_speed) < 650.0, "uphill sliding spends momentum")

	# Complete the entire real course using inputs; no teleport during traversal.
	release_all()
	lab.reset_run()
	lab.set_physics_process(true)
	await frames(10)
	Input.action_press("move_right")
	var first_gap_jumped := false
	var second_gap_jumped := false
	var route_trace: Array = []
	for i in range(1800):
		var x: float = player.position.x
		if i % 20 == 0:
			route_trace.append([snappedf(x, 1.0), snappedf(player.position.y, 1.0), snappedf(player.velocity.x, 1.0), snappedf(player.velocity.y, 1.0)])
		if x > 700.0 and x < 2400.0:
			Input.action_press("slide")
		else:
			Input.action_release("slide")
		if not first_gap_jumped and x > 2070.0:
			Input.action_press("jump")
			first_gap_jumped = true
		if first_gap_jumped and x > 2400.0 and not second_gap_jumped:
			Input.action_release("jump")
		if not second_gap_jumped and x > 3260.0:
			Input.action_press("jump")
			second_gap_jumped = true
		if second_gap_jumped and x > 3540.0:
			Input.action_release("jump")
		await frames(1)
		if lab.finished:
			break
		if first_gap_jumped and player.position.x < 200.0:
			break
	check(lab.finished, "full course is finishable with run, slide, and two jumps")
	if not lab.finished:
		print("ROUTE TRACE [x,y,vx,vy]: ", route_trace)
	check(FileAccess.file_exists(lab.replay_path), "completed run saves telemetry and ghost")
	check(lab.previous_samples.size() > 20, "completed run contains replay samples")
	var saved_time: float = lab.previous_time
	lab.previous_samples.clear()
	lab.load_previous_run()
	check(not lab.previous_samples.is_empty() and is_equal_approx(lab.previous_time, saved_time), "saved ghost reloads with its timing intact")
	release_all()
	lab.reset_run()
	await frames(2)
	check(lab.ghost.visible and lab.elapsed == 0.0 and player.control_enabled, "restart restores controls and displays prior ghost")
	Input.action_press("toggle_ghost")
	await frames(1)
	check(not lab.ghost.visible, "ghost can be hidden")
	release_all()
	player.position = Vector2(2300.0, 1300.0)
	lab.running = true
	await frames(2)
	check(player.position.x < 200.0 and lab.elapsed == 0.0, "falling out resets the run")
	# A corrupt save must be ignored without aborting the game.
	var file := FileAccess.open(lab.replay_path, FileAccess.WRITE)
	file.store_string('{"version":1,"course":"movement_lab_01","samples":[null,null]}')
	file.close()
	lab.previous_samples.clear()
	lab.load_previous_run()
	check(lab.previous_samples.is_empty(), "invalid replay data is rejected")
	DirAccess.remove_absolute(lab.replay_path)
	print("RESULT: %d checks, %d failures" % [assertions, failures.size()])
	quit(0 if failures.is_empty() else 1)
