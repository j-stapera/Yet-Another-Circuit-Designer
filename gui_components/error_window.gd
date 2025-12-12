extends Control



func set_error(err: String):
	$PanelContainer/Label.text = err
	


func _on_panel_container_mouse_entered() -> void:
	$Timer.start()



func _on_timer_timeout() -> void:
	queue_free()

func _process(_delta):
	var transparency = $Timer.get_time_left()
	$PanelContainer.self_modulate = Color(0, 0, 0, transparency)
	$PanelContainer/Label.self_modulate = Color(1, 1, 1, transparency)
	
