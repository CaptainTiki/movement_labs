extends SceneTree

var lab
var player
var failures: Array[String] = []
var assertions: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, description: String) -> void:
	assertions += 1
	print(("PASS: " if ok else "FAIL: ") + description)
	if not ok:
		failures.append(description)

func frames(count: int) -> void:
	for i in range(count):
		await physics_frame
	await process_frame

func release_all() -> void:
	for action in ["move_left", "move_right", "jump", "slide"]:
		Input.action_release(action)

func place(point: Vector2, settle: int = 12) -> void:
	release_all()
	player.reset_at(point)
	await frames(settle)

func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://tests/.runtime")
	lab = load("res://scenes/movement_lab_02.tscn").instantiate()
	lab.replay_path = "res://tests/.runtime/lab02.json"
	root.add_child(lab)
	lab.set_physics_process(false)
	player = lab.player
	await frames(15)
	check(player.is_on_floor(), "Lab 02 spawn is grounded")
	var feet: float = player.position.y + 20.0
	Input.action_press("slide")
	await frames(1)
	check(player.crouched and player.collider.shape.height == 22.0, "slide physically reduces capsule from 40 to 22 px")
	check(absf(player.position.y + player.collider.position.y + 11.0 - feet) < 0.2, "crouching keeps feet anchored")
	Input.action_release("slide")
	await frames(2)
	check(not player.crouched and player.collider.shape.height == 40.0, "clear space restores standing shape")

	# Enter the real 28 px tunnel, release slide and request jump under the roof.
	await place(Vector2(2380, 1078))
	Input.action_press("move_right")
	Input.action_press("slide")
	for i in range(100):
		await frames(1)
		if player.position.x > 2530:
			break
	check(player.position.x > 2530 and player.crouched, "reduced collider passes through the actual low shortcut")
	Input.action_release("slide")
	Input.action_release("move_right")
	Input.action_press("jump")
	await frames(3)
	check(player.crouched and not player.can_stand() and player.velocity.y >= -1.0, "blocked uncrouch and jump cannot expand into the roof")
	Input.action_release("jump")
	Input.action_press("move_right")
	await frames(100)
	check(player.position.x > 2750 and not player.crouched, "exiting tunnel automatically restores standing")

	# Both wall directions, buffered contact, wall coyote time and expiration.
	for direction in [-1.0, 1.0]:
		await place(Vector2(710, 0), 1)
		var action := "move_left" if direction < 0 else "move_right"
		Input.action_press(action)
		for i in range(60):
			await frames(1)
			if player.is_on_wall():
				break
		await frames(1)
		check(player.wall_left > 0, "wall contact is available on side %s" % direction)
		Input.action_press("jump")
		await frames(1)
		check(player.velocity.x * direction < -300 and player.velocity.y < -500, "wall jump pushes away and up on side %s" % direction)
		var count: int = player.wall_jump_count
		await frames(4)
		check(player.velocity.x * direction < 0 and player.wall_jump_count == count, "held inward input cannot cancel launch or repeat jump")

	await place(Vector2(742, 40), 1)
	Input.action_press("move_right")
	player.velocity.x = 250
	Input.action_press("jump")
	await frames(7)
	check(player.wall_jump_count == 1 and player.velocity.y < 0, "jump buffered before wall contact launches on contact")
	await place(Vector2(755, 80), 1)
	Input.action_press("move_right")
	await frames(5)
	Input.action_release("move_right")
	Input.action_press("move_left")
	await frames(3)
	Input.action_press("jump")
	await frames(1)
	check(player.wall_jump_count == 1, "wall coyote jump works shortly after peeling away")
	await place(Vector2(710, 0), 1)
	await frames(15)
	Input.action_press("jump")
	await frames(2)
	check(player.wall_jump_count == 0 and player.velocity.y > 0, "no wall jump without a recent wall contact")
	await place(Vector2(755, 80), 1)
	Input.action_press("move_right")
	await frames(12)
	check(player.is_on_wall() and player.velocity.y <= player.wall_fall_speed + 1, "holding into a wall caps descent for forgiving timing")
	Input.action_release("move_right")
	Input.action_press("move_left")
	player.velocity.x = -340
	await frames(11)
	Input.action_press("jump")
	await frames(1)
	check(player.wall_jump_count == 0 and player.wall_left == 0, "wall coyote memory expires after leaving an actual wall")

	# Release crouch while airborne beneath the same low roof.
	await place(Vector2(2590, 1078), 1)
	Input.action_press("slide")
	await frames(2)
	player.position.y -= 3
	player.velocity.y = -30
	Input.action_release("slide")
	await frames(1)
	check(player.crouched and not player.can_stand(), "airborne uncrouch also respects ceiling clearance")

	# A real ascent, from the floor through the first shaft to the high launch.
	await place(Vector2(710, 478))
	Input.action_press("jump")
	Input.action_press("move_left")
	var shaft_top := false
	for i in range(700):
		await frames(1)
		if player.is_on_wall() and player.wall_lock_left <= 0:
			Input.action_release("jump")
			await frames(1)
			Input.action_press("jump")
			if player.get_wall_normal().x > 0:
				Input.action_release("move_left")
				Input.action_press("move_right")
			else:
				Input.action_release("move_right")
				Input.action_press("move_left")
		if player.position.y < -85:
			shaft_top = true
			break
	check(shaft_top, "optional shaft can be climbed from its floor with repeated wall jumps")
	# Follow the upper crossing back to the main line, jumping only level gaps.
	await place(Vector2(930, -82))
	Input.action_press("move_right")
	var upper_jumps := [2060.0, 2530.0, 3000.0]
	var upper_index := 0
	var upper_landed: Dictionary = {}
	var upper_trace: Array = []
	for i in range(1200):
		if i % 12 == 0 and player.position.x > 2000 and player.position.x < 3400:
			upper_trace.append([snappedf(player.position.x, 1), snappedf(player.position.y, 1), player.is_on_floor()])
		if player.is_on_floor():
			Input.action_release("jump")
			for k in range(5):
				if player.position.x >= 2220 + k * 235 and player.position.x <= 2380 + k * 235 and player.position.y < 850:
					upper_landed[k] = true
			if upper_index < upper_jumps.size() and player.position.x >= upper_jumps[upper_index]:
				Input.action_press("jump")
				upper_index += 1
		await frames(1)
		if player.position.x > 4500:
			break
	check(player.position.x > 4500 and upper_landed.size() == 5, "upper route visits all five islands and rejoins the main descent")
	if upper_landed.size() != 5:
		print("UPPER LANDED: ", upper_landed, " position: ", player.position, " trace: ", upper_trace)

	# Recover from the catch pocket using two ordinary jumps through the gap.
	await place(Vector2(3010, 1278))
	Input.action_press("move_right")
	Input.action_press("jump")
	var recovered_step := false
	for i in range(150):
		if player.position.x > 3090 and not recovered_step:
			Input.action_release("move_right")
		if player.is_on_floor() and player.position.y < 1200:
			recovered_step = true
			Input.action_release("jump")
			await frames(1)
			Input.action_press("jump")
			Input.action_press("move_right")
		await frames(1)
		if recovered_step and player.is_on_floor() and player.position.x > 3180:
			break
	check(recovered_step and player.position.x > 3180 and player.position.y < 1100, "lower recovery pocket rejoins through two reachable hops")

	# Preserve the uploaded position replay and reject it for the new course.
	var fixture := "res://tests/fixtures/lab01_7_78.json"
	var old = load("res://scenes/movement_lab.tscn").instantiate()
	old.replay_path = fixture
	root.add_child(old)
	old.set_physics_process(false)
	old.player.set_physics_process(false)
	check(old.previous_samples.size() == 235 and absf(old.previous_time - 7.7833333333) < 0.0001, "Lab 01 loads the unmodified 7.78-second / 235-sample baseline")
	old.elapsed = 3.57
	old.update_ghost()
	check(old.ghost.visible and old.ghost.position.x > 1700 and old.ghost.position.x < 1720, "baseline ghost interpolation still follows its original positions")
	old.queue_free()
	lab.replay_path = fixture
	lab.load_previous_run()
	check(lab.previous_samples.is_empty(), "Lab 02 rejects the Lab 01 course identifier")
	lab.replay_path = "res://tests/.runtime/lab02.json"

	# One uninterrupted timed route using only inputs: wall jumping is optional.
	release_all()
	lab.reset_run()
	lab.set_physics_process(true)
	await frames(10)
	Input.action_press("move_right")
	var gaps: Dictionary = {}
	var trace: Array = []
	for i in range(7200):
		var x: float = player.position.x
		var basin := int(x / 5600.0)
		var local_x := fposmod(x, 5600.0)
		if x > 700:
			Input.action_press("slide")
		if local_x > 2860 and local_x < 3000 and not gaps.has(basin):
			Input.action_press("jump")
			gaps[basin] = true
		if local_x > 3300:
			Input.action_release("jump")
		await frames(1)
		if i % 120 == 0:
			trace.append([snappedf(player.position.x, 1), snappedf(player.position.y, 1)])
		if lab.finished or (gaps.size() > 0 and player.position.x < 200):
			break
	check(lab.finished, "complete Lab 02 speed route is traversable without teleporting")
	print("ROUTE: %.3f seconds, %.1f peak px/s, %d wall jumps" % [lab.elapsed, lab.peak_speed, player.wall_jump_count])
	if not lab.finished:
		print("TRACE: ", trace)
	check(lab.finished and lab.elapsed >= 30 and lab.elapsed <= 60, "measured scripted speedrun falls in the 30–60 second target")
	check(player.wall_jump_count == 0, "fast route does not require wall jumping")
	check(lab.samples.size() > 900 and lab.samples[-1].has("real_vx") and lab.samples[-1].has("floor_ny") and lab.samples[-1].has("crouched"), "long run records actual velocity, floor normal and physical posture")
	var duration: float = lab.elapsed
	lab.load_previous_run()
	check(absf(lab.previous_time - duration) < 0.001 and not lab.previous_samples.is_empty(), "Lab 02 saves and reloads its own long ghost")
	release_all()
	lab.reset_run()
	await frames(2)
	check(player.control_enabled and not player.crouched and player.wall_left == 0, "restart clears posture and wall forgiveness state")
	lab.exploring = true
	lab.reset_run()
	var saved_text := FileAccess.get_file_as_string(lab.replay_path)
	player.position = Vector2(28610, 5230)
	lab.running = true
	await frames(2)
	check(not lab.finished, "exploration can cross finish without ending")
	player.position = Vector2(200, 2100)
	await frames(2)
	check(player.position.distance_to(lab.recovery_point) < 50, "exploration falls recover locally")
	check(FileAccess.get_file_as_string(lab.replay_path) == saved_text, "exploration never overwrites timed ghost")
	check(lab.max_run_seconds >= 600 and lab.get_node("Discoveries").get_child_count() >= 35, "long exploration budget and optional discovery targets exist")
	# The loader must accept a full ten-minute ghost, beyond the old 6,000 limit.
	lab.exploring = false
	var long_samples: Array = []
	for i in range(18001):
		long_samples.append({"t": i / 30.0, "x": 140.0 + i, "y": 478.0, "crouched": i % 2 == 0})
	var file := FileAccess.open(lab.replay_path, FileAccess.WRITE)
	file.store_string(JSON.stringify({"version": 1, "course": lab.course_id, "duration": 600, "samples": long_samples}))
	file.close()
	lab.load_previous_run()
	check(lab.previous_time == 600 and lab.previous_samples.size() == 18001, "ten-minute / 18,001-sample ghost reloads")
	lab.elapsed = 500.0
	lab.update_ghost()
	check(lab.ghost_index == 15000 and lab.ghost.polygon[0].y == -2, "long ghost seeks correctly and shows recorded crouch")
	file = FileAccess.open(lab.replay_path, FileAccess.WRITE)
	file.store_string('{"version":1,"course":"movement_lab_02_v1","samples":[{"t":-1,"x":0,"y":0},{"t":1,"x":1,"y":1}]}')
	file.close()
	lab.load_previous_run()
	check(lab.previous_samples.is_empty() and lab.ghost_index == 0, "invalid replay clears previous ghost and playback cursor")
	DirAccess.remove_absolute(lab.replay_path)
	print("RESULT: %d checks, %d failures" % [assertions, failures.size()])
	quit(0 if failures.is_empty() else 1)
