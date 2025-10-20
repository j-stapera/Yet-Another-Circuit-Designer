extends LineEdit

var previous_text

func _ready():
	pass



func _on_text_submitted(new_text):
	if new_text.is_valid_float():
		pass
	else:
		text = "Enter valid integer"


func _on_editing_toggled(toggled_on):
	if toggled_on:
		previous_text = get_selected_text()
		print("Selection made, previous_text set to ", get_selected_text())
