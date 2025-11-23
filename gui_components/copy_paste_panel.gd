extends Panel

@onready var confirm_window_scene = preload("res://popup_windows/one_button_window.tscn")
@onready var why_window_scene = preload("res://popup_windows/two_button_window.tscn")
@onready var info_window_scene = preload("res://popup_windows/informational_window.tscn")



func _on_simplify_button_pressed() -> void:
	# call simplify method
	# TODO: Make method call
	
	var info_window = info_window_scene.instantiate()
	get_tree().current_scene.add_child(info_window)
	info_window.change_label("This is where the output\nof the circuit simplication would be.")
	


func _on_check_button_pressed() -> void:
	# call circuit check method
	# TODO: Make method call, should return true or false
	var method_bool = false
	
	var check_window
	if method_bool == true:
		check_window = confirm_window_scene.instantiate()
		get_tree().current_scene.add_child(check_window)
		check_window.change_label("Circuit is a valid circuit")
	else:
		check_window = why_window_scene.instantiate()
		get_tree().current_scene.add_child(check_window)
		check_window.change_label("Circuit is not a valid circuit")
