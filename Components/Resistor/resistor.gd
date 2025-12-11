class_name Resistor
extends Component

var resistance = 5000.0
static var counter = 0
@onready var shader = preload("res://Components/outline_glow.gdshader")

func _ready():
	component_type = "resistor"
	id = get_prefix() + str(counter)
	counter += 1
	
	label = $LineEdit
	id_label = $Label
	label.text = str(resistance)
	id_label.text = id
	Global.connect("theme_change", _update_theme)
	_update_theme(Global.currentTheme)
	something_changed.connect(_on_something_changed)

func get_save_data():
	return {
		"type": component_type,
		"id": id,
		"position": {
			"x": position.x,
			"y": position.y
		},
		"rotation": rotation,
		"current": current,
		"value": resistance
	}

func load_save_data(data: Dictionary):
	id = data["id"]
	position = Vector2(data["position"]["x"], data["position"]["y"])
	rotation = data.get("rotation", 0.0)
	resistance = data.get("value")

func get_value():
	return resistance

func set_value(new_value):
	resistance = new_value
	if label:
		label.text = str(resistance)
	print("Resistance changed to ", resistance)

func get_prefix() -> String:
	return "R"

func _on_line_edit_text_submitted(new_text):
	var res = new_text.to_float()
	set_value(res)

func _input(event):
	if event.is_action_pressed("Reset"):
		counter = 0
	if hover and event.is_action_pressed("Delete"):
		queue_free()

func _update_theme(newValue):
	if(newValue == false):
		get_node("Sprite2D").get_material().shader = null
	else:
		get_node("Sprite2D").get_material().shader = shader
	
func snap_to_grid(pos):
	var half_grid = Global.grid_size / 2.0
	var rotation_mod = fmod(abs(rotation_degrees), 180)
	
	var is_rotated_90 = (rotation_mod > 45 && rotation_mod < 135)
	var should_be_vertical = false
	should_be_vertical = is_rotated_90
	if should_be_vertical:
		return Vector2(
			round(pos.x / Global.grid_size) * Global.grid_size,
			round(pos.y / Global.grid_size) * Global.grid_size + half_grid
		)
	else:
		return Vector2(
			round(pos.x / Global.grid_size) * Global.grid_size + half_grid,
			round(pos.y / Global.grid_size) * Global.grid_size
		)

func  _on_something_changed():
	print("Something changed")
