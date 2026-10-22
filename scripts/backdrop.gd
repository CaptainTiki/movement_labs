extends Node2D

var camera_position := Vector2.ZERO
var clock: float = 0.0

func _process(delta: float) -> void:
	clock += delta
	queue_redraw()

func _draw() -> void:
	var size := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, size), Color("0b1822"))
	# Screen-space silhouettes scroll at separate fractions of camera travel.
	for layer in range(3):
		var step := 170.0 + float(layer) * 80.0
		var offset := fposmod(camera_position.x * (0.08 + layer * 0.06), step)
		var color := Color("142630") if layer == 0 else Color("19333c")
		if layer == 2:
			color = Color("1c3b43")
		for i in range(-1, int(size.x / step) + 2):
			var x := i * step - offset
			var top := size.y * (0.27 + layer * 0.16) + sin(float(i) * 2.4) * 65.0
			draw_colored_polygon(PackedVector2Array([Vector2(x, size.y), Vector2(x, top + 50.0), Vector2(x + step * 0.35, top), Vector2(x + step * 0.7, top + 35.0), Vector2(x + step, size.y)]), color)
	for i in range(32):
		var x := fposmod(i * 173.0 - camera_position.x * 0.24 + sin(clock * 0.2 + i) * 15.0, size.x)
		var y := fposmod(i * 97.0 + sin(clock * 0.35 + i * 2.0) * 18.0, size.y)
		draw_circle(Vector2(x, y), 1.3, Color(0.65, 0.83, 0.78, 0.22))
