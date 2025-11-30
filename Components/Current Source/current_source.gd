class_name CurrentSource
extends Component

@onready var shader = preload("res://Components/outline_glow.gdshader")
static var counter = 0

func _ready():
	component_type = "current_source"
	id = get_prefix() + str(counter)
	counter += 1
	current = 1
	
	# Set up UI
	label = $LineEdit
	id_label = $Label
	label.text = str(current)
	id_label.text = id
	Global.connect("theme_change", _update_theme)

func get_value():
	return current

func set_value(new_value):
	current = new_value
	if label:
		label.text = str(current)
	print("Current changed to ", current)

func get_prefix() -> String:
	return "I"

func _on_line_edit_text_submitted(new_text):
	var i = new_text.to_float()
	set_value(i)
	
func _update_theme(newValue):
	if(newValue == false):
		get_node("CurrentSource").get_material().shader = null
	else:
		get_node("CurrentSource").get_material().shader = shader
