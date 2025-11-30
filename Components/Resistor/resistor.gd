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

#func on_input(event):
	#if event is InputEventMouseButton and event.is_pressed():
		#if event.is_double_click():
			#display_info()

#func display_info():
	#var info_instance = info_window.instance()
	#add_child(info_instance)
	#
	#var dialog = info_instance.get_child(0)
	#
	#dialog.set_text("Test")
	
