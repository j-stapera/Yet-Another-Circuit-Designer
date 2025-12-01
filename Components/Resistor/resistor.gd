class_name Resistor
extends Component

var resistance = 5000.0
static var counter = 0

func _ready():
	component_type = "resistor"
	id = get_prefix() + str(counter)
	counter += 1
	
	label = $LineEdit
	id_label = $Label
	label.text = str(resistance)
	id_label.text = id

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

	
