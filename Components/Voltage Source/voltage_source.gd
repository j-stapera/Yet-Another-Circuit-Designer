class_name VoltageSource
extends Component

var voltage = 5.0
static var counter = 0

func _ready():
	component_type = "voltage_source"
	id = get_prefix() + str(counter)
	counter += 1
	
	label = $LineEdit
	id_label = $Label
	label.text = str(voltage)
	id_label.text = id

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
