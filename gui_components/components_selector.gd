extends FoldableContainer

#func _process():
	#if folded:
		
## There was probably a smarter way of doing this. I dont care
@onready var shader = preload("res://gui_components/glass-panels.gdshader")
func _on_button_resistor_mouse_entered() -> void:
	$"MarginContainer/VBoxContainer/Button Resistor/PanelContainer".visible = true


func _on_button_resistor_mouse_exited() -> void:
	$"MarginContainer/VBoxContainer/Button Resistor/PanelContainer".visible = false



func _on_button_capacitor_mouse_entered() -> void:
	$"MarginContainer/VBoxContainer/Button Capacitor/PanelContainer".visible = true


func _on_button_capacitor_mouse_exited() -> void:
	$"MarginContainer/VBoxContainer/Button Capacitor/PanelContainer".visible = false

func _on_button_voltage_source_mouse_entered() -> void:
	$"MarginContainer/VBoxContainer/Button Voltage Source/PanelContainer".visible = true

func _on_button_voltage_source_mouse_exited() -> void:
	$"MarginContainer/VBoxContainer/Button Voltage Source/PanelContainer".visible = false

func _on_button_wire_mouse_entered() -> void:
	$"MarginContainer/VBoxContainer/Button Wire/PanelContainer".visible = true

func _on_button_wire_mouse_exited() -> void:
	$"MarginContainer/VBoxContainer/Button Wire/PanelContainer".visible = false



func _on_button_inductor_mouse_entered() -> void:
	$"MarginContainer/VBoxContainer/Button Inductor/PanelContainer".visible = true


func _on_button_inductor_mouse_exited() -> void:
	$"MarginContainer/VBoxContainer/Button Inductor/PanelContainer".visible = false



func _on_button_current_source_mouse_entered() -> void:
	$"MarginContainer/VBoxContainer/Button Current Source/PanelContainer".visible = true


func _on_button_current_source_mouse_exited() -> void:
	$"MarginContainer/VBoxContainer/Button Current Source/PanelContainer".visible = false


func _on_theme_toggle_toggled(toggled_on: bool) -> void:
	if(toggled_on == false):
		get_material().shader = null
	else:
		get_material().shader = shader
