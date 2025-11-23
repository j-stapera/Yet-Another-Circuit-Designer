extends "res://popup_windows/window.gd"
@onready var info_window_scene = preload("res://popup_windows/informational_window.tscn")

func _on_ok_button_pressed() -> void:
	hide()
	
func _on_why_button_pressed() -> void:
	var info_window = info_window_scene.instantiate()
	get_tree().current_scene.add_child(info_window)
	info_window.change_label("This is where the errors in the circuit would be listed")
