extends Control


func _ready():
	$Window/LineEdit.call_deferred("grab_focus")

func _on_line_edit_text_submitted(new_text: String) -> void:
	queue_free()



func _on_window_close_requested() -> void:
	queue_free()
