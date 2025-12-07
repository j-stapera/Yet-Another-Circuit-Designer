extends PanelContainer

@onready var confirm_window_scene = preload("res://popup_windows/one_button_window.tscn")
@onready var why_window_scene = preload("res://popup_windows/two_button_window.tscn")
@onready var info_window_scene = preload("res://popup_windows/informational_window.tscn")
@onready var solution_window_scene = preload("res://popup_windows/solution_window.tscn")
@onready var shader = preload("res://gui_components/glass-panels.gdshader")

func _on_simplify_button_pressed() -> void:
	# call simplify method
	# TODO: Make method call
	
	var info_window = info_window_scene.instantiate()
	get_tree().current_scene.add_child(info_window)
	info_window.change_label("This is where the output\nof the circuit simplication would be.")



func _on_check_button_pressed() -> void:
	%Graph.run()
	var dict = %Graph.validate_circuit()
	var method_bool = false
	
	if dict["valid"]:
		method_bool = true
	
	var check_window
	if method_bool == true:
		check_window = confirm_window_scene.instantiate()
		get_tree().current_scene.add_child(check_window)
		check_window.change_label("Circuit is a valid circuit")
	else:
		check_window = why_window_scene.instantiate()
		get_tree().current_scene.add_child(check_window)
		check_window.change_label("Circuit is not a valid circuit")






func _on_solve_pressed() -> void:
	%Graph.run()
	if %OptionButton.get_selected() == 0:
		%Solver.run()
	if %OptionButton.get_selected() == 1:
		%"Mesh Loop".run()
	#var soln_window = solution_window_scene.instantiate()
	#add_child(soln_window)





func _on_save_button_pressed() -> void:
	pass # Replace with function body.
	
func _on_theme_toggle_toggled(toggled_on: bool) -> void:
	Global.currentTheme = toggled_on
	Global.emit_signal("theme_change", toggled_on)
	if(toggled_on == false):
		get_material().shader = null
	else:
		get_material().shader = shader
