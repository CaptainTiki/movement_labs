extends Node2D

const LAST_RUN_PATH := "user://movement_lab_last_run.json"
const MAX_RUN_SECONDS := 180.0
@export var course_id: String = "movement_lab_01"
@export var max_run_seconds: float = MAX_RUN_SECONDS
@export var fall_y: float = 1250.0
@export var finish_y: float = 760.0
@export var replay_path: String = LAST_RUN_PATH

@onready var player = $Player
@onready var camera: Camera2D = $Camera2D
@onready var readout: Label = $HUD/Readout
@onready var message: Label = $HUD/Message
@onready var background = $Background/Backdrop
@onready var ghost: Polygon2D = $Ghost

var elapsed: float = 0.0
var running: bool = false
var finished: bool = false
var peak_speed: float = 0.0
var jump_count: int = 0
var samples: Array = []
var previous_samples: Array = []
var previous_time: float = 0.0
var ghost_visible: bool = true
var ghost_index: int = 0
var record_clock: float = 0.0

func _ready() -> void:
	player.jumped.connect(func(): jump_count += 1)
	load_previous_run()
	reset_run()

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("restart"):
		reset_run()
	if Input.is_action_just_pressed("toggle_ghost"):
		ghost_visible = not ghost_visible
	if not running and not finished and (Input.get_axis("move_left", "move_right") != 0.0 or Input.is_action_just_pressed("jump")):
		running = true
	if running:
		elapsed += delta
		peak_speed = maxf(peak_speed, player.get_real_velocity().length())
		record_clock += delta
		if record_clock >= 1.0 / 30.0:
			record_clock -= 1.0 / 30.0
			record_sample()
		if finish_reached():
			complete_run()
		elif run_failed():
			reset_run()
	update_ghost()
	var target: Vector2 = player.position + Vector2(150.0, -80.0)
	target.x = maxf(640.0, target.x)
	camera.position = camera.position.lerp(target, 1.0 - exp(-5.0 * delta))
	background.camera_position = camera.position
	readout.text = "%03d  px/s     %s\n%05.2f s     PEAK %03d     JUMPS %d" % [roundi(player.get_real_velocity().length()), player.state_name, elapsed, roundi(peak_speed), jump_count]
	if not finished:
		var ghost_status := "GHOST ON" if ghost_visible else "GHOST OFF"
		if previous_samples.is_empty():
			ghost_status = "FINISH A RUN TO SET YOUR GHOST"
		message.text = ("MOVE TO START   /   " if not running else "") + ghost_status

func reset_run() -> void:
	player.reset_at($Spawn.position)
	elapsed = 0.0
	running = false
	finished = false
	peak_speed = 0.0
	jump_count = 0
	record_clock = 0.0
	ghost_index = 0
	samples.clear()
	record_sample()
	camera.position = Vector2(640.0, 420.0)
	camera.reset_smoothing()

func record_sample() -> void:
	samples.append({"t": elapsed, "x": player.position.x, "y": player.position.y,
		"vx": player.velocity.x, "vy": player.velocity.y, "state": player.state_name,
		"axis": Input.get_axis("move_left", "move_right"), "jump": Input.is_action_pressed("jump"),
		"slide": Input.is_action_pressed("slide")})
	if player.has_method("ground_telemetry"):
		samples[-1].merge(player.ground_telemetry())

func complete_run() -> void:
	running = false
	finished = true
	record_sample()
	player.control_enabled = false
	player.velocity = Vector2.ZERO
	var comparison := ""
	if previous_time > 0.0:
		comparison = "  /  %+.2f s" % (elapsed - previous_time)
	message.text = "FINISH  %.2f s%s  /  R: AGAIN" % [elapsed, comparison]
	previous_samples = samples.duplicate(true)
	previous_time = elapsed
	var file := FileAccess.open(replay_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"version": 1, "course": course_id, "duration": elapsed, "samples": samples}))
	else:
		message.text += "   /   GHOST SAVE FAILED"

func load_previous_run() -> void:
	previous_samples = []
	previous_time = 0.0
	ghost_index = 0
	if not FileAccess.file_exists(replay_path):
		return
	var file := FileAccess.open(replay_path, FileAccess.READ)
	if not file or file.get_length() > 16000000:
		return
	var data = JSON.parse_string(file.get_as_text())
	if not data is Dictionary or data.get("version") != 1 or data.get("course") != course_id:
		return
	var saved = data.get("samples")
	if not saved is Array or saved.size() < 2 or saved.size() > ceili(max_run_seconds * 30.0) + 3:
		return
	var last_t: float = -1.0
	for sample in saved:
		if not sample is Dictionary:
			return
		for key in ["t", "x", "y"]:
			if not sample.get(key) is float and not sample.get(key) is int:
				return
			if not is_finite(float(sample[key])):
				return
		if float(sample.t) < 0.0 or float(sample.t) < last_t or float(sample.t) > max_run_seconds + 1.0:
			return
		last_t = float(sample.t)
	previous_samples = saved
	previous_time = last_t

func update_ghost() -> void:
	ghost.visible = ghost_visible and not previous_samples.is_empty() and not finished
	if not ghost.visible:
		return
	while ghost_index + 1 < previous_samples.size() and float(previous_samples[ghost_index + 1].t) <= elapsed:
		ghost_index += 1
	var a: Dictionary = previous_samples[ghost_index]
	var b: Dictionary = previous_samples[mini(ghost_index + 1, previous_samples.size() - 1)]
	var weight := clampf((elapsed - float(a.t)) / maxf(float(b.t) - float(a.t), 0.001), 0.0, 1.0)
	if a.has("crouched") and a.crouched is bool:
		ghost.polygon = PackedVector2Array([Vector2(-11, -2), Vector2(11, -2), Vector2(11, 20), Vector2(-11, 20)]) if a.crouched else PackedVector2Array([Vector2(-12, -20), Vector2(12, -20), Vector2(12, 20), Vector2(-12, 20)])
	ghost.position = Vector2(float(a.x), float(a.y)).lerp(Vector2(float(b.x), float(b.y)), weight)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_1:
			get_tree().change_scene_to_file("res://scenes/movement_lab.tscn")
		elif event.physical_keycode == KEY_2:
			get_tree().change_scene_to_file("res://scenes/movement_lab_02.tscn")

func finish_reached() -> bool:
	return player.position.x >= $Finish.position.x and player.position.y < finish_y

func run_failed() -> bool:
	return player.position.y > fall_y or elapsed >= max_run_seconds
