extends LineEdit

@onready var error_window = preload("res://gui_components/Error Window.tscn")

var previous_text



func _ready():
	pass



func _on_text_submitted(new_text):
	if new_text.is_valid_float():
		pass
	else:
		var err_win = error_window.instantiate()
		add_child(err_win)
		err_win.set_error("Enter valid integer")
		err_win.global_position = global_position - Vector2(0, 60)
			#var x_spawn = get_global_mouse_position().x
	#var y_spawn = get_global_mouse_position().y + 40
	#position = Vector2(x_spawn, y_spawn)


func _on_editing_toggled(toggled_on):
	if toggled_on:
		previous_text = get_selected_text()
		print("Selection made, previous_text set to ", get_selected_text())
