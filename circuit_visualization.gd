extends Window

@onready var circuit_display = $HSplitContainer/PanelContainer/Circuit
@onready var solution_text = $HSplitContainer/ScrollContainer/VBoxContainer/RichTextLabel

@onready var Graph = %Graph
@onready var Solver = %Solver
@onready var Loop = %"Mesh Loop"


@export var component_spacing = 100


func _on_close_requested() -> void:
	hide()
