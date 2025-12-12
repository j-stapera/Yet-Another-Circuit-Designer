extends Control

const grid_size = 128
const grid_color = Color(0.2, 0.2, 0.2, 0.5)
var wire_mode = false
var placing_wire = false
signal theme_change(newValue: bool)
var currentTheme = false


func _ready():
	z_index = -1


func _draw():
	var camera = get_viewport().get_camera_2d()
	if camera == null:
		return
		
	var viewport_size = get_viewport_rect().size
	var zoom = camera.zoom
	var camera_pos = camera.global_position
	
	var half_size = (viewport_size / zoom) / 2.0
	var top_left = camera_pos - half_size
	var bottom_right = camera_pos + half_size
	
	var start_x = int(top_left.x / Global.grid_size) * Global.grid_size
	var start_y = int(top_left.y / Global.grid_size) * Global.grid_size
	
	var x = start_x
	while x <= bottom_right.x:
		draw_line(Vector2(x, top_left.y), Vector2(x, bottom_right.y), Global.grid_color)
		x += Global.grid_size
	
	var y = start_y
	while y <= bottom_right.y:
		draw_line(Vector2(top_left.x, y), Vector2(bottom_right.x, y), Global.grid_color)
		y += Global.grid_size
