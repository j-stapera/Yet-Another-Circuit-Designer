class_name VoltageSource
extends Component

var voltage = 10.0
static var counter = 0
@onready var shader = preload("res://Components/outline_glow.gdshader")

func _ready():
	component_type = "voltage_source"
	id = get_prefix() + str(counter)
	counter += 1
	
	label = $LineEdit
	id_label = $Label
	label.text = str(voltage)
	id_label.text = id
	Global.connect("theme_change", _update_theme)
	_update_theme(Global.currentTheme)

func get_value():
	return voltage

func set_value(new_value):
	voltage = new_value
	if label:
		label.text = str(voltage)
	print("Voltage changed to ", voltage)

func get_prefix() -> String:
	return "V"

func _on_line_edit_text_submitted(new_text):
	var v = new_text.to_float()
	set_value(v)
	
func _update_theme(newValue):
	if(newValue == false):
		get_node("Sprite2D").get_material().shader = null
	else:
		get_node("Sprite2D").get_material().shader = shader
