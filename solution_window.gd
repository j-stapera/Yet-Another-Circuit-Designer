extends Window

@onready var soln_text = $ScrollContainer/RichTextLabel

func populate_solution_text(solution_steps):
	var text = ""
	for step in solution_steps:
		if step.type == "step":
			text += "[b][font_size=24][color=#4A90E2]" + step.title + "[/color][/font_size][/b]\n"
			if "description" in step and step.description != "":
				text += step.description + "\n"
		elif step.type == "result":
			text += step.text + "\n"
		elif step.type == "equation":
			text += "[color=#E8B44C]  " + step.text + "[/color]\n"
		text += "\n"
	
	soln_text.text = text


func _on_close_requested() -> void:
	hide()
