class_name Capacitor
extends Component

var capacitance = 5000.0
static var counter = 0
@onready var shader = preload("res://Components/outline_glow.gdshader")
func _ready():
	component_type = "capacitor"
	id = get_prefix() + str(counter)
	counter += 1
	
	label = $LineEdit
	id_label = $Label
	label.text = str(capacitance)
	id_label.text = id
	Global.connect("theme_change", _update_theme)
	_update_theme(Global.currentTheme)


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
		"value": capacitance
	}

func load_save_data(data: Dictionary):
	id = data["id"]
	position = Vector2(data["position"]["x"], data["position"]["y"])
	rotation = data.get("rotation", 0.0)
	capacitance = data.get("value")

func get_value():
	return capacitance

func set_value(new_value):
	capacitance = new_value
	if label:
		label.text = str(capacitance)
	print("Resistance changed to ", capacitance)

func get_prefix() -> String:
	return "C"

func _on_line_edit_text_submitted(new_text):
	var res = new_text.to_float()
	set_value(res)

func _input(event):
	if event.is_action_pressed("Reset"):
		counter = 0
func _update_theme(newValue):
	if(newValue == false):
		get_node("Sprite2D").get_material().shader = null
	else:
		get_node("Sprite2D").get_material().shader = shader

func snap_to_grid(pos):
	var half_grid = Global.grid_size / 2.0
	#var rotation_mod = fmod(abs(holo_node.rotation_degrees), 180)
	
	return Vector2(
		round(pos.x / Global.grid_size) * Global.grid_size,
		round(pos.y / Global.grid_size) * Global.grid_size + half_grid
	)
	
