extends CharacterBody2D
## Momentum is measured along the floor; slopes redirect it without silently
## clamping it back to run speed. Jumping keeps the current horizontal velocity.

signal jumped

@export_category("Run")
@export var run_speed: float = 340.0
@export var acceleration: float = 1500.0
@export var braking: float = 2100.0
@export var air_acceleration: float = 700.0
@export_category("Jump forgiveness")
@export var jump_speed: float = 610.0
@export var gravity: float = 1750.0
@export var coyote_time: float = 0.14
@export var jump_buffer_time: float = 0.16
@export_category("Slide")
@export var slide_gravity: float = 1450.0
@export var slide_friction: float = 95.0
@export var maximum_speed: float = 1050.0

var ground_speed: float = 0.0
var coyote_left: float = 0.0
var buffer_left: float = 0.0
var sliding: bool = false
var was_grounded: bool = false
var facing: float = 1.0
var jump_cut_applied: bool = false
var control_enabled: bool = true
var trail: Array[Vector2] = []
var trail_clock: float = 0.0
var state_name: String = "READY"

func _physics_process(delta: float) -> void:
	if not control_enabled:
		return
	var axis := Input.get_axis("move_left", "move_right")
	var grounded := is_on_floor()
	buffer_left = maxf(0.0, buffer_left - delta)
	if Input.is_action_just_pressed("jump"):
		buffer_left = jump_buffer_time
	if grounded:
		coyote_left = coyote_time
	else:
		coyote_left = maxf(0.0, coyote_left - delta)
	sliding = Input.is_action_pressed("slide") and grounded
	if axis != 0.0:
		facing = signf(axis)
	if grounded:
		var normal := get_floor_normal()
		var tangent := Vector2(-normal.y, normal.x)
		if not was_grounded:
			ground_speed = velocity.dot(tangent)
		if sliding:
			ground_speed += slide_gravity * tangent.y * delta
			ground_speed = move_toward(ground_speed, 0.0, slide_friction * delta)
			# Input can push a slow slide or brake it, but cannot manufacture speed.
			if axis != 0.0 and (absf(ground_speed) < run_speed * 0.55 or signf(axis) != signf(ground_speed)):
				ground_speed = move_toward(ground_speed, axis * run_speed * 0.55, acceleration * 0.45 * delta)
		else:
			ground_speed = steer(ground_speed, axis, acceleration, braking, delta)
		ground_speed = clampf(ground_speed, -maximum_speed, maximum_speed)
		velocity = tangent * ground_speed
	else:
		velocity.x = steer(velocity.x, axis, air_acceleration, 0.0, delta)
		velocity.y = minf(velocity.y + gravity * delta, 1200.0)
	var did_jump := false
	if buffer_left > 0.0 and coyote_left > 0.0:
		velocity.y = -jump_speed + minf(velocity.y, 0.0) * 0.30
		buffer_left = 0.0
		coyote_left = 0.0
		jump_cut_applied = false
		sliding = false
		did_jump = true
		jumped.emit()
	if velocity.y < 0.0 and not Input.is_action_pressed("jump") and not jump_cut_applied:
		velocity.y *= 0.48
		jump_cut_applied = true
	# Floor snapping is deliberately disabled for a jump's launch frame.
	floor_snap_length = 0.0 if did_jump else 14.0
	move_and_slide()
	if is_on_wall():
		ground_speed = velocity.x
	was_grounded = grounded and not did_jump
	state_name = "SLIDE" if sliding else ("RUN" if absf(velocity.x) > 10.0 else "IDLE")
	if not is_on_floor():
		state_name = "RISE" if velocity.y < 0.0 else "FALL"
	trail_clock += delta
	if trail_clock >= 0.035:
		trail_clock = 0.0
		trail.push_front(global_position)
		if trail.size() > 12:
			trail.pop_back()
	queue_redraw()

func steer(speed: float, axis: float, push: float, drag: float, delta: float) -> float:
	if axis == 0.0:
		return move_toward(speed, 0.0, drag * delta)
	if signf(axis) == signf(speed) and absf(speed) > run_speed:
		return move_toward(speed, axis * run_speed, drag * 0.18 * delta)
	var rate := push if signf(axis) == signf(speed) else maxf(push, drag)
	return move_toward(speed, axis * run_speed, rate * delta)

func reset_at(point: Vector2) -> void:
	global_position = point
	velocity = Vector2.ZERO
	ground_speed = 0.0
	coyote_left = 0.0
	buffer_left = 0.0
	was_grounded = false
	sliding = false
	jump_cut_applied = false
	control_enabled = true
	trail.clear()
	queue_redraw()

func _draw() -> void:
	for i in range(trail.size() - 1, -1, -1):
		var alpha := (1.0 - float(i) / 12.0) * 0.19
		draw_circle(to_local(trail[i]), 8.0, Color(0.37, 0.95, 0.83, alpha))
	var body := Rect2(-12.0, -20.0, 24.0, 40.0)
	if sliding:
		body = Rect2(-19.0, -2.0, 38.0, 22.0)
	draw_style_box(body_style(), body)
	var eye_y := 5.0 if sliding else -8.0
	draw_line(Vector2(facing * 2.0, eye_y), Vector2(facing * 9.0, eye_y), Color("102c32"), 4.0)

func body_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("8ff0d1")
	style.set_corner_radius_all(7)
	return style
