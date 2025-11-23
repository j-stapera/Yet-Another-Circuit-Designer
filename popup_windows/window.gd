extends Window

@onready var label = $Dialog


func change_label(new_text):
	print("Accessing")
	label.text = new_text


func _on_close_requested() -> void:
	hide()
