extends Window

@onready var label = $Label


func change_label(new_text):
	label.text = new_text


func _on_close_requested() -> void:
	hide()
